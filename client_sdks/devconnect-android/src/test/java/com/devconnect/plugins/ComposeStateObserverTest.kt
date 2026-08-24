package com.devconnect.plugins

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.lang.reflect.Method
import java.util.Optional
import java.util.concurrent.ConcurrentHashMap

/**
 * Tests for [ComposeStateObserver] bug fixes from Round 5.
 *
 * **Bug #4** — every state change previously re-ran
 * `cls.methods.firstOrNull { it.name == "getValue" && it.parameterCount == 0 }`
 * which clones the methods array on each call. On a hot Compose-driven UI
 * with thousands of writes per second this adds up. The fix caches the
 * resolved [Method] per `Class<*>` in a `ConcurrentHashMap` (wrapped in
 * `Optional` so negative hits can be cached without null-value
 * restrictions).
 *
 * We exercise the cache directly via reflection because the public
 * `start()` / `stop()` path requires Compose's `Snapshot` runtime which
 * is not available on the JVM unit-test classpath even with
 * `androidx.compose.runtime:runtime` on the test runtime — the runtime
 * ships classes but no `Snapshot.applyObserver` implementation outside
 * of an Android `Looper`.
 */
class ComposeStateObserverTest {

    private val observerClass: Class<*> = ComposeStateObserver::class.java

    @Test
    fun `per-class getValue method cache is a ConcurrentHashMap`() {
        // Pin the field type so a future refactor can't accidentally
        // regress to a synchronized HashMap or a kotlin MutableMap
        // (which would still work but lose the per-class lock-free
        // read path the bug fix depends on).
        val field = observerClass.getDeclaredField("getValueMethodCache")
        field.isAccessible = true
        val cache = field.get(ComposeStateObserver)
        assertNotNull("cache field must be initialised", cache)
        assertTrue(
            "cache must be ConcurrentHashMap for lock-free concurrent reads",
            cache is ConcurrentHashMap<*, *>,
        )
    }

    @Test
    fun `cache is populated and reused for repeated state classes`() {
        // Reset caches by stopping the observer (start() is a no-op
        // on the JVM unit-test runtime, but stop() clears the cache
        // unconditionally — that's the contract we want to verify).
        ComposeStateObserver.stop()

        val cacheField = observerClass.getDeclaredField("getValueMethodCache").apply { isAccessible = true }
        @Suppress("UNCHECKED_CAST")
        val cache = cacheField.get(ComposeStateObserver) as ConcurrentHashMap<Class<*>, Optional<Method>>

        // Prime the cache by invoking the private safeStringify method
        // reflectively. Two distinct classes, two calls each.
        val safeStringify = observerClass.getDeclaredMethod("safeStringify", Any::class.java).apply {
            isAccessible = true
        }

        val fakeStateA = FakeComposeState(value = "a")
        val fakeStateB = FakeComposeState(value = "b")

        // First call populates the cache for FakeComposeState's class.
        val resultA1 = safeStringify.invoke(ComposeStateObserver, fakeStateA) as String?
        // Second call must hit the cache, not re-walk methods.
        val resultA2 = safeStringify.invoke(ComposeStateObserver, fakeStateA) as String?

        assertEquals("a", resultA1)
        assertEquals("a", resultA2)
        assertTrue("cache must contain an entry for FakeComposeState's class",
            cache.containsKey(FakeComposeState::class.java))
        assertTrue(
            "cache must record the resolved method for FakeComposeState's class",
            cache[FakeComposeState::class.java]!!.isPresent,
        )

        // Distinct subclass → distinct cache entry.
        val resultB = safeStringify.invoke(ComposeStateObserver, fakeStateB) as String?
        assertEquals("b", resultB)
    }

    @Test
    fun `cache stores negative hit when class lacks a no-arg getValue method`() {
        ComposeStateObserver.stop()
        val cacheField = observerClass.getDeclaredField("getValueMethodCache").apply { isAccessible = true }
        @Suppress("UNCHECKED_CAST")
        val cache = cacheField.get(ComposeStateObserver) as ConcurrentHashMap<Class<*>, Optional<Method>>

        val safeStringify = observerClass.getDeclaredMethod("safeStringify", Any::class.java).apply {
            isAccessible = true
        }
        // A plain object without a getValue() method must return null
        // and the result MUST be cached so we don't re-walk methods
        // for every subsequent state write. Wrapping in `Optional` is
        // what makes this possible — ConcurrentHashMap rejects null
        // values outright.
        val result = safeStringify.invoke(ComposeStateObserver, PlainState()) as String?
        assertNull(result)
        assertTrue(
            "cache must record the negative lookup to avoid re-walking methods",
            cache.containsKey(PlainState::class.java),
        )
        assertFalse(
            "the cached lookup must be Optional.empty() for a class without getValue()",
            cache[PlainState::class.java]!!.isPresent,
        )
    }

    @Test
    fun `stop clears the per-class method cache`() {
        ComposeStateObserver.stop()
        val cacheField = observerClass.getDeclaredField("getValueMethodCache").apply { isAccessible = true }
        @Suppress("UNCHECKED_CAST")
        val cache = cacheField.get(ComposeStateObserver) as ConcurrentHashMap<Class<*>, Optional<Method>>
        val resolved = FakeComposeState::class.java.methods.firstOrNull { it.name == "getValue" }
        cache[FakeComposeState::class.java] = Optional.ofNullable(resolved)
        assertFalse("precondition: cache should be primed", cache.isEmpty())

        ComposeStateObserver.stop()
        assertTrue(
            "stop() must clear the method cache alongside lastValues",
            cache.isEmpty(),
        )
    }

    /**
     * Mimics Compose's `MutableState<T>` by exposing a no-arg
     * `getValue()` method that returns the underlying value. Reflection
     * is the only thing we can run on the JVM unit-test runtime —
     * Compose itself doesn't initialise `Snapshot` here.
     */
    @Suppress("unused")
    private class FakeComposeState(private val value: String) {
        fun getValue(): String = value
    }

    /** Intentionally lacks a `getValue()` method — exercises the cache's null entry. */
    private class PlainState
}
