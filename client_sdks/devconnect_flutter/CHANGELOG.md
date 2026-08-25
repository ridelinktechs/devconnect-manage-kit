## 1.0.6

- **WebSocket inspector (Round 3)**: new `DevConnectWebSocket` wrapper
  (dart:io) and `DevConnectWebSocketHelper` emit `client:ws_open`,
  `client:ws_frame`, and `client:ws_close` events to the DevConnect
  desktop, so WebSocket traffic shows up in the protocol inspectors.
- **GraphQL link (Round 3)**: new `DevConnectLink` for `graphql_flutter`
  / ferry — emits `client:graphql_operation` and
  `client:graphql_response` events with operation name, variables,
  response data, and errors for the desktop GraphQL inspector.
- **Mock server (Round 4)**: `MockRule`, `setMockRules`, and
  `findMatch` implement the server→client mock rule push
  (`server:mock_rules_update`). The HTTP interceptors check the mock
  store before hitting the network and return the canned response
  (regex + header matching, optional delay).
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
