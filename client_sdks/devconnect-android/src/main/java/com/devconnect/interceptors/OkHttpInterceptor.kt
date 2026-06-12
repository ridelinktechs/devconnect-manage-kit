package com.devconnect.interceptors

import com.devconnect.DevConnect
import okhttp3.Interceptor
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
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
class OkHttpInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val requestId = UUID.randomUUID().toString()
        val request = chain.request()
        val startTime = System.currentTimeMillis()

        // Extract request info
        val method = request.method.uppercase()
        val url = request.url.toString()

        // Request headers
        val reqHeaders = mutableMapOf<String, String>()
        request.headers.forEach { (name, value) ->
            reqHeaders[name] = value
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
                            fields[name] = buffer.readUtf8()
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
                    requestBody = try { JSONObject(bodyStr) } catch (_: Exception) { bodyStr }
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

            // Response headers
            val resHeaders = mutableMapOf<String, String>()
            response.headers.forEach { (name, value) ->
                resHeaders[name] = value
            }

            // Response body - read and re-create to not consume the stream
            var responseBody: Any? = null
            val responseBodyStr = response.body?.string()
            responseBodyStr?.let { str ->
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
}
