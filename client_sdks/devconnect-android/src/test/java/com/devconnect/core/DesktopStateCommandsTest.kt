package com.devconnect.core

import com.devconnect.DevConnect
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class DesktopStateCommandsTest {

    @After
    fun unwire() {
        DevConnect.onStateRestore = null
        DevConnect.onReduxDispatch = null
    }

    /** Hands [type] to the SDK the way its socket does. */
    private fun fromDesktop(type: String, payload: String) =
        DesktopCommands.handle(type, JSONObject("""{"type":"$type","payload":$payload}"""))

    @Test
    fun `a dispatched action reaches onReduxDispatch as a map`() {
        val got = mutableListOf<Map<String, Any>>()
        DevConnect.onReduxDispatch = { got += it }
        fromDesktop("server:redux:dispatch", """{"action":{"type":"LOGOUT","meta":{"ids":[1,2]}}}""")
        assertEquals(listOf(mapOf("type" to "LOGOUT", "meta" to mapOf("ids" to listOf(1, 2)))), got)
    }

    @Test
    fun `a restored state reaches onStateRestore with its nested maps and lists`() {
        val got = mutableListOf<Map<String, Any>>()
        DevConnect.onStateRestore = { got += it }
        fromDesktop(
            "server:state:restore",
            """{"state":{"user":{"name":"Ada","age":36},"items":[{"id":1},{"id":2}],"dark":true}}""",
        )
        assertEquals(
            listOf(
                mapOf(
                    "user" to mapOf("name" to "Ada", "age" to 36),
                    "items" to listOf(mapOf("id" to 1), mapOf("id" to 2)),
                    "dark" to true,
                ),
            ),
            got,
        )
    }

    @Test
    fun `a null in the state reads as null and nested arrays become lists`() {
        val got = mutableListOf<Map<String, Any>>()
        DevConnect.onStateRestore = { got += it }
        fromDesktop(
            "server:state:restore",
            """{"state":{"user":{"name":"Ada","nick":null},"grid":[[1,2],[3,null]],"tags":[null,"a"]}}""",
        )
        val state = got.single()
        val user = state["user"] as Map<*, *>
        assertEquals(null, user["nick"])
        assertEquals(false, user.containsKey("nick"))
        assertEquals(listOf(listOf(1, 2), listOf(3, null)), state["grid"])
        assertEquals(listOf(null, "a"), state["tags"])
    }

    @Test
    fun `with nothing wired, a dispatch or a restore is ignored`() {
        fromDesktop("server:redux:dispatch", """{"action":{"type":"LOGOUT"}}""")
        fromDesktop("server:state:restore", """{"state":{"a":1}}""")
    }

    @Test
    fun `a command without its payload, or with the wrong kind, reaches no handler`() {
        val actions = mutableListOf<Map<String, Any>>()
        val states = mutableListOf<Map<String, Any>>()
        DevConnect.onReduxDispatch = { actions += it }
        DevConnect.onStateRestore = { states += it }
        fromDesktop("server:redux:dispatch", "{}")
        fromDesktop("server:redux:dispatch", """{"action":null}""")
        fromDesktop("server:redux:dispatch", """{"action":[1,2]}""")
        fromDesktop("server:state:restore", """{"state":"not a map"}""")
        fromDesktop("server:state:restore", "null")
        assertTrue(actions.isEmpty())
        assertTrue(states.isEmpty())
    }

    @Test
    fun `a handler that throws does not escape into the socket`() {
        DevConnect.onStateRestore = { throw IllegalStateException("setValue on a background thread") }
        DevConnect.onReduxDispatch = { throw IllegalArgumentException("unknown action") }
        fromDesktop("server:state:restore", """{"state":{"a":1}}""")
        fromDesktop("server:redux:dispatch", """{"action":{"type":"X"}}""")
    }
}
