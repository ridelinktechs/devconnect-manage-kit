<div align="center">

# DevConnect Manage Kit

### A modern, cross-platform manage and debug tool — alternative to Reactotron and Flipper

**Debug Flutter, React Native & Android apps — network, state, logs, storage, database — all in one beautiful desktop tool.**

[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Windows-blue)](https://github.com/ridelinktechs/devconnect-manage-kit/releases)
[![Flutter](https://img.shields.io/badge/Flutter-SDK-02569B?logo=flutter)](client_sdks/devconnect_flutter/README.md)
[![React Native](https://img.shields.io/badge/React%20Native-SDK-61DAFB?logo=react)](client_sdks/devconnect-react-native/README.md)
[![Android](https://img.shields.io/badge/Android-SDK-3DDC84?logo=android)](client_sdks/devconnect-android/README.md)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[Features](#features) · [Download](#download) · [Quick Start](#quick-start) · [Desktop Guide](#using-the-desktop-app) · [Mock Server](#mock-server) · [SDKs](#sdks) · [Support](#support-devconnect-manage-kit)

</div>

---

## Why DevConnect Manage Kit?

If you've used **Reactotron**, **Flipper**, or **Flutter DevTools** — you know they're powerful but limited to one framework. DevConnect Manage Kit is a **single desktop app** that works with all of them.

|                        |          DevConnect Manage Kit           |  Reactotron   |    Flipper    | Flutter DevTools |
| ---------------------- | :--------------------------------------: | :-----------: | :-----------: | :--------------: |
| Flutter support        |                    ✅                    |      ❌       |   ⚠️ plugin   |        ✅        |
| React Native support   |                    ✅                    |      ✅       |      ✅       |        ❌        |
| Android Native support |                    ✅                    |      ❌       |      ✅       |        ❌        |
| Network inspector      |                    ✅                    |      ✅       |      ✅       |        ✅        |
| State debugging        | ✅ Redux/MobX/Zustand/BLoC/Riverpod/GetX | ✅ Redux/MobX |      ✅       |        ❌        |
| Log viewer             |                    ✅                    |      ✅       |      ✅       |        ✅        |
| Storage viewer         |                    ✅                    |      ✅       |      ✅       |        ❌        |
| Database browser       |                    ✅                    |      ❌       |      ✅       |        ❌        |
| Performance profiling  |          ✅ FPS/CPU/Memory/Jank          |      ❌       |      ❌       |        ✅        |
| Memory leak detection  |                    ✅                    |      ❌       |      ❌       |        ✅        |
| Benchmark timing       |                    ✅                    |      ✅       |      ❌       |        ✅        |
| Custom commands        |                    ✅                    |      ✅       |      ❌       |        ❌        |
| Multi-device           |                    ✅                    |      ❌       |      ✅       |        ❌        |
| Zero-config setup      |              ✅ auto-detect              |   ❌ manual   |      ⚠️       |        ⚠️        |
| macOS + Windows        |                    ✅                    |      ✅       | ⚠️ deprecated |        ✅        |
| Dark + Light theme     |                    ✅                    |      ✅       |      ✅       |        ✅        |
| Active maintenance     |                    ✅                    |    ⚠️ slow    | ❌ deprecated |        ✅        |

> **TL;DR** — One tool to replace Reactotron + Flipper + DevTools. Works with Flutter, React Native, and Android Native. Auto-detects everything.

---

## Features

- **Network Inspector** — HTTP request/response viewer with headers, body (tree + JSON), timing bar, copy as cURL, status badges
- **State Inspector** — Real-time state change timeline with before/after diff for Redux, MobX, Zustand, Jotai, Valtio, XState, BLoC, Riverpod, GetX, Provider, ViewModel, StateFlow, LiveData
- **Console / Logs** — Log viewer with level filters (debug/info/warn/error), search, tags, metadata, stack traces
- **Storage Viewer** — Browse and monitor SharedPreferences, AsyncStorage, Hive, MMKV, SecureStorage, DataStore
- **Database Browser** — SQLite, Drift, Room, Isar table viewer with SQL query editor
- **Performance Profiling** — Real-time FPS, CPU, memory usage charts with jank frame detection
- **Memory Leak Detection** — Detect undisposed controllers, streams, timers, growing collections with severity levels and stack traces
- **Benchmark** — Performance timing with step markers
- **Custom Commands** — Send commands from desktop to app and get results
- **Multi-Device** — Connect multiple apps simultaneously, per-device filtering
- **All Events** — Unified timeline of all events across features
- **Mock Server** — Push mock HTTP responses down to devices, audit every intercepted request with full URL/method/status/rule-name
- **Screenshot** — Full-content screenshot capture of any detail panel
- **ADB Reverse** — One-click USB connection for Android devices
- **Auto-detect** — SDK auto-discovers desktop IP, zero configuration needed
- **Dual Theme** — Dark and light mode

[![Sponsor on GitHub](https://img.shields.io/badge/Sponsor-♥-ea4aaa?logo=github-sponsors)](https://github.com/sponsors/ridelinktechs)

### Screenshots

| All Events                                     | State Inspector                                    |
| ---------------------------------------------- | -------------------------------------------------- |
| ![All Events](docs/screenshots/all-events.png) | ![State Detail](docs/screenshots/state-detail.png) |

| Network Inspector                                  | Network Detail                                         |
| -------------------------------------------------- | ------------------------------------------------------ |
| ![Network List](docs/screenshots/network-list.png) | ![Network Detail](docs/screenshots/network-detail.png) |

| Performance Profiler                             | Benchmark                                    |
| ------------------------------------------------ | -------------------------------------------- |
| ![Performance](docs/screenshots/performance.png) | ![Benchmark](docs/screenshots/benchmark.png) |

| Storage Viewer                           |
| ---------------------------------------- |
| ![Storage](docs/screenshots/storage.png) |

---

## Download

| Platform | File                                              | Architecture   |
| -------- | ------------------------------------------------- | -------------- |
| macOS    | `DevConnectManageTool-macOS-v1.0.1-universal.dmg` | arm64 + x86_64 |
| Windows  | `DevConnectManageTool-Windows-v1.0.1.zip`         | x64            |

Download from [Releases](https://github.com/ridelinktechs/devconnect-manage-kit/releases).

---

## Quick Start

### Flutter — 2 lines

```dart
import 'package:devconnect_manage_kit/devconnect_manage_kit.dart';

void main() async {
  await DevConnect.initAndRunApp(
    appName: 'MyApp',
    runApp: () => runApp(const MyApp()),
  );
  // Done. Network + logs auto-captured.
}
```

### React Native — 1 line

```typescript
import { DevConnect } from "devconnect-manage-kit";

await DevConnect.init({ appName: "MyApp" });
// Done. fetch + XHR + console auto-captured.
```

### Android Native — 1 line

```kotlin
// Application.onCreate()
DevConnect.installForApp(
    context = this,
    appName = "MyApp",
    enabled = BuildConfig.DEBUG,
)
```

That's it. Open DevConnect Manage Tool desktop, run your app, and everything appears.

---

## Desktop App

### Build from source

```bash
git clone https://github.com/ridelinktechs/devconnect-manage-kit.git
cd devconnect
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build macos --release   # macOS
flutter build windows --release # Windows
# Output: build/macos/Build/Products/Release/DevConnectManageTool.app
```

### Features

- Console/Logs - real-time log viewer, level filters, search, clear
- Network Inspector - request/response, headers, body, timing, copy cURL, copy response
- State Inspector - state change timeline, before/after diff, snapshot + restore
- Storage Viewer - SharedPreferences, AsyncStorage, Hive, MMKV, SecureStorage
- Database Viewer - SQLite, Drift, Room, Isar with query editor
- Performance Profiling - real-time FPS, CPU, memory charts with jank detection
- Memory Leak Detection - severity-based leak viewer with stack traces and metadata
- Benchmark - performance timing with steps
- Custom Commands - send commands from desktop to app
- Device Panel - connected devices with platform badge, OS version
- ADB Reverse - one-click for Android USB
- Port Config - change WebSocket port in Settings
- Auto-detect Host - SDK auto-finds desktop IP
- Dual Theme - dark / light

---

## SDKs

Each SDK ships as its own package with a complete install + API guide. Pick yours:

### Flutter — `devconnect_manage_kit`

```yaml
# pubspec.yaml
dependencies:
  devconnect_manage_kit: ^1.0.6
```

- Network (dio, http, GraphQL, gRPC) · State (Riverpod, BLoC, GetX, Provider, ViewModel) · Storage (SharedPreferences, Hive, MMKV) · Database (Drift, Isar, SQLite) · Performance + Memory Leak Detection + Benchmark · Mock server

📖 **[Full Flutter SDK guide →](client_sdks/devconnect_flutter/README.md)**

### React Native — `devconnect-manage-kit`

```bash
npm install devconnect-manage-kit
# or
yarn add devconnect-manage-kit
```

- Network (fetch, XHR, axios, Apollo, urql, TanStack Query, SWR) · State (Redux, MobX, Zustand, Jotai, Valtio, XState) · Storage (AsyncStorage, MMKV) · Performance + Memory Leak Detection + Benchmark · Mock server

📖 **[Full React Native SDK guide →](client_sdks/devconnect-react-native/README.md)**

### Android — `io.github.buivietphi:devconnect-android`

```gradle
// app/build.gradle.kts
dependencies {
    implementation("io.github.buivietphi:devconnect-android:1.1.0")
}
```

- Network (OkHttp, Ktor, Volley) · State (ViewModel/StateFlow/LiveData) · Storage (SharedPreferences, DataStore, MMKV) · Database (Room) · Crash & ANR detection (native signal handler, pre-built in AAR) · Compose, GraphQL, gRPC, WebSocket inspector

> The native crash handler ships inside the AAR — no NDK setup required. Optional deps (OkHttp, lifecycle, kotlin-reflect…) are `compileOnly`; see [Android SDK README → Runtime dependencies](client_sdks/devconnect-android/README.md#runtime-dependencies).

📖 **[Full Android SDK guide →](client_sdks/devconnect-android/README.md)**

See [Architecture](#architecture) for protocol details.

---

## Real Device Connection

### Auto-detect (default)

SDK tries these addresses in order:

1. `localhost` (iOS simulator, macOS)
2. `10.0.2.2` (Android emulator)
3. `10.0.3.2` (Genymotion)
4. Scan local network subnet

### Manual IP

Check your desktop IP in **Settings** page (click to copy), then:

```dart
await DevConnect.init(appName: 'MyApp', host: '192.168.1.5');
```

### Android USB

In desktop **Settings > Android Device (USB)**, click **"Run ADB Reverse"**.

Or manually: `adb reverse tcp:9090 tcp:9090`

---

## Using the Desktop App

### Overview

Open DevConnect, run your app with the SDK — data appears automatically. The sidebar shows all features, the bottom bar shows connected devices.

### Tabs & Features

| Tab              | What it shows                        | Key actions                                                                                                                       |
| ---------------- | ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| **Console**      | Real-time logs from your app         | Filter by level (debug/info/warn/error), search, click to expand                                                                  |
| **Network**      | HTTP requests & responses            | Filter by method (GET/POST/PUT/PATCH/DELETE), filter by source (App/Library/System), click request to see headers + body + timing |
| **State**        | State changes timeline               | Click to see before/after diff, snapshot & restore state                                                                          |
| **Storage**      | Key/value storage entries            | Filter by operation (READ/WRITE/DELETE), filter by type (AS/SP/HV/SQL), click to see full value                                   |
| **Database**     | SQLite tables & queries              | Browse tables, view schema, run SQL queries                                                                                       |
| **Performance**  | Real-time FPS, CPU, memory charts    | Hover for exact values, jank frames highlighted                                                                                   |
| **Memory Leaks** | Detected leaks with severity         | Sorted by severity (critical/warning/info), stack traces                                                                          |
| **Benchmark**    | Timing measurements with steps       | Start/step/stop lifecycle with duration                                                                                           |
| **Mock Server**  | Push mock HTTP responses to device   | Add rule → push to SDK → audit shows every intercepted request                                                                    |
| **All Events**   | Unified timeline across all features | Filter by type, search across everything                                                                                          |

### Mock Server

Replace real network responses with mock data for testing edge cases without touching the backend. The desktop pushes rules down; the SDK intercepts matching requests before they hit the network and audits every hit back to the desktop.

**Creating a rule**

1. Open **Mock Server** tab
2. Click **+ Add rule**
3. Fill in:
   - **Rule name** — human-readable label (e.g. `Get user 404`)
   - **Method** — GET / POST / PUT / PATCH / DELETE
   - **URL pattern** — regex (e.g. `^/api/users/999$`)
   - **Status** — HTTP status code (200, 404, 500, ...)
   - **Response headers** — one per line, `key: value`
   - **Response body** — raw string or JSON
4. Optional wire-only fields:
   - **Delay (ms)** — sleep before returning the mocked response
   - **Scope deviceIds** — comma-separated; empty means every device
   - **Expires at** — ISO-8601 timestamp; rule is ignored past this time
5. Click **Push all** to push the full list, or **Push this** for just the selected rule

**On the device**

No code changes needed. The SDK's `MockServerInterceptor` (already installed alongside `dio` / `axios` / `okHttp` interceptors) listens for `server:mock_rules_update` and caches the rule list in memory. When a matching request fires, the interceptor returns the mocked response immediately — the real network stack is never touched.

**Auditing**

Every intercepted request emits `client:mocked_request` back to the desktop. The Audit panel (inside the Mock Server tab) shows:

- Method + URL pattern that matched
- HTTP status returned
- Rule name (looked up locally by `ruleId`)
- Timestamp

Click any row for the full entry detail.

**Example**

| Field      | Value                       |
| ---------- | --------------------------- |
| Name       | Get user 404                |
| Method     | GET                         |
| URL        | `^/api/users/999$`          |
| Status     | 404                         |
| Body       | `{"error":"not found"}`     |
| Delay      | 500                         |

In the app, calling `GET /api/users/999` returns 404 instantly with the mock body — the desktop audit row appears the moment the SDK intercepts it.

### Toolbar Controls

Every list page has these controls in the toolbar:

- **Filter chips** — Click to filter (single-select for methods, multi-select for types)
- **Search** — Filter by text content
- **Auto-scroll** — Pin to newest entries (click to toggle)
- **Sort direction** — Newest first or oldest first
- **Clear** — Delete all entries (trash icon)

### Multi-Device

When multiple apps are connected, use the device selector in the bottom bar to filter by device or view "All Devices".

### Settings

- **Server** — Start/stop WebSocket server, change port (default: 9090)
- **Network IPs** — Your desktop IP addresses (click to copy)
- **ADB Reverse** — One-click USB setup for Android
- **Appearance** — Dark/light theme, scroll direction
- **Tab Visibility** — Show/hide tabs you don't need

---

## Production Safety

All SDKs are **disabled by default in production builds** — zero runtime overhead.

| SDK          | Guard               | Behavior in production                             |
| ------------ | ------------------- | -------------------------------------------------- |
| Flutter      | `kDebugMode`        | Returns immediately, no WebSocket, no interceptors |
| React Native | `__DEV__`           | Creates dummy instance, all methods are no-ops     |
| Android      | `BuildConfig.DEBUG` | Returns immediately, nothing initialized           |

You can also manually disable:

```dart
DevConnect.init(appName: 'MyApp', enabled: false);  // Flutter
```

```typescript
DevConnect.init({ appName: "MyApp", enabled: false }); // React Native
```

```kotlin
DevConnect.init(context = this, appName = "MyApp", enabled = false)  // Android
```

**No need to remove SDK code for release builds.** The compiler strips dead code paths automatically.

---

## Architecture

- **Desktop**: Flutter Desktop (macOS/Windows) + Riverpod + go_router + Freezed
- **Protocol**: JSON over WebSocket (default port 9090)
- **SDKs**: Flutter (pub.dev), React Native (npm), Android (Maven Central — AAR)

## Contributing

DevConnect Manage Kit is **open source** under the [MIT License](LICENSE). Contributions are welcome!

### How to contribute

1. Fork the repo
2. Create your branch (`git checkout -b feature/my-feature`)
3. Commit changes (`git commit -m 'feat: add my feature'`)
4. Push (`git push origin feature/my-feature`)
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

---

## Related Projects & Alternatives

Looking for mobile debugging tools? Here's how DevConnect compares:

- **[Reactotron](https://github.com/infinitered/reactotron)** — Great for React Native + Redux, but no Flutter/Android support. DevConnect covers all three.
- **[Flipper](https://github.com/facebook/flipper)** — Facebook's extensible debugger, now deprecated. DevConnect is actively maintained.
- **[Flutter DevTools](https://docs.flutter.dev/tools/devtools)** — Official Flutter debugging, but no React Native or Android Native. DevConnect adds cross-platform support.

> Searching for: _reactotron alternative_, _flipper replacement_, _flutter debugging tool_, _react native debugger_, _android debug inspector_, _mobile app debugger_, _cross-platform debugging_, _network inspector_, _state debugger_, _redux devtools mobile_? DevConnect is built for you.

---

## Support DevConnect Manage Kit

DevConnect Manage Kit is free and open source. If it saves you debugging time, consider supporting development:

<div align="center">

[![GitHub Sponsors](https://img.shields.io/badge/GitHub-Sponsor-EA4AAA?logo=github&logoColor=white)](https://github.com/sponsors/ridelinktechs)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/buivietphi)
[![PayPal](https://img.shields.io/badge/PayPal-Donate-0070BA?logo=paypal&logoColor=white)](https://paypal.me/buivietphi)

</div>

---

## License

**MIT License** — Everything in this repository (desktop app + all SDKs) is free
for any use, including commercial. Use it, modify it, ship it — no restrictions.

```
MIT License

Copyright (c) 2026 MTI ridelinktechs

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
```

See [LICENSE](LICENSE) and [client_sdks/*/LICENSE](client_sdks/) for the full text.

---

<div align="center">

**DevConnect Manage Tool** — Debug Flutter, React Native & Android apps from one desktop tool.

_A modern alternative to Reactotron, Flipper, and platform-specific debugging tools._

</div>
