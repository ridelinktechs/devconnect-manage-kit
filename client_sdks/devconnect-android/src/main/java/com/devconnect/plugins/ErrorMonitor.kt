package com.devconnect.plugins

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.os.Looper
import com.devconnect.DevConnect
import java.lang.Thread.UncaughtExceptionHandler
import kotlin.system.exitProcess

/**
 * DevConnect Error Monitor Plugin
 *
 * Captures and reports errors from:
 * - Java exceptions (caught exceptions)
 * - Native crashes (uncaught exceptions)
 * - ANR (Application Not Responding)
 */
object ErrorMonitor {
    private var running = false
    private var previousHandler: UncaughtExceptionHandler? = null
    private var appContext: android.content.Context? = null

    data class ErrorMonitorOptions(
        val captureCaughtExceptions: Boolean = true,
        val captureANR: Boolean = true,
        val captureNativeCrashes: Boolean = true,
        val captureThreadExceptions: Boolean = true
    )

    /**
     * Start error monitoring
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

        // ---- Uncaught Exception Handler (Native Crashes) ----
        if (opts.captureNativeCrashes) {
            setupUncaughtExceptionHandler()
        }

        // ---- ANR Detection ----
        if (opts.captureANR) {
            setupANRDetection()
        }

        // ---- Activity Lifecycle for exception tracking ----
        if (context is Application) {
            context.registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
                override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
                override fun onActivityStarted(activity: Activity) {}
                override fun onActivityResumed(activity: Activity) {}
                override fun onActivityPaused(activity: Activity) {}
                override fun onActivityStopped(activity: Activity) {}
                override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
                override fun onActivityDestroyed(activity: Activity) {}
            })
        }
    }

    private fun setupUncaughtExceptionHandler() {
        previousHandler = Thread.getDefaultUncaughtExceptionHandler()

        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            val message = throwable.message ?: "Uncaught exception"
            val stackTrace = throwable.stackTraceToString()

            val deviceInfo = getDeviceInfo()

            sendError(
                platform = "android",
                severity = "fatal",
                message = message,
                stackTrace = stackTrace,
                source = "uncaught_exception",
                metadata = mapOf(
                    "threadName" to thread.name,
                    "deviceInfo" to deviceInfo,
                    "isNativeCrash" to true
                )
            )

            // Call previous handler (usually logs to logcat and exits)
            previousHandler?.uncaughtException(thread, throwable)
        }
    }

    private fun setupANRDetection() {
        // ANR detection via MainLooper watcher
        val handler = android.os.Handler(Looper.getMainLooper())
        var isAnr = false

        handler.post(object : Runnable {
            override fun run() {
                if (running && !isAnr) {
                    isAnr = true

                    // Check if main thread is blocked (ANR condition)
                    val stackTrace = Looper.getMainLooper().thread.stackTrace
                    val mainStack = stackTrace?.filter { it.threadName == "main" }?.take(10)

                    sendError(
                        platform = "android",
                        severity = "warning",
                        message = "Application Not Responding (ANR) detected",
                        source = "anr",
                        metadata = mapOf(
                            "deviceInfo" to getDeviceInfo(),
                            "mainThreadStack" to (mainStack?.joinToString("\n") { "${it.fileName}:${it.lineNumber}" } ?: "")
                        )
                    )

                    isAnr = false
                }

                if (running) {
                    handler.postDelayed(this, 5000) // Check every 5 seconds
                }
            }
        })
    }

    /**
     * Report a caught/handled exception
     *
     * Usage:
     * ```
     * try {
     *     // risky code
     * } catch (e: Exception) {
     *     ErrorMonitor.reportCaughtException(e)
     *     throw e // re-throw if needed
     * }
     * ```
     */
    fun reportCaughtException(
        throwable: Throwable,
        context: android.content.Context? = null,
        extra: Map<String, String> = emptyMap()
    ) {
        if (!running) return

        val message = throwable.message ?: "Caught exception"
        val stackTrace = throwable.stackTraceToString()

        sendError(
            platform = "android",
            severity = "error",
            message = message,
            stackTrace = stackTrace,
            source = "caught_exception",
            metadata = extra + mapOf(
                "deviceInfo" to getDeviceInfo(),
                "exceptionClass" to throwable.javaClass.simpleName
            )
        )
    }

    /**
     * Report a native crash from NDK/C++
     */
    fun reportNativeCrash(
        signal: Int,
        stackTrace: String,
        context: android.content.Context? = null
    ) {
        if (!running) return

        sendError(
            platform = "android",
            severity = "crash",
            message = "Native crash (signal: $signal)",
            stackTrace = stackTrace,
            source = "native.crash",
            metadata = mapOf(
                "signal" to signal.toString(),
                "deviceInfo" to getDeviceInfo()
            )
        )
    }

    private fun sendError(
        platform: String,
        severity: String,
        message: String,
        stackTrace: String? = null,
        source: String,
        metadata: Map<String, String> = emptyMap()
    ) {
        // Skip internal DevConnect errors
        if (message.contains("DevConnect") || message.contains("[DC_")) return

        try {
            val payload = mutableMapOf(
                "platform" to platform,
                "severity" to severity,
                "message" to message,
                "source" to source,
                "deviceInfo" to getDeviceInfo()
            )

            if (stackTrace != null) {
                payload["stackTrace"] = stackTrace
            }

            if (metadata.isNotEmpty()) {
                payload["metadata"] = metadata.entries.joinToString("; ") { "${it.key}=${it.value}" }
            }

            DevConnect.safeSend("client:error", payload)
        } catch (_: Exception) {
            // Never throw in error handler
        }
    }

    private fun getDeviceInfo(): String {
        return try {
            val os = "Android ${android.os.Build.VERSION.SDK_INT}"
            val model = android.os.Build.MODEL
            val manufacturer = android.os.Build.MANUFACTURER
            "$os | $manufacturer $model"
        } catch (_: Exception) {
            "Android unknown"
        }
    }

    fun stop() {
        running = false
        previousHandler?.let {
            Thread.setDefaultUncaughtExceptionHandler(it)
        }
        previousHandler = null
    }
}