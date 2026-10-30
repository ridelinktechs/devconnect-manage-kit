package com.devconnect.interceptors.graphql

import com.apollographql.apollo3.api.ApolloRequest
import com.apollographql.apollo3.api.ApolloResponse
import com.apollographql.apollo3.api.CustomScalarAdapters
import com.apollographql.apollo3.api.Mutation
import com.apollographql.apollo3.api.Operation
import com.apollographql.apollo3.api.Subscription
import com.apollographql.apollo3.api.json.MapJsonWriter
import com.apollographql.apollo3.api.variables
import com.apollographql.apollo3.interceptor.ApolloInterceptor
import com.apollographql.apollo3.interceptor.ApolloInterceptorChain
import com.devconnect.DevConnect
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.onCompletion
import kotlinx.coroutines.flow.onEach
import java.util.UUID

/**
 * Apollo Kotlin `ApolloInterceptor` that emits `client:graphql_*` events
 * to the desktop State Inspector / Network Inspector.
 *
 * Wire it into the Apollo client:
 * ```kotlin
 * val apollo = ApolloClient.Builder()
 *     .serverUrl("https://api.example.com/graphql")
 *     .addInterceptor(DevConnectApolloInterceptor())
 *     .build()
 * ```
 *
 * Spec (Round 3 / 3.1):
 *  - On `intercept(request, chain)`: parse `request.operation.name()`
 *    and `request.operation.variables()` → emit `client:graphql_operation`.
 *  - On response: emit `client:graphql_response { operation, latencyMs,
 *    cacheHit: response.extensions["persistedQuery"] != null, errors: [...] }`.
 *  - Both carry the same `operationId`, one per intercepted request.
 *
 * Notes:
 *  - Apollo Kotlin 3.x has a unified Flow-based interceptor API (no
 *    `onResponse`/`onFetchError` callbacks). We wrap `chain.proceed(...)`
 *    with `onEach`/`onCompletion` operators to capture timing + errors.
 *  - Variables and response data are written to plain maps through the
 *    operation's generated serializers, with the client's custom scalar
 *    adapters.
 */
class DevConnectApolloInterceptor : ApolloInterceptor {
    override fun <D : Operation.Data> intercept(
        request: ApolloRequest<D>,
        chain: ApolloInterceptorChain,
    ): Flow<ApolloResponse<D>> {
        val startTime = System.currentTimeMillis()
        val operationId = UUID.randomUUID().toString()
        val operation = request.operation
        val operationName = operation.name()
        val operationType = when (operation) {
            is Mutation<*> -> "mutation"
            is Subscription<*> -> "subscription"
            else -> "query"
        }
        val adapters = request.executionContext[CustomScalarAdapters] ?: CustomScalarAdapters.Empty

        try {
            DevConnect.safeSend("client:graphql_operation", mapOf(
                "operationId" to operationId,
                "operation" to operationName,
                "type" to operationType,
                "variables" to runCatching { operation.variables(adapters).valueMap }.getOrDefault(emptyMap()),
            ))
        } catch (_: Throwable) {}

        return chain.proceed(request)
            .onEach { response ->
                try {
                    val cacheHit = response.extensions["persistedQuery"] != null
                    val data = response.data?.let { data ->
                        runCatching {
                            MapJsonWriter().apply { operation.adapter().toJson(this, adapters, data) }.root()
                        }.getOrNull()
                    }
                    val errors = response.errors?.takeIf { it.isNotEmpty() }?.map { err ->
                        buildMap<String, Any?> {
                            put("message", err.message)
                            err.path?.let { put("path", it) }
                            err.locations?.let { locs ->
                                put("locations", locs.map { mapOf("line" to it.line, "column" to it.column) })
                            }
                        }
                    }
                    DevConnect.safeSend("client:graphql_response", buildMap<String, Any?> {
                        put("operationId", operationId)
                        put("operation", operationName)
                        put("type", operationType)
                        // Captured at intercept(), not a fresh `now - 0`.
                        put("latencyMs", System.currentTimeMillis() - startTime)
                        put("cacheHit", cacheHit)
                        if (data != null) put("data", data)
                        if (errors != null) put("errors", errors)
                    })
                } catch (_: Throwable) {}
            }
            .onCompletion { cause ->
                // Cancelled (screen left, flow.first()) isn't a failed request.
                if (cause != null && cause !is CancellationException) {
                    try {
                        DevConnect.safeSend("client:graphql_response", buildMap<String, Any?> {
                            put("operationId", operationId)
                            put("operation", operationName)
                            put("type", operationType)
                            put("latencyMs", System.currentTimeMillis() - startTime)
                            put("error", cause.message ?: cause.javaClass.simpleName)
                            put("stack", cause.stackTraceToString())
                        })
                    } catch (_: Throwable) {}
                }
            }
    }
}
