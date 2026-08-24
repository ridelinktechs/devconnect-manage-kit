# Round 3 — Protocol Inspectors (GraphQL, gRPC, WebSocket)

## Problem

`DevConnect` today treats every HTTP request as a flat `(method, url, status, latency, body)` tuple. Real backend traffic in 2026 is dominated by 3 protocols that have their own structure:

1. **GraphQL** — `POST /graphql` with body `{ query: "query GetUser { user { id name } }", variables: {...} }`. Desktop shows the raw body but doesn't group by operation name, doesn't show the operation type (query/mutation/subscription), doesn't deduplicate identical operations, and can't aggregate cache hits vs misses.
2. **gRPC** — `POST /UserService/GetUser` with protobuf-encoded request/response. Desktop can't decode the bytes at all — every gRPC call shows `body = "<binary 0x...>"`.
3. **WebSocket / Socket.IO** — long-lived connections exchanging structured frames. Desktop's HTTP inspector closes the request as soon as the upgrade completes; subsequent frames are invisible.

Without protocol-level inspectors, debugging "why is `GetUser` slow?" requires opening Apollo Studio, gRPCurl, or wscat in a second window. Goal: all three visible in `DevConnect Manage Tool`.

## Approach

Three independent sub-projects, each with an SDK side (parses + annotates the protocol) and a desktop side (renders a protocol-specific tab under Network Inspector).

### Sub-project 3.1 — GraphQL inspector

**Android (Apollo Kotlin)**. Apollo Kotlin's `ApolloInterceptor` chain runs once per operation. New `DevConnectApolloInterceptor` extends `ApolloInterceptor` and:
- On `intercept(request, chain)`: parse `request.operation.name()` and `request.operation.variables()` → emit `client:graphql_operation { operation: "GetUser", type: "query", variables: {...} }`. Forward to the chain.
- On response: read `response.data`, emit `client:graphql_response { operation: ..., latencyMs: ..., cacheHit: response.extensions["persistedQuery"] != null, errors: [...] }`.

**Flutter (graphql_flutter / ferry)**. `graphql_flutter` has no interceptor API; the client is wrapped via `Link`. New `DevConnectLink` extends `Link` and wraps the original. Similar emit pattern as Android.

`ferry` ships a `TypedLink` interceptor chain. New `DevConnectTypedLink` — same emit pattern, simpler wiring (link passed to `client.link`).

**RN (Apollo Client)**. Apollo Client has an `ApolloLink` middleware chain. New `DevConnectApolloLink` extends `ApolloLink` and requests `operation.operationName`, `operation.variables`, `operation.getContext()`. Wraps the original link via `ApolloLink.from([devConnectLink, httpLink])`.

**Desktop side**. New `lib/features/network_inspector/presentation/widgets/graphql_tab.dart`:
- Group by `operation` name (collapsible tree, default expanded)
- Columns: operation, type, count, p50 latency, p95 latency, error rate
- Click → side panel showing variables, response data (truncated at 4 KB), errors
- Filter: by operation name (type-ahead), by type (query/mutation/subscription)

### Sub-project 3.2 — gRPC inspector

**Android (grpc-java / grpc-kotlin)**. grpc-java has `ClientInterceptor` with `onMessage` / `onClose` hooks per RPC. New `DevConnectGrpcClientInterceptor` extends `ClientInterceptor`:
- On `interceptCall`: parse method descriptor → `service = "UserService"`, `method = "GetUser"`. Emit `client:grpc_call_start`.
- On `onMessage` (request): forward to next handler but capture bytes for later parsing.
- On `onClose`: emit `client:grpc_call_end { service, method, latencyMs, status, requestBytes: bytes1, responseBytes: bytes2 }`.

Protobuf decoding requires the consumer's `.proto` files. Without them we can only show byte counts + method descriptor name. With `.proto`s, we parse to JSON via `com.google.protobuf:protobuf-java-util:JsonFormat.printer()`. Approach: optional `protoDir: File?` config — if non-null, scan for `.proto` files, compile to descriptor set on first use, decode bytes.

**Flutter (grpc-dart)**. `grpc-dart` exposes `ClientInterceptor` via `ClientChannel` builder. New `DevConnectGrpcInterceptor extends ClientInterceptor`. Decoding requires `protoc_plugin` generated descriptors. Same opt-in pattern as Android.

**RN (grpc-web / @grpc/grpc-js)**. `grpc-web` runs over HTTP/1.1 with `application/grpc-web+proto` content type; the body is length-prefixed protobuf frames. `@grpc/grpc-js` is Node-only and not relevant for RN. Approach: detect `Content-Type: application/grpc-web+proto` and parse the framed body in the existing HTTP interceptor. No separate interceptor needed — just a content-type-specific parser.

**Desktop side**. New `lib/features/network_inspector/presentation/widgets/grpc_tab.dart`:
- Group by `service` → list of methods
- Columns: method, count, p50 latency, status (OK / ERROR_CODE / UNKNOWN)
- Click → side panel: request bytes (base64), response bytes (base64), or decoded JSON if `.proto` provided

### Sub-project 3.3 — WebSocket inspector

Single design across all 3 platforms because WebSocket is a stable wire protocol (RFC 6455):

**SDK side**. Each platform's HTTP inspector (`HttpURLConnection` on Android, `http` on Flutter, `fetch` on RN) already handles the upgrade. Extend it to:
- Don't close the request when status = `101 Switching Protocols`. Open a new "WebSocket frame" sub-tab instead.
- On every frame sent/received: emit `client:ws_frame { url, direction: "send" | "receive", opcode: "text" | "binary" | "ping" | "pong" | "close", payload, timestamp }`.

