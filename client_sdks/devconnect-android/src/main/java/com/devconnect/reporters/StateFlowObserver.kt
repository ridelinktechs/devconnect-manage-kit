package com.devconnect.reporters

import com.devconnect.DevConnect
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch

/**
 * StateFlow/LiveData observer that reports state changes to DevConnect.
 *
 * Observes StateFlow or LiveData and reports previous/next state changes
 * to the DevConnect desktop app for real-time state debugging.
 *
 * ## StateFlow usage:
 * ```kotlin
 * import kotlinx.coroutines.CoroutineScope
 * import kotlinx.coroutines.flow.StateFlow
 *
 * // In a ViewModel or anywhere with a CoroutineScope:
 * DevConnectStateObserver.observe(viewModelScope, uiState, "UserState")
 *
 * // With MutableStateFlow:
 * val _state = MutableStateFlow(UiState())
 * DevConnectStateObserver.observe(viewModelScope, _state, "MainScreen")
 * ```
 *
 * ## LiveData usage:
 * ```kotlin
 * import androidx.lifecycle.LifecycleOwner
 * import androidx.lifecycle.LiveData
 *
 * // In an Activity or Fragment:
 * DevConnectStateObserver.observe(this, viewModel.userData, "UserData")
 * ```
 *
 * ## Flow usage:
 * ```kotlin
 * // Any Flow can be observed:
 * DevConnectStateObserver.observeFlow(scope, myFlow, "MyFlow")
 * ```
 */
object DevConnectStateObserver {

    private const val TAG = "StateObserver"

    /**
     * Observe a [StateFlow] and report state changes to DevConnect.
     *
     * The previous implementation spawned a polling thread that read
     * `stateFlow.value` every 100 ms — burning battery and CPU, and
     * missing emissions that landed in the same polling window. This
     * implementation subscribes via `flow.distinctUntilChanged().collect`
     * on [Dispatchers.Default], so each emission is reported exactly once.
     */
    fun observe(scope: CoroutineScope, stateFlow: StateFlow<Any?>, name: String) {
        try {
            observeFlow(scope, stateFlow, name)
        } catch (e: Exception) {
            DevConnect.sendLog(
                "warn",
                "Failed to observe StateFlow '$name': ${e.message}. " +
                    "Use manual reporting with DevConnectStateObserver.reportChange() instead.",
                TAG,
                e.stackTraceToString()
            )
        }
    }

    /**
     * Observe a LiveData and report state changes to DevConnect.
     *
     * LiveData itself is androidx-only (and is a `compileOnly` dep of
     * this SDK). We reflect on the class via reflection so callers can
     * still pass a `LiveData<Any?>` without our SDK importing
     * androidx.lifecycle.LiveData at compile time.
     */
    fun observe(lifecycleOwner: Any, liveData: Any, name: String) {
        try {
            observeLiveDataViaReflection(lifecycleOwner, liveData, name)
        } catch (e: Exception) {
            DevConnect.sendLog(
                "warn",
                "Failed to observe LiveData '$name': ${e.message}. " +
                    "Use manual reporting with DevConnectStateObserver.reportChange() instead.",
                TAG,
                e.stackTraceToString()
            )
        }
    }

    /**
     * Observe any [Flow] and report emitted values to DevConnect.
     */
    fun observeFlow(scope: CoroutineScope, flow: Flow<Any?>, name: String) {
        var previousValue: Any? = null
        var firstEmission = true
        scope.launch(Dispatchers.Default) {
            try {
                flow.distinctUntilChanged()
                    .onEach { currentValue ->
                        DevConnect.reportStateChange(
                            stateManager = name,
                            action = "state_updated",
                            previousState = toStateMap(previousValue),
                            nextState = toStateMap(currentValue)
                        )
                        previousValue = currentValue
                        firstEmission = false
                    }
                    .collect()
                // No-op terminal; collect on a cold flow runs forever.
                // If the flow completes (e.g. from a SharedFlow with no
                // replay), we surface that to the desktop once.
                if (!firstEmission) {
                    DevConnect.sendLog("info", "Flow '$name' completed", TAG)
                }
            } catch (e: Exception) {
                DevConnect.sendLog(
                    "warn",
                    "Flow observation ended for '$name': ${e.message}",
                    TAG,
                    e.stackTraceToString()
                )
            }
        }
    }

