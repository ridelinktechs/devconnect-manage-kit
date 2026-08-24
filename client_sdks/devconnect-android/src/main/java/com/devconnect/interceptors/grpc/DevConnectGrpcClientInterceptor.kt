package com.devconnect.interceptors.grpc

import com.devconnect.DevConnect
import io.grpc.CallOptions
import io.grpc.Channel
import io.grpc.ClientCall
import io.grpc.ClientInterceptor
import io.grpc.ForwardingClientCall
import io.grpc.ForwardingClientCallListener
import io.grpc.Metadata
import io.grpc.MethodDescriptor
import io.grpc.Status

/**
 * gRPC `ClientInterceptor` that emits `client:grpc_*` events on every
 * unary RPC.
 *
 * Wire it into the gRPC managed channel:
 * ```kotlin
 * val channel = ManagedChannelBuilder.forAddress(host, port)
 *     .usePlaintext()
 *     .intercept(DevConnectGrpcClientInterceptor())
 *     .build()
 * ```
 *
 * Spec (Round 3 / 3.2):
 *  - On `interceptCall`: parse method descriptor → `service`, `method`.
 *    Emit `client:grpc_call_start`.
 *  - On `onMessage`: capture request bytes (count only).
 *  - On `onClose`: emit `client:grpc_call_end { service, method, latencyMs,
 *    status, requestBytes, responseBytes }`.
 *
 * Notes:
 *  - Streaming RPCs (server / bidi) emit `start` and `end` but the byte
 *    counts are best-effort — see spec "unary only in round 3".
 *  - Protobuf decoding requires `.proto` files (out of scope this round).
 *    Without them, the desktop shows byte counts + method name only.
 */
class DevConnectGrpcClientInterceptor : ClientInterceptor {

    override fun <ReqT : Any?, RespT : Any?> interceptCall(
        method: MethodDescriptor<ReqT, RespT>,
        callOptions: CallOptions,
        next: Channel,
    ): ClientCall<ReqT, RespT> {
        val fullMethod = method.fullMethodName.orEmpty()
        // Format: "/<service>/<method>" — strip leading slash for readability.
        val parts = fullMethod.removePrefix("/").split("/")
        val service = parts.firstOrNull() ?: "unknown"
        val rpcMethod = parts.drop(1).joinToString("/").ifEmpty { fullMethod }

        val startTime = System.currentTimeMillis()
        var requestBytes = 0L
        var responseBytes = 0L

        try {
            DevConnect.safeSend("client:grpc_call_start", mapOf(
                "service" to service,
                "method" to rpcMethod,
                "fullMethod" to fullMethod,
                "requestStreaming" to (method.type == MethodDescriptor.MethodType.CLIENT_STREAMING ||
                    method.type == MethodDescriptor.MethodType.BIDI_STREAMING),
                "responseStreaming" to (method.type == MethodDescriptor.MethodType.SERVER_STREAMING ||
                    method.type == MethodDescriptor.MethodType.BIDI_STREAMING),
            ))
        } catch (_: Throwable) {}

        val call = next.newCall(method, callOptions)

        return object : ForwardingClientCall<ReqT, RespT>() {
            override fun delegate(): ClientCall<ReqT, RespT> = call

            override fun start(responseListener: Listener<RespT>, headers: Metadata) {
                val wrappedListener = object : ForwardingClientCallListener.SimpleForwardingClientCallListener<RespT>(responseListener) {
                    override fun onMessage(message: RespT) {
                        try {
                            // Best-effort byte count: estimate via toString().length for non-trivial types.
                            responseBytes += estimateSize(message)
                        } catch (_: Throwable) {}
                        super.onMessage(message)
                    }

                    override fun onClose(status: Status, trailers: Metadata) {
                        val latencyMs = System.currentTimeMillis() - startTime
                        try {
                            val payload = buildMap<String, Any?> {
                                put("service", service)
                                put("method", rpcMethod)
                                put("latencyMs", latencyMs)
                                put("status", status.code.name)
                                put("statusDescription", status.description ?: "")
                                put("requestBytes", requestBytes)
                                put("responseBytes", responseBytes)
                                if (!status.isOk) {
                                    put("error", status.cause?.message ?: status.description ?: "")
                                }
                            }
                            DevConnect.safeSend("client:grpc_call_end", payload)
                        } catch (_: Throwable) {}
                        super.onClose(status, trailers)
                    }
                }
                super.start(wrappedListener, headers)
            }

            override fun sendMessage(message: ReqT) {
                try {
                    requestBytes += estimateSize(message)
                } catch (_: Throwable) {}
                super.sendMessage(message)
            }
        }
    }

    /**
     * Best-effort byte size. For ProtoBuf messages this is just the
     * toString().length — accurate enough for a UI counter. Avoids
     * pulling in the full proto runtime here.
     */
    private fun estimateSize(message: Any?): Long {
        if (message == null) return 0L
        return try {
            message.toString().length.toLong()
        } catch (_: Throwable) {
            0L
        }
    }
}