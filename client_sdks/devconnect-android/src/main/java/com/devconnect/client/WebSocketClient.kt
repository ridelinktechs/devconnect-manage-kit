package com.devconnect.client

import kotlinx.coroutines.*
import org.json.JSONObject
import java.io.BufferedInputStream
import java.io.PrintWriter
import java.net.Socket
import java.security.MessageDigest
import java.util.*
import java.util.concurrent.ConcurrentLinkedQueue

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
    var isConnected = false
        private set

    private var socket: Socket? = null
    private var writer: PrintWriter? = null
    private val messageQueue = ConcurrentLinkedQueue<String>()
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var reconnectJob: Job? = null

    fun connect() {
        scope.launch {
            try {
                socket = Socket(host, port)
                writer = PrintWriter(socket!!.getOutputStream(), true)

                // Perform WebSocket handshake
                val key = Base64.getEncoder().encodeToString(
                    ByteArray(16).also { Random().nextBytes(it) }
                )
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
                val lineBuf = StringBuilder()
                while (true) {
                    val b = inputStream.read()
                    if (b == -1) break
                    if (b == '\n'.code) {
                        val line = lineBuf.toString().trimEnd('\r')
                        lineBuf.clear()
                        if (line.isEmpty()) break  // end of HTTP headers
                    } else {
                        lineBuf.append(b.toChar())
                    }
                }

                isConnected = true

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
                    // Simplified WebSocket frame reading
                    val firstByte = inputStream.read()
                    if (firstByte == -1) break

                    val secondByte = inputStream.read()
                    val payloadLength = secondByte and 0x7F

                    val actualLength = when {
                        payloadLength <= 125 -> payloadLength
                        payloadLength == 126 -> {
                            val b1 = inputStream.read()
                            val b2 = inputStream.read()
                            (b1 shl 8) or b2
                        }
                        else -> {
                            // 8 bytes for length - skip for simplicity
                            repeat(8) { inputStream.read() }
                            0
                        }
                    }

                    if (actualLength > 0) {
                        val data = ByteArray(actualLength)
                        var totalRead = 0
                        while (totalRead < actualLength) {
                            val read = inputStream.read(
                                data, totalRead, actualLength - totalRead
                            )
                            if (read == -1) break
                            totalRead += read
                        }

                        val message = String(data)
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

        // Mask key
        val maskKey = ByteArray(4).also { Random().nextBytes(it) }
        frame.addAll(maskKey.toList())

        // Masked data
        for (i in data.indices) {
            frame.add((data[i].toInt() xor maskKey[i % 4].toInt()).toByte())
        }

        return frame.toByteArray()
    }

    private fun scheduleReconnect() {
        reconnectJob?.cancel()
        reconnectJob = scope.launch {
            delay(3000)
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
}
