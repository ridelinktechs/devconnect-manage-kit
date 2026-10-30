package com.devconnect.interceptors

import com.devconnect.DevConnect
import okhttp3.Interceptor
import okhttp3.MediaType
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Protocol
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import okhttp3.ResponseBody
import okhttp3.ResponseBody.Companion.asResponseBody
import okhttp3.ResponseBody.Companion.toResponseBody
import okio.Buffer
import okio.BufferedSink
import okio.ForwardingSource
import okio.buffer
import okio.source
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.io.ByteArrayInputStream

/**
 * [OkHttpInterceptor] only observes: the app gets its bodies untouched.
 *
 *  - responses used to be rebuilt from a UTF-8 string of the first ~1 MB,
 *    corrupting binary bodies, cutting large ones and blocking on streams;
 *  - request bodies used to be read whole, so big uploads OOMed and
 *    one-shot bodies were consumed before the real send.
 */
class OkHttpInterceptorTest {

    // As in WebSocketInterceptorTest: enabled but never initialised,
    // DevConnect queues each event where the test reads it.
    private val enabledField = DevConnect::class.java.getDeclaredField("enabled").apply { isAccessible = true }
    private val queueField = DevConnect::class.java.getDeclaredField("preInitQueue").apply { isAccessible = true }

    @Suppress("UNCHECKED_CAST")
    private fun queue() = queueField.get(DevConnect) as MutableList<Pair<String, JSONObject>>

    private fun reports() = queue().filter { it.first == "client:network:request_complete" }.map { it.second }

    @Before
    fun captureEvents() {
        enabledField.setBoolean(DevConnect, true)
        queue().clear()
    }

    @After
    fun stopCapturing() {
        enabledField.setBoolean(DevConnect, false)
        queue().clear()
    }

    @Test
    fun `binary response over the cap reaches the app byte for byte`() {
        // Not valid UTF-8, bigger than the 1 MB cap, streamed like a network body.
        val image = ByteArray(2 * 1024 * 1024) { it.toByte() }
        val body = ByteArrayInputStream(image).source().buffer()
            .asResponseBody("image/jpeg".toMediaType(), image.size.toLong())

        val response = call(get()) { respond(it, body) }

        assertArrayEquals(image, response.body.bytes())
        assertEquals("<binary, 2097152 bytes>", reports().single().getString("responseBody"))
    }

    @Test
    fun `event stream reaches the app unread`() {
        // An SSE stream stays open; peeking it would block the call.
        val events = object : ForwardingSource(Buffer().writeUtf8("data: hi\n\n")) {
            var reads = 0
            override fun read(sink: Buffer, byteCount: Long) = super.read(sink, byteCount).also { reads++ }
        }

        val response = call(get()) {
            respond(it, events.buffer().asResponseBody("text/event-stream".toMediaType()))
        }

        assertEquals(0, events.reads)
        assertEquals("data: hi\n\n", response.body.string())
        assertEquals("<stream>", reports().single().getString("responseBody"))
    }

    @Test
    fun `a body without a content type is still reported as text`() {
        val response = call(get()) { respond(it, "plain".toResponseBody(null)) }

        assertEquals("plain", response.body.string())
        assertEquals("plain", reports().single().getString("responseBody"))
    }

    @Test
    fun `small json bodies are still captured`() {
        val json = "application/json".toMediaType()
        val request = Request.Builder().url(URL).post("""{"q":1}""".toRequestBody(json)).build()

        val response = call(request) { respond(it, """{"ok":true}""".toResponseBody(json)) }

        assertEquals("""{"ok":true}""", response.body.string())
        val report = reports().single()
        assertEquals(1, report.getJSONObject("requestBody").getInt("q"))
        assertTrue(report.getJSONObject("responseBody").getBoolean("ok"))
    }

    @Test
    fun `one-shot, unknown-length and large request bodies are not read`() {
        val oneShot = SpyBody(length = 3, oneShot = true)
        val unknown = SpyBody(length = -1)
        val upload = SpyBody(length = 50L * 1024 * 1024)
        val field = SpyBody(length = 50L * 1024 * 1024)
        val form = MultipartBody.Builder().setType(MultipartBody.FORM)
            .addFormDataPart("meta", null, field)
            .build()

        for (body in listOf(oneShot, unknown, upload, form)) {
            call(Request.Builder().url(URL).post(body).build()) { respond(it, "".toResponseBody()) }.close()
        }

        assertEquals(0, oneShot.writes + unknown.writes + upload.writes + field.writes)
        val (a, b, c, d) = reports().map { it.get("requestBody") }
        assertEquals("<stream, 3 bytes>", a)
        assertEquals("<stream>", b)
        assertEquals("<large, 52428800 bytes>", c)
        assertEquals("<large, 52428800 bytes>", (d as JSONObject).getString("meta"))
    }

    /** Counts reads; writes nothing, since the fake network never sends it. */
    private class SpyBody(private val length: Long, private val oneShot: Boolean = false) : RequestBody() {
        var writes = 0
        override fun contentType(): MediaType? = null
        override fun contentLength() = length
        override fun isOneShot() = oneShot
        override fun writeTo(sink: BufferedSink) {
            writes++
        }
    }

    /** Runs [request] through the interceptor; [network] stands in for the server. */
    private fun call(request: Request, network: (Request) -> Response): Response =
        OkHttpClient.Builder()
            .addInterceptor(OkHttpInterceptor())
            .addInterceptor(Interceptor { network(it.request()) })
            .build()
            .newCall(request)
            .execute()

    private fun get() = Request.Builder().url(URL).build()

    private fun respond(request: Request, body: ResponseBody) = Response.Builder()
        .request(request)
        .protocol(Protocol.HTTP_1_1)
        .code(200)
        .message("OK")
        .body(body)
        .build()

    private companion object {
        const val URL = "https://api.example.com/upload"
    }
}
