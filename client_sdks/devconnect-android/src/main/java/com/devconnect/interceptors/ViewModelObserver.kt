package com.devconnect.interceptors

import com.devconnect.DevConnect
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

/**
 * Helper to report ViewModel state changes to DevConnect.
 *
 * Usage with ViewModel + StateFlow:
 * ```kotlin
 * class MyViewModel : ViewModel() {
 *     private val _uiState = MutableStateFlow(MyUiState())
 *     val uiState: StateFlow<MyUiState> = _uiState.asStateFlow()
 *
 *     init {
 *         // Auto-report all state changes
 *         viewModelScope.launch {
 *             DevConnectViewModelObserver.observe(
 *                 flow = uiState,
 *                 viewModelName = "MyViewModel",
 *                 scope = viewModelScope
 *             )
 *         }
 *     }
 * }
 * ```
 *
 * Usage with LiveData:
 * ```kotlin
 * class MyViewModel : ViewModel() {
 *     val data = MutableLiveData<String>()
 *
 *     init {
 *         data.observeForever { newValue ->
 *             DevConnectViewModelObserver.reportChange(
 *                 viewModelName = "MyViewModel",
 *                 propertyName = "data",
 *                 newValue = newValue
 *             )
 *         }
 *     }
 * }
 * ```
 */
object DevConnectViewModelObserver {

    /**
     * Observe a [Flow] and report each emitted value to DevConnect.
     *
     * The previous implementation was a no-op (it logged "Observing …"
     * but never launched any collector), so callers got zero state
     * changes from this entry point.
     */
    fun observe(
        flow: Flow<Any?>,
        viewModelName: String,
        scope: CoroutineScope
    ) {
        scope.launch {
            try {
                flow.collect { value ->
                    try {
                        DevConnect.reportStateChange(
                            stateManager = "viewmodel",
                            action = "$viewModelName state changed",
                            nextState = mapOf("value" to (value?.toString() ?: "null"))
                        )
                    } catch (_: Exception) {
                        // Never let a consumer's reportStateChange failure
                        // tear down the collector.
                    }
                }
            } catch (_: Exception) {
                // Collector cancelled or flow threw — drop silently.
                // Cancellation propagates via the scope.
            }
        }
    }

    /**
     * Manually report a ViewModel state change.
     */
    fun reportChange(
        viewModelName: String,
        propertyName: String,
        previousValue: Any? = null,
        newValue: Any? = null
    ) {
        DevConnect.reportStateChange(
            stateManager = "viewmodel",
            action = "$viewModelName.$propertyName changed",
            previousState = previousValue?.let { mapOf(propertyName to it.toString()) },
            nextState = newValue?.let { mapOf(propertyName to it.toString()) }
        )
    }

    /**
     * Report a full ViewModel state update (e.g., data class state).
     */
    fun reportStateUpdate(
        viewModelName: String,
        action: String,
        previousState: Map<String, Any>? = null,
        nextState: Map<String, Any>? = null
    ) {
        DevConnect.reportStateChange(
            stateManager = "viewmodel",
            action = "$viewModelName: $action",
            previousState = previousState,
            nextState = nextState
        )
    }
}
