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
