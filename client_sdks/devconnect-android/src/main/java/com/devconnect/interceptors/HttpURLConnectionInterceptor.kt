package com.devconnect.interceptors

import com.devconnect.DevConnect
import org.json.JSONObject
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.UUID

/**
 * Wrapper for HttpURLConnection that auto-reports to DevConnect.
 *
 * For apps that use HttpURLConnection directly (or Volley, which uses it internally).
 *
 * Usage:
 * ```kotlin
 * // Instead of:
 * val conn = URL("https://api.example.com/data").openConnection() as HttpURLConnection
 *
 * // Use:
 * val conn = DevConnectHttpURLConnection.open("https://api.example.com/data")
 * ```
 *
 * For Volley:
 * ```kotlin
 * // Create a custom HurlStack that wraps connections
 * val stack = object : HurlStack() {
 *     override fun createConnection(url: URL): HttpURLConnection {
 *         return DevConnectHttpURLConnection.wrap(super.createConnection(url))
 *     }
 * }
 * val queue = Volley.newRequestQueue(context, stack)
 * ```
 */
object DevConnectHttpURLConnection {

    // Cap captured bodies at 1 MB so a chatty / large-response endpoint
    // (Firebase Real DB snapshot, S3 list-objects, …) cannot OOM the SDK.
    private const val MAX_CAPTURED_BODY_BYTES = 1_048_576

    fun open(url: String): HttpURLConnection {
        val conn = URL(url).openConnection() as HttpURLConnection
        return wrap(conn)
    }

    fun wrap(conn: HttpURLConnection): HttpURLConnection {
        return TrackedConnection(conn)
    }

