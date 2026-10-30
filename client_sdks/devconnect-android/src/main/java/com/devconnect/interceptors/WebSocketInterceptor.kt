package com.devconnect.interceptors

import com.devconnect.DevConnect
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString
import okio.utf8Size
import java.util.UUID
import java.util.WeakHashMap

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
 * To also see what the app sends, open the socket with
 * `DevConnect.newWebSocket(client, req, listener)` instead.
 *
 * Spec (Round 3 / 3.3): "On Android: extend `URLStreamHandlerFactory` to
 * capture the `HttpURLConnection` and hook `getInputStream()` /
 * `getOutputStream()`. [...] keeping a reference to the open socket and
 * reading frames asynchronously."
 *
 * OkHttp's WebSocket listener model gives us a cleaner alternative: we
 * listen for events on the listener and emit on each frame.
 */
class DevConnectWebSocketListener internal constructor(
    private val delegate: WebSocketListener?,
    /** Set by `DevConnect.newWebSocket`: [delegate] gets the reporting socket it returned. */
    private val wrapSocket: Boolean,
) : WebSocketListener() {

    /** Reports events and answers the peer's close itself. */
    constructor() : this(null, false)

    /** Reports events, then hands each to [delegate], which decides how to close. */
    constructor(delegate: WebSocketListener) : this(delegate, false)

    // One socket per listener when wrapSocket: newWebSocket makes a new one each time.
    private var wrapped: WebSocket? = null

    /** The socket the app sees: a [DevConnectWebSocket] for `DevConnect.newWebSocket`, else OkHttp's own. */
    internal fun appSocket(webSocket: WebSocket): WebSocket =
        if (!wrapSocket) webSocket
        else synchronized(this) { wrapped ?: DevConnectWebSocket(webSocket).also { wrapped = it } }

    override fun onOpen(webSocket: WebSocket, response: Response) {
        report(
            "client:ws_open", webSocket,
            "openedAt" to System.currentTimeMillis(),
            "protocol" to response.header("Sec-WebSocket-Protocol").orEmpty(),
        )
        delegate?.onOpen(appSocket(webSocket), response)
    }

    override fun onMessage(webSocket: WebSocket, text: String) {
        reportFrame(webSocket, "receive", text)
        delegate?.onMessage(appSocket(webSocket), text)
    }

    override fun onMessage(webSocket: WebSocket, bytes: ByteString) {
        reportFrame(webSocket, "receive", bytes)
        delegate?.onMessage(appSocket(webSocket), bytes)
    }

    // Not reported: the close event goes out once, from onClosed or onFailure.
    override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
        if (delegate != null) {
            delegate.onClosing(appSocket(webSocket), code, reason)
        } else {
            // OkHttp rejects echoing some codes (1005 "no status"), so fall back to a normal close.
            runCatching { webSocket.close(code, reason) }.onFailure { runCatching { webSocket.close(1000, null) } }
        }
    }

    override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
        report(
            "client:ws_close", webSocket,
            "code" to code,
            "reason" to reason,
            "timestamp" to System.currentTimeMillis(),
        )
        delegate?.onClosed(appSocket(webSocket), code, reason)
    }

    override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
        report(
            "client:ws_close", webSocket,
            "error" to (t.message ?: t.javaClass.name),
            "timestamp" to System.currentTimeMillis(),
        )
        delegate?.onFailure(appSocket(webSocket), t, response)
    }
}

/** OkHttp [WebSocket] that reports each frame the app sends, then sends it. */
internal class DevConnectWebSocket(private val delegate: WebSocket) : WebSocket by delegate {
    override fun send(text: String): Boolean {
        reportFrame(delegate, "send", text)
        return delegate.send(text)
    }

    override fun send(bytes: ByteString): Boolean {
        reportFrame(delegate, "send", bytes)
        return delegate.send(bytes)
    }
}

/** One id per OkHttp socket, so the desktop can tell connections apart; weak, so closed sockets drop out. */
private val connectionIds = WeakHashMap<WebSocket, String>()

/** Sends a `client:ws_*` event for [webSocket], OkHttp's own socket (never a [DevConnectWebSocket]). */
private fun report(type: String, webSocket: WebSocket, vararg fields: Pair<String, Any?>) {
    try {
        val id = synchronized(connectionIds) {
            connectionIds.getOrPut(webSocket) { UUID.randomUUID().toString() }
        }
        // From the request, so frames sent before onOpen have it too.
        val url = webSocket.request().url.toString()
        DevConnect.safeSend(type, mapOf("connectionId" to id, "url" to url, *fields))
    } catch (_: Throwable) {}
}

private fun reportFrame(webSocket: WebSocket, direction: String, text: String) = report(
    "client:ws_frame", webSocket,
    "direction" to direction,
    "opcode" to "text",
    "payload" to text,
    "sizeBytes" to text.utf8Size(),
    "timestamp" to System.currentTimeMillis(),
)

private fun reportFrame(webSocket: WebSocket, direction: String, bytes: ByteString) = report(
    "client:ws_frame", webSocket,
    "direction" to direction,
    "opcode" to "binary",
    "payload" to "<binary ${bytes.size} bytes>",
    "sizeBytes" to bytes.size,
    "timestamp" to System.currentTimeMillis(),
)

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
 * without subclassing `DevConnectWebSocketListener`. Sees incoming
 * frames, open and close; `DevConnect.newWebSocket` also sees sends.
 *
 * ```kotlin
 * val socket = client.newWebSocket(req, devConnectWrap(listener))
 * ```
 */
fun devConnectWrap(delegate: WebSocketListener): WebSocketListener = DevConnectWebSocketListener(delegate)