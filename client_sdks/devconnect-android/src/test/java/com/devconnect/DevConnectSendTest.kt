package com.devconnect

import com.devconnect.client.WebSocketClient
import org.json.JSONObject
import org.junit.After
import org.junit.Before
import org.junit.Test

/**
 * Sending runs inside the app's own calls (its network stack, its logs):
 * a message that can't be written is dropped, never thrown at the app.
 */
class DevConnectSendTest {

    private val enabledField = DevConnect::class.java.getDeclaredField("enabled").apply { isAccessible = true }
    private val clientField = DevConnect::class.java.getDeclaredField("client").apply { isAccessible = true }

    @Before
    fun connectToNothing() {
        enabledField.setBoolean(DevConnect, true)
        // Never connected: send() writes the message, then queues it.
        clientField.set(DevConnect, WebSocketClient("127.0.0.1", 1, "dev", "app", "1.0"))
    }

    @After
    fun reset() {
        clientField.set(DevConnect, null)
        enabledField.setBoolean(DevConnect, false)
    }

    @Test
    fun `a payload that can't be written is dropped`() {
        // Android's org.json gives null from toString() for a NaN its parser
        // let in; here the value's own toString() fails the write instead.
        val unwritable = JSONObject().put("value", object {
            override fun toString(): String = throw IllegalStateException("unwritable")
        })

        DevConnect.send("client:log", unwritable)
    }

    @Test
    fun `a network report org_json rejects is dropped`() {
        DevConnect.reportNetworkComplete(
            requestId = "r", method = "GET", url = "https://example.com",
            statusCode = 200, startTime = 0,
            responseBody = listOf(1.0, Double.NaN),
        )
    }
}
