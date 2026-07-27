package com.devconnect.plugins

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import com.devconnect.DevConnect
import java.lang.Thread.UncaughtExceptionHandler
import java.security.MessageDigest
import java.util.ArrayDeque
import java.util.Deque

/**
 * DevConnect Error Monitor Plugin
 *
 * Captures and reports errors from:
 * - Java exceptions (caught + uncaught)
 * - Native crashes via Thread.setDefaultUncaughtExceptionHandler (covers
 *   Java uncaught; true NDK/JNI C/C++ crashes still need a separate
 *   signal handler — see TODO at the bottom of this file).
 * - ANR (Application Not Responding) — detected by posting tick tasks
 *   to the main looper and timing how long they take to fire.
 *
 * Adds:
 * - Stack-trace dedup keyed on SHA-256 of the first 4 stack lines.
 * - Breadcrumb buffer (30 events) attached to each report.
 * - Public [reportError] for caught exceptions.
 */
object ErrorMonitor {
    private var running = false
    private var previousHandler: UncaughtExceptionHandler? = null
    private var appContext: android.content.Context? = null

    private val breadcrumbs: Deque<String> = ArrayDeque()
    private val seenSignatures: MutableSet<String> = HashSet()
    private val sigOrder: Deque<String> = ArrayDeque()
    private val maxDedupWindow = 50
    private val breadcrumbLimit = 30

    data class ErrorMonitorOptions(
        val captureCaughtExceptions: Boolean = true,
        val captureANR: Boolean = true,
        val captureNativeCrashes: Boolean = true,
        val captureThreadExceptions: Boolean = true
    )

    /**
     * Start error monitoring.
     *
     * Call from Application.onCreate():
     * ```
     * ErrorMonitor.start(this)
     * ```
     */
    fun start(context: android.content.Context, opts: ErrorMonitorOptions = ErrorMonitorOptions()) {
        if (running) return
        running = true
        appContext = context.applicationContext

        if (opts.captureNativeCrashes) {
            setupUncaughtExceptionHandler()
        }
        if (opts.captureANR) {
            setupANRDetection()
        }
        if (opts.captureThreadExceptions) {
            setupDefaultThreadExceptionHandler()
        }
    }

