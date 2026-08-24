package com.devconnect.plugins

import androidx.compose.runtime.snapshots.Snapshot
import androidx.compose.runtime.snapshots.ObserverHandle
import com.devconnect.DevConnect
import java.lang.reflect.Method
import java.util.Optional
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Observes Compose `MutableState<T>` writes via the public `Snapshot`
 * API and emits `client:state_change` events on each write.
 *
 * Spec: "Hook `androidx.compose.runtime.snapshots.Snapshot.registerApplyObserver`
 * (a public, stable API since Compose 1.0). Every state write goes through
 * the apply observer — we filter for `MutableState` instances referenced
 * by the apply block and emit a state-change event with the value's
 * `toString()`."
 *
 * Trade-offs vs the spec's "ideal" Compose instrumentation:
 *  - We don't get a label per state. We label by `runtimeType` of the
 *    captured state instance (e.g. `MutableState<String>`).
 *  - We do NOT walk the slot table — that requires private APIs.
 *  - State values larger than 4 KB are truncated per spec.
 *
 * Lifecycle: [start] is idempotent and installs an apply observer.
 * [stop] unregisters it.
 */
object ComposeStateObserver {

    private val running = AtomicBoolean(false)
    private var observerHandle: ObserverHandle? = null

    /**
     * Track the last emitted value per state instance so we only emit
     * when the value actually changes (not on every apply tick).
     */
    private val lastValues = ConcurrentHashMap<Any, String>()

    /**
     * Cache of resolved `getValue()` [Method] per state class. `cls.methods`
     * is array-cloned on every call; on hot paths the same `MutableState`
     * subclass can show up thousands of times per second.
     *
     * `ConcurrentHashMap` rejects null values, so we wrap the lookup
     * result in `Optional` to record negative hits (no `getValue()`
     * method) without losing them on the next call.
     *
     * ponytail: per-class lookup table; bounded by the number of distinct
     * Compose state implementations in the host app. Replace with a
     * WeakReference cache if memory churn from dead classes becomes
     * measurable.
     */
    private val getValueMethodCache = ConcurrentHashMap<Class<*>, Optional<Method>>()

    /**
     * Cap on serialized value size in bytes (per spec: 4 KB).
     */
    private const val MAX_VALUE_BYTES = 4096

    fun isRunning(): Boolean = running.get()

    fun start(@Suppress("UNUSED_PARAMETER") context: Any? = null) {
        if (!running.compareAndSet(false, true)) return
        try {
            val handle = Snapshot.registerApplyObserver { changedStates, _ ->
                try {
                    val iter = changedStates.iterator()
                    while (iter.hasNext()) {
                        val state = iter.next()
                        try {
                            val raw = safeStringify(state)
                            if (raw == null) continue
                            val truncated = raw.take(MAX_VALUE_BYTES)
                            val key = state
                            val prev = lastValues.put(key, truncated)
                            if (prev == truncated) continue

                            val typeLabel = state::class.simpleName ?: "MutableState"
                            DevConnect.reportStateChange(
                                stateManager = "Compose::$typeLabel",
                                action = "set",
                                previousState = if (prev != null) mapOf("value" to prev) else null,
                                nextState = mapOf("value" to truncated),
                            )
                        } catch (_: Throwable) {
                            // never throw out of an apply observer
                        }
                    }
                } catch (_: Throwable) {
                    // observer must never throw
                }
            }
            observerHandle = handle
        } catch (_: Throwable) {
            // Snapshot API not available (running on the JVM unit-test runtime)
            // — gracefully no-op.
            observerHandle = null
            running.set(false)
        }
    }

    fun stop() {
        // Always clear the per-class method cache, even if we never
        // observed. The JVM unit-test runtime can't construct a
        // Snapshot observer (and would set `running` back to false on
        // failure), so consumers may legitimately call stop() while
        // running is false; the cache still needs to be flushed.
        val wasRunning = running.compareAndSet(true, false)
        if (wasRunning) {
            val handle = observerHandle
            observerHandle = null
            if (handle != null) {
                try {
                    handle.dispose()
                } catch (_: Throwable) {}
            }
        }
        lastValues.clear()
        getValueMethodCache.clear()
    }

    /**
     * Try to get a string representation of a Compose `State<T>` value
     * without forcing evaluation if it's already invalid.
     */
    private fun safeStringify(state: Any): String? {
        // State<T> exposes `getValue()` via property delegate. Use reflection
        // because we don't import compose.runtime.State to keep this file
        // minimal — the consumer's app module already pulls in Compose.
        return try {
            val cls = state.javaClass
            // Cache lookup avoids re-walking `cls.methods` for every state write.
            // `Optional` wraps both the positive (method found) and negative
            // (no method on this class) results so ConcurrentHashMap can
            // store both without null-value restrictions.
            val getValueMethod = getValueMethodCache
                .getOrPut(cls) { Optional.ofNullable(cls.methods.firstOrNull { it.name == "getValue" && it.parameterCount == 0 }) }
                .orElse(null) ?: return null
            val value = getValueMethod.invoke(state)
            value?.toString()
        } catch (_: Throwable) {
            null
        }
    }
}