The trick is keeping a reference to the open socket and reading frames asynchronously. On Android: extend `URLStreamHandlerFactory` to capture the `HttpURLConnection` and hook `getInputStream()`/`getOutputStream()`. On Flutter: wrap `WebSocket.connect` with a frame logger. On RN: wrap `global.WebSocket` constructor.

**Desktop side**. New `lib/features/network_inspector/presentation/widgets/websocket_tab.dart`:
- List of open connections at top: `ws://api.example.com/orderbook` (status, frames/sec, total bytes)
- Click → frame timeline (left = send, right = receive, vertical timeline, color-coded by opcode)
- Filter by opcode, search payloads

**Socket.IO sub-mode**. Socket.IO adds its own framing (`42["subscribe",{"channel":"orders"}]`) on top of WebSocket. Auto-detect by `socket.io` query param or transport header; parse frames by stripping the Socket.IO engine.io prefix and emit `client:ws_frame` with `engine = "socketio"` and `event = "subscribe"`.

### Sub-project 3.4 — Desktop protocol tabs integration

Add 3 tabs to Network Inspector's right panel: **GraphQL** | **gRPC** | **WebSocket**. Tab badges show the count of in-flight operations. The existing **HTTP** tab stays for non-protocol traffic (REST, plain JSON, file uploads).

A request that matches multiple protocols (e.g. `POST /graphql` is both HTTP and GraphQL) shows up in both tabs — the HTTP tab shows the raw request, the GraphQL tab shows the parsed operation.

## Data flow

```
SDK side (3 platforms × 3 protocols):
  GraphQL client ──► interceptor/link ──► parse + emit client:graphql_*
  gRPC client     ──► clientInterceptor ──► parse + emit client:grpc_*
  WebSocket       ──► wrap connect/read  ──► parse + emit client:ws_frame
                       │
                       └─► existing DevConnect.send() ──► WebSocket

Desktop side:
  client:graphql_* / client:grpc_* / client:ws_frame
                       │
                       └─► protocol_router.dart ──► GraphQL tab / gRPC tab / WS tab
```

## Error handling

| Failure | Behaviour |
|---|---|
| GraphQL operation has no name (anonymous query) | Label as "anonymous"; group by hash of the operation body. |
| gRPC descriptor set fails to compile (bad .proto) | Fall back to byte-count-only view; log a one-time WARN to logcat. |
| WebSocket frame body is binary (Blob, ArrayBuffer) | Emit `payload = "<binary 4 KB>"` with `metadata.sizeBytes`. |
| Socket.IO parsing fails (custom parser) | Fall back to raw frame view. |
| Decoder can't handle newer protobuf features (unknown fields) | Use `JsonFormat.printer().ignoringUnknownFields()` to skip gracefully. |

## Out of scope

- **Apollo Studio schema sync** — we don't pull the schema from Apollo's registry. Consumers wire `.proto`/GraphQL schema files locally.
- **gRPC streaming** — unary only in round 3. Server/bidi streaming comes later if requested.
- **GraphQL subscriptions over WebSocket** — round 3 covers WS frames generically; sub-event parsing is a follow-up.
- **Protocol-specific mocking** (Round 4's mock server will support GraphQL/gRPC fixtures, but that's separate).

## Files

**New (SDK side):**

| Sub-project | Files |
|---|---|
| 3.1 GraphQL Android | `client_sdks/devconnect-android/src/main/java/com/devconnect/interceptors/graphql/DevConnectApolloInterceptor.kt` |
| 3.1 GraphQL Flutter | `client_sdks/devconnect_flutter/lib/src/interceptors/graphql/devconnect_link.dart` |
| 3.1 GraphQL RN | `client_sdks/devconnect-react-native/src/interceptors/apollo/devConnectApolloLink.ts` |
| 3.2 gRPC Android | `client_sdks/devconnect-android/src/main/java/com/devconnect/interceptors/grpc/DevConnectGrpcClientInterceptor.kt` |
| 3.2 gRPC Flutter | `client_sdks/devconnect_flutter/lib/src/interceptors/grpc/devconnect_interceptor.dart` |
| 3.3 WebSocket Android | extend `URLStreamHandlerFactory.kt` |
| 3.3 WebSocket Flutter | new `client_sdks/devconnect_flutter/lib/src/interceptors/websocket/devconnect_websocket.dart` |
| 3.3 WebSocket RN | wrap `global.WebSocket` in existing `src/interceptors/networkInterceptor.ts` |

**New (desktop side):**
- `lib/features/network_inspector/presentation/widgets/graphql_tab.dart`
- `lib/features/network_inspector/presentation/widgets/grpc_tab.dart`
- `lib/features/network_inspector/presentation/widgets/websocket_tab.dart`
- `lib/features/network_inspector/presentation/widgets/protocol_router.dart`
- `lib/features/network_inspector/data/protocol_event_router.dart`

**Updated:**
- `lib/features/network_inspector/presentation/pages/network_inspector_page.dart` — add 3 new tabs
- `client_sdks/devconnect-android/README.md` — GraphQL / gRPC sections
- `client_sdks/devconnect_flutter/README.md` — same
- `client_sdks/devconnect-react-native/README.md` — same

## Testing

For each platform × protocol:
- Integration test with a fake GraphQL/gRPC/WS server. Verify the SDK emits the right `client:*` event shape.
- Verify protobuf / GraphQL parsing handles malformed input without crashing the inspector.
- Desktop widget tests: golden tests for each tab with a fixture dataset (10 operations, varying latencies, 1 error).

## Non-goals

- No commits (standing instruction).
- No new release until all 3 protocols ship on all 3 platforms (one SDK release per protocol-platform pair is the upper bound).
