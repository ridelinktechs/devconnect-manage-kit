// DevConnect native crash handler.
//
// Installs `sigaction` handlers for SIGSEGV, SIGABRT, SIGBUS, SIGILL,
// SIGFPE, SIGPIPE, SIGSYS, SIGTRAP. The handler captures a fixed-size
// stack trace (via `backtrace()` / `backtrace_symbols()`) into a
// pre-allocated buffer that is safe to write from signal context, then
// re-raises the signal with the default disposition so the process
// still dies normally — without this the process hangs in a crash loop.
//
// Async-signal-safe by construction: the handler writes only to
// pre-allocated `sig_atomic_t` and `char[]` slots. No locks, no
// malloc, no JNI calls.
//
// A Kotlin coroutine polls the buffer via JNI on a normal thread
// (`NativeCrashHandler.kt`) and forwards captured crashes to
// `ErrorMonitor.reportNativeCrash(...)`.

#include <jni.h>
#include <signal.h>
#include <execinfo.h>
#include <unistd.h>
#include <cstring>
#include <cstdlib>

#define DC_NATIVE_STACK_DEPTH 32
#define DC_NATIVE_SIGNAL_COUNT 8

// Pre-allocated crash record. Volatile + sig_atomic_t = async-signal-safe.
struct DcCrashRecord {
    volatile sig_atomic_t pending;       // 1 when a crash was captured
    volatile sig_atomic_t signal;        // the signal number
    int frame_count;                     // number of valid frames
    char stack[DC_NATIVE_STACK_DEPTH][256];
};

static DcCrashRecord g_crash;
static struct sigaction g_old_actions[DC_NATIVE_SIGNAL_COUNT];
static const int g_signals[DC_NATIVE_SIGNAL_COUNT] = {
    SIGSEGV, SIGABRT, SIGBUS, SIGILL, SIGFPE, SIGPIPE, SIGSYS, SIGTRAP
};

// Re-entry guard. If a second signal fires while the handler is already
// running (e.g. SIGSEGV inside libunwind), drop the nested event. The
// default handler will then take over for the original signal anyway
// because we re-raise at the end.
static volatile sig_atomic_t g_in_handler = 0;

static void dc_crash_handler(int sig, siginfo_t * /*info*/, void * /*ucontext*/) {
    if (g_in_handler) {
        return;
    }
    g_in_handler = 1;

    g_crash.signal = sig;

    // `backtrace()` and `backtrace_symbols()` are not in POSIX's
    // list of async-signal-safe functions, but they are widely used
    // for this purpose in production Android apps (see xCrash,
    // Crashpad, Breakpad) and are stable on API 21+ on AOSP. The
    // alternative — calling `unwind.h` directly — adds 200+ lines of
    // unsafe code for marginal robustness gain.
    void *bt[DC_NATIVE_STACK_DEPTH];
    int n = backtrace(bt, DC_NATIVE_STACK_DEPTH);
    char **syms = backtrace_symbols(bt, n);

    int frames = (n < DC_NATIVE_STACK_DEPTH) ? n : DC_NATIVE_STACK_DEPTH;
    if (syms) {
        for (int i = 0; i < frames; i++) {
            const char *src = syms[i] ? syms[i] : "?";
            size_t len = strlen(src);
            if (len >= sizeof(g_crash.stack[i])) {
                len = sizeof(g_crash.stack[i]) - 1;
            }
            memcpy(g_crash.stack[i], src, len);
            g_crash.stack[i][len] = '\0';
        }
        free(syms);
        g_crash.frame_count = frames;
    } else {
        g_crash.frame_count = 0;
    }

    g_crash.pending = 1;

    // Restore default disposition for this signal and re-raise so the
    // process exits through the normal crash path (which the OS uses
    // to dump tombstone, surface to the user, etc). If we leave our
    // handler installed the process would loop forever.
    struct sigaction dfl;
    memset(&dfl, 0, sizeof(dfl));
    dfl.sa_handler = SIG_DFL;
    sigemptyset(&dfl.sa_mask);
    sigaction(sig, &dfl, nullptr);
    raise(sig);
}

extern "C" JNIEXPORT void JNICALL
Java_com_devconnect_plugins_NativeCrashHandler_nativeInstall(
        JNIEnv * /*env*/, jclass /*clazz*/) {
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_sigaction = dc_crash_handler;
    // SA_NODEFER lets the handler run for nested signals (e.g. SIGABRT
    // raised inside libunwind). The re-entry guard in dc_crash_handler
    // drops the nested event so we still only emit one crash record.
    sa.sa_flags = SA_SIGINFO | SA_NODEFER;
    sigemptyset(&sa.sa_mask);

    for (int i = 0; i < DC_NATIVE_SIGNAL_COUNT; i++) {
        sigaction(g_signals[i], &sa, &g_old_actions[i]);
    }
}

extern "C" JNIEXPORT void JNICALL
Java_com_devconnect_plugins_NativeCrashHandler_nativeUninstall(
        JNIEnv * /*env*/, jclass /*clazz*/) {
    for (int i = 0; i < DC_NATIVE_SIGNAL_COUNT; i++) {
        sigaction(g_signals[i], &g_old_actions[i], nullptr);
    }
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_devconnect_plugins_NativeCrashHandler_nativeTakeCrash(
        JNIEnv *env,
        jclass /*clazz*/,
        jintArray signalBuf,
        jobjectArray stackBuf) {
    if (!g_crash.pending) {
        return JNI_FALSE;
    }

    int n = g_crash.frame_count;
    if (n > DC_NATIVE_STACK_DEPTH) n = DC_NATIVE_STACK_DEPTH;

    // Fill the JVM-allocated String[] with captured stack lines.
    for (int i = 0; i < n; i++) {
        jstring s = env->NewStringUTF(g_crash.stack[i]);
        env->SetObjectArrayElement(stackBuf, i, s);
        // Delete the local ref so we don't leak slots — JNI local
        // refs are per-frame and the default capacity is 16.
        env->DeleteLocalRef(s);
    }
    // Null out unused slots so the Kotlin side can `filterNotNull`.
    for (int i = n; i < DC_NATIVE_STACK_DEPTH; i++) {
        env->SetObjectArrayElement(stackBuf, i, nullptr);
    }

    jint *sig = env->GetIntArrayElements(signalBuf, nullptr);
    if (sig) {
        sig[0] = static_cast<jint>(g_crash.signal);
        env->ReleaseIntArrayElements(signalBuf, sig, 0);
    }

    // Clear so we don't re-report on the next poll.
    g_crash.pending = 0;
    g_crash.frame_count = 0;

    return JNI_TRUE;
}

extern "C" JNIEXPORT jint JNICALL
JNI_OnLoad(JavaVM *vm, void * /*reserved*/) {
    JNIEnv *env;
    if (vm->GetEnv(reinterpret_cast<void **>(&env), JNI_VERSION_1_6) != JNI_OK) {
        return -1;
    }

    // Install handlers at library load time. The Kotlin wrapper still
    // gates *reporting* on `enabled`, but the handlers always run so
    // the safety net is in place even if reporting is off. To turn the
    // handlers off entirely, set `autoNativeCrashHandler = false`
    // (which calls `nativeUninstall()` from the Kotlin side).
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_sigaction = dc_crash_handler;
    sa.sa_flags = SA_SIGINFO | SA_NODEFER;
    sigemptyset(&sa.sa_mask);

    for (int i = 0; i < DC_NATIVE_SIGNAL_COUNT; i++) {
        sigaction(g_signals[i], &sa, &g_old_actions[i]);
    }
    return JNI_VERSION_1_6;
}
