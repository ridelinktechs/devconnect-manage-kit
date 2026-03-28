package com.devconnect.plugins

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import com.devconnect.DevConnect

private var running = false
private var checkHandler: Handler? = null
private var checkRunnable: Runnable? = null
private val heapSnapshots = mutableListOf<Double>()

data class MemoryLeakDetectorOptions(
    val checkInterval: Long = 10000L,
    val heapGrowthThresholdMB: Double = 20.0,
    val maxSnapshots: Int = 10
)

fun startMemoryLeakDetector(context: Any? = null, opts: MemoryLeakDetectorOptions = MemoryLeakDetectorOptions()) {
    if (running) return
    running = true

    // ---- Track Activity lifecycle for leak detection ----
    if (context is Application) {
        context.registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
            private val activityCounts = mutableMapOf<String, Int>()

            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
                val name = activity::class.java.simpleName
                activityCounts[name] = (activityCounts[name] ?: 0) + 1
            }

            override fun onActivityDestroyed(activity: Activity) {
                val name = activity::class.java.simpleName
                val count = (activityCounts[name] ?: 1) - 1
                activityCounts[name] = count

                // Check heap on Activity destroy
                checkHeapGrowth(opts.heapGrowthThresholdMB, opts.maxSnapshots)
            }

            override fun onActivityStarted(activity: Activity) {}
            override fun onActivityResumed(activity: Activity) {}
            override fun onActivityPaused(activity: Activity) {}
            override fun onActivityStopped(activity: Activity) {}
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
        })
    }

    // ---- Periodic heap growth check ----
    val handler = Handler(Looper.getMainLooper())
    checkHandler = handler
    val runnable = object : Runnable {
        override fun run() {
            if (!running) return
            checkHeapGrowth(opts.heapGrowthThresholdMB, opts.maxSnapshots)
            handler.postDelayed(this, opts.checkInterval)
        }
    }
    checkRunnable = runnable
    handler.postDelayed(runnable, opts.checkInterval)
}

fun stopMemoryLeakDetector() {
    running = false
    checkHandler?.removeCallbacksAndMessages(null)
    checkHandler = null
    checkRunnable = null
    heapSnapshots.clear()
}

private fun checkHeapGrowth(thresholdMB: Double, maxSnapshots: Int) {
    val runtime = Runtime.getRuntime()
    val usedMB = (runtime.totalMemory() - runtime.freeMemory()).toDouble() / 1024 / 1024

    heapSnapshots.add(usedMB)
    if (heapSnapshots.size > maxSnapshots) {
        heapSnapshots.removeAt(0)
    }

    if (heapSnapshots.size >= 3) {
        val first = heapSnapshots.first()
        val last = heapSnapshots.last()
        val growth = last - first

        var isGrowing = true
        for (i in 1 until heapSnapshots.size) {
            if (heapSnapshots[i] <= heapSnapshots[i - 1]) {
                isGrowing = false
                break
            }
        }

        if (isGrowing && growth > thresholdMB) {
            DevConnect.reportMemoryLeak(
                leakType = "growing_collection",
                severity = if (growth > thresholdMB * 2) "critical" else "warning",
                objectName = "JVM Heap",
                detail = "Heap grew ${Math.round(growth)}MB over ${heapSnapshots.size} samples (${Math.round(first)}MB → ${Math.round(last)}MB)",
                retainedSizeBytes = (growth * 1024 * 1024).toLong(),
                metadata = mapOf(
                    "snapshots" to heapSnapshots.map { Math.round(it * 10.0) / 10.0 },
                    "growthMB" to Math.round(growth * 10.0) / 10.0
                )
            )
        }
    }
}
