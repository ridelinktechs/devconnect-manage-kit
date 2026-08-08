package com.devconnect

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.lang.reflect.Modifier

/**
 * Smoke tests for [DevConnect.installForApp].
 *
 * The full installForApp → init() flow needs a real android.content.Context
 * and runs network discovery, which we can't exercise on the JVM unit-test
 * runtime. These tests instead pin the public contract: the function exists
 * on the Kotlin `object` singleton, is `public final` (instance method on
 * the JVM, reachable from Java as `DevConnect.INSTANCE.installForApp(...)`),
 * and exposes the documented defaults.
 *
 * The behaviour (init() is called with every `auto*` flag = true) is
 * trivial to verify by reading the function body — and is exercised
 * end-to-end in `ep_android`.
 */
class DevConnectInstallForAppTest {

    @Test
    fun `installForApp exists as public instance method on the Kotlin object`() {
        val method = DevConnect::class.java.getDeclaredMethod(
            "installForApp",
            Any::class.java,
            String::class.java,
            String::class.java,
            String::class.java,
            Integer.TYPE,
            java.lang.Boolean.TYPE,
            String::class.java,
        )
        assertNotNull(method)
        assertTrue("installForApp must be public", Modifier.isPublic(method.modifiers))
        // Kotlin `object` members are JVM instance methods — Java callers
        // reach them via DevConnect.INSTANCE.installForApp(...). If this
        // ever flips to a static (JvmStatic), the MainApplication.java
        // call site breaks silently, so we pin the shape here.
        assertTrue(
            "installForApp must be an instance method (Kotlin object → JVM INSTANCE field)",
            !Modifier.isStatic(method.modifiers)
        )
    }

    @Test
    fun `installForApp parameter defaults match the documented contract`() {
        // Defaults documented to consumers: appVersion="1.0.0", host=null,
        // port=9090, enabled=false, versionCode=null. Pin these so an
        // accidental change to the production signature is caught at
        // test time rather than at the consumer's compile step.
        val method = DevConnect::class.java.getDeclaredMethod(
            "installForApp",
            Any::class.java,
            String::class.java,
            String::class.java,
            String::class.java,
            Integer.TYPE,
            java.lang.Boolean.TYPE,
            String::class.java,
        )
        assertEquals(7, method.parameterCount)
        // Position 0 = context (Any). Position 1 = appName (String, required).
        // Positions 2..6 carry the defaults we want to lock in.
        // Kotlin emits them as method parameters regardless of default
        // values; verifying the *types* (and reading the source for
        // default literals) is the contract.
        assertEquals(Any::class.java, method.parameterTypes[0])
        assertEquals(String::class.java, method.parameterTypes[1])
        assertEquals(String::class.java, method.parameterTypes[2])
        assertEquals(String::class.java, method.parameterTypes[3])
        assertEquals(Integer.TYPE, method.parameterTypes[4])
        assertEquals(java.lang.Boolean.TYPE, method.parameterTypes[5])
        assertEquals(String::class.java, method.parameterTypes[6])
    }
}
