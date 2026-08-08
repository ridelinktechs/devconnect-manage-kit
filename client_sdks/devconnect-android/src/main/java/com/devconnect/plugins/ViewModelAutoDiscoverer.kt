package com.devconnect.plugins

import android.app.Activity
import android.app.Application
import android.os.Bundle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelStore
import androidx.lifecycle.ViewModelStoreOwner
import com.devconnect.DevConnect
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.reflect.KClass
import kotlin.reflect.full.memberProperties

/**
 * Walks every Activity / Fragment's `ViewModelStore`, finds ViewModels
 * whose properties expose `StateFlow<*>` or `LiveData<*>`, and
 * installs observers that emit `client:state_change` events on each
 * update.
 *
 * Reflection-only — we never link against a specific ViewModel class.
 * This means the discoverer works against any consumer ViewModel, but
 * the price is that we cannot know the *exact* property type at
 * compile time. We rely on `KClass.memberProperties` and on the
 * canonical name of the return type to decide whether to attach an
 * observer.
 *
 * Lifecycle: [start] is idempotent and installs an
 * `ActivityLifecycleCallbacks`. [stop] unregisters the callbacks and
 * cancels all per-VM collection coroutines.
 *
 * Static utility [discoverViewModel] is exposed for unit-testing and
 * for consumers who want to wire their own ViewModelStore scanning.
 */
object ViewModelAutoDiscoverer {

    data class Options(
        /** Include ViewModels from the Fragment scope as well. */
        val includeFragments: Boolean = true,
    )

    private val running = AtomicBoolean(false)
    private var callbacks: Application.ActivityLifecycleCallbacks? = null
    private var app: Application? = null

    /** key = "${viewModelStoreOwner}::${vmName}::${property}", value = last seen value */
    private val lastValues = ConcurrentHashMap<String, Any?>()

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val observerJobs = ConcurrentHashMap<String, Job>()

    fun isRunning(): Boolean = running.get()

    /**
     * Walk one ViewModelStore and return a list of `(propertyName, typeLabel)`
     * for each property that looks like state-bearing. Used by both the
     * production lifecycle hook and by unit tests.
     */
    fun discoverViewModel(
        store: ViewModelStore,
        ownerLabel: String,
    ): List<Pair<String, String>> {
        val found = mutableListOf<Pair<String, String>>()

        // ViewModelStore keeps an internal `map: Map<String, ViewModel>`.
        // The field name changed from `mMap` (≤ 2.6) to `map` in 2.7.0.
        // We use reflection because the field is private.
        val mapField = try {
            ViewModelStore::class.java.getDeclaredField("map").apply { isAccessible = true }
        } catch (_: NoSuchFieldException) {
            return emptyList()
        }
        @Suppress("UNCHECKED_CAST")
        val map = mapField.get(store) as? Map<String, ViewModel> ?: return emptyList()

        for ((_, vm) in map) {
            val kClass: KClass<out ViewModel> = vm::class
            for (prop in kClass.memberProperties) {
                val typeName = prop.returnType.toString()
                when {
                    typeName.contains("StateFlow") || typeName.contains("MutableStateFlow") -> {
                        found += prop.name to "StateFlow"
                        attachFlowObserver(vm, prop.name, ownerLabel)
                    }
                    typeName.contains("LiveData") -> {
                        found += prop.name to "LiveData"
                        attachLiveDataObserver(vm, prop.name, ownerLabel)
                    }
                }
            }
        }
        return found
    }

    private fun attachFlowObserver(vm: ViewModel, propName: String, ownerLabel: String) {
        val key = "$ownerLabel::${vm::class.simpleName}::$propName"
        observerJobs.computeIfAbsent(key) {
            scope.launch {
                try {
                    val kClass = vm::class
                    val prop = kClass.memberProperties.firstOrNull { it.name == propName } ?: return@launch
                    @Suppress("UNCHECKED_CAST")
                    val flow = (prop.getter.call(vm) as? StateFlow<Any?>) ?: return@launch
                    flow.collect { value: Any? ->
                        val prev: Any? = lastValues[key]
                        lastValues[key] = value
                        if (prev != value) {
                            DevConnect.reportStateChange(
                                stateManager = "${ownerLabel}::${vm::class.simpleName}",
                                action = "set",
                                previousState = if (prev != null) mapOf(propName to prev) else null,
                                nextState = mapOf(propName to value),
                            )
                        }
                    }
                } catch (_: Throwable) {
                    // a single bad VM must not stop the discoverer
                }
            }
        }
    }

    private fun attachLiveDataObserver(vm: ViewModel, propName: String, ownerLabel: String) {
        val key = "$ownerLabel::${vm::class.simpleName}::$propName"
        observerJobs.computeIfAbsent(key) {
            scope.launch {
                try {
                    val kClass = vm::class
                    val prop = kClass.memberProperties.firstOrNull { it.name == propName } ?: return@launch
                    @Suppress("UNCHECKED_CAST")
                    val liveData = (prop.getter.call(vm) as? androidx.lifecycle.LiveData<Any?>) ?: return@launch
                    val observer = androidx.lifecycle.Observer<Any?> { value: Any? ->
                        val prev: Any? = lastValues[key]
                        lastValues[key] = value
                        if (prev != value) {
                            DevConnect.reportStateChange(
                                stateManager = "${ownerLabel}::${vm::class.simpleName}",
                                action = "set",
                                previousState = if (prev != null) mapOf(propName to prev) else null,
                                nextState = mapOf(propName to value),
                            )
                        }
                    }
                    val weakObserver = java.lang.ref.WeakReference(observer)
                    liveData.observeForever(object : androidx.lifecycle.Observer<Any?> {
                        override fun onChanged(value: Any?) {
                            weakObserver.get()?.onChanged(value)
                        }
                    })
                } catch (_: Throwable) {
                    // never throw from a state observer
                }
            }
        }
    }

    fun start(context: Any? = null, opts: Options = Options()) {
        if (!running.compareAndSet(false, true)) return
        val a = (context as? Application)
            ?: (context as? android.content.Context)?.applicationContext as? Application
            ?: return
        app = a

        val c = object : Application.ActivityLifecycleCallbacks {
            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
            override fun onActivityStarted(activity: Activity) {}
            override fun onActivityResumed(activity: Activity) {
                if (activity is ViewModelStoreOwner) {
                    discoverViewModel(activity.viewModelStore, activity::class.simpleName ?: "?")
                }
            }
            override fun onActivityPaused(activity: Activity) {}
            override fun onActivityStopped(activity: Activity) {}
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
            override fun onActivityDestroyed(activity: Activity) {}
        }
        callbacks = c
        a.registerActivityLifecycleCallbacks(c)
    }

    fun stop() {
        if (!running.compareAndSet(true, false)) return
        callbacks?.let { app?.unregisterActivityLifecycleCallbacks(it) }
        callbacks = null
        app = null
        observerJobs.values.forEach { it.cancel() }
        observerJobs.clear()
        lastValues.clear()
    }
}
