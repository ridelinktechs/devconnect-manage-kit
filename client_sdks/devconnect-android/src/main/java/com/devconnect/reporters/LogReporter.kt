package com.devconnect.reporters

import com.devconnect.DevConnect

/**
 * Tagged logger for DevConnect.
 *
 * ```kotlin
 * val logger = DevConnect.logger("AuthService")
 * logger.info("User logged in")
 * logger.error("Login failed", stackTrace = Log.getStackTraceString(e))
 * ```
 *
 * Metadata values are redacted before they reach the desktop inspector:
 * keys matching `token`, `password`, `secret`, `apikey`, `api_key`,
 * `authorization`, `cookie`, `credential` have their values replaced with
 * `[REDACTED]`. The previous implementation forwarded metadata verbatim.
 */
class LogReporter(private val tag: String? = null) {

    fun debug(message: String, metadata: Map<String, Any>? = null) {
        DevConnect.debug(message, tag, redactMetadata(metadata))
    }

    fun info(message: String, metadata: Map<String, Any>? = null) {
        DevConnect.log(message, tag, redactMetadata(metadata))
    }

    fun warn(message: String, metadata: Map<String, Any>? = null) {
        DevConnect.warn(message, tag, redactMetadata(metadata))
    }

    fun error(
        message: String,
        stackTrace: String? = null,
        metadata: Map<String, Any>? = null
    ) {
        DevConnect.error(message, tag, stackTrace, redactMetadata(metadata))
    }

    /**
     * Log an exception with full stack trace.
     */
    fun exception(e: Throwable, message: String? = null) {
        DevConnect.error(
            message = message ?: e.message ?: e.toString(),
            tag = tag,
            stackTrace = e.stackTraceToString()
        )
    }

    private companion object {
        val SENSITIVE_KEY_HINTS = listOf(
            "token", "password", "secret", "apikey", "api_key",
            "authorization", "cookie", "credential",
        )

        fun redactMetadata(metadata: Map<String, Any>?): Map<String, Any>? {
            if (metadata.isNullOrEmpty()) return metadata
            var dirty = false
            val out = LinkedHashMap<String, Any>(metadata.size)
            for ((k, v) in metadata) {
                val lower = k.lowercase()
                if (SENSITIVE_KEY_HINTS.any { lower.contains(it) }) {
                    out[k] = "[REDACTED]"
                    dirty = true
                } else {
                    out[k] = v
                }
            }
            return if (dirty) out else metadata
        }
    }
}
