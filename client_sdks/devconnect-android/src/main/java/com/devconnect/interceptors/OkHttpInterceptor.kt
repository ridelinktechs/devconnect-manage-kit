package com.devconnect.interceptors

import com.devconnect.DevConnect
import okhttp3.Response
import org.json.JSONObject
import java.util.UUID

/**
 * OkHttp Interceptor that auto-captures all HTTP requests for DevConnect.
 *
 * Works with:
 * - OkHttp direct usage
 * - Retrofit (uses OkHttp)
 * - Firebase (uses OkHttp on Android)
 * - OAuth2 token requests
 * - Glide/Coil image loading
 *
 * Usage:
 * ```kotlin
 * val client = OkHttpClient.Builder()
 *     .addInterceptor(DevConnect.okHttpInterceptor())
 *     .build()
 * ```
 *
 * For Retrofit:
 * ```kotlin
 * val retrofit = Retrofit.Builder()
 *     .client(client)
 *     .baseUrl("https://api.example.com/")
 *     .build()
 * ```
 */
class OkHttpInterceptor : okhttp3.Interceptor {
    override fun intercept(chain: okhttp3.Interceptor.Chain): Response {
        val requestId = UUID.randomUUID().toString()
        val request = chain.request()
        OkHttpCalls.remember(requestId, chain.call())
        val startTime = System.currentTimeMillis()

        // Extract request info
        val method = request.method.uppercase()
        val url = request.url.toString()

        // Request headers — redact Authorization / Cookie / Set-Cookie
        // before forwarding to the desktop UI. The previous implementation
        // forwarded these verbatim, leaking bearer tokens, session cookies,
        // and CSRF tokens into a network log visible to anyone with access
        // to the desktop inspector.
        val reqHeaders = mutableMapOf<String, String>()
        request.headers.forEach { (name, value) ->
            reqHeaders[name] = redactHeader(name, value)
        }

        // Request body
        var requestBody: Any? = null
        try {
            request.body?.let { body ->
                if (body is okhttp3.MultipartBody) {
                    val fields = mutableMapOf<String, Any?>()
                    val files = mutableListOf<Map<String, Any?>>()
                    body.parts.forEach { part ->
                        val contentDisposition = part.headers?.get("Content-Disposition") ?: ""
                        val nameMatch = Regex("""name="([^"]+)"""").find(contentDisposition)
                        val filenameMatch = Regex("""filename="([^"]+)"""").find(contentDisposition)
                        val name = nameMatch?.groupValues?.get(1) ?: "unknown"
                        if (filenameMatch != null) {
                            files.add(mapOf(
                                "key" to name,
                                "filename" to filenameMatch.groupValues[1],
                                "contentType" to part.body.contentType()?.toString(),
                                "length" to part.body.contentLength()
                            ))
                        } else {
                            // Field name may carry a credential — redact value.
                            fields[name] = bodySummary(part.body) ?: run {
                                val buffer = okio.Buffer()
                                part.body.writeTo(buffer)
                                redactValue(name, buffer.readUtf8())
                            }
                        }
                    }
                    val result = mutableMapOf<String, Any?>()
                    result.putAll(fields)
                    if (files.isNotEmpty()) {
                        result["_files"] = files
                        result["_contentType"] = "multipart/form-data"
                    }
                    requestBody = result
                } else {
                    requestBody = bodySummary(body) ?: run {
                        val buffer = okio.Buffer()
                        body.writeTo(buffer)
                        parseText(buffer.readUtf8())
                    }
                }
            }
        } catch (_: Exception) {}

        // Detect special request types and tag
        val tag = when {
            url.contains("firebaseio.com") -> "Firebase"
            url.contains("googleapis.com/identitytoolkit") -> "Firebase Auth"
            url.contains("googleapis.com/oauth2") -> "OAuth2"
            url.contains("googleapis.com/token") -> "OAuth2"
            url.contains("/oauth") || url.contains("/token") -> "OAuth2"
            url.contains("fcm.googleapis.com") -> "FCM"
            else -> null
        }

        // Report start
        DevConnect.reportNetworkStart(
            requestId = requestId,
            method = method,
            url = url,
            headers = reqHeaders,
            body = requestBody
        )

        // Log special requests
        tag?.let { DevConnect.log("$it request: $method $url", it) }

        // Execute the request
        return try {
            // Desktop-set throttling; failing here reports like a real failure.
            DevConnect.applyNetworkConditions()
            val response = chain.proceed(request)

            // Response headers — same redaction pass.
            val resHeaders = mutableMapOf<String, String>()
            response.headers.forEach { (name, value) ->
                resHeaders[name] = redactHeader(name, value)
            }

            val responseBody: Any? = try {
                captureResponseBody(response)
            } catch (_: Exception) {
                null
            }

            // Report complete
            DevConnect.reportNetworkComplete(
                requestId = requestId,
                method = method,
                url = url,
                statusCode = response.code,
                startTime = startTime,
                requestHeaders = reqHeaders,
                responseHeaders = resHeaders,
                requestBody = requestBody,
                responseBody = responseBody
            )

            response
        } catch (e: Exception) {
            DevConnect.reportNetworkComplete(
                requestId = requestId,
                method = method,
                url = url,
                statusCode = 0,
                startTime = startTime,
                requestHeaders = reqHeaders,
                requestBody = requestBody,
                error = e.message ?: e.toString()
            )
            throw e
        }
    }

    private companion object {
        // Request bodies that aren't text are summarised past 1 MB, so a
        // big upload isn't buffered; text is captured whole.
        const val MAX_CAPTURED_BODY_BYTES = 1_048_576

        /** Images up to this many bytes are sent for the desktop to show; bigger ones by their size. */
        const val MAX_IMAGE_BYTES = 10 * 1_048_576

        /** Text longer than this is sent unparsed: the desktop parses it, off its UI thread. */
        const val MAX_PARSE_CHARS = 1_048_576

        // Header names that carry credentials. Compared case-insensitively.
        val SENSITIVE_HEADERS = setOf(
            "authorization",
            "proxy-authorization",
            "cookie",
            "set-cookie",
            "x-api-key",
            "x-auth-token",
            "x-csrf-token",
            "x-xsrf-token",
        )

        // Substrings used to detect sensitive query / form-field names.
        val SENSITIVE_KEY_HINTS = listOf(
            "token", "password", "secret", "apikey", "api_key",
            "authorization", "cookie", "credential",
        )

        fun redactHeader(name: String, value: String): String {
            return if (name.lowercase() in SENSITIVE_HEADERS) "[REDACTED]" else value
        }

        fun redactValue(key: String, value: String): String {
            val lower = key.lowercase()
            return if (SENSITIVE_KEY_HINTS.any { lower.contains(it) }) "[REDACTED]" else value
        }

        // Content types decoded as text for the report; others are summarised.
        val TEXT_TYPE_HINTS = listOf(
            "text/", "json", "xml", "javascript", "x-www-form-urlencoded", "graphql",
        )

        /**
         * What to report instead of reading [body], or null when it's safe to
         * read: one-shot / duplex bodies would be consumed before the real
         * send, and unknown-length or large ones (file uploads) buffered whole.
         */
        fun bodySummary(body: okhttp3.RequestBody): String? {
            val length = body.contentLength()
            val type = body.contentType()?.toString()?.lowercase() ?: ""
            return when {
                body.isOneShot() || body.isDuplex() || length < 0 -> sized("stream", length)
                length > MAX_CAPTURED_BODY_BYTES && TEXT_TYPE_HINTS.none { type.contains(it) } ->
                    sized("large", length)
                else -> null
            }
        }

        /** Text bodies whole, images as a `data:` URL; other binary bodies and streams as a summary. */
        fun captureResponseBody(response: Response): Any {
            val body = response.body
            val type = body.contentType()?.toString()?.lowercase() ?: ""
            val length = body.contentLength()
            return when {
                length == 0L -> ""
                type.startsWith("image/") && !type.contains("svg") && length <= MAX_IMAGE_BYTES -> {
                    val bytes = response.peekBody(MAX_IMAGE_BYTES + 1L).byteString()
                    if (bytes.size > MAX_IMAGE_BYTES) {
                        sized("binary", length)
                    } else {
                        "data:${type.substringBefore(';').trim()};base64,${bytes.base64()}"
                    }
                }
                type.isNotEmpty() && TEXT_TYPE_HINTS.none { type.contains(it) } -> sized("binary", length)
                // SSE / NDJSON stay open: peeking them would block the call.
                type.contains("stream") || type.contains("ndjson") -> "<stream>"
                else -> parseText(response.peekBody(Long.MAX_VALUE).string())
            }
        }

        /** [text] as a JSONObject when it is one, unless it's longer than [MAX_PARSE_CHARS]. */
        fun parseText(text: String): Any = if (text.length > MAX_PARSE_CHARS) {
            text
        } else {
            try {
                JSONObject(text)
            } catch (_: Exception) {
                text
            }
        }

        /** "<kind, N bytes>", or "<kind>" when the length is unknown. */
        fun sized(kind: String, length: Long) = if (length < 0) "<$kind>" else "<$kind, $length bytes>"
    }
}

/** Recent OkHttp calls by request id, so the desktop can replay one. */
internal object OkHttpCalls {
    private val recent = object : LinkedHashMap<String, okhttp3.Call>(64, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, okhttp3.Call>?) =
            size > 200
    }

    @Synchronized
    fun remember(requestId: String, call: okhttp3.Call) {
        recent[requestId] = call
    }

    /**
     * Sends call [requestId] again as an OkHttp clone: the app's own client
     * and interceptors run it (real auth headers, which the capture
     * redacts) and DevConnect records it. False when it's not remembered.
     */
    fun replay(requestId: String): Boolean {
        val call = synchronized(this) { recent[requestId] } ?: return false
        call.clone().enqueue(object : okhttp3.Callback {
            override fun onFailure(call: okhttp3.Call, e: java.io.IOException) {}

            override fun onResponse(call: okhttp3.Call, response: okhttp3.Response) {
                response.close()
            }
        })
        return true
    }
}
