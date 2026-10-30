package com.devconnect.client

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.DataInputStream
import java.io.OutputStream
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.security.MessageDigest
import java.util.Base64
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * [WebSocketClient.send] used to launch every write on the shared
 * Dispatchers.IO. When the desktop stops reading (hung, laptop asleep,
 * half-open link) each write blocks, so each message parked one of the
 * app's IO threads and the rest piled up behind them without bound.
 */
class WebSocketClientTest {

    @Test
    fun `a desktop that stops reading parks only the writer thread`() {
        val server = ServerSocket()
        server.receiveBufferSize = 16 * 1024 // writes block after a few hundred KB
        server.bind(InetSocketAddress(InetAddress.getLoopbackAddress(), 0))
        val client = WebSocketClient("127.0.0.1", server.localPort, "device", "app", "1.0")
        try {
            client.connect()
            server.accept().use { desktop ->
                val input = DataInputStream(desktop.getInputStream())
                acceptUpgrade(input, desktop.getOutputStream())
                waitFor { client.isConnected }

                val count = 5000
                val padding = "x".repeat(8 * 1024)
                repeat(count) { client.send("$it $padding") }

                val ioFree = CountDownLatch(1)
                CoroutineScope(Dispatchers.IO).launch { ioFree.countDown() }
                assertTrue("the app's IO threads are parked", ioFree.await(5, TimeUnit.SECONDS))

                // The desktop reads again: in order, newest kept, backlog bounded.
                desktop.soTimeout = 10_000
                val received = mutableListOf<Int>()
                while (received.lastOrNull() != count - 1) {
                    received += readFrame(input).substringBefore(' ').toInt()
                }
                assertTrue("out of order", received.zipWithNext().all { (a, b) -> a < b })
                assertTrue("backlog not bounded: ${received.size}", received.size < count)
            }
        } finally {
            client.disconnect()
            server.close()
        }
    }

    /** Answers the client's upgrade request the way the desktop does. */
    private fun acceptUpgrade(input: DataInputStream, output: OutputStream) {
        var key = ""
        while (true) {
            val line = buildString {
                while (true) {
                    val c = input.readUnsignedByte()
                    if (c == '\n'.code) break
                    append(c.toChar())
                }
            }.trim()
            if (line.isEmpty()) break
            if (line.startsWith("Sec-WebSocket-Key:")) key = line.substringAfter(':').trim()
        }
        val sha1 = MessageDigest.getInstance("SHA-1")
            .digest((key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").toByteArray())
        output.write(
            ("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n" +
                "Sec-WebSocket-Accept: ${Base64.getEncoder().encodeToString(sha1)}\r\n\r\n").toByteArray()
        )
        output.flush()
    }

    /** Reads one masked client frame (RFC 6455 §5.2) as text. */
    private fun readFrame(input: DataInputStream): String {
        input.readUnsignedByte() // FIN + opcode
        val length = when (val len = input.readUnsignedByte() and 0x7F) {
            126 -> input.readUnsignedShort()
            127 -> input.readLong().toInt()
            else -> len
        }
        val mask = ByteArray(4).also { input.readFully(it) }
        val data = ByteArray(length).also { input.readFully(it) }
        for (i in data.indices) data[i] = (data[i].toInt() xor mask[i % 4].toInt()).toByte()
        return String(data, Charsets.UTF_8)
    }

    private fun waitFor(condition: () -> Boolean) {
        val deadline = System.currentTimeMillis() + 5_000
        while (!condition()) {
            check(System.currentTimeMillis() < deadline) { "timed out" }
            Thread.sleep(10)
        }
    }
}
