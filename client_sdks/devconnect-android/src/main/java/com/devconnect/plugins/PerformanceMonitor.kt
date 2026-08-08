package com.devconnect.plugins

import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Choreographer
import com.devconnect.DevConnect

private var running = false
private var memoryHandler: Handler? = null
private var memoryRunnable: Runnable? = null
private var cpuHandler: Handler? = null
private var cpuRunnable: Runnable? = null
private var systemHandler: Handler? = null
private var systemRunnable: Runnable? = null
private var startupReported = false
private var appContext: Context? = null
private var lastMemoryMB = 0.0

data class PerformanceMonitorOptions(
    val fpsInterval: Long = 2000L,
    val memoryInterval: Long = 5000L,
    val cpuInterval: Long = 3000L,
    val systemInterval: Long = 10000L,
    val jankThresholdMs: Double = 32.0
)

private val initTimeMs = System.currentTimeMillis()

fun startPerformanceMonitor(context: Any? = null, opts: PerformanceMonitorOptions = PerformanceMonitorOptions()) {
    if (running) return
    running = true

    // Save context for battery/thermal
    if (context is Context) appContext = context.applicationContext
    if (context is Activity) appContext = context.applicationContext

    // ---- Startup Time ----
    if (!startupReported) {
        val startupMs = System.currentTimeMillis() - initTimeMs
        DevConnect.reportPerformanceMetric(
            metricType = "startup_time",
            value = startupMs.toDouble(),
            label = "App startup: ${startupMs}ms"
        )
        startupReported = true
    }

    // ---- FPS + Jank + Frame Timing via Choreographer ----
    // Choreographer.getInstance() requires a thread with a Looper.
    // PerformanceMonitor may be invoked from a worker coroutine
    // (e.g. inside DevConnect.init's IO-dispatched initScope), so
    // post the frame-callback registration to the main thread.
    Handler(Looper.getMainLooper()).post { startFrameMonitor(opts) }

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

    // ---- CPU monitor ----
    val cpuH = Handler(Looper.getMainLooper())
    cpuHandler = cpuH
    lastCpuTime = android.os.Process.getElapsedCpuTime()
    lastCpuWallTime = System.currentTimeMillis()
    val cpuR = object : Runnable {
        override fun run() {
            if (!running) return
            reportCpu()
            cpuH.postDelayed(this, opts.cpuInterval)
        }
    }
    cpuRunnable = cpuR
    cpuH.postDelayed(cpuR, opts.cpuInterval)

    // ---- System metrics (battery, threads, disk, thermal) ----
    val sysH = Handler(Looper.getMainLooper())
    systemHandler = sysH
    reportSystemMetrics() // Report immediately
    val sysR = object : Runnable {
        override fun run() {
            if (!running) return
            reportSystemMetrics()
            sysH.postDelayed(this, opts.systemInterval)
        }
    }
    systemRunnable = sysR
    sysH.postDelayed(sysR, opts.systemInterval)
}

fun stopPerformanceMonitor() {
    running = false
    memoryHandler?.removeCallbacksAndMessages(null)
    memoryHandler = null
    memoryRunnable = null
    cpuHandler?.removeCallbacksAndMessages(null)
    cpuHandler = null
    cpuRunnable = null
    systemHandler?.removeCallbacksAndMessages(null)
    systemHandler = null
    systemRunnable = null
}

// ---- Frame monitoring ----

private val frameSampleRate = 5 // report every Nth frame to reduce overhead
private var frameCount = 0
private var lastFpsReportTime = 0L
private var lastFrameTime = 0L
private var lastCpuTime = 0L
private var lastCpuWallTime = 0L

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

                // Report frame build time (sampled)
                if (frameCount % frameSampleRate == 0) {
                    DevConnect.reportPerformanceMetric(
                        metricType = "frame_build_time",
                        value = Math.round(frameDeltaMs * 10.0) / 10.0,
                        label = "Frame: ${Math.round(frameDeltaMs)}ms"
                    )
                }

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

private fun reportCpu() {
    try {
        val currentCpuTime = android.os.Process.getElapsedCpuTime()
        val currentWallTime = System.currentTimeMillis()
        val cpuDelta = currentCpuTime - lastCpuTime
        val wallDelta = currentWallTime - lastCpuWallTime
        if (wallDelta > 0) {
            val cores = Runtime.getRuntime().availableProcessors()
            val usage = (cpuDelta.toDouble() / wallDelta * 100 / cores).coerceIn(0.0, 100.0)
            DevConnect.reportPerformanceMetric(
                metricType = "cpu_usage",
                value = Math.round(usage * 10.0) / 10.0,
                label = "Process CPU (%)",
                metadata = mapOf(
                    "cpuTimeMs" to cpuDelta,
                    "wallTimeMs" to wallDelta,
                    "cores" to cores
                )
            )
        }
        lastCpuTime = currentCpuTime
        lastCpuWallTime = currentWallTime
    } catch (_: Exception) {}
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

    // Native heap
    try {
        val nativeHeap = android.os.Debug.getNativeHeapAllocatedSize().toDouble() / 1024 / 1024
        DevConnect.reportPerformanceMetric(
            metricType = "memory_peak",
            value = Math.round(nativeHeap * 10.0) / 10.0,
            label = "Native Heap (MB)"
        )
    } catch (_: Exception) {}

    // Memory allocation rate
    if (lastMemoryMB > 0) {
        val deltaMB = usedMB - lastMemoryMB
        val ratePerSec = Math.round(deltaMB / 5.0 * 100) / 100.0 // 5s interval
        DevConnect.reportPerformanceMetric(
            metricType = "memory_allocation_rate",
            value = ratePerSec,
            label = "${if (ratePerSec >= 0) "+" else ""}$ratePerSec MB/s"
        )
    }
    lastMemoryMB = usedMB
}

