## Unreleased

- **Mock server**: desktop rules now answer requests. `server:mock_rules_update`
  is handled from `init` (each push replaces the whole list); matching
  requests are served through `HttpOverrides` (any `dart:io` client) and
  through the Dio interceptor given `responseFactory: Response.new`, and
  reported as `client:mocked_request`. Rules honour `expiresAt` and
  `scope.deviceIds`, and a rule with header matchers no longer matches a
  request without those headers.
- **WebSocket**: `DevConnectWebSocket` is exported and is a `Stream`: frames
  received through `listen()` / `await for` / `frames` are captured, events
  carry a `connectionId`, and exactly one `client:ws_close` is sent (on
  `close()` or when the stream ends). `DevConnect.websocketConnect` /
  `websocketWrap` return it instead of `dynamic`.
- **GraphQL**: `DevConnect.reportGraphQLOperation` returns an `operationId`;
  the new `DevConnect.reportGraphQLResponse` completes it with `data`,
  `errors` or a transport `error`. Anonymous operations are named
  "anonymous". The README has a `gql_link` adapter (`DevConnectGqlLink`).
- **Payloads**: a value that can't be JSON-encoded (e.g. a `DateTime` in
  GraphQL variables) no longer turns its whole map into a string. A map or
  list inside itself becomes `<cycle>` and the copy stops after 10,000
  values, so cyclic data with branches no longer freezes the app.
- **BLoC**: `DevConnect.blocObserver()` is deprecated. It is not a
  `flutter_bloc` `BlocObserver`, so `Bloc.observer = DevConnect.blocObserver()`
  threw at startup; it is now typed, so that line fails to compile. Call
  `DevConnect.reportBlocChange` from your own `BlocObserver` (see its docs).
- **Network**: bodies past 1 MB are no longer buffered and are reported as
  `<N bytes, cut>`; event streams as `<event stream, N bytes>`, binary
  types as `N bytes`. Dio byte data (`ResponseType.bytes`, uploads) is
  reported as `N bytes` instead of a huge JSON array of ints.
- Docs: the Dio interceptor is added through `InterceptorsWrapper` (it is
  not a Dio `Interceptor` subclass).

## 1.0.6

- **WebSocket inspector (Round 3)**: new `DevConnectWebSocket` wrapper
  (dart:io) and `DevConnectWebSocketHelper` emit `client:ws_open` and
  `client:ws_frame` events to the DevConnect desktop (`client:ws_close`
  only through the helper; see Unreleased).
- **GraphQL link (Round 3)**: new `DevConnectLink`, on the package's own
  link types (it does not plug into `gql_link`), emits
  `client:graphql_operation` and `client:graphql_response` events with
  operation name and variables (data and errors: see Unreleased).
- **Mock server (Round 4)**: `MockRule`, `setMockRules`, and
  `findMockMatch` model and match the server→client mock rule push
  (`server:mock_rules_update`) with regex + header matching and an
  optional delay; requests were not yet answered from the rules (see
  Unreleased).
- **Structured header/query values**: network interceptors now carry
  structured data for headers and query parameters instead of
  stringifying everything.

## 1.0.5

- **Hot reload / hot restart from desktop**: new public API
  `DevConnect.onReloadRequest` and `DevConnect.onHotRestartRequest`.
  The SDK now responds to `server:reload` and `server:hot_restart`
  messages from DevConnect Manage Tool. Default implementation calls
  `WidgetsBinding.reassembleApplication` (the same mechanism
  `flutter run -r` uses). Override the hooks to wipe in-memory state
  before reload or to remount your root widget for true hot-restart
  semantics.
- **Host cache identity verification**: the cached host entry now
  carries the desktop's stable `machineId`, and the SDK probes the
  server with a short-lived WebSocket on every reconnect to verify
  the cached IP still points at the same machine. Stale or
  mismatched entries are invalidated automatically — fixes the
  simulator/device-swap reconnect bug.
- **Legacy cache invalidation**: caches written by older SDKs (no
  `machineId`) are now treated as absent instead of being trusted
  blindly.

## 1.0.4

- **Error monitoring**: new `error_monitor` plugin + cross-platform Error Inspector that captures uncaught and zone errors.
- **Storage**: `TextComponent`, expanded storage-type coverage, and `SharedPreferences` async + cached wrappers.
- **Network**: interceptors now parse `multipart/form-data` bodies and capture Android error streams.

## 1.0.3

- Auto HTTP interception (Dio/http), Realm & Isar storage wrappers, zone-mismatch fix.

## 1.0.2

- Storage reporters and auto-wrappers; internal refactor (font/color constants).

## 1.0.1

- Performance profiling, benchmark and memory-leak detection plugins across all SDKs.

## 1.0.0

- Initial release.
- Auto-intercept HTTP (Dio, http, Firebase, OAuth2, GraphQL, gRPC-web).
- Auto-capture logs (print, debugPrint, logger, talker, fimber, logging).
- State management support (Riverpod, BLoC, Provider, GetX, MobX, Signals).
- Storage wrappers (SharedPreferences, Hive, Realm, SecureStorage, MMKV, ObjectBox, Sembast, sqflite, Floor).
- Database support (Drift, Isar, sqflite).
- Performance metrics & benchmarking.
- Custom commands.
- Multi-platform: Android, iOS, macOS, Linux, Windows.
