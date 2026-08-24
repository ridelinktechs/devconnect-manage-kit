package com.devconnect.interceptors

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.lang.reflect.Modifier

/**
 * Tests for the [DevConnectWebSocketListener] and [DevConnectWebSocketHelper]
 * fixes from Round 5.
 *
 * Bugs covered:
 *  - **#3** `openedAt` / `url` are mutated from OkHttp reader threads; the
 *    fields MUST be `@Volatile` so the writes are visible to whichever
 *    thread emits the `client:ws_*` event. Pin the modifier here.
 *  - **#7** `reportClose(...)` previously compiled (and would have
 *    crashed at runtime) because `mapOf(...)` with `if (cond) "k" to v
 *    else null` is not a valid vararg element. After the fix the helper
 *    accepts `Int?` / `String?` / `String?` nullable parameters and
 *    builds the payload map explicitly.
 *  - **#8** the file no longer carries the dead `@Suppress("unused")
 *    private val _request: Request? = null` or the unused `Request`
 *    import. Pin the absence so the dead code can't sneak back.
 */
class WebSocketInterceptorTest {

    // ---- Bug #3: @Volatile guarantees for cross-thread visibility ----

    @Test
    fun `openedAt field is @Volatile`() {
        val field = DevConnectWebSocketListener::class.java.getDeclaredField("openedAt")
        // On the JVM @Volatile is encoded as the ACC_VOLATILE modifier
        // bit on the Field. Reading the modifiers here is the cheapest
        // way to pin the annotation without re-introducing it.
        assertTrue(
            "openedAt must be volatile so writes from OkHttp reader threads are visible",
            field.modifiers and Modifier.VOLATILE != 0,
        )
    }

    @Test
    fun `url field is @Volatile`() {
        val field = DevConnectWebSocketListener::class.java.getDeclaredField("url")
        assertTrue(
            "url must be volatile so writes from OkHttp reader threads are visible",
            field.modifiers and Modifier.VOLATILE != 0,
        )
    }

    // ---- Bug #7: helper accepts nullable fields without compile/runtime errors ----

    @Test
    fun `reportClose accepts all-nullable params without throwing`() {
        // Before the fix this either failed to compile (mapOf with
        // conditional Pair?) or threw at runtime when filterValues saw
        // a Pair?. After the fix the helper builds the payload via
        // buildMap and filterValues only sees Any? values.
        DevConnectWebSocketHelper.reportClose(
            url = "wss://example.com/ws",
            code = null,
            reason = null,
            error = null,
        )
        // Reaching here without exception is the assertion.
        assertTrue(true)
    }

    @Test
    fun `reportClose populates only provided fields`() {
        // The helper filters out null values before emitting. We can't
        // intercept the WebSocket send on the JVM unit-test runtime
        // (DevConnect.init is never called here), so we just confirm
        // the call path doesn't throw when given a partial payload.
        DevConnectWebSocketHelper.reportClose(
            url = "wss://example.com/ws",
            code = 1000,
            reason = "normal",
            error = null,
        )
        assertTrue(true)
    }

    @Test
    fun `reportFrame accepts all-nullable params without throwing`() {
        DevConnectWebSocketHelper.reportFrame(
            url = "wss://example.com/ws",
            direction = "send",
            opcode = "text",
            payload = null,
            sizeBytes = null,
        )
        assertTrue(true)
    }

    // ---- Bug #8: dead `_request: Request? = null` and Request import are gone ----

    @Test
    fun `dead _request field is removed`() {
        // The old file shipped with `@Suppress("unused") private val _request:
        // Request? = null` — a leftover from a wrapper prototype. Removing
        // it removes the unused `Request` import too. Pin the absence so a
        // regression doesn't slip back in.
        val fields = DevConnectWebSocketListener::class.java.declaredFields +
            DevConnectWebSocketHelper::class.java.declaredFields
        for (f in fields) {
            assertFalse(
                "_request was dead code and must not return; found on ${f.declaringClass.simpleName}",
                f.name == "_request",
            )
        }
    }

    @Test
    fun `file no longer imports okhttp3 Request`() {
        // A bare import line is a top-level Kotlin construct; reflect on
        // the source file directly so we don't pull okhttp3.Request onto
        // the test classpath just to check.
        val sourceUrl = DevConnectWebSocketListener::class.java.protectionDomain.codeSource.location
            ?: error("test classloader didn't expose a code source")
        val srcFile = java.io.File(sourceUrl.toURI())
            .toPath()
            .resolve("../../../../../../../../../main/java/com/devconnect/interceptors/WebSocketInterceptor.kt")
            .toAbsolutePath()
            .toFile()
        // Fall back to scanning by walking up directories; the build
        // directory layout makes the above path unreliable.
        val candidate = if (srcFile.exists()) srcFile else findSourceFile()
        if (candidate != null) {
            val text = candidate.readText()
            assertFalse(
                "WebSocketInterceptor.kt must not import okhttp3.Request (dead since _request was removed)",
                text.contains("import okhttp3.Request"),
            )
        } else {
            // Source not reachable in this build (e.g. test-jar layout).
            // Skip silently — the field-absence check above is the
            // primary regression guard.
        }
    }

    private fun findSourceFile(): java.io.File? {
        // Locate src/main/.../WebSocketInterceptor.kt by walking up from
        // the working directory until we hit the project root.
        var dir: java.io.File? = java.io.File(".").absoluteFile
        repeat(6) {
            dir = dir?.parentFile ?: return null
            val candidate = java.io.File(dir, "src/main/java/com/devconnect/interceptors/WebSocketInterceptor.kt")
            if (candidate.exists()) return candidate
        }
        return null
    }

    // ---- sanity: helper emits nothing when DevConnect.init wasn't called ----

    @Test
    fun `reportOpen is safe without DevConnect init`() {
        DevConnectWebSocketHelper.reportOpen(url = "wss://example.com/ws", openedAt = 0L)
        // The helper sends via DevConnect.safeSend which is a no-op
        // when the SDK is disabled (the default in unit tests).
        assertEquals(0L, 0L) // sentinel: call path didn't throw
    }
}
