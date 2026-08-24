package com.devconnect.interceptors

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * Tests for the in-memory mock rule store backing [MockServerInterceptor].
 *
 * The store is a Kotlin `object` (process-wide singleton), so each test
 * resets the state in `@After` to keep the suite order-independent.
 */
class MockRuleStoreTest {

    @After
    fun reset() {
        MockRuleStore.setRules(emptyList())
    }

    // ---------- setRules ----------

    @Test
    fun `setRules only keeps enabled rules`() {
        val rules = listOf(
            rule(id = "a", enabled = true),
            rule(id = "b", enabled = false),
        )
        MockRuleStore.setRules(rules)
        val match = MockRuleStore.findMatch(method = "GET", url = "https://x/y", headers = null)
        assertNotNull("enabled rule 'a' should be present", match)
        assertEquals("a", match!!.id)
    }

    @Test
    fun `setRules drops every disabled rule`() {
        val rules = listOf(
            rule(id = "a", enabled = false),
            rule(id = "b", enabled = false),
        )
        MockRuleStore.setRules(rules)
        val match = MockRuleStore.findMatch(method = "GET", url = "https://x/y", headers = null)
        assertNull("all rules disabled → no match", match)
    }

    // ---------- findMatch: method / url matching ----------

    @Test
    fun `findMatch matches method case-insensitively`() {
        MockRuleStore.setRules(listOf(rule(id = "a", enabled = true, method = "POST")))
        val match = MockRuleStore.findMatch(method = "post", url = "https://x/y", headers = null)
        assertNotNull(match)
        assertEquals("a", match!!.id)
    }

    @Test
    fun `findMatch matches url via regex`() {
        MockRuleStore.setRules(listOf(rule(id = "a", enabled = true, url = "^https://api\\.example\\.com/users/\\d+$")))
        val match = MockRuleStore.findMatch(method = "GET", url = "https://api.example.com/users/42", headers = null)
        assertNotNull(match)
    }

    @Test
    fun `findMatch returns null when no rule matches`() {
        MockRuleStore.setRules(listOf(rule(id = "a", enabled = true, method = "GET", url = "^https://only-this-host")))
        val match = MockRuleStore.findMatch(method = "GET", url = "https://other-host/path", headers = null)
        assertNull(match)
    }

    @Test
    fun `findMatch returns null on empty rule list`() {
        val match = MockRuleStore.findMatch(method = "GET", url = "https://x/y", headers = null)
        assertNull(match)
    }

    // ---------- findMatch: header constraints (the bug) ----------

    @Test
    fun `findMatch skips disabled rules even when other constraints match`() {
        MockRuleStore.setRules(listOf(
            rule(id = "a", enabled = false, method = "GET", url = ".*"),
        ))
        val match = MockRuleStore.findMatch(method = "GET", url = "https://x/y", headers = null)
        assertNull(match)
    }

    /**
     * Cross-SDK consistency bug: when a rule's header constraint fails,
     * [MockRuleStore.findMatch] should CONTINUE to the next rule, not
     * abort the entire search. Mirrors the behavior of the Flutter
     * (`mock_server_interceptor.dart`) and React Native
     * (`mockServerInterceptor.ts`) implementations, which both use
     * `continue` after a header check fails.
     */
    @Test
    fun `findMatch continues to next rule when header constraint fails`() {
        MockRuleStore.setRules(listOf(
            // rule A: header is required, request lacks it.
            rule(
                id = "a",
                enabled = true,
                method = "GET",
                url = ".*",
                matchHeaders = mapOf("X-Api-Key" to "secret-.*"),
            ),
            // rule B: no header constraint, should still match.
            rule(id = "b", enabled = true, method = "GET", url = ".*"),
        ))
        val match = MockRuleStore.findMatch(
            method = "GET",
            url = "https://x/y",
            headers = mapOf("X-Other" to "value"),
        )
        assertNotNull("expected rule 'b' to be matched after rule 'a' was skipped", match)
        assertEquals("b", match!!.id)
    }

