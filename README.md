<div align="center">

# DevConnect Manage Kit

### A modern, cross-platform manage and debug tool — alternative to Reactotron and Flipper

**Debug Flutter, React Native & Android apps — network, state, logs, storage, database — all in one beautiful desktop tool.**

[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Windows-blue)](https://github.com/ridelinktechs/devconnect-manage-kit/releases)
[![Flutter](https://img.shields.io/badge/Flutter-SDK-02569B?logo=flutter)](client_sdks/devconnect_manage_kit)
[![React Native](https://img.shields.io/badge/React%20Native-SDK-61DAFB?logo=react)](client_sdks/devconnect-manage-kit)
[![Android](https://img.shields.io/badge/Android-SDK-3DDC84?logo=android)](client_sdks/devconnect-manage-android)
[![License](https://img.shields.io/badge/License-Free%20Non--Commercial-green.svg)](LICENSE)

[Features](#features) · [Download](#download) · [Quick Start](#quick-start) · [Desktop Guide](#using-the-desktop-app) · [SDKs](#flutter-sdk) · [Support](#support-devconnect-manage-kit)

</div>

---

## Why DevConnect Manage Kit?

If you've used **Reactotron**, **Flipper**, or **Flutter DevTools** — you know they're powerful but limited to one framework. DevConnect Manage Kit is a **single desktop app** that works with all of them.

| | DevConnect Manage Kit | Reactotron | Flipper | Flutter DevTools |
|---|:---:|:---:|:---:|:---:|
| Flutter support | ✅ | ❌ | ⚠️ plugin | ✅ |
| React Native support | ✅ | ✅ | ✅ | ❌ |
| Android Native support | ✅ | ❌ | ✅ | ❌ |
| Network inspector | ✅ | ✅ | ✅ | ✅ |
| State debugging | ✅ Redux/MobX/Zustand/BLoC/Riverpod/GetX | ✅ Redux/MobX | ✅ | ❌ |
| Log viewer | ✅ | ✅ | ✅ | ✅ |
| Storage viewer | ✅ | ✅ | ✅ | ❌ |
| Database browser | ✅ | ❌ | ✅ | ❌ |
| Performance profiling | ✅ FPS/CPU/Memory/Jank | ❌ | ❌ | ✅ |
| Memory leak detection | ✅ | ❌ | ❌ | ✅ |
| Benchmark timing | ✅ | ✅ | ❌ | ✅ |
| Custom commands | ✅ | ✅ | ❌ | ❌ |
| Multi-device | ✅ | ❌ | ✅ | ❌ |
| Zero-config setup | ✅ auto-detect | ❌ manual | ⚠️ | ⚠️ |
| macOS + Windows | ✅ | ✅ | ⚠️ deprecated | ✅ |
| Dark + Light theme | ✅ | ✅ | ✅ | ✅ |
| Active maintenance | ✅ | ⚠️ slow | ❌ deprecated | ✅ |

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
- **Screenshot** — Full-content screenshot capture of any detail panel
- **ADB Reverse** — One-click USB connection for Android devices
- **Auto-detect** — SDK auto-discovers desktop IP, zero configuration needed
- **Dual Theme** — Dark and light mode

### Screenshots

| All Events | State Inspector |
|---|---|
| ![All Events](docs/screenshots/all-events.png) | ![State Detail](docs/screenshots/state-detail.png) |

| Network Inspector | Network Detail |
|---|---|
| ![Network List](docs/screenshots/network-list.png) | ![Network Detail](docs/screenshots/network-detail.png) |

| Performance Profiler | Benchmark |
|---|---|
| ![Performance](docs/screenshots/performance.png) | ![Benchmark](docs/screenshots/benchmark.png) |

| Storage Viewer |
|---|
| ![Storage](docs/screenshots/storage.png) |

---

## Download

| Platform | File | Architecture |
|----------|------|-------------|
| macOS | `DevConnectManageTool-macOS-v1.0.1-universal.dmg` | arm64 + x86_64 |
| Windows | `DevConnectManageTool-Windows-v1.0.1.zip` | x64 |

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
import { DevConnect } from 'devconnect-manage-kit';

await DevConnect.init({ appName: 'MyApp' });
// Done. fetch + XHR + console auto-captured.
```

### Android Native — 1 line

```kotlin
// Application.onCreate()
DevConnect.init(context = this, appName = "MyApp")
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

## Flutter SDK

### Install

```bash
# From pub.dev (after published)
flutter pub add devconnect_manage_kit
```

Or from GitHub:

```yaml
# pubspec.yaml
dependencies:
  devconnect_manage_kit:
    git:
      url: https://github.com/ridelinktechs/devconnect-manage-kit.git
      path: client_sdks/devconnect_manage_kit
```

### Init

```dart
import 'package:devconnect_manage_kit/devconnect_manage_kit.dart';

void main() async {
  // Auto-detect: captures all HTTP + logs automatically
  await DevConnect.initAndRunApp(
    appName: 'MyApp',
    runApp: () => runApp(const MyApp()),
  );
}
```

### Config

```dart
await DevConnect.initAndRunApp(
  appName: 'MyApp',
  runApp: () => runApp(const MyApp()),
  appVersion: '1.0.0',
  host: null,                  // null = auto-detect, '192.168.1.100' = manual
  port: 9090,                  // default: 9090
  enabled: true,               // false = disable (production)
  autoInterceptHttp: true,     // auto-capture all HTTP (default: true)
  autoInterceptLogs: true,     // auto-capture print/debugPrint (default: true)
);
```

### Manual Setup

> `initAndRunApp()` already calls `init()` + `httpOverrides()` + `runZoned()` internally.
> Only use manual setup if you need to control each step separately (e.g., custom HttpOverrides, custom Zone, or init without runApp).

```dart
void main() async {
  // Step 1: Connect to DevConnect Manage Tool desktop (WebSocket)
  await DevConnect.init(appName: 'MyApp');

  // Step 2: Intercept ALL HTTP globally (http, Dio, Chopper, etc.)
  // Skip if you already have a custom HttpOverrides
  HttpOverrides.global = DevConnect.httpOverrides();

  // Step 3: Capture print/debugPrint logs via Zone + run app
  DevConnect.runZoned(() => runApp(const MyApp()));
}
```

### Network

Auto-captured via `HttpOverrides`: http, Dio, Chopper, Retrofit, GraphQL, Firebase, OAuth2, gRPC-web, Image.network.

```dart
// Dio (optional, for extra detail)
dio.interceptors.add(DevConnect.dioInterceptor());

// GetX GetConnect
final connect = GetConnect();
connect.httpClient.addRequestModifier(DevConnect.getConnectModifier());
connect.httpClient.addResponseModifier(DevConnect.getConnectResponseModifier());
```

### Logs

Auto-captured via Zone: print, debugPrint, logger, talker, logging, fimber, simple_logger.

```dart
// Manual
DevConnect.log('User logged in');
DevConnect.debug('Token refreshed', tag: 'Auth');
DevConnect.warn('Rate limit approaching');
DevConnect.error('Payment failed', stackTrace: StackTrace.current.toString());

// Tagged logger
final logger = DevConnect.logger('AuthService');
logger.info('Login success');

// Loggy
final printer = DevConnect.loggyPrinter();
```

### State

```dart
// Riverpod
class DevConnectObserver extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderBase p, Object? prev, Object? next, ProviderContainer c) {
    DevConnect.reportStateChange(
      stateManager: 'riverpod',
      action: '${p.name ?? p.runtimeType} updated',
      previousState: {'value': prev.toString()},
      nextState: {'value': next.toString()},
    );
  }
}

// main.dart
runApp(
  ProviderScope(
    observers: [DevConnectObserver()],
    child: const MyApp(),
  ),
);
```

```dart
// BLoC
class DevConnectBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    DevConnect.reportStateChange(
      stateManager: 'bloc',
      action: '${bloc.runtimeType} changed',
      previousState: {'state': change.currentState.toString()},
      nextState: {'state': change.nextState.toString()},
    );
  }
}

// main.dart
Bloc.observer = DevConnectBlocObserver();
```

```dart
// Provider / ChangeNotifier
class MyModel extends ChangeNotifier {
  String _name = '';
  set name(String val) {
    final prev = _name;
    _name = val;
    notifyListeners();
    DevConnect.reportStateChange(
      stateManager: 'provider',
      action: 'name changed',
      previousState: {'name': prev},
      nextState: {'name': val},
    );
  }
}
```

```dart
// GetX
class MyController extends GetxController {
  final count = 0.obs;

  void increment() {
    final prev = count.value;
    count.value++;
    DevConnect.reportStateChange(
      stateManager: 'getx',
      action: 'increment',
      previousState: {'count': prev},
      nextState: {'count': count.value},
    );
  }
}
```

```dart
// MobX
final counter = Observable(0);
autorun((_) {
  DevConnect.reportStateChange(
    stateManager: 'mobx',
    action: 'counter changed',
    nextState: {'counter': counter.value},
  );
});
```

```dart
// Signals
final observer = DevConnect.signalsObserver();
observer.observe(mySignal, 'counterSignal');
```

### Storage

```dart
// SharedPreferences
final reporter = DevConnect.sharedPreferencesReporter();
reporter.reportWrite('token', 'abc123');
reporter.reportRead('token', 'abc123');
reporter.reportDelete('token');

// Hive
final hiveReporter = DevConnect.hiveReporter();
hiveReporter.reportWrite('settings', {'darkMode': true});

// flutter_secure_storage
final secureReporter = DevConnect.secureStorageReporter();
secureReporter.reportWrite('token', 'secret');
secureReporter.reportRead('token', '***');

// MMKV
final mmkvReporter = DevConnect.mmkvReporter();
mmkvReporter.reportWrite('key', 'value');
mmkvReporter.reportRead('key', 'value');
```

### Database

```dart
// Drift
final driftReporter = DevConnect.driftReporter();
driftReporter.reportQuery('SELECT * FROM users', results);

// Drift auto-intercept
final executor = DevConnect.driftQueryExecutor(innerExecutor);

// Isar
final isarReporter = DevConnect.isarReporter();
isarReporter.reportQuery('User', results);
isarReporter.reportPut('User', {'name': 'John'});
```

### Performance Profiling

```dart
// Report FPS
DevConnect.reportPerformanceMetric(
  metricType: 'fps',
  value: 58.5,
  label: 'Main Thread FPS',
);

// Report memory usage (MB)
DevConnect.reportPerformanceMetric(
  metricType: 'memory_usage',
  value: 142.3,
  label: 'Dart Heap',
);

// Report CPU usage (%)
DevConnect.reportPerformanceMetric(
  metricType: 'cpu_usage',
  value: 35.2,
);

// Report jank frame (build time in ms)
DevConnect.reportPerformanceMetric(
  metricType: 'jank_frame',
  value: 32.1,
  label: 'Slow build in ListView',
);
```

Available metric types: `fps`, `frame_build_time`, `frame_raster_time`, `memory_usage`, `memory_peak`, `cpu_usage`, `jank_frame`.

### Memory Leak Detection

```dart
// Report undisposed controller
DevConnect.reportMemoryLeak(
  leakType: 'undisposed_controller',
  severity: 'warning',
  objectName: 'AnimationController',
  detail: 'AnimationController not disposed in ProfileScreen',
  retainedSizeBytes: 2048,
  stackTrace: StackTrace.current.toString(),
);

// Report growing collection
DevConnect.reportMemoryLeak(
  leakType: 'growing_collection',
  severity: 'critical',
  objectName: 'eventCache',
  detail: 'List grows unbounded — 15000 items, expected < 100',
  retainedSizeBytes: 1200000,
  metadata: {'currentSize': 15000, 'maxExpected': 100},
);
```

Available leak types: `undisposed_controller`, `undisposed_stream`, `undisposed_timer`, `undisposed_animation_controller`, `widget_leak`, `growing_collection`, `custom`.

Severity levels: `info`, `warning`, `critical`.

### Benchmark

```dart
DevConnect.benchmarkStart('loadHome');
await fetchUser();
DevConnect.benchmarkStep('loadHome');
await fetchPosts();
DevConnect.benchmarkStop('loadHome');
```

### Custom Commands

```dart
DevConnect.registerCommand('clearCache', (args) {
  return {'cleared': true};
});
```

### State Snapshot + Restore

```dart
// Send a state snapshot to desktop
DevConnect.sendStateSnapshot(
  stateManager: 'riverpod',
  state: {'counter': 42, 'user': userMap},
);

// Handle state restore from desktop
DevConnect.onStateRestore = (state) {
  ref.read(appStateProvider.notifier).restore(state);
};
```

### Connection Management

```dart
// Check connection status
if (DevConnect.isConnected) {
  print('Connected to DevConnect desktop');
}

// Disconnect
await DevConnect.disconnect();
```

### Navigation

```dart
MaterialApp(navigatorObservers: [DevConnect.navigationObserver()])
GoRouter(observers: [DevConnect.navigationObserver()])
```

---

## React Native SDK

### Install

```bash
# From npm (after published)
yarn add devconnect-manage-kit
# or
npm install devconnect-manage-kit
```

Or from GitHub:

```bash
yarn add github:ridelinktechs/devconnect-manage-kit#main
```

### Init

```typescript
import { DevConnect } from 'devconnect-manage-kit';

await DevConnect.init({ appName: 'MyApp' });
// Auto-captures: fetch, XHR, console.log/warn/error
```

### Config

```typescript
await DevConnect.init({
  appName: 'MyApp',
  appVersion: '1.0.0',
  host: undefined,            // undefined = auto-detect, '192.168.1.100' = manual
  port: 9090,                 // default: 9090
  enabled: __DEV__,           // false in production
  autoInterceptFetch: true,
  autoInterceptXHR: true,
  autoInterceptConsole: true,
});
```

### Network

Auto-captured: fetch, XHR, axios, got, ky, superagent, apisauce, Apollo, urql, TanStack Query, SWR, RTK Query, ofetch, wretch, redaxios, Firebase, OAuth2.

```typescript
// Axios (optional, for extra tagging)
import { setupAxiosInterceptor } from 'devconnect-manage-kit';
setupAxiosInterceptor(axios);
```

### Logs

Auto-captured: console.log, console.debug, console.info, console.warn, console.error, console.trace. Also auto-captures: consola, debug, tslog, signale (they use console internally).

```typescript
// Manual
DevConnect.log('User logged in');
DevConnect.debug('Debug info', 'Auth');
DevConnect.warn('Warning');
DevConnect.error('Error', 'Tag', stackTrace);

// react-native-logs
import { devConnectTransport } from 'devconnect-manage-kit';
const log = logger.createLogger({ transport: [consoleTransport, devConnectTransport] });

// loglevel
import { patchLoglevel } from 'devconnect-manage-kit';
patchLoglevel(log);

// pino
import { pinoDevConnectTransport } from 'devconnect-manage-kit';
const logger = pino({}, pinoDevConnectTransport());

// winston
import { winstonDevConnectTransport } from 'devconnect-manage-kit';

// bunyan
import { bunyanDevConnectStream } from 'devconnect-manage-kit';

// Any custom logger
import { wrapLogger } from 'devconnect-manage-kit';
const wrapped = wrapLogger(myLogger, 'myLoggerName');
```

### State

```typescript
// Redux - Classic createStore
import { createStore, applyMiddleware, compose } from 'redux';
import { devConnectReduxMiddleware } from 'devconnect-manage-kit';
import { DevConnect } from 'devconnect-manage-kit';

let store;
if (__DEV__) {
  store = createStore(
    rootReducer,
    compose(applyMiddleware(thunkMiddleware, devConnectReduxMiddleware))
  );
  // Allow desktop to dispatch actions into the app
  DevConnect.connectReduxStore(store);
} else {
  store = createStore(rootReducer, applyMiddleware(thunkMiddleware));
}
```

```typescript
// Redux Toolkit
import { configureStore } from '@reduxjs/toolkit';
import { devConnectReduxMiddleware } from 'devconnect-manage-kit';
import { DevConnect } from 'devconnect-manage-kit';

const store = configureStore({
  reducer: rootReducer,
  middleware: (getDefault) =>
    __DEV__
      ? getDefault().concat(devConnectReduxMiddleware)
      : getDefault(),
});

if (__DEV__) DevConnect.connectReduxStore(store);
```

```typescript
// MobX
import { spy } from 'mobx';
import { setupMobxSpy } from 'devconnect-manage-kit';

if (__DEV__) {
  setupMobxSpy(spy); // reports all observable changes
}
```

```typescript
// Zustand
import { create } from 'zustand';
import { devConnectMiddleware } from 'devconnect-manage-kit';

// Wrap your store creator with devConnectMiddleware
const useStore = create(
  devConnectMiddleware(
    (set) => ({
      count: 0,
      name: '',
      increment: () => set((s) => ({ count: s.count + 1 })),
      setName: (name: string) => set({ name }),
    }),
    'CounterStore' // label shown in DevConnect desktop
  )
);
```

```typescript
// Jotai
import { atom, createStore } from 'jotai';
import { watchAtom } from 'devconnect-manage-kit';

const countAtom = atom(0);
const store = createStore();

if (__DEV__) {
  // Watches atom and reports every value change
  const unsub = watchAtom(store, countAtom, 'countAtom');
  // unsub() to stop watching
}
```

```typescript
// Valtio
import { proxy } from 'valtio';
import { watchValtio } from 'devconnect-manage-kit';

const state = proxy({ count: 0, user: { name: '' } });

if (__DEV__) {
  watchValtio(state, 'AppState'); // reports all proxy mutations
}
```

```typescript
// XState
import { interpret } from 'xstate';
import { devConnectXStateInspector } from 'devconnect-manage-kit';

const service = interpret(toggleMachine);

if (__DEV__) {
  // Reports every state transition (event, from, to, context)
  service.onTransition(devConnectXStateInspector('ToggleMachine'));
}

service.start();
```

### Storage

```typescript
// AsyncStorage
import { DevConnectAsyncStorage } from 'devconnect-manage-kit';
DevConnectAsyncStorage.patchInPlace(AsyncStorage);

// MMKV
import { DevConnectMMKV } from 'devconnect-manage-kit';
DevConnectMMKV.wrap(storage);
```

### Performance Profiling

```typescript
// Report FPS
DevConnect.reportPerformanceMetric({
  metricType: 'fps',
  value: 58.5,
  label: 'JS Thread FPS',
});

// Report memory usage (MB)
DevConnect.reportPerformanceMetric({
  metricType: 'memory_usage',
  value: 142.3,
  label: 'JS Heap',
});

// Report CPU usage (%)
DevConnect.reportPerformanceMetric({
  metricType: 'cpu_usage',
  value: 35.2,
});

// Report jank frame (ms)
DevConnect.reportPerformanceMetric({
  metricType: 'jank_frame',
  value: 32.1,
  label: 'Slow render in FlatList',
});
```

### Memory Leak Detection

```typescript
// Report undisposed subscription
DevConnect.reportMemoryLeak({
  leakType: 'undisposed_stream',
  severity: 'warning',
  objectName: 'UserDataSubscription',
  detail: 'EventEmitter listener not removed in ProfileScreen',
  retainedSizeBytes: 2048,
  stackTrace: new Error().stack,
});

// Report growing collection
DevConnect.reportMemoryLeak({
  leakType: 'growing_collection',
  severity: 'critical',
  objectName: 'eventCache',
  detail: 'Array grows unbounded — 15000 items, expected < 100',
  retainedSizeBytes: 1200000,
  metadata: { currentSize: 15000, maxExpected: 100 },
});
```

### Tagged Logger

```typescript
const logger = DevConnect.logger('AuthService');
logger.log('User logged in');
logger.debug('Token refreshed');
logger.warn('Session expiring');
logger.error('Login failed', error.stack);
```

### Manual Network Reporting

```typescript
// When auto-interception is disabled or for custom transports
const requestId = 'req-123';

DevConnect.reportNetworkStart({
  requestId,
  method: 'POST',
  url: 'https://api.example.com/data',
  headers: { 'Content-Type': 'application/json' },
  body: { name: 'John' },
});

// After response
DevConnect.reportNetworkComplete({
  requestId,
  method: 'POST',
  url: 'https://api.example.com/data',
  statusCode: 200,
  startTime: 1711180800000,
  responseBody: { success: true },
});
```

### Benchmark

```typescript
DevConnect.benchmark('loadUserData');
await fetchUser();
DevConnect.benchmarkStep('loadUserData', 'fetched user');
await fetchPosts();
DevConnect.benchmarkStop('loadUserData');
```

### Custom Commands

```typescript
DevConnect.registerCommand('clearCache', () => {
  AsyncStorage.clear();
  return { success: true };
});
```

### State Snapshot + Restore

```typescript
DevConnect.sendStateSnapshot('redux', store.getState());
DevConnect.onStateRestore((state) => {
  store.dispatch({ type: 'RESTORE_STATE', payload: state });
});
```

### Connection Management

```typescript
// Check connection status
if (DevConnect.isConnected()) {
  console.log('Connected to DevConnect desktop');
}

// Disconnect
DevConnect.disconnect();
```

---

## Android Native SDK

### Install

```gradle
// From Maven Central (after published)
dependencies {
    implementation("com.ridelink:devconnect-manage-android:1.0.0")
}
```

Or from JitPack (GitHub):

```gradle
// settings.gradle.kts
dependencyResolutionManagement {
    repositories {
        maven { url = uri("https://jitpack.io") }
    }
}

// app/build.gradle.kts
dependencies {
    implementation("com.github.ridelinktechs.devconnect:devconnect-manage-android:v1.0.0")
}
```

Or AAR file from [Releases](https://github.com/ridelinktechs/devconnect-manage-kit/releases):

```gradle
dependencies {
    implementation(files("libs/devconnect-manage-android-1.0.0.aar"))
}
```

### Init

```kotlin
class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()
        DevConnect.init(
            context = this,
            appName = "MyApp",
        )
    }
}
```

### Config

```kotlin
DevConnect.init(
    context = this,
    appName = "MyApp",
    appVersion = "1.0.0",
    host = null,                    // null = auto-detect, "192.168.1.100" = manual
    port = 9090,                    // default: 9090
    enabled = BuildConfig.DEBUG,    // false in release
    autoInterceptLogs = true,       // auto-capture println() (default: false)
)
```

### Network

```kotlin
// OkHttp (captures Retrofit, Firebase, OAuth2, Glide, Coil)
val client = OkHttpClient.Builder()
    .addInterceptor(DevConnect.okHttpInterceptor())
    .build()

// Ktor
val client = HttpClient {
    install(DevConnect.ktorPlugin())
}

// Volley
val stack = object : HurlStack() {
    override fun createConnection(url: URL): HttpURLConnection {
        return DevConnectHttpURLConnection.wrap(super.createConnection(url))
    }
}
```

### Logs

```kotlin
// Drop-in replacement for android.util.Log
// Change: import android.util.Log -> import com.devconnect.interceptors.DCLog as Log
// All existing Log.d/i/w/e calls will send to both Logcat AND DevConnect
import com.devconnect.interceptors.DCLog as Log

Log.d("MyTag", "Hello")       // -> Logcat + DevConnect
Log.e("MyTag", "Error", exception)
Log.w("MyTag", "Warning")
```

```kotlin
// Timber - add DevConnect tree alongside DebugTree
import com.devconnect.interceptors.DevConnectTimberHelper

class DevConnectTree : Timber.Tree() {
    override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
        DevConnectTimberHelper.log(priority, tag, message, t)
    }
}

// Application.onCreate()
Timber.plant(Timber.DebugTree())    // keep normal logcat
Timber.plant(DevConnectTree())       // add DevConnect reporting
```

```kotlin
// Intercept all println() calls
DevConnectLogInterceptor.interceptSystemOut()
```

```kotlin
// Kermit (KMP) - add DevConnect log writer
import co.touchlab.kermit.Logger
Logger.addLogWriter(DevConnect.kermitWriter())
```

```kotlin
// Napier (KMP) - set DevConnect as antilog
import io.github.aakira.napier.Napier
Napier.base(DevConnect.napierAntilog())
```

```kotlin
// Manual logging
DevConnect.sendLog("info", "User logged in", tag = "Auth")
DevConnect.sendLog("error", "Payment failed", tag = "Payment", stackTrace = e.stackTraceToString())
```

### State

```kotlin
// ViewModel + StateFlow
class MyViewModel : ViewModel() {
    private val _state = MutableStateFlow(UserState())
    val state = _state.asStateFlow()

    fun updateName(name: String) {
        val prev = _state.value
        _state.value = prev.copy(name = name)
        DevConnectViewModelObserver.reportStateUpdate(
            viewModelName = "MyViewModel",
            action = "updateName",
            previousState = mapOf("name" to prev.name),
            nextState = mapOf("name" to name),
        )
    }
}
```

```kotlin
// Auto-observe StateFlow (reports every change automatically)
val observer = DevConnect.stateObserver()
observer.observe(viewLifecycleOwner.lifecycleScope, viewModel.state, "UserState")
```

```kotlin
// Auto-observe LiveData
val observer = DevConnect.stateObserver()
observer.observe(viewLifecycleOwner, viewModel.userLiveData, "UserLiveData")
```

### Storage

```kotlin
// SharedPreferences
val reporter = DevConnect.sharedPrefsReporter()
reporter.reportWrite("token", "abc123")
reporter.reportRead("token", "abc123")
reporter.reportDelete("token")

// DataStore
val dsReporter = DevConnect.dataStoreReporter()
dsReporter.reportWrite("darkMode", true)
dsReporter.reportRead("darkMode", true)

// MMKV
val mmkvReporter = DevConnect.mmkvReporter()
mmkvReporter.reportWrite("key", "value")
mmkvReporter.reportRead("key", "value")
```

### Database

```kotlin
// Room
val roomReporter = DevConnect.roomReporter()
roomReporter.reportQuery("SELECT * FROM users", results)
roomReporter.reportInsert("users", rowId)
```

### Performance Profiling

```kotlin
// Report FPS
DevConnect.reportPerformanceMetric(
    metricType = "fps",
    value = 58.5,
    label = "Main Thread FPS"
)

// Report memory usage (MB)
DevConnect.reportPerformanceMetric(
    metricType = "memory_usage",
    value = 142.3,
    label = "Heap Used"
)

// Report CPU usage (%)
DevConnect.reportPerformanceMetric(
    metricType = "cpu_usage",
    value = 35.2
)

// Report jank frame (ms)
DevConnect.reportPerformanceMetric(
    metricType = "jank_frame",
    value = 32.1,
    label = "Slow render in RecyclerView"
)
```

### Memory Leak Detection

```kotlin
// Report undisposed listener (integrates well with LeakCanary)
DevConnect.reportMemoryLeak(
    leakType = "undisposed_stream",
    severity = "warning",
    objectName = "LocationListener",
    detail = "LocationManager listener not removed in MapsActivity",
    retainedSizeBytes = 4096
)

// Report Activity leak (e.g. from LeakCanary)
DevConnect.reportMemoryLeak(
    leakType = "widget_leak",
    severity = "critical",
    objectName = "DetailActivity",
    detail = "Activity retained after onDestroy",
    stackTrace = leakTrace.toString()
)

// Report growing collection
DevConnect.reportMemoryLeak(
    leakType = "growing_collection",
    severity = "critical",
    objectName = "eventCache",
    detail = "ArrayList grows unbounded — 15000 items",
    retainedSizeBytes = 1200000,
    metadata = mapOf("currentSize" to 15000, "maxExpected" to 100)
)
```

### Benchmark

```kotlin
DevConnect.benchmarkStart("loadHome")
fetchUser()
DevConnect.benchmarkStep("loadHome")
fetchPosts()
DevConnect.benchmarkStop("loadHome")
```

### Custom Commands

```kotlin
DevConnect.registerCommand("clearCache") { args ->
    mapOf("cleared" to true)
}
```

### State Snapshot + Restore

```kotlin
// Send a state snapshot to desktop
DevConnect.sendStateSnapshot("viewmodel", mapOf("user" to userMap))

// Handle state restore from desktop
DevConnect.onStateRestore = { state ->
    viewModel.restoreState(state)
}
```

### Connection Management

```kotlin
// Check connection status
if (DevConnect.isConnected()) {
    Log.d("DC", "Connected to DevConnect desktop")
}

// Disconnect
DevConnect.disconnect()
```

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

| Tab | What it shows | Key actions |
|-----|---------------|-------------|
| **Console** | Real-time logs from your app | Filter by level (debug/info/warn/error), search, click to expand |
| **Network** | HTTP requests & responses | Filter by method (GET/POST/PUT/PATCH/DELETE), filter by source (App/Library/System), click request to see headers + body + timing |
| **State** | State changes timeline | Click to see before/after diff, snapshot & restore state |
| **Storage** | Key/value storage entries | Filter by operation (READ/WRITE/DELETE), filter by type (AS/SP/HV/SQL), click to see full value |
| **Database** | SQLite tables & queries | Browse tables, view schema, run SQL queries |
| **Performance** | Real-time FPS, CPU, memory charts | Hover for exact values, jank frames highlighted |
| **Memory Leaks** | Detected leaks with severity | Sorted by severity (critical/warning/info), stack traces |
| **Benchmark** | Timing measurements with steps | Start/step/stop lifecycle with duration |
| **All Events** | Unified timeline across all features | Filter by type, search across everything |

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

| SDK | Guard | Behavior in production |
|-----|-------|----------------------|
| Flutter | `kDebugMode` | Returns immediately, no WebSocket, no interceptors |
| React Native | `__DEV__` | Creates dummy instance, all methods are no-ops |
| Android | `BuildConfig.DEBUG` | Returns immediately, nothing initialized |

You can also manually disable:

```dart
DevConnect.init(appName: 'MyApp', enabled: false);  // Flutter
```

```typescript
DevConnect.init({ appName: 'MyApp', enabled: false });  // React Native
```

```kotlin
DevConnect.init(context = this, appName = "MyApp", enabled = false)  // Android
```

**No need to remove SDK code for release builds.** The compiler strips dead code paths automatically.

---

## Architecture

- **Desktop**: Flutter Desktop (macOS/Windows) + Riverpod + go_router + Freezed
- **Protocol**: JSON over WebSocket (default port 9090)
- **SDKs**: Flutter (pub.dev / git), React Native (npm / git), Android (Maven / JitPack / AAR)

---

## Support DevConnect Manage Kit

DevConnect Manage Kit is free and open source. If it saves you debugging time, consider supporting development:

<div align="center">

[![GitHub Sponsors](https://img.shields.io/badge/GitHub-Sponsor-EA4AAA?logo=github&logoColor=white)](https://github.com/sponsors/buivietphi)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/buivietphi)
[![PayPal](https://img.shields.io/badge/PayPal-Donate-0070BA?logo=paypal&logoColor=white)](https://paypal.me/buivietphi)

</div>

Scan QR code to donate via MoMo or ZaloPay:

| MoMo | ZaloPay |
|:---:|:---:|
| <img src="docs/donate/momo-qr.jpeg" width="200"> | <img src="docs/donate/zalopay-qr.jpeg" width="200"> |

---

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

> Searching for: *reactotron alternative*, *flipper replacement*, *flutter debugging tool*, *react native debugger*, *android debug inspector*, *mobile app debugger*, *cross-platform debugging*, *network inspector*, *state debugger*, *redux devtools mobile*? DevConnect is built for you.

---

## License

| Component | License | Commercial use |
|---|---|---|
| **Client SDKs** (Flutter, React Native, Android) | MIT | Free, no restrictions |
| **Desktop Application** (source code) | Custom Non-Commercial | Requires paid license |

**SDKs** — Use freely in any project, including commercial apps. See [client_sdks/*/LICENSE](client_sdks/).

**Desktop App** — Free for personal, educational, and open-source use. Commercial use requires written permission. Contact [buivietphi](https://github.com/buivietphi) for commercial licensing. See [LICENSE](LICENSE).

---

<div align="center">

**DevConnect Manage Tool** — Debug Flutter, React Native & Android apps from one desktop tool.

*A modern alternative to Reactotron, Flipper, and platform-specific debugging tools.*

[![GitHub Sponsors](https://img.shields.io/badge/GitHub-Sponsor-EA4AAA?logo=github&logoColor=white)](https://github.com/sponsors/buivietphi) [![Ko-fi](https://img.shields.io/badge/Ko--fi-Support-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/buivietphi) [![PayPal](https://img.shields.io/badge/PayPal-Donate-0070BA?logo=paypal&logoColor=white)](https://paypal.me/buivietphi)

</div>