// ---- System metrics ----

private fun reportSystemMetrics() {
    // Thread count
    try {
        val threadCount = Thread.activeCount()
        DevConnect.reportPerformanceMetric(
            metricType = "thread_count",
            value = threadCount.toDouble(),
            label = "$threadCount threads"
        )
    } catch (_: Exception) {}

    // Disk I/O via /proc/self/io
    try {
        val io = java.io.File("/proc/self/io").readText()
        val readBytes = Regex("read_bytes:\\s+(\\d+)").find(io)?.groupValues?.get(1)?.toLongOrNull()
        val writeBytes = Regex("write_bytes:\\s+(\\d+)").find(io)?.groupValues?.get(1)?.toLongOrNull()
        if (readBytes != null) {
            val mb = Math.round(readBytes.toDouble() / 1024 / 1024 * 10) / 10.0
            DevConnect.reportPerformanceMetric(
                metricType = "disk_read",
                value = mb,
                label = "Disk Read: $mb MB"
            )
        }
        if (writeBytes != null) {
            val mb = Math.round(writeBytes.toDouble() / 1024 / 1024 * 10) / 10.0
            DevConnect.reportPerformanceMetric(
                metricType = "disk_write",
                value = mb,
                label = "Disk Write: $mb MB"
            )
        }
    } catch (_: Exception) {}

    // Battery level
    val ctx = appContext
    if (ctx != null) {
        try {
            val batteryIntent = ctx.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            if (batteryIntent != null) {
                val level = batteryIntent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = batteryIntent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                val status = batteryIntent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                val temp = batteryIntent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1)
                val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
                if (level >= 0 && scale > 0) {
                    val pct = level * 100 / scale
                    DevConnect.reportPerformanceMetric(
                        metricType = "battery_level",
                        value = pct.toDouble(),
                        label = "Battery: $pct%${if (isCharging) " (charging)" else ""}",
                        metadata = mapOf(
                            "charging" to isCharging,
                            "temperature" to (temp / 10.0)
                        )
                    )
                }
            }
        } catch (_: Exception) {}
    }

    // Thermal state via thermal_zone0
    try {
        val temp = java.io.File("/sys/class/thermal/thermal_zone0/temp").readText().trim().toLongOrNull()
        if (temp != null) {
            val tempC = temp / 1000.0
            val state = when {
                tempC < 35 -> 0.0  // nominal
                tempC < 40 -> 1.0  // fair
                tempC < 45 -> 2.0  // serious
                else -> 3.0        // critical
            }
            DevConnect.reportPerformanceMetric(
                metricType = "thermal_state",
                value = state,
                label = "Thermal: ${Math.round(tempC * 10) / 10.0}°C",
                metadata = mapOf("temperatureC" to tempC)
            )
        }
    } catch (_: Exception) {}

    // ANR detection (main thread responsiveness)
    detectAnr()
}

// ---- ANR detection ----
private val mainThreadAck = java.util.concurrent.atomic.AtomicBoolean(false)

private fun detectAnr() {
    // The previous implementation reset `anrCheckTime` both on the
    // worker thread (before sleeping) and on the main thread (via
    // handler.post). That meant the worker's `delay = now - anrCheckTime`
    // was always ~5000 ms regardless of whether the main thread was
    // responsive, so the `> 6000` threshold was never reached — ANRs
    // were silently dropped.

    mainThreadAck.set(false)
    val handler = Handler(Looper.getMainLooper())
    handler.post { mainThreadAck.set(true) }

    Thread {
        Thread.sleep(5000)
        if (!running) return@Thread
        if (mainThreadAck.get()) return@Thread

        // Main thread didn't ack within 5 s. Sleep one more second to
        // rule out transient jank (GC pause, layout inflation, ...) and
        // re-check. Only report if it still hasn't responded.
        Thread.sleep(1000)
        if (!running) return@Thread
        if (mainThreadAck.get()) return@Thread

        // Capture the main thread's stack trace — we're on a background
        // thread right now, so reading `Looper.getMainLooper().thread`
        // is safe.
        val mainStack = Looper.getMainLooper().thread.stackTrace
            .take(20)
            .joinToString("\n") {
                "${it.className}.${it.methodName}(${it.fileName}:${it.lineNumber})"
            }

        DevConnect.reportPerformanceMetric(
            metricType = "anr",
            value = 6000.0,
            label = "ANR detected: main thread blocked ≥6s",
            metadata = mapOf(
                "blockDurationMs" to 6000,
                "mainThreadStack" to mainStack
            )
        )
    }.start()
}