    /**
     * Manually report a state change.
     *
     * Use this as a fallback if automatic observation fails, or when you
     * want fine-grained control over what's reported.
     *
     * ```kotlin
     * val oldState = _state.value
     * _state.value = newState
     * DevConnectStateObserver.reportChange(
     *     name = "UserState",
     *     previousState = mapOf("loggedIn" to false),
     *     nextState = mapOf("loggedIn" to true, "userId" to "123")
     * )
     * ```
     */
    fun reportChange(
        name: String,
        previousState: Map<String, Any>? = null,
        nextState: Map<String, Any>? = null,
        action: String = "state_updated"
    ) {
        DevConnect.reportStateChange(
            stateManager = name,
            action = action,
            previousState = previousState,
            nextState = nextState
        )
    }

    /**
     * Report a state snapshot (the full current state).
     */
    fun reportSnapshot(name: String, state: Map<String, Any>) {
        DevConnect.sendStateSnapshot(
            stateManager = name,
            state = state
        )
    }

    // ---- Internal LiveData observer (androidx is compileOnly) ----

    private fun observeLiveDataViaReflection(lifecycleOwner: Any, liveData: Any, name: String) {
        // LiveData.observe(LifecycleOwner, Observer)
        // Observer is a functional interface: void onChanged(T value)

        try {
            val liveDataClass = Class.forName("androidx.lifecycle.LiveData")
            val lifecycleOwnerClass = Class.forName("androidx.lifecycle.LifecycleOwner")
            val observerClass = Class.forName("androidx.lifecycle.Observer")

            var previousValue: Any? = null

            val observer = java.lang.reflect.Proxy.newProxyInstance(
                observerClass.classLoader,
                arrayOf(observerClass)
            ) { _, method, args ->
                if (method.name == "onChanged" && args != null && args.isNotEmpty()) {
                    val newValue = args[0]
                    DevConnect.reportStateChange(
                        stateManager = name,
                        action = "state_updated",
                        previousState = toStateMap(previousValue),
                        nextState = toStateMap(newValue)
                    )
                    previousValue = newValue
                }
                null
            }

            val observeMethod = liveDataClass.getMethod(
                "observe",
                lifecycleOwnerClass,
                observerClass
            )
            observeMethod.invoke(liveData, lifecycleOwner, observer)
        } catch (e: Exception) {
            // Fallback: try observeForever if LifecycleOwner fails
            try {
                observeForeverViaReflection(liveData, name)
            } catch (e2: Exception) {
                throw e
            }
        }
    }

    private fun observeForeverViaReflection(liveData: Any, name: String) {
        val liveDataClass = Class.forName("androidx.lifecycle.LiveData")
        val observerClass = Class.forName("androidx.lifecycle.Observer")

        var previousValue: Any? = null

        val observer = java.lang.reflect.Proxy.newProxyInstance(
            observerClass.classLoader,
            arrayOf(observerClass)
        ) { _, method, args ->
            if (method.name == "onChanged" && args != null && args.isNotEmpty()) {
                val newValue = args[0]
                DevConnect.reportStateChange(
                    stateManager = name,
                    action = "state_updated",
                    previousState = toStateMap(previousValue),
                    nextState = toStateMap(newValue)
                )
                previousValue = newValue
            }
            null
        }

        val observeForeverMethod = liveDataClass.getMethod("observeForever", observerClass)
        observeForeverMethod.invoke(liveData, observer)
    }

    private fun toStateMap(value: Any?): Map<String, Any>? {
        if (value == null) return null

        return try {
            when (value) {
                is Map<*, *> -> {
                    @Suppress("UNCHECKED_CAST")
                    value as Map<String, Any>
                }
                is String, is Number, is Boolean -> {
                    mapOf("value" to value)
                }
                else -> {
                    // Try to convert data class fields to a map via reflection
                    val fields = value.javaClass.declaredFields
                    val map = mutableMapOf<String, Any>()
                    for (field in fields) {
                        try {
                            field.isAccessible = true
                            val fieldValue = field.get(value)
                            if (fieldValue != null) {
                                map[field.name] = fieldValue.toString()
                            }
                        } catch (_: Exception) {}
                    }
                    if (map.isNotEmpty()) map else mapOf("value" to value.toString())
                }
            }
        } catch (_: Exception) {
            mapOf("value" to value.toString())
        }
    }
}