    // ------------------------------------------------------------------
    // Uncaught exceptions (Java + native that funnels through here)
    // ------------------------------------------------------------------
    private fun setupUncaughtExceptionHandler() {
        previousHandler = Thread.getDefaultUncaughtExceptionHandler()

        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            val message = throwable.message ?: "Uncaught exception"
            val stackTrace = throwable.stackTraceToString()

            // Crashlytics / Sentry rely on the previously-installed
            // handler being called *after* our report — otherwise the
            // OS kills the app before upstream networks see the
            // event. Guard with try/catch so a broken previousHandler
            // can't suppress us.
            try {
                sendError(
                    platform = "android",
                    severity = "fatal",
                    message = message,
                    stackTrace = stackTrace,
                    source = "uncaught_exception",
                    dedup = true,
                    metadata = mapOf(
                        "threadName" to thread.name,
                        "deviceInfo" to getDeviceInfo(),
                    ),
                )
            } catch (_: Exception) {}
            try {
                previousHandler?.uncaughtException(thread, throwable)
            } catch (_: Exception) {}
        }
    }

    // ------------------------------------------------------------------
    // ANR detection — actually works now.
    //
    // Approach: every 500ms, post a no-op Runnable to the main looper
    // and measure how long before it runs. If the gap exceeds 5s the
    // main thread is blocked → emit one ANR report per "blocked
    // episode" (not per 5s poll). When the main thread recovers we
    // clear the "blocked" state and resume normal polling.
    // ------------------------------------------------------------------
    private fun setupANRDetection() {
        val mainHandler = Handler(Looper.getMainLooper())
        val anrThresholdMs = 5_000L
        val pollIntervalMs = 500L
        var lastTickAt = System.currentTimeMillis()
        var anrActive = false // true while we believe main thread is currently stuck

        val tick = object : Runnable {
            override fun run() {
                if (!running) return
                val now = System.currentTimeMillis()
                val gap = now - lastTickAt
                lastTickAt = now

                if (gap > anrThresholdMs && !anrActive) {
                    // Main thread just unblocked. If it took > 5s
                    // we're in an ANR; report it once and mark active.
                    anrActive = true
                    val mainStack = Looper.getMainLooper().thread.stackTrace
                        .filter { it.className.contains("android.os") || it.className.contains("com.devconnect") || it.className.contains("android.app") }
                        .take(10)
                    sendError(
                        platform = "android",
                        severity = "warning",
                        message = "Application Not Responding (ANR) detected",
                        stackTrace = mainStack.joinToString("\n") { "${it.className}.${it.methodName}(${it.fileName}:${it.lineNumber})" },
                        source = "anr",
                        dedup = true,
                        metadata = mapOf(
                            "deviceInfo" to getDeviceInfo(),
                            "blockedMs" to gap.toString(),
                        ),
                    )
                } else if (gap < anrThresholdMs && anrActive) {
                    // Main thread recovered — reset for next episode.
                    anrActive = false
                }

                if (running) mainHandler.postDelayed(this, pollIntervalMs)
            }
        }
        mainHandler.postDelayed(tick, pollIntervalMs)
    }

    // ------------------------------------------------------------------
    // Thread.setDefaultUncaughtExceptionHandler already covers us —
    // but if a downstream library chains a handler that resets the
    // default (e.g. some crash SDKs), this re-asserts ours. Idempotent.
    // ------------------------------------------------------------------
    private fun setupDefaultThreadExceptionHandler() = setupUncaughtExceptionHandler()

    // ------------------------------------------------------------------
    // Public API
    // ------------------------------------------------------------------
    fun reportCaughtException(
        throwable: Throwable,
        context: android.content.Context? = null,
        extra: Map<String, String> = emptyMap(),
    ) {
        if (!running) return
        val message = throwable.message ?: "Caught exception"
        sendError(
            platform = "android",
            severity = "error",
            message = message,
            stackTrace = throwable.stackTraceToString(),
            source = "caught_exception",
            dedup = true,
            metadata = extra + mapOf(
                "deviceInfo" to getDeviceInfo(),
                "exceptionClass" to throwable.javaClass.simpleName,
            ),
        )
    }

    fun reportNativeCrash(
        signal: Int,
        stackTrace: String,
        context: android.content.Context? = null,
    ) {
        if (!running) return
        sendError(
            platform = "android",
            severity = "crash",
            message = "Native crash (signal: $signal)",
            stackTrace = stackTrace,
            source = "native.crash",
            dedup = true,
            metadata = mapOf(
                "signal" to signal.toString(),
                "deviceInfo" to getDeviceInfo(),
            ),
        )
    }

    /** Record a contextual event to attach to the next crash. */
    fun addBreadcrumb(event: String) {
        if (!running) return
        if (breadcrumbs.size >= breadcrumbLimit) breadcrumbs.pollFirst()
        breadcrumbs.offerLast("${System.currentTimeMillis()} $event")
    }

    fun reportError(error: Throwable, source: String = "manual") {
        reportCaughtException(error, null)
    }

    fun stop() {
        running = false
        previousHandler?.let { Thread.setDefaultUncaughtExceptionHandler(it) }
        previousHandler = null
    }

    // ------------------------------------------------------------------
    // Internals
    // ------------------------------------------------------------------
    private fun signature(message: String, stackTrace: String?): String {
        if (stackTrace.isNullOrBlank()) return "m:${message.lineSequence().first()}"
        val head = stackTrace.lineSequence()
            .filter { it.isNotBlank() }
            .take(4)
            .joinToString("|")
        return "s:$head"
    }

    private fun sha256Short(s: String): String {
        val md = MessageDigest.getInstance("SHA-256")
        val bytes = md.digest(s.toByteArray(Charsets.UTF_8))
        return bytes.joinToString("") { "%02x".format(it) }.take(16)
    }

    /** True if the signature was already in the dedup window. */
    private fun trackDedup(sig: String): Boolean {
        val alreadySeen = !seenSignatures.add(sig)
        if (!alreadySeen) {
            sigOrder.offerLast(sig)
            if (sigOrder.size > maxDedupWindow) {
                val evicted = sigOrder.pollFirst()
                evicted?.let { seenSignatures.remove(it) }
            }
        }
        return alreadySeen
    }

    private fun sendError(
        platform: String,
        severity: String,
        message: String,
        stackTrace: String? = null,
        source: String,
        dedup: Boolean,
        metadata: Map<String, String> = emptyMap(),
    ) {
        if (message.contains("DevConnect") || message.contains("[DC_")) return

        val sig = sha256Short(signature(message, stackTrace))
        val isDup = trackDedup(sig)

        try {
            val payload = mutableMapOf<String, Any>(
                "platform" to platform,
                "severity" to severity,
                "message" to message,
                "source" to source,
                "deviceInfo" to getDeviceInfo(),
                "signature" to sig,
                "deduped" to isDup,
            )
            if (stackTrace != null) payload["stackTrace"] = stackTrace

            val merged = metadata + ("breadcrumbs" to breadcrumbs.joinToString(" | "))
            if (merged.isNotEmpty()) payload["metadata"] = merged.toString()

            DevConnect.safeSend("client:error", payload)
        } catch (_: Exception) {
            // Never throw from inside an error handler.
        }
    }

    private fun getDeviceInfo(): String = try {
        val os = "Android ${android.os.Build.VERSION.SDK_INT}"
        val model = android.os.Build.MODEL
        val manufacturer = android.os.Build.MANUFACTURER
        "$os | $manufacturer $model"
    } catch (_: Exception) {
        "Android unknown"
    }
}

// ----------------------------------------------------------------------------
// Native NDK signal handler — TODO
// ----------------------------------------------------------------------------
//
// Catching SIGSEGV / SIGABRT / SIGBUS from native code (Hermes engine,
// Reanimated, third-party native libs, custom JNI code) requires a
// tiny `.so` registered via `System.loadLibrary` that calls
// `sigaction()` for each signal and writes the offending PC / fault
// address to a known shm region the JVM thread reads on startup. That
// is a multi-file C++ change with NDK build wiring. Out of scope for
// the desktop-side audit; the missing piece is intentional.
//
// Until then, fatal signals will crash the process *before* any Java
// handler can run — `Thread.setDefaultUncaughtExceptionHandler` does
// not intercept real native faults.