    @Test
    fun `findMatch matches rule whose header constraint is satisfied`() {
        MockRuleStore.setRules(listOf(
            rule(
                id = "a",
                enabled = true,
                method = "GET",
                url = ".*",
                matchHeaders = mapOf("X-Api-Key" to "secret-.*"),
            ),
        ))
        val match = MockRuleStore.findMatch(
            method = "GET",
            url = "https://x/y",
            headers = mapOf("X-Api-Key" to "secret-abc"),
        )
        assertNotNull(match)
        assertEquals("a", match!!.id)
    }

    @Test
    fun `findMatch header lookup is case-insensitive on request side`() {
        MockRuleStore.setRules(listOf(
            rule(
                id = "a",
                enabled = true,
                method = "GET",
                url = ".*",
                matchHeaders = mapOf("X-Api-Key" to ".*"),
            ),
        ))
        // request uses lowercase key — should still match because the
        // matcher normalizes lookup to lowercase.
        val match = MockRuleStore.findMatch(
            method = "GET",
            url = "https://x/y",
            headers = mapOf("x-api-key" to "anything"),
        )
        assertNotNull(match)
    }

    // ---------- findMatch: invalid regex / caching ----------

    @Test
    fun `findMatch does not throw on invalid regex pattern`() {
        MockRuleStore.setRules(listOf(
            rule(id = "a", enabled = true, method = "GET", url = "(unclosed"),
        ))
        // Should return null (regex never matches) rather than throwing.
        val match = MockRuleStore.findMatch(method = "GET", url = "https://x/y", headers = null)
        assertNull(match)
    }

    @Test
    fun `findMatch reuses cached regex across calls`() {
        val r = rule(id = "cache-test", enabled = true, method = "GET", url = ".*")
        MockRuleStore.setRules(listOf(r))
        // Two consecutive lookups must both succeed — proves the
        // compiled regex is stored and reused.
        assertNotNull(MockRuleStore.findMatch("GET", "https://x/1", null))
        assertNotNull(MockRuleStore.findMatch("GET", "https://x/2", null))
    }

    @Test
    fun `setRules clears the regex cache`() {
        MockRuleStore.setRules(listOf(
            rule(id = "a", enabled = true, method = "GET", url = ".*"),
        ))
        // Warm the cache.
        assertNotNull(MockRuleStore.findMatch("GET", "https://x/y", null))
        // Replace the rule set entirely; old cache entries for rule id
        // "a" must be dropped so a stale compiled regex can't be reused
        // for a different rule.
        MockRuleStore.setRules(listOf(
            rule(id = "a", enabled = true, method = "GET", url = "^https://different-host/.*"),
        ))
        val match = MockRuleStore.findMatch("GET", "https://other/y", null)
        assertNull(match)
    }

    // ---------- loadFromJson ----------

    @Test
    fun `loadFromJson parses a valid rule list`() {
        val json = """
            [
              {
                "id": "r1",
                "enabled": true,
                "match": { "method": "GET", "url": "^https://api/users$" },
                "response": { "status": 201, "body": "{\"ok\":true}" }
              }
            ]
        """.trimIndent()
        MockRuleStore.loadFromJson(json)
        val match = MockRuleStore.findMatch("GET", "https://api/users", null)
        assertNotNull(match)
        assertEquals("r1", match!!.id)
        assertEquals(201, match.response.status)
        assertEquals("{\"ok\":true}", match.response.body)
    }

    @Test
    fun `loadFromJson falls back to empty rules on bad JSON`() {
        MockRuleStore.loadFromJson("not valid json {{")
        val match = MockRuleStore.findMatch("GET", "https://x", null)
        assertNull(match)
    }

