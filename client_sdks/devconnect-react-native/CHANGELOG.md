# Changelog

## 1.0.7

- **Fetch / XHR dedup**: when the same request runs through both
  transports (e.g. `fetch` internally calls `XMLHttpRequest`, or a
  library wraps `fetch` with its own XHR wrapper), the SDK now
  tracks in-flight calls via a `fetchInFlight` counter and only
  emits a single `client:network:request_start` event. Previously
  duplicate rows showed up in DevConnect Manage Tool's network
  inspector. Hot-reload + host-cache features from 1.0.6 unchanged.

## 1.0.6

- **Hot reload from desktop**: new public API
  `DevConnect.registerReloadHandler(() => { ... })`. The SDK now
  responds to `server:reload` and `server:hot_restart` messages from
  DevConnect Manage Tool — the default handler calls
  `DevSettings.reload()` (the same path the dev menu's "Reload"
  uses). Register a custom handler to wipe in-memory state before
  the reload.
- **AWS SDK v3 compatibility**: the fetch interceptor now handles
  the `fetch(request)` call shape used by `@aws-sdk/fetch-http-handler`,
  where the input is a fully-built `Request` object and `init` is
  `undefined`. All headers added by the signer middleware
  (`X-Amz-Date`, `Authorization`, …) are now captured correctly.
- **`Headers` instance tracking**: new `wrapFetchInit` and
  `readFinalHeaders` helpers track headers added to a real
  `Headers` instance after the interceptor reads them — fixes
  double-tracking and ensures the devtools-side request panel
  reflects the final headers actually sent.
- **Host cache identity verification**: the cached host entry now
  carries the desktop's stable `machineId`, and the SDK probes
  the server with a short-lived WebSocket on every reconnect to
  verify the cached IP still points at the same machine. Stale or
  mismatched entries are invalidated automatically — fixes the
  simulator/device-swap reconnect bug.
- **iOS device model fix**: prefer `interfaceIdiom` (iPhone / iPad /
  tvOS) over `systemName` so the device list shows the correct
  device shape regardless of iOS version.
- **Legacy cache invalidation**: caches written by older SDKs (no
  `machineId`) are now treated as absent instead of being trusted
  blindly.

## 1.0.5

- `react-native` peer dependency constraint removed so the kit
  installs on any RN version.
- Auto-stringify object-shaped log payloads (prevent
  `[object Object]` in network inspector).
- Storage reporters for MMKV, EncryptedStorage, WatermelonDB,
  SQLite, Realm.

## 1.0.4

- HTTP intercept for `fetch` and `axios` with full multipart /
  form-data body parsing.
- Redux / MobX / Zustand / Jotai / Valtio / XState reporters.
- AsyncStorage, MMKV, EncryptedStorage, WatermelonDB, SQLite,
  Realm reporters.

## 1.0.3

- Initial published release of `devconnect-manage-kit` for React
  Native.
