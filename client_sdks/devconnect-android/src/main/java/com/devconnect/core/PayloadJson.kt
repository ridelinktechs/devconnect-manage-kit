package com.devconnect.core

import org.json.JSONObject

/** Keys whose values must be redacted before they leave the device.
 *  Matches `Authorization`, `Cookie`, `password`, `token`, `secret`,
 *  etc. by substring (case-insensitive) — same heuristic the desktop
 *  side uses. */
private val sensitiveKeyPatterns = listOf(
    "token", "password", "secret", "apikey", "api_key",
    "authorization", "cookie", "set-cookie", "credential"
)

internal fun redactSensitiveValue(key: String, value: Any?): Any? {
    if (value == null) return null
    val lower = key.lowercase()
    if (sensitiveKeyPatterns.any { lower.contains(it) }) {
        return "[REDACTED]"
    }
    return value
}

internal fun buildPayload(block: JSONObject.() -> Unit): JSONObject {
    return JSONObject().apply(block)
}

/**
 * [v] as a value [JSONObject.put] writes as JSON. Android's org.json
 * stores a Kotlin Map/List as-is and writes it with toString()
 * ("{k=v}"); `wrap` converts it, nested values included. The org.json
 * jar the JVM unit tests run on converts either way, so they can't see this.
 */
internal fun jsonValue(v: Any?): Any = JSONObject.wrap(v) ?: v.toString()

/**
 * Recursively convert a `Map<String, Any?>` (and any nested
 * `List<*>` / `Map<*, *>` values) to a [JSONObject] so the JSON
 * encoder carries structured header values through to the desktop
 * inspector — instead of coercing everything via `toString()` and
 * producing literal `"[object Object]"` once it round-trips back
 * through WS.
 *
 * Non-collection values are passed through to [JSONObject.put]
 * which already accepts the JSON-encodable primitives.
 */
internal fun headersToJson(headers: Map<String, Any?>): JSONObject {
    val obj = JSONObject()
    for ((k, v) in headers) {
        obj.put(k, encodeHeaderValue(v))
    }
    return obj
}

private fun encodeHeaderValue(v: Any?): Any = when (v) {
    null -> JSONObject.NULL
    is List<*> -> org.json.JSONArray().also { arr ->
        for (item in v) arr.put(encodeHeaderValue(item))
    }
    is Map<*, *> -> {
        val nested = JSONObject()
        for ((nk, nv) in v) nested.put(nk.toString(), encodeHeaderValue(nv))
        nested
    }
    is Number, is Boolean, is String -> v
    else -> v.toString()
}

internal fun jsonObjectToMap(json: JSONObject): Map<String, Any> {
    val map = mutableMapOf<String, Any>()
    for (key in json.keys()) {
        jsonToKotlin(json.opt(key))?.let { map[key] = it }
    }
    return map
}

/**
 * An org.json value as plain Kotlin: maps, lists, and `null` for
 * [JSONObject.NULL] at any depth. [jsonObjectToMap] leaves a null member
 * out, since its map can't hold one; reading that key still gives null.
 */
internal fun jsonToKotlin(value: Any?): Any? = when (value) {
    null, JSONObject.NULL -> null
    is JSONObject -> jsonObjectToMap(value)
    is org.json.JSONArray -> List(value.length()) { jsonToKotlin(value.opt(it)) }
    else -> value
}
