package com.devconnect.interceptors

import com.devconnect.DevConnect
import java.util.UUID

/**
 * Manual Ktor HTTP reporting helper for DevConnect.
 *
 * Ktor is not on the SDK's compile classpath, so we do NOT attempt to
 * install an automatic interceptor via reflection — the previous
 * implementation called `config.install(...)` through `getMethod("install")`
 * on `HttpClientConfig`, which found nothing matching the signature and
 * silently logged "DevConnect Ktor plugin installed" without actually
 * wiring anything up.
 *
 * Instead, callers report requests manually using [reportRequest] /
 * [onRequestStart] / [onRequestComplete]:
 *
 * ```kotlin
 * val requestId = DevConnectKtorPlugin.onRequestStart(
 *     method = "GET",
 *     url = "https://api.example.com/users",
 *     headers = mapOf("Authorization" to "Bearer …") // redacted below
 * )
 * try {
 *     val response = client.get("https://api.example.com/users")
 *     DevConnectKtorPlugin.onRequestComplete(
 *         requestId = requestId,
 *         method = "GET",
 *         url = "https://api.example.com/users",
 *         statusCode = response.status.value,
 *         startTime = startTime,
 *         responseBody = response.bodyAsText()
 *     )
 * } catch (e: Exception) {
 *     DevConnectKtorPlugin.onRequestComplete(
 *         requestId = requestId,
 *         method = "GET",
 *         url = "https://api.example.com/users",
 *         statusCode = 0,
 *         startTime = startTime,
 *         error = e.message
 *     )
 * }
 * ```
 *
 * Sensitive header names (Authorization, Cookie, Set-Cookie, …) are
 * redacted before they reach the desktop UI.
 */
object DevConnectKtorPlugin {

    private const val TAG = "KtorInterceptor"

    /**
     * Report a Ktor request/response pair.
     */
    fun reportRequest(
        method: String,
        url: String,
        statusCode: Int,
        requestHeaders: Map<String, String>? = null,
        responseHeaders: Map<String, String>? = null,
        requestBody: Any? = null,
        responseBody: Any? = null,
        startTime: Long = System.currentTimeMillis(),
        error: String? = null
    ) {
        val requestId = UUID.randomUUID().toString()

        DevConnect.reportNetworkStart(
            requestId = requestId,
            method = method.uppercase(),
            url = url,
            headers = requestHeaders?.let(::redactHeaders),
            body = requestBody
        )

        DevConnect.reportNetworkComplete(
            requestId = requestId,
            method = method.uppercase(),
            url = url,
            statusCode = statusCode,
            startTime = startTime,
            requestHeaders = requestHeaders?.let(::redactHeaders),
            responseHeaders = responseHeaders?.let(::redactHeaders),
            requestBody = requestBody,
            responseBody = responseBody,
            error = error
        )
    }

    /**
     * Open a manual start of a request — returns the `requestId` so the
     * caller can pair it with [onRequestComplete].
     */
    fun onRequestStart(
        method: String,
        url: String,
        headers: Map<String, String>? = null,
        body: Any? = null
    ): String {
        val requestId = UUID.randomUUID().toString()
        DevConnect.reportNetworkStart(
            requestId = requestId,
            method = method.uppercase(),
            url = url,
            headers = headers?.let(::redactHeaders),
            body = body
        )
        return requestId
    }

    fun onRequestComplete(
        requestId: String,
        method: String,
        url: String,
        statusCode: Int,
        startTime: Long,
        requestHeaders: Map<String, String>? = null,
        responseHeaders: Map<String, String>? = null,
        requestBody: Any? = null,
        responseBody: Any? = null,
        error: String? = null
    ) {
        DevConnect.reportNetworkComplete(
            requestId = requestId,
            method = method.uppercase(),
            url = url,
            statusCode = statusCode,
            startTime = startTime,
            requestHeaders = requestHeaders?.let(::redactHeaders),
            responseHeaders = responseHeaders?.let(::redactHeaders),
            requestBody = requestBody,
            responseBody = responseBody,
            error = error
        )
    }

    // ── internal ──────────────────────────────────────────────────────

    private val SENSITIVE_HEADERS = setOf(
        "authorization",
        "proxy-authorization",
        "cookie",
        "set-cookie",
        "x-api-key",
        "x-auth-token",
        "x-csrf-token",
        "x-xsrf-token",
    )

    private fun redactHeaders(headers: Map<String, String>): Map<String, String> {
        if (headers.isEmpty()) return headers
        val out = LinkedHashMap<String, String>(headers.size)
        for ((name, value) in headers) {
            out[name] = if (name.lowercase() in SENSITIVE_HEADERS) "[REDACTED]" else value
        }
        return out
    }
}