    private class TrackedConnection(
        private val inner: HttpURLConnection
    ) : HttpURLConnection(inner.url) {

        private val requestId = UUID.randomUUID().toString()
        private val startTime = System.currentTimeMillis()
        private var reportedStart = false

        private fun ensureStartReported() {
            if (reportedStart) return
            reportedStart = true

            val headers = mutableMapOf<String, String>()
            inner.requestProperties.forEach { (k, v) ->
                headers[k] = v.joinToString(", ")
            }

            DevConnect.reportNetworkStart(
                requestId = requestId,
                method = inner.requestMethod ?: "GET",
                url = inner.url.toString(),
                headers = headers
            )
        }

        override fun connect() {
            ensureStartReported()
            inner.connect()
        }

        override fun getInputStream(): InputStream {
            ensureStartReported()

            return try {
                val stream = inner.inputStream
                // Cap capture at 1 MB so a chatty / large-response endpoint
                // (Firebase Real DB snapshot, S3 list-objects, …) cannot
                // OOM the SDK. The consumer still gets the full stream —
                // we only stop copying into our local buffer.
                val bytes = ByteArrayOutputStream()
                val buf = ByteArray(8 * 1024)
                var copied = 0L
                var truncated = false
                while (true) {
                    val n = stream.read(buf)
                    if (n == -1) break
                    if (copied + n > MAX_CAPTURED_BODY_BYTES) {
                        val remaining = (MAX_CAPTURED_BODY_BYTES - copied).toInt()
                        if (remaining > 0) bytes.write(buf, 0, remaining)
                        copied = MAX_CAPTURED_BODY_BYTES.toLong()
                        truncated = true
                        break
                    }
                    bytes.write(buf, 0, n)
                    copied += n
                }
                val data = bytes.toByteArray()

                // Report response
                reportComplete(data, truncated = truncated)

                ByteArrayInputStream(data)
            } catch (e: Exception) {
                reportComplete(null, error = e.message, truncated = false)
                throw e
            }
        }

        override fun getErrorStream(): InputStream? {
            return try {
                val stream = inner.errorStream ?: return null
                val bytes = ByteArrayOutputStream()
                val buf = ByteArray(8 * 1024)
                var copied = 0L
                var truncated = false
                while (true) {
                    val n = stream.read(buf)
                    if (n == -1) break
                    if (copied + n > MAX_CAPTURED_BODY_BYTES) {
                        val remaining = (MAX_CAPTURED_BODY_BYTES - copied).toInt()
                        if (remaining > 0) bytes.write(buf, 0, remaining)
                        copied = MAX_CAPTURED_BODY_BYTES.toLong()
                        truncated = true
                        break
                    }
                    bytes.write(buf, 0, n)
                    copied += n
                }
                val data = bytes.toByteArray()
                reportComplete(data, truncated = truncated)
                ByteArrayInputStream(data)
            } catch (e: Exception) {
                reportComplete(null, error = e.message, truncated = false)
                inner.errorStream
            }
        }

        private fun reportComplete(
            responseBytes: ByteArray?,
            error: String? = null,
            truncated: Boolean = false
        ) {
            val resHeaders = mutableMapOf<String, String>()
            inner.headerFields?.forEach { (k, v) ->
                if (k != null) resHeaders[k] = v.joinToString(", ")
            }

            var responseBody: Any? = null
            responseBytes?.let {
                if (truncated) {
                    // Annotate truncation so the desktop UI can show a
                    // "body was truncated at 1 MB" banner instead of
                    // appearing to be a complete response.
                    responseBody = try {
                        JSONObject(String(it)).put("_truncated", true)
                    } catch (_: Exception) {
                        String(it) + "…[truncated at 1 MB]"
                    }
                } else {
                    val str = String(it)
                    responseBody = try { JSONObject(str) } catch (_: Exception) { str }
                }
            }

            DevConnect.reportNetworkComplete(
                requestId = requestId,
                method = inner.requestMethod ?: "GET",
                url = inner.url.toString(),
                statusCode = try { inner.responseCode } catch (_: Exception) { 0 },
                startTime = startTime,
                responseHeaders = resHeaders,
                responseBody = responseBody,
                error = error
            )
        }

        // Delegate all other methods
        override fun disconnect() = inner.disconnect()
        override fun usingProxy(): Boolean = inner.usingProxy()
        override fun getResponseCode(): Int = inner.responseCode
        override fun getResponseMessage(): String? = inner.responseMessage
        override fun setRequestMethod(method: String?) { inner.requestMethod = method }
        override fun getRequestMethod(): String = inner.requestMethod
        override fun setRequestProperty(key: String?, value: String?) = inner.setRequestProperty(key, value)
        override fun addRequestProperty(key: String?, value: String?) = inner.addRequestProperty(key, value)
        override fun getRequestProperty(key: String?): String? = inner.getRequestProperty(key)
        override fun getRequestProperties(): MutableMap<String, MutableList<String>> = inner.requestProperties
        override fun getHeaderField(name: String?): String? = inner.getHeaderField(name)
        override fun getHeaderFields(): MutableMap<String, MutableList<String>> = inner.headerFields
        override fun getOutputStream() = inner.outputStream
        override fun setDoOutput(doOutput: Boolean) { inner.doOutput = doOutput }
        override fun getDoOutput(): Boolean = inner.doOutput
        override fun setDoInput(doInput: Boolean) { inner.doInput = doInput }
        override fun getDoInput(): Boolean = inner.doInput
        override fun setConnectTimeout(timeout: Int) { inner.connectTimeout = timeout }
        override fun getConnectTimeout(): Int = inner.connectTimeout
        override fun setReadTimeout(timeout: Int) { inner.readTimeout = timeout }
        override fun getReadTimeout(): Int = inner.readTimeout
        override fun getContentType(): String? = inner.contentType
        override fun getContentLength(): Int = inner.contentLength
        override fun setUseCaches(usecaches: Boolean) { inner.useCaches = usecaches }
        override fun getUseCaches(): Boolean = inner.useCaches
        override fun setInstanceFollowRedirects(followRedirects: Boolean) {
            inner.instanceFollowRedirects = followRedirects
        }
        override fun getInstanceFollowRedirects(): Boolean = inner.instanceFollowRedirects
    }
}