    @Test
    fun `loadFromJson defaults method to GET when missing`() {
        val json = """[{"id":"r","match":{"url":".*"},"response":{}}]"""
        MockRuleStore.loadFromJson(json)
        val match = MockRuleStore.findMatch("GET", "https://x", null)
        assertNotNull(match)
        // POST should NOT match because method defaults to GET.
        assertNull(MockRuleStore.findMatch("POST", "https://x", null))
    }

    @Test
    fun `loadFromJson defaults url to regex matching anything`() {
        val json = """[{"id":"r","match":{"method":"GET"},"response":{}}]"""
        MockRuleStore.loadFromJson(json)
        assertNotNull(MockRuleStore.findMatch("GET", "https://anything/at/all", null))
    }

    @Test
    fun `loadFromJson defaults status to 200 when missing`() {
        val json = """[{"id":"r","match":{"method":"GET","url":".*"},"response":{}}]"""
        MockRuleStore.loadFromJson(json)
        val match = MockRuleStore.findMatch("GET", "https://x", null)!!
        assertEquals(200, match.response.status)
    }

    @Test
    fun `loadFromJson defaults body to empty string when missing`() {
        val json = """[{"id":"r","match":{"method":"GET","url":".*"},"response":{"status":204}}]"""
        MockRuleStore.loadFromJson(json)
        val match = MockRuleStore.findMatch("GET", "https://x", null)!!
        assertEquals("", match.response.body)
    }

    @Test
    fun `loadFromJson parses a positive delayMs`() {
        val json = """[{"id":"r","match":{"method":"GET","url":".*"},"response":{"status":200,"delayMs":250}}]"""
        MockRuleStore.loadFromJson(json)
        val match = MockRuleStore.findMatch("GET", "https://x", null)!!
        assertEquals(250, match.response.delayMs)
    }

    @Test
    fun `loadFromJson omits delayMs when field is -1`() {
        val json = """[{"id":"r","match":{"method":"GET","url":".*"},"response":{"status":200,"delayMs":-1}}]"""
        MockRuleStore.loadFromJson(json)
        val match = MockRuleStore.findMatch("GET", "https://x", null)!!
        assertNull(match.response.delayMs)
    }

    @Test
    fun `loadFromJson omits delayMs when field is missing`() {
        val json = """[{"id":"r","match":{"method":"GET","url":".*"},"response":{"status":200}}]"""
        MockRuleStore.loadFromJson(json)
        val match = MockRuleStore.findMatch("GET", "https://x", null)!!
        assertNull(match.response.delayMs)
    }

    @Test
    fun `loadFromJson parses header constraints on the match block`() {
        val json = """
            [{"id":"r","match":{
                "method":"GET",
                "url":".*",
                "headers":{"X-Api-Key":"secret-.*"}
            },"response":{}}]
        """.trimIndent()
        MockRuleStore.loadFromJson(json)
        // Matching header → match.
        assertNotNull(MockRuleStore.findMatch("GET", "https://x", mapOf("X-Api-Key" to "secret-abc")))
        // Non-matching header → no match.
        assertNull(MockRuleStore.findMatch("GET", "https://x", mapOf("X-Api-Key" to "wrong")))
    }

    @Test
    fun `loadFromJson parses response headers`() {
        val json = """
            [{"id":"r","match":{"method":"GET","url":".*"},
              "response":{"status":200,"body":"hi","headers":{"X-Trace":"abc"}}}]
        """.trimIndent()
        MockRuleStore.loadFromJson(json)
        val match = MockRuleStore.findMatch("GET", "https://x", null)!!
        assertEquals(mapOf("X-Trace" to "abc"), match.response.headers)
    }

    // ---------- helpers ----------

    private fun rule(
        id: String,
        enabled: Boolean = true,
        method: String = "GET",
        url: String = ".*",
        matchHeaders: Map<String, String>? = null,
    ): MockRule = MockRule(
        id = id,
        enabled = enabled,
        match = MockMatch(method = method, url = url, headers = matchHeaders),
        response = MockResponse(status = 200, body = ""),
    )
}
