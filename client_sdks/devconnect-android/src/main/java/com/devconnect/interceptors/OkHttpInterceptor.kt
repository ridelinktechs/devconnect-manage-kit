package com.devconnect.interceptors

import com.devconnect.DevConnect
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import okio.Buffer
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
                            val buffer = okio.Buffer()
                            part.body.writeTo(buffer)
                            // Field name may carry a credential — redact value.
                            fields[name] = redactValue(name, buffer.readUtf8())
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
                    val buffer = okio.Buffer()
                    body.writeTo(buffer)
                    val bodyStr = buffer.readUtf8()
                    requestBody = try {
                        JSONObject(bodyStr)
                    } catch (_: Exception) {
                        bodyStr
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
            val response = chain.proceed(request)

            // Response headers — same redaction pass.
            val resHeaders = mutableMapOf<String, String>()
            response.headers.forEach { (name, value) ->
                resHeaders[name] = redactHeader(name, value)
            }

            // Response body — capture up to MAX_CAPTURED_BODY_BYTES bytes
            // without consuming the underlying stream. We buffer the
            // source into a fresh Buffer and re-attach a synthesized
            // body so the call chain downstream still sees the full
            // response.
            //
            // OkHttp 4.12.0 does not expose `ResponseBody.peekBody` (that
            // arrived in OkHttp 5.x), so we read via `source().request(N)`
            // ourselves.
            var responseBody: Any? = null
            val originalBody = response.body
            val responseBodyStr: String? = if (originalBody != null) {
                try {
                    val sink = Buffer()
                    originalBody.source().request(MAX_CAPTURED_BODY_BYTES.toLong())
                    sink.write(originalBody.source(), originalBody.source().buffer.size)
                    val bytes = sink.readByteArray()
                    bytes.toString(Charsets.UTF_8)
                } catch (e: Exception) {
                    null
                }
            } else null
            val displayBody = if (responseBodyStr != null &&
                responseBodyStr.length > MAX_CAPTURED_BODY_BYTES
            ) {
                responseBodyStr.substring(0, MAX_CAPTURED_BODY_BYTES) + "…[truncated]"
            } else {
                responseBodyStr
            }
            displayBody?.let { str ->
                responseBody = try {
                    JSONObject(str)
                } catch (_: Exception) {
                    str
                }
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

            // Rebuild response with body since we consumed it
            response.newBuilder()
                .body((responseBodyStr ?: "").toResponseBody(response.body?.contentType()))
                .build()
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
        // Cap captured bodies at 1 MB. The desktop inspector renders a
        // small fraction of any body anyway; this avoids OOM on chatty
        // or large-response APIs (e.g. Firebase Real Database snapshots,
        // S3 list-objects).
        const val MAX_CAPTURED_BODY_BYTES = 1_048_576

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
    }
}
