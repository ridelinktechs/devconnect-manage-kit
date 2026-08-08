package com.devconnect.client

import kotlinx.coroutines.*
import org.json.JSONObject
import java.io.BufferedInputStream
import java.io.PrintWriter
import java.net.Socket
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.*
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.atomic.AtomicInteger
import kotlin.math.min

/**
 * Lightweight WebSocket client for DevConnect.
 * Uses raw sockets to avoid external dependencies.
 */
class WebSocketClient(
    private val host: String,
    private val port: Int,
    private val deviceId: String,
    private val appName: String,
    private val appVersion: String,
    private val versionCode: String? = null
) {
    /** Callback for incoming server messages (type, payload) */
    var onServerMessage: ((String, JSONObject) -> Unit)? = null
    /**
     * Fired when the server's first message is `server:hello`. The argument is
     * the announced machineId (or null when missing) — used by the host cache
     * for identity verification on subsequent reconnects.
     */
    var onServerHello: ((String?) -> Unit)? = null
    var isConnected = false
        private set

    private var socket: Socket? = null
    private var writer: PrintWriter? = null
    private val messageQueue = ConcurrentLinkedQueue<String>()
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var reconnectJob: Job? = null
    private val reconnectAttempts = AtomicInteger(0)
    private val secureRandom = SecureRandom()

    fun connect() {
        scope.launch {
            try {
                socket = Socket(host, port)
                writer = PrintWriter(socket!!.getOutputStream(), true)

                // Perform WebSocket handshake
                val keyBytes = ByteArray(16).also { secureRandom.nextBytes(it) }
                val key = Base64.getEncoder().encodeToString(keyBytes)
                val handshake = """
                    GET / HTTP/1.1
                    Host: $host:$port
                    Upgrade: websocket
                    Connection: Upgrade
                    Sec-WebSocket-Key: $key
                    Sec-WebSocket-Version: 13

                """.trimIndent() + "\r\n"

                socket!!.getOutputStream().write(handshake.toByteArray())
                socket!!.getOutputStream().flush()

                // Read handshake response using BufferedInputStream
                // (avoids BufferedReader stealing bytes from the WebSocket frame stream)
                val inputStream = BufferedInputStream(socket!!.getInputStream())
                val statusLine = readLine(inputStream)
                    ?: throw java.io.IOException("Empty handshake response")
                if (!statusLine.contains("101")) {
                    throw java.io.IOException("Unexpected handshake response: $statusLine")
                }
                var acceptHeader: String? = null
                while (true) {
                    val line = readLine(inputStream) ?: break
                    if (line.isEmpty()) break  // end of HTTP headers
                    if (line.startsWith("Sec-WebSocket-Accept:", ignoreCase = true)) {
                        acceptHeader = line.substringAfter(':').trim()
                    }
                }
                // Validate the Sec-WebSocket-Accept per RFC 6455 §1.3.
                val expected = computeSecWebSocketAccept(key)
                if (acceptHeader == null || acceptHeader != expected) {
                    throw java.io.IOException(
                        "Invalid Sec-WebSocket-Accept (expected=$expected got=$acceptHeader)"
                    )
                }

                isConnected = true
                reconnectAttempts.set(0)

                // Flush queued messages
                while (messageQueue.isNotEmpty()) {
                    sendRaw(messageQueue.poll()!!)
                }

                // Wait for server:hello before sending handshake

                // Listen for messages
                listenForMessages(inputStream)
            } catch (e: Exception) {
                isConnected = false
                scheduleReconnect()
            }
        }
    }

    private fun readLine(input: BufferedInputStream): String? {
        val sb = StringBuilder()
        while (true) {
            val b = input.read()
            if (b == -1) return if (sb.isEmpty()) null else sb.toString().trimEnd('\r')
            if (b == '\n'.code) return sb.toString().trimEnd('\r')
            sb.append(b.toChar())
        }
    }

    private fun computeSecWebSocketAccept(clientKey: String): String {
        val sha1 = MessageDigest.getInstance("SHA-1")
        sha1.update(clientKey.toByteArray())
        sha1.update(WEB_SOCKET_MAGIC_GUID.toByteArray())
        return Base64.getEncoder().encodeToString(sha1.digest())
    }

    private fun sendHandshake() {
        val payload = JSONObject().apply {
            put("deviceInfo", JSONObject().apply {
                put("deviceId", deviceId)
                put("deviceName", android.os.Build.MODEL)
                put("platform", "android")
                put("osVersion", "Android ${android.os.Build.VERSION.RELEASE}")
                put("appName", appName)
                put("appVersion", appVersion)
                if (versionCode != null) put("versionCode", versionCode)
                put("sdkVersion", "1.0.0")
            })
        }

        val msg = JSONObject().apply {
            put("id", UUID.randomUUID().toString())
            put("type", "client:handshake")
            put("deviceId", deviceId)
            put("timestamp", System.currentTimeMillis())
            put("payload", payload)
        }

        sendRaw(msg.toString())
    }

    private fun listenForMessages(inputStream: BufferedInputStream) {
        scope.launch {
            try {
                while (isConnected) {
                    // WebSocket frame reading per RFC 6455 §5.2.
                    val firstByte = inputStream.read()
                    if (firstByte == -1) break

                    val secondByte = inputStream.read()
                    val payloadLength = secondByte and 0x7F

                    val actualLength: Long = when {
                        payloadLength <= 125 -> payloadLength.toLong()
                        payloadLength == 126 -> {
                            // 16-bit length
                            val b1 = inputStream.read()
                            val b2 = inputStream.read()
                            if (b1 == -1 || b2 == -1) break
                            ((b1 shl 8) or b2).toLong()
                        }
                        else -> {
                            // 64-bit length — previous implementation
                            // read and discarded the 8 bytes, returning
                            // 0, which silently dropped every frame
                            // larger than 64 KB.
                            var length = 0L
                            for (i in 0 until 8) {
                                val b = inputStream.read()
                                if (b == -1) break
                                length = (length shl 8) or b.toLong()
                            }
                            length
                        }
                    }

                    // Client-to-server frames must be masked (RFC 6455
                    // §5.1), but server-to-client frames are unmasked —
                    // skip the 4-byte mask key only if present.
                    val masked = (secondByte and 0x80) != 0
                    if (masked) {
                        repeat(4) { inputStream.read() }
                    }

                    if (actualLength > 0) {
                        // Cap a single captured frame at 8 MB so a
                        // runaway server cannot OOM the device. Larger
                        // frames are read but only the prefix is parsed.
                        val toParse = min(actualLength, MAX_FRAME_BYTES.toLong()).toInt()
                        val data = ByteArray(toParse)
                        var totalRead = 0
                        while (totalRead < toParse) {
                            val read = inputStream.read(
                                data, totalRead, toParse - totalRead
                            )
                            if (read == -1) break
                            totalRead += read
                        }
                        // Drain any remaining bytes of the frame so we
                        // stay aligned with the next frame.
                        if (actualLength > toParse) {
                            var remaining = actualLength - toParse
                            val sink = ByteArray(8 * 1024)
                            while (remaining > 0) {
                                val chunk = if (remaining > sink.size) sink.size else remaining.toInt()
                                val n = inputStream.read(sink, 0, chunk)
                                if (n == -1) break
                                remaining -= n
                            }
                        }

                        val message = String(data, 0, totalRead, Charsets.UTF_8)
                        handleMessage(message)
                    }
                }
            } catch (e: Exception) {
                isConnected = false
                scheduleReconnect()
            }
        }
    }

    private fun handleMessage(message: String) {
        try {
            val json = JSONObject(message)
            val type = json.optString("type")
            if (type == "server:hello") {
                sendHandshake()
                val payload = json.optJSONObject("payload")
                val machineId = payload?.optString("machineId", null)
                onServerHello?.invoke(machineId)
            } else if (type.startsWith("server:")) {
                val payload = json.optJSONObject("payload") ?: JSONObject()
                onServerMessage?.invoke(type, json)
            }
        } catch (_: Exception) {}
    }

    fun send(message: String) {
        if (isConnected) {
            scope.launch { sendRaw(message) }
        } else {
            if (messageQueue.size < 1000) {
                messageQueue.add(message)
            }
        }
    }

    private fun sendRaw(message: String) {
        try {
            val data = message.toByteArray()
            val frame = buildWebSocketFrame(data)
            socket?.getOutputStream()?.write(frame)
            socket?.getOutputStream()?.flush()
        } catch (e: Exception) {
            isConnected = false
            scheduleReconnect()
        }
    }

    private fun buildWebSocketFrame(data: ByteArray): ByteArray {
        val frame = mutableListOf<Byte>()
        // Text frame, FIN bit set
        frame.add(0x81.toByte())

        // Mask bit set (client must mask)
        val maskBit = 0x80

        when {
            data.size <= 125 -> {
                frame.add((maskBit or data.size).toByte())
            }
            data.size <= 65535 -> {
                frame.add((maskBit or 126).toByte())
                frame.add((data.size shr 8).toByte())
                frame.add((data.size and 0xFF).toByte())
            }
            else -> {
                frame.add((maskBit or 127).toByte())
                for (i in 7 downTo 0) {
                    frame.add(((data.size.toLong() shr (8 * i)) and 0xFF).toByte())
                }
            }
        }

        // Mask key — use SecureRandom per RFC 6455 §5.3. The previous
        // implementation used `Random()` which uses a Linear
        // Congruential Generator seeded from the system clock; that
        // makes the 32-bit mask key trivially guessable by an on-path
        // observer and breaks WebSocket's framing-integrity guarantee.
        val maskKey = ByteArray(4).also { secureRandom.nextBytes(it) }
        frame.addAll(maskKey.toList())

        // Masked data
        for (i in data.indices) {
            frame.add((data[i].toInt() xor maskKey[i % 4].toInt()).toByte())
        }

        return frame.toByteArray()
    }

    private fun scheduleReconnect() {
        reconnectJob?.cancel()
        val attempt = reconnectAttempts.incrementAndGet()
        // Exponential backoff with jitter, capped at 30 s.
        //   1st retry  →  ~500 ms
        //   5th retry  →  ~8 s
        //   10th retry →  30 s (cap)
        // Jitter avoids the thundering-herd reconnect pattern when
        // the server comes back and many clients try at once.
        val baseMs = (1L shl min(attempt - 1, 6)).coerceAtMost(60L) * 500L
        val cappedMs = min(baseMs, MAX_RECONNECT_DELAY_MS)
        // `java.security.SecureRandom` does not have a `nextLong(bound)`
        // overload — only `nextLong()` (no args). Compute the jitter
        // range in a way that avoids that non-existent method.
        val jitterBound = (cappedMs / 4 + 1).toInt().coerceAtLeast(1)
        val jitterMs = secureRandom.nextInt(jitterBound).toLong()
        val delayMs = cappedMs + jitterMs
        reconnectJob = scope.launch {
            delay(delayMs)
            if (!isConnected) connect()
        }
    }

    fun disconnect() {
        isConnected = false
        reconnectJob?.cancel()
        reconnectJob = null
        scope.coroutineContext.cancelChildren()  // Cancel children, keep scope alive
        try { socket?.close() } catch (_: Exception) {}
        socket = null
    }

    private companion object {
        // RFC 6455 §1.3 — magic GUID concatenated with the client's
        // Sec-WebSocket-Key before SHA-1 hashing for the server's
        // Sec-WebSocket-Accept.
        const val WEB_SOCKET_MAGIC_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

        // Cap a single parsed frame at 8 MB. Server-to-client frames
        // larger than this are read and discarded; only the first 8 MB
        // is parsed into a String. Prevents a runaway server from OOMing
        // the device with a giant frame.
        const val MAX_FRAME_BYTES = 8 * 1024 * 1024

        // Cap reconnect backoff at 30 s. The base grows as
        // `2^(attempt-1) * 500 ms` so attempts 1–6 are
        // 500/1000/2000/4000/8000/16000 ms; attempt 7+ stay at the cap.
        const val MAX_RECONNECT_DELAY_MS = 30_000L
    }
}
