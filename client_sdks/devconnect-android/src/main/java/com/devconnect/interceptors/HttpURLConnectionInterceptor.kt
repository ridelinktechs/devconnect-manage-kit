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
                val bytes = ByteArrayOutputStream()
                stream.copyTo(bytes)
                val data = bytes.toByteArray()

                // Report response
                reportComplete(data, null)

                ByteArrayInputStream(data)
            } catch (e: Exception) {
                reportComplete(null, e.message)
                throw e
            }
        }

        override fun getErrorStream(): InputStream? {
            return try {
                val stream = inner.errorStream ?: return null
                val bytes = ByteArrayOutputStream()
                stream.copyTo(bytes)
                val data = bytes.toByteArray()
                reportComplete(data, null)
                ByteArrayInputStream(data)
            } catch (e: Exception) {
                reportComplete(null, e.message)
                inner.errorStream
            }
        }

        private fun reportComplete(responseBytes: ByteArray?, error: String?) {
            val resHeaders = mutableMapOf<String, String>()
            inner.headerFields?.forEach { (k, v) ->
                if (k != null) resHeaders[k] = v.joinToString(", ")
            }

            var responseBody: Any? = null
            responseBytes?.let {
                val str = String(it)
                responseBody = try { JSONObject(str) } catch (_: Exception) { str }
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
