package com.devconnect.interceptors

import com.devconnect.DevConnect
import okhttp3.Interceptor
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.Protocol
import okhttp3.Request
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import org.json.JSONObject
import java.util.concurrent.ConcurrentHashMap

/**
 * OkHttp interceptor that short-circuits HTTP requests matching mock
 * server rules pushed from the desktop.
 *
 * Spec (Round 4 / 4.2): "In the existing HTTP interceptor
 * ([OkHttpInterceptor]): before forwarding the request to the real
 * network, check the rule list. If matched, short-circuit with the mock
 * response (delay → emit response with synthetic latency). Emit
 * `client:mocked_request` so the user knows the response was synthetic."
 *
 * Wire it into your OkHttp client:
 * ```kotlin
 * val client = OkHttpClient.Builder()
 *     .addInterceptor(MockServerInterceptor())
 *     .build()
 * ```
 */
class MockServerInterceptor : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val rule = MockRuleStore.findMatch(
            method = request.method,
            url = request.url.toString(),
            headers = request.headers.toMap(),
        ) ?: return chain.proceed(request)

        return MockRuleStore.buildMockResponse(rule, request)
    }
}

/** Mock rule pushed from the desktop. */
data class MockRule(
    val id: String,
    val enabled: Boolean,
    val match: MockMatch,
    val response: MockResponse,
)

data class MockMatch(
    val method: String,
    val url: String, // regex
    val headers: Map<String, String>? = null,
)

data class MockResponse(
    val status: Int,
    val body: String,
    val headers: Map<String, String>? = null,
    val delayMs: Int? = null,
)

/** Thread-safe in-memory rule store. */
object MockRuleStore {

    @Volatile private var rules: List<MockRule> = emptyList()
    private val regexCache = ConcurrentHashMap<String, Regex>()

    fun setRules(newRules: List<MockRule>) {
        // Clear BEFORE updating `rules`. Otherwise a concurrent findMatch
        // can read the NEW `rule.id` and populate the cache with the OLD
        // `rule.match.url` regex — the cache would then keep matching
        // requests against a stale pattern until the next setRules call.
        // ponytail: cache keyed by rule.id; if a single rule's URL is
        // mutated in place (not supported today), the cache would still
        // serve the stale compiled regex. Migrate to URL-keyed cache if
        // hot-reloading individual rules becomes a requirement.
        regexCache.clear()
        rules = newRules.filter { it.enabled }
    }

    /**
     * Parse rules from a JSON list (e.g. from `server:mock_rules_update`).
     */
    fun loadFromJson(json: String) {
        try {
            val arr = org.json.JSONArray(json)
            val list = mutableListOf<MockRule>()
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                val matchObj = o.optJSONObject("match") ?: JSONObject()
                val respObj = o.optJSONObject("response") ?: JSONObject()
                val matchHeaders = matchObj.optJSONObject("headers")?.let { ho ->
                    val map = mutableMapOf<String, String>()
                    ho.keys().forEach { k -> map[k] = ho.getString(k) }
                    map
                }
                val respHeaders = respObj.optJSONObject("headers")?.let { ho ->
                    val map = mutableMapOf<String, String>()
                    ho.keys().forEach { k -> map[k] = ho.getString(k) }
                    map
                }
                list += MockRule(
                    id = o.getString("id"),
                    enabled = o.optBoolean("enabled", true),
                    match = MockMatch(
                        method = matchObj.optString("method", "GET").uppercase(),
                        url = matchObj.optString("url", ".*"),
                        headers = matchHeaders,
                    ),
                    response = MockResponse(
                        status = respObj.optInt("status", 200),
                        body = respObj.optString("body", ""),
                        headers = respHeaders,
                        delayMs = respObj.optInt("delayMs", -1).takeIf { it >= 0 },
                    ),
                )
            }
            setRules(list)
        } catch (_: Throwable) {
            // Bad payload — clear rules so the app falls back to real network.
            setRules(emptyList())
        }
    }

    fun findMatch(method: String, url: String, headers: Map<String, String>?): MockRule? {
        for (rule in rules) {
            if (!rule.enabled) continue
            if (rule.match.method.uppercase() != method.uppercase()) continue
            val regex = regexCache.getOrPut(rule.id) {
                try { Regex(rule.match.url) } catch (_: Throwable) { Regex("(?!)") }
                // ponytail: invalid regex → never-matches; cached per rule.id
                // so we don't re-parse the bad pattern on every request.
            }
            if (!regex.containsMatchIn(url)) continue
            rule.match.headers?.let { required ->
                val req = headers ?: emptyMap()
                var headerOk = true
                for ((k, v) in required) {
                    val actual = req[k.lowercase()] ?: req[k] ?: ""
                    if (!Regex(v).containsMatchIn(actual)) {
                        headerOk = false
                        break
                    }
                }
                if (!headerOk) continue
            }
            return rule
        }
        return null
    }

    /**
     * Build a synthetic OkHttp [Response] from a rule. Apply [delayMs]
     * before returning so the consumer sees realistic latency.
     *
     * ponytail: `Thread.sleep` blocks the OkHttp dispatcher thread for the
     * full delay. For typical mock latencies (<500 ms) this is acceptable
     * — the OkHttp dispatcher pool has 64 threads by default and a brief
     * stall won't trip the user's ANR watchdog. If delays grow past a few
     * seconds, switch to a deferred-response wrapper that returns a 202
     * Accepted here and posts the real response on a Handler after the
     * delay.
     */
    fun buildMockResponse(rule: MockRule, request: Request): Response {
        rule.response.delayMs?.let { if (it > 0) Thread.sleep(it.toLong()) }
        try {
            DevConnect.safeSend("client:mocked_request", mapOf(
                "ruleId" to rule.id,
                "status" to rule.response.status,
                "url" to request.url.toString(),
                "method" to request.method,
                "timestamp" to System.currentTimeMillis(),
            ))
        } catch (_: Throwable) {}

        val mediaType = (rule.response.headers?.get("Content-Type")
            ?: rule.response.headers?.get("content-type")
            ?: "application/json").toMediaTypeOrNull()
        val body = rule.response.body.toResponseBody(mediaType)
        val builder = Response.Builder()
            .request(request)
            .protocol(Protocol.HTTP_1_1)
            .code(rule.response.status)
            .message(if (rule.response.status in 200..299) "OK" else "Mocked")
            .body(body)
        for ((k, v) in rule.response.headers.orEmpty()) {
            builder.header(k, v)
        }
        return builder.build()
    }
}

/**
 * Helper for consumers who want to push mock rules from their own code
 * (e.g. when manually wiring a `MockServerInterceptor` outside `DevConnect.install()`).
 */
fun installMockRules(rules: List<MockRule>) = MockRuleStore.setRules(rules)

fun installMockRulesFromJson(json: String) = MockRuleStore.loadFromJson(json)