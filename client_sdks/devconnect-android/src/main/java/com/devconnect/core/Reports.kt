package com.devconnect.core

import com.devconnect.DevConnect
import org.json.JSONObject

/** Builds and sends the profiling, network, benchmark, snapshot, display and async-operation reports. */
internal object Reports {
    fun reportPerformanceMetric(
        metricType: String,
        value: Double,
        label: String?,
        metadata: Map<String, Any>?
    ) {
        DevConnect.send("client:performance:metric", buildPayload {
            put("metricType", metricType)
            put("value", value)
            label?.let { put("label", it) }
            metadata?.let { put("metadata", JSONObject(it)) }
        })
    }

    fun reportMemoryLeak(
        leakType: String,
        severity: String,
        objectName: String,
        detail: String?,
        retainedSizeBytes: Long?,
        stackTrace: String?,
        metadata: Map<String, Any>?
    ) {
        DevConnect.send("client:memory:leak", buildPayload {
            put("leakType", leakType)
            put("severity", severity)
            put("objectName", objectName)
            detail?.let { put("detail", it) }
            retainedSizeBytes?.let { put("retainedSizeBytes", it) }
            stackTrace?.let { put("stackTrace", it) }
            metadata?.let { put("metadata", JSONObject(it)) }
        })
    }

    fun reportNetworkStart(
        requestId: String,
        method: String,
        url: String,
        headers: Map<String, Any?>?,
        body: Any?
    ) {
        try {
            DevConnect.send("client:network:request_start", buildPayload {
                put("requestId", requestId)
                put("method", method)
                put("url", url)
                put("startTime", System.currentTimeMillis())
                headers?.let { put("requestHeaders", headersToJson(it)) }
                body?.let { put("requestBody", jsonValue(it)) }
            })
        } catch (_: Exception) {}
    }

    fun reportNetworkComplete(
        requestId: String,
        method: String,
        url: String,
        statusCode: Int,
        startTime: Long,
        requestHeaders: Map<String, Any?>?,
        responseHeaders: Map<String, Any?>?,
        requestBody: Any?,
        responseBody: Any?,
        error: String?
    ) {
        val now = System.currentTimeMillis()
        try {
            DevConnect.send("client:network:request_complete", buildPayload {
                put("requestId", requestId)
                put("method", method)
                put("url", url)
                put("statusCode", statusCode)
                put("startTime", startTime)
                put("endTime", now)
                put("duration", now - startTime)
                requestHeaders?.let { put("requestHeaders", headersToJson(it)) }
                responseHeaders?.let { put("responseHeaders", headersToJson(it)) }
                requestBody?.let { put("requestBody", jsonValue(it)) }
                responseBody?.let { put("responseBody", jsonValue(it)) }
                error?.let { put("error", it) }
            })
        } catch (_: Exception) {}
    }

    private val benchmarks = java.util.concurrent.ConcurrentHashMap<String, MutableList<Long>>()

    fun benchmarkStart(title: String) {
        benchmarks[title] = mutableListOf(System.currentTimeMillis())
    }

    fun benchmarkStep(title: String) {
        // Synchronize the inner list — ConcurrentHashMap only guards the
        // map access, not the underlying list's mutation.
        synchronized(benchmarks) {
            benchmarks[title]?.add(System.currentTimeMillis())
        }
    }

    fun benchmarkStop(title: String) {
        val times = benchmarks.remove(title) ?: return
        val startTime = times.first()
        val endTime = System.currentTimeMillis()

        DevConnect.send("client:benchmark", buildPayload {
            put("title", title)
            put("startTime", startTime)
            put("endTime", endTime)
            put("duration", endTime - startTime)
        })
    }

    fun sendStateSnapshot(stateManager: String, state: Map<String, Any>) {
        DevConnect.send("client:state:snapshot", buildPayload {
            put("stateManager", stateManager)
            put("state", JSONObject(state))
        })
    }

    fun display(
        name: String,
        value: Any?,
        preview: String?,
        image: String?,
        metadata: Map<String, Any>?
    ) {
        DevConnect.send("client:display", buildPayload {
            put("name", name)
            value?.let { put("value", jsonValue(it)) }
            preview?.let { put("preview", it) }
            image?.let { put("image", it) }
            metadata?.let { put("metadata", JSONObject(it)) }
        })
    }

    fun reportAsyncOperation(
        operationType: String,
        description: String,
        status: String,
        duration: Long?,
        sagaName: String?,
        error: String?,
        result: Any?,
        metadata: Map<String, Any>?
    ) {
        DevConnect.send("client:async:operation", buildPayload {
            put("operationType", operationType)
            put("description", description)
            put("status", status)
            duration?.let { put("duration", it) }
            sagaName?.let { put("sagaName", it) }
            error?.let { put("error", it) }
            result?.let { put("result", jsonValue(it)) }
            metadata?.let { put("metadata", JSONObject(it)) }
        })
    }
}
