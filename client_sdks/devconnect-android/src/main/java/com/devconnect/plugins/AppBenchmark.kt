package com.devconnect.plugins

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import com.devconnect.DevConnect
import org.json.JSONObject
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

private var startupDone = false
private var appStateDone = false

data class AppBenchmarkOptions(
    val trackStartup: Boolean = true,
    val trackAppState: Boolean = true
)

fun setupAppBenchmark(context: Any? = null, opts: AppBenchmarkOptions = AppBenchmarkOptions()) {
    val handler = Handler(Looper.getMainLooper())

    // ---- App Startup Benchmark ----
    if (opts.trackStartup && !startupDone) {
        startupDone = true
        DevConnect.benchmarkStart("App Startup")
        DevConnect.benchmarkStep("App Startup")

        // Mark first activity visible as "First Render Complete"
        if (context is Application) {
            context.registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
                private val firstResume = AtomicBoolean(true)

                override fun onActivityResumed(activity: Activity) {
                    if (firstResume.compareAndSet(true, false)) {
                        DevConnect.benchmarkStep("App Startup")

                        // Triple post for layout stability (matches Flutter/RN pattern)
                        handler.post {
                            handler.post {
                                handler.post {
                                    DevConnect.benchmarkStop("App Startup")
                                }
                            }
                        }
                    }
                }

                override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
                override fun onActivityStarted(activity: Activity) {}
                override fun onActivityPaused(activity: Activity) {}
                override fun onActivityStopped(activity: Activity) {}
                override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
                override fun onActivityDestroyed(activity: Activity) {}
            })
        } else {
            // No Application context — use triple post as "ready"
            handler.post {
                DevConnect.benchmarkStep("App Startup")
                handler.post {
                    handler.post {
                        DevConnect.benchmarkStop("App Startup")
                    }
                }
            }
        }
    }

    // ---- App State Benchmark (background/foreground) ----
    if (opts.trackAppState && !appStateDone && context is Application) {
        appStateDone = true
        var backgroundTime = 0L

        context.registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
            private val activeCount = AtomicInteger(0)

            override fun onActivityStarted(activity: Activity) {
                if (activeCount.incrementAndGet() == 1 && backgroundTime > 0) {
                    // Returned to foreground
                    DevConnect.benchmarkStep("App Background")
                    DevConnect.benchmarkStop("App Background")
                    backgroundTime = 0
                }
            }

            override fun onActivityStopped(activity: Activity) {
                if (activeCount.decrementAndGet() == 0) {
                    // Went to background
                    backgroundTime = System.currentTimeMillis()
                    DevConnect.benchmarkStart("App Background")
                    DevConnect.benchmarkStep("App Background")
                }
            }

            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
            override fun onActivityResumed(activity: Activity) {}
            override fun onActivityPaused(activity: Activity) {}
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
            override fun onActivityDestroyed(activity: Activity) {}
        })
    }
}

fun benchmarkScreen(screenName: String): () -> Unit {
    val title = "Screen: $screenName"
    DevConnect.benchmarkStart(title)
    DevConnect.benchmarkStep(title)

    val stopped = AtomicBoolean(false)
    val handler = Handler(Looper.getMainLooper())

    // Triple post for layout stability (matches Flutter/RN pattern)
    handler.post {
        DevConnect.benchmarkStep(title)
        handler.post {
            handler.post {
                if (stopped.compareAndSet(false, true)) {
                    DevConnect.benchmarkStop(title)
                }
            }
        }
    }

    return {
        if (stopped.compareAndSet(false, true)) {
            DevConnect.benchmarkStop(title)
        }
    }
}

suspend fun <T> benchmarkAsync(title: String, block: suspend () -> T): T {
    DevConnect.benchmarkStart(title)
    DevConnect.benchmarkStep(title)
    return try {
        val result = block()
        DevConnect.benchmarkStep(title)
        DevConnect.benchmarkStop(title)
        result
    } catch (e: Exception) {
        DevConnect.benchmarkStep(title)
        DevConnect.benchmarkStop(title)
        throw e
    }
}
