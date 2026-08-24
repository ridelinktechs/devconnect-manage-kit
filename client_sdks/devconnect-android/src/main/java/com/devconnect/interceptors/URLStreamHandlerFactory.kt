package com.devconnect.interceptors

import com.devconnect.DevConnect
import org.json.JSONObject
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLConnection
import java.net.URLStreamHandler
import java.net.URLStreamHandlerFactory
import java.util.UUID

/**
 * Global URLStreamHandlerFactory that auto-intercepts ALL HttpURLConnection requests.
 *
 * Captures: HttpURLConnection, Volley, and any library using java.net URL connections.
 * Does NOT capture OkHttp (it uses its own socket layer).
 *
 * Installed automatically when autoInterceptHttp=true in DevConnect.init().
 */
object DevConnectURLStreamHandlerFactory {

    // Cap captured bodies at 1 MB. See HttpURLConnectionInterceptor for
    // the rationale.
    private const val MAX_CAPTURED_BODY_BYTES = 1_048_576

    private var installed = false

    fun install() {
        if (installed) return
        try {
            URL.setURLStreamHandlerFactory(Factory)
            installed = true
        } catch (e: Exception) {
            // The JVM factory can only be set once per process. If the app
            // or another library already installed one, our interceptor
            // never runs — without a log the developer has no way to
            // know why network capture is silent.
            DevConnect.sendLog(
                "warn",
                "DevConnect URLStreamHandlerFactory not installed: ${e.message}. " +
                    "Another library probably called URL.setURLStreamHandlerFactory() first; " +
                    "use the OkHttp interceptor instead.",
                TAG
            )
        }
    }

    private const val TAG = "URLStreamHandlerFactory"

    private object Factory : URLStreamHandlerFactory {
        override fun createURLStreamHandler(protocol: String): URLStreamHandler? {
            if (protocol != "http" && protocol != "https") return null
            return object : URLStreamHandler() {
                override fun openConnection(url: URL): URLConnection {
                    val conn = url.openConnection()
                    return if (conn is HttpURLConnection) {
                        TrackedHttpConnection(conn)
                    } else {
                        conn
                    }
                }

                override fun openConnection(url: URL, proxy: java.net.Proxy?): URLConnection {
                    val conn = if (proxy != null) url.openConnection(proxy) else url.openConnection()
                    return if (conn is HttpURLConnection) {
                        TrackedHttpConnection(conn)
                    } else {
                        conn
                    }
                }
            }
        }
    }

    private class TrackedHttpConnection(
        private val inner: HttpURLConnection
    ) : HttpURLConnection(inner.url) {

        private val requestId = UUID.randomUUID().toString()
        private val startTime = System.currentTimeMillis()
        private var reportedStart = false

        private fun ensureStartReported() {
            if (reportedStart) return
            reportedStart = true

            val headers = mutableMapOf<String, Any?>()
            inner.requestProperties.forEach { (k, v) ->
                headers[k] = if (v.size == 1) v[0] else v.toList()
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
                val (data, truncated) = readCapped(stream)
                reportComplete(data, error = null, truncated = truncated)
                ByteArrayInputStream(data)
            } catch (e: Exception) {
                reportComplete(null, error = e.message, truncated = false)
                throw e
            }
        }

        override fun getErrorStream(): InputStream? {
            return try {
                val stream = inner.errorStream ?: return null
                val (data, truncated) = readCapped(stream)
                reportComplete(data, error = null, truncated = truncated)
                ByteArrayInputStream(data)
            } catch (e: Exception) {
                reportComplete(null, error = e.message, truncated = false)
                inner.errorStream
            }
        }

        private fun readCapped(stream: InputStream): Pair<ByteArray, Boolean> {
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
            return bytes.toByteArray() to truncated
        }

        private fun reportComplete(
            responseBytes: ByteArray?,
            error: String?,
            truncated: Boolean
        ) {
            val resHeaders = mutableMapOf<String, Any?>()
            inner.headerFields?.forEach { (k, v) ->
                if (k != null) resHeaders[k] = if (v.size == 1) v[0] else v.toList()
            }

            var responseBody: Any? = null
            responseBytes?.let {
                if (truncated) {
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

        // Delegate everything else
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
