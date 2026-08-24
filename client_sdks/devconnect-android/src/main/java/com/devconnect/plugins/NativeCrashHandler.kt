package com.devconnect.plugins

import android.os.Handler
import android.os.Looper
import com.devconnect.DevConnect
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Native crash handler bridge.
 *
 * Loads `libdc-native.so` and starts a polling coroutine that drains
 * the native crash buffer (filled by the `sigaction` handlers in
 * [signal_handler.cpp]) on a normal thread, then forwards the result
 * to [ErrorMonitor.reportNativeCrash] on the main thread.
 *
 * **Split between handler and reporting**: the native handlers are
 * installed at library load time inside `JNI_OnLoad`, so they run
 * whether or not [start] is called. This is the *safety net*. [start]
 * only gates the *reporting* path — flipping `autoNativeCrashHandler
 * = false` at install time stops reports from being sent to the
 * desktop without removing the crash-trace capture (which is what the
 * OS uses to write a tombstone).
 *
 * **Library loading is best-effort**: if NDK is unavailable (JVM unit
 * tests, stripped AAR, or a host that has no `libdc-native.so`), [start]
 * silently no-ops. The rest of the SDK still works.
 *
 * The polling interval is 250 ms — fast enough that we catch a crash
 * before the process exits, slow enough that the overhead is
 * negligible. The handler in C++ is async-signal-safe; the Kotlin
 * side is not, hence the coroutine boundary.
 */
object NativeCrashHandler {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var pollingJob: Job? = null

    @Volatile private var libraryLoaded = false

    /**
     * Start polling. Idempotent — repeat calls are no-ops while the
     * poller is alive.
     */
    fun start() {
        if (pollingJob?.isActive == true) return

        try {
            if (!libraryLoaded) {
                System.loadLibrary("dc-native")
                libraryLoaded = true
            }
        } catch (_: UnsatisfiedLinkError) {
            // NDK library not available. This is expected on the JVM
            // unit-test runtime and on hosts where the AAR was built
            // without the .so files. Silently disable — the rest of
            // the SDK still works.
            return
        }

        pollingJob = scope.launch {
            // Reuse buffers across ticks so we don't churn the heap.
            val signalBuf = IntArray(1)
            val stackBuf = arrayOfNulls<String>(DC_NATIVE_STACK_DEPTH)

            while (isActive) {
                try {
                    if (nativeTakeCrash(signalBuf, stackBuf)) {
                        val sig = signalBuf[0]
                        val stack = buildString {
                            for (line in stackBuf) {
                                if (line != null) {
                                    append(line)
                                    append('\n')
                                }
                            }
                        }.trimEnd()
                        // Marshal to the main thread so ErrorMonitor's
                        // main-thread Looper assumptions hold.
                        Handler(Looper.getMainLooper()).post {
                            try {
                                ErrorMonitor.reportNativeCrash(sig, stack)
                            } catch (_: Throwable) {
                                // never throw from a crash handler
                            }
                        }
                    }
                } catch (_: Throwable) {
                    // A bad native read must not kill the poller.
                }
                delay(POLL_INTERVAL_MS)
            }
        }
    }

    /**
     * Stop polling and uninstall the signal handlers. After [stop] the
     * SDK no longer captures native crashes until [start] is called
     * again.
     */
    fun stop() {
        pollingJob?.cancel()
        pollingJob = null
        if (libraryLoaded) {
            try {
                nativeUninstall()
            } catch (_: UnsatisfiedLinkError) {
                // Library not loaded — nothing to uninstall.
            } catch (_: Throwable) {
                // Never throw from stop().
            }
        }
    }

    /**
     * Drain the native crash buffer. Fills [signalBuf] (index 0) with
     * the captured signal number and [stackBuf] with up to 32 captured
     * stack lines. Returns true if a crash was captured since the last
     * call, false otherwise.
     *
     * Native impl: `cpp/signal_handler.cpp` — `Java_..._nativeTakeCrash`.
     */
    @JvmStatic
    private external fun nativeTakeCrash(
        signalBuf: IntArray,
        stackBuf: Array<String?>,
    ): Boolean

    /**
     * Restore the default signal disposition for all captured signals.
     * Idempotent.
     */
    @JvmStatic
    private external fun nativeUninstall()

    private const val POLL_INTERVAL_MS = 250L
    private const val DC_NATIVE_STACK_DEPTH = 32
}
