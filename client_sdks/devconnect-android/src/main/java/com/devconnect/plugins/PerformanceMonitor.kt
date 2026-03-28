package com.devconnect.plugins

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Choreographer
import com.devconnect.DevConnect

private var running = false
private var memoryHandler: Handler? = null
private var memoryRunnable: Runnable? = null

data class PerformanceMonitorOptions(
    val fpsInterval: Long = 2000L,
    val memoryInterval: Long = 5000L,
    val jankThresholdMs: Double = 32.0
)

fun startPerformanceMonitor(context: Any? = null, opts: PerformanceMonitorOptions = PerformanceMonitorOptions()) {
    if (running) return
    running = true

    // ---- FPS + Jank via Choreographer ----
    startFrameMonitor(opts)

    // ---- Memory monitor ----
    val handler = Handler(Looper.getMainLooper())
    memoryHandler = handler
    val runnable = object : Runnable {
        override fun run() {
            if (!running) return
            reportMemory()
            handler.postDelayed(this, opts.memoryInterval)
        }
    }
    memoryRunnable = runnable
    handler.postDelayed(runnable, opts.memoryInterval)
}

fun stopPerformanceMonitor() {
    running = false
    memoryHandler?.removeCallbacksAndMessages(null)
    memoryHandler = null
    memoryRunnable = null
}

// ---- Frame monitoring ----

private var frameCount = 0
private var lastFpsReportTime = 0L
private var lastFrameTime = 0L

private fun startFrameMonitor(opts: PerformanceMonitorOptions) {
    lastFpsReportTime = System.currentTimeMillis()
    lastFrameTime = System.nanoTime()

    val callback = object : Choreographer.FrameCallback {
        override fun doFrame(frameTimeNanos: Long) {
            if (!running) return

            val now = System.nanoTime()
            if (lastFrameTime > 0) {
                val frameDeltaMs = (now - lastFrameTime) / 1_000_000.0
                frameCount++

                // Detect jank
                if (frameDeltaMs > opts.jankThresholdMs) {
                    DevConnect.reportPerformanceMetric(
                        metricType = "jank_frame",
                        value = Math.round(frameDeltaMs * 10.0) / 10.0,
                        label = "Slow frame: ${Math.round(frameDeltaMs)}ms",
                        metadata = mapOf("threshold" to opts.jankThresholdMs)
                    )
                }
            }
            lastFrameTime = now

            // Report FPS periodically
            val nowMs = System.currentTimeMillis()
            val elapsed = nowMs - lastFpsReportTime
            if (elapsed >= opts.fpsInterval) {
                val fps = Math.round(frameCount.toDouble() / elapsed * 1000 * 10) / 10.0
                DevConnect.reportPerformanceMetric(
                    metricType = "fps",
                    value = fps,
                    label = "UI Thread FPS"
                )
                frameCount = 0
                lastFpsReportTime = nowMs
            }

            Choreographer.getInstance().postFrameCallback(this)
        }
    }

    Choreographer.getInstance().postFrameCallback(callback)
}

private fun reportMemory() {
    val runtime = Runtime.getRuntime()
    val usedMB = (runtime.totalMemory() - runtime.freeMemory()).toDouble() / 1024 / 1024
    val maxMB = runtime.maxMemory().toDouble() / 1024 / 1024

    DevConnect.reportPerformanceMetric(
        metricType = "memory_usage",
        value = Math.round(usedMB * 10.0) / 10.0,
        label = "JVM Heap Used (MB)",
        metadata = mapOf(
            "totalMemory" to runtime.totalMemory(),
            "freeMemory" to runtime.freeMemory(),
            "maxMemory" to runtime.maxMemory(),
            "maxMB" to Math.round(maxMB * 10.0) / 10.0
        )
    )

    // Native heap via Debug
    try {
        val nativeHeap = android.os.Debug.getNativeHeapAllocatedSize().toDouble() / 1024 / 1024
        DevConnect.reportPerformanceMetric(
            metricType = "memory_usage",
            value = Math.round(nativeHeap * 10.0) / 10.0,
            label = "Native Heap (MB)"
        )
    } catch (_: Exception) {}
}
