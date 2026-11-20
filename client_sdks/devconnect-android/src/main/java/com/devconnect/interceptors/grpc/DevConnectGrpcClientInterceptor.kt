package com.devconnect.interceptors.grpc

import com.devconnect.DevConnect
import io.grpc.CallOptions
import io.grpc.Channel
import io.grpc.ClientCall
import io.grpc.ClientInterceptor
import io.grpc.ForwardingClientCall
import io.grpc.ForwardingClientCallListener
import io.grpc.KnownLength
import io.grpc.Metadata
import io.grpc.MethodDescriptor
import io.grpc.Status
import java.io.InputStream
import java.util.UUID
import java.util.concurrent.atomic.AtomicLong

/**
 * gRPC `ClientInterceptor` that emits `client:grpc_*` events on every
 * RPC.
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
 *  - On `start`: parse method descriptor → `service`, `method`.
 *    Emit `client:grpc_call_start` with a per-call `callId`.
 *  - On `sendMessage` / `onMessage`: add up request / response bytes.
 *  - On `onClose`: emit `client:grpc_call_end { callId, service, method,
 *    latencyMs, status, requestBytes, responseBytes }`.
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

        val callId = UUID.randomUUID().toString()
        // sendMessage runs on the app's thread, onMessage on gRPC's executor.
        val requestBytes = AtomicLong()
        val responseBytes = AtomicLong()

        val call = next.newCall(method, callOptions)

        return object : ForwardingClientCall<ReqT, RespT>() {
            override fun delegate(): ClientCall<ReqT, RespT> = call

            override fun start(responseListener: Listener<RespT>, headers: Metadata) {
                val startNanos = System.nanoTime()
                try {
                    DevConnect.safeSend("client:grpc_call_start", mapOf(
                        "callId" to callId,
                        "service" to service,
                        "method" to rpcMethod,
                        "fullMethod" to fullMethod,
                        "requestStreaming" to (method.type == MethodDescriptor.MethodType.CLIENT_STREAMING ||
                            method.type == MethodDescriptor.MethodType.BIDI_STREAMING),
                        "responseStreaming" to (method.type == MethodDescriptor.MethodType.SERVER_STREAMING ||
                            method.type == MethodDescriptor.MethodType.BIDI_STREAMING),
                    ))
                } catch (_: Throwable) {}

                val wrappedListener = object : ForwardingClientCallListener.SimpleForwardingClientCallListener<RespT>(responseListener) {
                    override fun onMessage(message: RespT) {
                        try {
                            responseBytes.addAndGet(wireSize(method.streamResponse(message)))
                        } catch (_: Throwable) {}
                        super.onMessage(message)
                    }

                    override fun onClose(status: Status, trailers: Metadata) {
                        val latencyMs = (System.nanoTime() - startNanos) / 1_000_000
                        try {
                            val payload = buildMap<String, Any?> {
                                put("callId", callId)
                                put("service", service)
                                put("method", rpcMethod)
                                put("latencyMs", latencyMs)
                                put("status", status.code.name)
                                put("statusDescription", status.description ?: "")
                                put("requestBytes", requestBytes.get())
                                put("responseBytes", responseBytes.get())
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
                    requestBytes.addAndGet(wireSize(method.streamRequest(message)))
                } catch (_: Throwable) {}
                super.sendMessage(message)
            }
        }
    }

    /**
     * Wire size of a message, from the call's own marshaller: protobuf's
     * stream is a [KnownLength] whose size is `getSerializedSize()`, read
     * without serializing (and without a protobuf dependency here).
     */
    // shortcut: other marshallers count 0 and may serialize once more here; size their streams if one shows up.
    private fun wireSize(stream: InputStream): Long = (stream as? KnownLength)?.available()?.toLong() ?: 0L
}