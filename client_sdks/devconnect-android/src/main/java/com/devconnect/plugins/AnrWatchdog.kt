package com.devconnect.plugins

import android.os.Handler
import android.os.Looper
import com.devconnect.DevConnect
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Standalone ANR Watchdog. Runs a daemon thread that posts a ping
 * Runnable to [Looper.getMainLooper] every [Options.pingIntervalMs].
 * If the Runnable doesn't ack within [Options.thresholdMs] (and stays
 * unacked for [Options.confirmMs] after a second re-check to rule out
 * GC pauses), captures the main thread stack and reports it as a
 * `performance_metric` event.
 *
 * Signal-safe by construction: the only shared state is the
 * [AtomicBoolean] ack flag, written by the main thread, read by the
 * watchdog thread. No locks.
 *
 * Safe to call [start] repeatedly — repeat calls are no-ops while the
 * watchdog is already running. [stop] is idempotent.
 */
object AnrWatchdog {

    data class Options(
        val pingIntervalMs: Long = 500L,
        val thresholdMs: Long = 5_000L,
        val confirmMs: Long = 1_000L,
    )

    private val running = AtomicBoolean(false)
    private var thread: Thread? = null
    private val mainThreadAck = AtomicBoolean(false)
    @Volatile private var lastAnrReportedMs = 0L

    fun isRunning(): Boolean = running.get()

    fun start(opts: Options = Options()) {
        if (!running.compareAndSet(false, true)) return

        thread = Thread({
            try {
                while (running.get()) {
                    mainThreadAck.set(false)
                    val handler = Handler(Looper.getMainLooper())
                    handler.post { mainThreadAck.set(true) }

                    Thread.sleep(opts.thresholdMs)
                    if (!running.get()) return@Thread
                    if (mainThreadAck.get()) continue

                    Thread.sleep(opts.confirmMs)
                    if (!running.get()) return@Thread
                    if (mainThreadAck.get()) continue

                    reportAnr()
                    Thread.sleep(opts.pingIntervalMs * 4)
                }
            } catch (_: InterruptedException) {
                // stop() interrupted us — exit cleanly.
            }
        }, "DevConnect-AnrWatchdog").apply {
            isDaemon = true
            start()
        }
    }

    fun stop() {
        if (!running.compareAndSet(true, false)) return
        thread?.interrupt()
        thread = null
    }

    private fun reportAnr() {
        val now = System.currentTimeMillis()
        if (now - lastAnrReportedMs < 30_000L) return
        lastAnrReportedMs = now

        try {
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
        } catch (_: Throwable) {
            // Never throw from a watchdog thread.
        }
    }
}