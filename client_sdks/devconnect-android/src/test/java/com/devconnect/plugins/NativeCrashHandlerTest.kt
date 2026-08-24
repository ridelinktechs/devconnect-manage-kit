package com.devconnect.plugins

import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * Tests for [NativeCrashHandler].
 *
 * These tests run on the JVM unit-test runtime, where `libdc-native.so`
 * is **not** on the classpath. The contract we verify here is the
 * graceful-degradation path: [start] must not throw when the native
 * library is missing, and [stop] must remain idempotent.
 *
 * End-to-end native crash capture is exercised on-device in the
 * `ep_android` smoke tests (manual: trigger `System.exit(1)` from a
 * JNI test bridge, confirm a `client:error` event with `severity =
 * crash` arrives on the desktop).
 */
class NativeCrashHandlerTest {

    @Before
    fun setup() {
        // Ensure no leftover poller from a previous test.
        NativeCrashHandler.stop()
    }

    @After
    fun teardown() {
        NativeCrashHandler.stop()
    }

    @Test
    fun `start is a no-op when libdc-native is not on the classpath`() {
        // JVM unit-test runtime has no .so — start() should swallow
        // the UnsatisfiedLinkError silently and not throw.
        NativeCrashHandler.start()
        NativeCrashHandler.start()
        NativeCrashHandler.start()
        // Reaching here without exception is the assertion.
        assertTrue(true)
    }

    @Test
    fun `stop is idempotent even when start never succeeded`() {
        // Never call start. stop() should still not throw.
        NativeCrashHandler.stop()
        NativeCrashHandler.stop()
        assertTrue(true)
    }

    @Test
    fun `stop after no-op start remains safe`() {
        NativeCrashHandler.start()
        NativeCrashHandler.stop()
        NativeCrashHandler.stop()
        assertFalse(false)
    }
}
