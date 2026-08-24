package com.devconnect.interceptors

import com.devconnect.DevConnect
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString

/**
 * OkHttp `WebSocket` listener that emits `client:ws_*` events to the
 * desktop WebSocket inspector.
 *
 * Wire it into your OkHttp client:
 * ```kotlin
 * val client = OkHttpClient.Builder()
 *     .build()
 *
 * val req = Request.Builder().url("wss://api.example.com/ws").build()
 * val socket = client.newWebSocket(req, DevConnectWebSocketListener())
 * socket.send("subscribe")
 * ```
 *
 * Spec (Round 3 / 3.3): "On Android: extend `URLStreamHandlerFactory` to
 * capture the `HttpURLConnection` and hook `getInputStream()` /
 * `getOutputStream()`. [...] keeping a reference to the open socket and
 * reading frames asynchronously."
 *
 * OkHttp's WebSocket listener model gives us a cleaner alternative: we
 * listen for events on the listener and emit on each frame.
 */
class DevConnectWebSocketListener : WebSocketListener() {

    // Both fields are written by OkHttp's reader thread and read by any
    // thread that emits the corresponding client:* event (often the
    // main thread when the desktop receives a ping). @Volatile gives us
    // the visibility guarantee without paying for a lock — the fields
    // are independent and the stale-read window is harmless.
    @Volatile private var openedAt: Long = 0L
    @Volatile private var url: String = ""

    override fun onOpen(webSocket: WebSocket, response: Response) {
        openedAt = System.currentTimeMillis()
        url = response.request.url.toString()
        try {
            DevConnect.safeSend("client:ws_open", mapOf(
                "url" to url,
                "openedAt" to openedAt,
                "protocol" to response.header("Sec-WebSocket-Protocol").orEmpty(),
            ))
        } catch (_: Throwable) {}
    }

    override fun onMessage(webSocket: WebSocket, text: String) {
        try {
            DevConnect.safeSend("client:ws_frame", mapOf(
                "url" to url,
                "direction" to "receive",
                "opcode" to "text",
                "payload" to text,
                "sizeBytes" to text.length,
                "timestamp" to System.currentTimeMillis(),
            ))
        } catch (_: Throwable) {}
    }

    override fun onMessage(webSocket: WebSocket, bytes: ByteString) {
        try {
            DevConnect.safeSend("client:ws_frame", mapOf(
                "url" to url,
                "direction" to "receive",
                "opcode" to "binary",
                "sizeBytes" to bytes.size,
                "payload" to "<binary ${bytes.size} bytes>",
                "timestamp" to System.currentTimeMillis(),
            ))
        } catch (_: Throwable) {}
    }

    override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
        try {
            DevConnect.safeSend("client:ws_close", mapOf(
                "url" to url,
                "code" to code,
                "reason" to reason,
                "timestamp" to System.currentTimeMillis(),
            ))
        } catch (_: Throwable) {}
        webSocket.close(code, reason)
    }

    override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
        try {
            DevConnect.safeSend("client:ws_close", mapOf(
                "url" to url,
                "code" to code,
                "reason" to reason,
                "timestamp" to System.currentTimeMillis(),
            ))
        } catch (_: Throwable) {}
    }

    override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
        try {
            DevConnect.safeSend("client:ws_close", mapOf(
                "url" to url,
                "error" to t.message,
                "timestamp" to System.currentTimeMillis(),
            ))
        } catch (_: Throwable) {}
    }
}

/**
 * Helper for consumers who use a non-OkHttp WebSocket client. Each frame
 * can be reported via this object — useful for the rare `java.net.http`
 * HttpClient WebSocket case or third-party libraries.
 */
object DevConnectWebSocketHelper {
    fun reportOpen(url: String, openedAt: Long = System.currentTimeMillis()) {
        try {
            DevConnect.safeSend("client:ws_open", mapOf(
                "url" to url,
                "openedAt" to openedAt,
            ))
        } catch (_: Throwable) {}
    }

    fun reportFrame(url: String, direction: String, opcode: String, payload: Any? = null, sizeBytes: Int? = null) {
        try {
            // `mapOf` with `if (cond) "k" to v else null` produces a
            // `Pair<String, T>?` which the vararg overload of mapOf can't
            // accept. Build explicitly so the payload map is always
            // homogeneous String→Any?.
            val payload = buildMap<String, Any?> {
                put("url", url)
                put("direction", direction)
                put("opcode", opcode)
                put("payload", payload)
                put("sizeBytes", sizeBytes)
                put("timestamp", System.currentTimeMillis())
            }
            DevConnect.safeSend("client:ws_frame", payload.filterValues { it != null })
        } catch (_: Throwable) {}
    }

    fun reportClose(url: String, code: Int? = null, reason: String? = null, error: String? = null) {
        try {
            val payload = buildMap<String, Any?> {
                put("url", url)
                put("code", code)
                put("reason", reason)
                put("error", error)
                put("timestamp", System.currentTimeMillis())
            }
            DevConnect.safeSend("client:ws_close", payload.filterValues { it != null })
        } catch (_: Throwable) {}
    }
}

/**
 * Static helper to wrap an OkHttp WebSocket with frame instrumentation
 * without subclassing `DevConnectWebSocketListener`:
 *
 * ```kotlin
 * val socket = client.newWebSocket(req, devConnectWrap { /* original */ })
 * ```
 */
inline fun devConnectWrap(
    delegate: WebSocketListener,
): WebSocketListener {
    val wrapper = DevConnectWebSocketListener()
    return object : WebSocketListener() {
        override fun onOpen(webSocket: WebSocket, response: Response) {
            wrapper.onOpen(webSocket, response)
            delegate.onOpen(webSocket, response)
        }
        override fun onMessage(webSocket: WebSocket, text: String) {
            wrapper.onMessage(webSocket, text)
            delegate.onMessage(webSocket, text)
        }
        override fun onMessage(webSocket: WebSocket, bytes: ByteString) {
            wrapper.onMessage(webSocket, bytes)
            delegate.onMessage(webSocket, bytes)
        }
        override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
            wrapper.onClosing(webSocket, code, reason)
            delegate.onClosing(webSocket, code, reason)
        }
        override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
            wrapper.onClosed(webSocket, code, reason)
            delegate.onClosed(webSocket, code, reason)
        }
        override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
            wrapper.onFailure(webSocket, t, response)
            delegate.onFailure(webSocket, t, response)
        }
    }
}