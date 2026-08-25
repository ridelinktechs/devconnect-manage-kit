// DevConnect native crash handler.
//
// Installs `sigaction` handlers for SIGSEGV, SIGABRT, SIGBUS, SIGILL,
// SIGFPE, SIGPIPE, SIGSYS, SIGTRAP. The handler captures raw program
// counters via `_Unwind_Backtrace()` (<unwind.h> — available on every
// Android API level, unlike <execinfo.h>'s `backtrace()` which Bionic
// only exposes from API 33). Only pre-allocated buffers are written,
// so it is async-signal-safe: no malloc, no locks, no JNI calls.
//
// Symbolication happens later on the Kotlin polling thread inside
// `nativeTakeCrash()` using `dladdr()` — that thread is not in signal
// context, so formatting/symbol lookup is safe there.
//
// After capturing, the handler restores the default disposition and
// re-raises so the process still dies normally (tombstone + system
// crash dialog) instead of hanging in a crash loop.
//
// A Kotlin coroutine polls the buffer via JNI on a normal thread
// (`NativeCrashHandler.kt`) and forwards captured crashes to
// `ErrorMonitor.reportNativeCrash(...)`.

#include <jni.h>
#include <signal.h>
#include <unwind.h>
#include <dlfcn.h>
#include <unistd.h>
#include <cstring>
#include <cstdio>
#include <cstdlib>

#define DC_NATIVE_STACK_DEPTH 32
#define DC_NATIVE_SIGNAL_COUNT 8

// Pre-allocated crash record. Volatile + sig_atomic_t = async-signal-safe.
struct DcCrashRecord {
    volatile sig_atomic_t pending;       // 1 when a crash was captured
    volatile sig_atomic_t signal;        // the signal number
    int frame_count;                     // number of valid PCs
    void *pcs[DC_NATIVE_STACK_DEPTH];    // raw program counters
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

struct DcUnwindState {
    void **pcs;
    int count;
    int max;
};

static _Unwind_Reason_Code dc_unwind_callback(
        struct _Unwind_Context *ctx, void *data) {
    DcUnwindState *s = static_cast<DcUnwindState *>(data);
    if (s->count >= s->max) {
        return _URC_END_OF_STACK;
    }
    s->pcs[s->count++] =
        reinterpret_cast<void *>(_Unwind_GetIP(ctx));
    return _URC_NO_REASON;
}

static void dc_crash_handler(int sig, siginfo_t * /*info*/, void * /*ucontext*/) {
    if (g_in_handler) {
        return;
    }
    g_in_handler = 1;

    g_crash.signal = sig;

    // Collect raw PCs only — `_Unwind_Backtrace` walks the DWARF/EHABI
    // unwind tables without allocating, so it is safe from signal
    // context. Symbolication is deferred to `nativeTakeCrash`.
    DcUnwindState state{g_crash.pcs, 0, DC_NATIVE_STACK_DEPTH};
    _Unwind_Backtrace(dc_unwind_callback, &state);
    g_crash.frame_count = state.count;
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

// Format one PC as "<lib> (<symbol>+<off>) [pc 0x...]" or a bare hex
// fallback when dladdr can't resolve it. Runs on the polling thread —
// NOT in signal context — so snprintf/dladdr are fine here.
static void dc_format_pc(void *pc, char *out, size_t outSize) {
    Dl_info info{};
    if (dladdr(pc, &info) && info.dli_fname) {
        const char *sym = info.dli_sname ? info.dli_sname : "?";
        long off = info.dli_saddr
            ? static_cast<long>(
                  reinterpret_cast<char *>(pc) -
                  reinterpret_cast<char *>(info.dli_saddr))
            : 0L;
        snprintf(out, outSize, "%s (%s+%ld) [pc %p]",
                 info.dli_fname, sym, off, pc);
    } else {
        snprintf(out, outSize, "pc %p", pc);
    }
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

    // Symbolicate + fill the JVM-allocated String[]. We are on the
    // Kotlin polling thread here, NOT in signal context, so dladdr and
    // snprintf are safe.
    for (int i = 0; i < n; i++) {
        char line[256];
        dc_format_pc(g_crash.pcs[i], line, sizeof(line));
        jstring s = env->NewStringUTF(line);
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
