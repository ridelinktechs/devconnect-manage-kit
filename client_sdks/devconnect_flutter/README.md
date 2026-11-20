# DevConnect Manage Kit — Flutter SDK

[![pub.dev](https://img.shields.io/pub/v/devconnect_manage_kit)](https://pub.dev/packages/devconnect_manage_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](../../LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.0-02569B?logo=flutter)](https://flutter.dev)

Debug your Flutter app with [DevConnect Manage Tool](https://github.com/ridelinktechs/devconnect-manage-kit) — network, state, logs, storage, database, performance — all in one desktop tool.

## Install

```yaml
# pubspec.yaml
dependencies:
  devconnect_manage_kit: ^1.0.5
```

## Quick Start

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

## Config

```dart
await DevConnect.initAndRunApp(
  appName: 'MyApp',
  runApp: () => runApp(const MyApp()),
  appVersion: '1.0.0',
  host: null,                  // null = auto-detect, '192.168.1.5' = manual
  port: 9090,                  // default: 9090
  enabled: true,               // false = disable (production)
  autoInterceptHttp: true,     // true = auto-capture all HTTP requests
  autoInterceptLogs: true,     // true = auto-capture print/debugPrint
);
```

Disable auto-intercepts if you want manual control:

```dart
await DevConnect.initAndRunApp(
  appName: 'MyApp',
  runApp: () => runApp(const MyApp()),
  autoInterceptHttp: false,    // disable auto — use Dio interceptor or manual report
  autoInterceptLogs: false,    // disable auto — use DevConnect.log/warn/error manually
);
```

## Features

### Network

Auto-captured via `HttpOverrides`: http, Dio, Chopper, Retrofit, GraphQL, Firebase, OAuth2, gRPC-web, Image.network.

```dart
// Dio (optional, for extra detail). The interceptor mirrors Dio's API
// without depending on Dio, so hand its callbacks to InterceptorsWrapper:
final dc = DevConnect.dioInterceptor(responseFactory: Response.new);
dio.interceptors.add(InterceptorsWrapper(
  onRequest: dc.onRequest,
  onResponse: dc.onResponse,
  onError: dc.onError,
));
```

### Mock Server

Rules you save in the desktop's **Mock** tab reach the app when you click
**Push all**, with no app code, and answer matching requests with the rule's
status, body, headers and delay; each mocked request is listed in the
desktop's **Network › Mock Audit**. A rule matches on method, URL regex
(found anywhere in the URL), optional header regexes (names
case-insensitive; a request without the header never matches),
`scope.deviceIds` and `expiresAt`.

- Through `HttpOverrides` (on by default with `initAndRunApp`), every
  `dart:io` client is mocked: http, Dio's default adapter, Chopper… The
  connection is opened, then dropped before the request is sent, so the
  host must be reachable.
- Through the Dio interceptor with `responseFactory: Response.new` (above),
  requests are answered before any connection, whatever Dio's adapter. A
  mocked 4xx/5xx comes back as a plain `Response` there (Dio runs
  `validateStatus` only on real responses); via `HttpOverrides` it throws a
  `DioException` like a real error.
- WebSocket handshakes are never mocked.

### WebSocket

```dart
final socket = await DevConnect.websocketConnect('wss://api.example.com/ws');
// or wrap one you opened: DevConnectWebSocket.wrap(webSocket, url)
socket.listen((message) => print(message)); // received frames are captured
socket.add('{"type":"subscribe"}');         // so are sent frames
await socket.close(1000, 'done');           // one close event per connection
```

Read messages through the wrapper (`listen`, `await for`, `frames`):
listening to `socket.inner` directly skips the capture.

### GraphQL

GraphQL requests already show up under Network. For the **GraphQL** tab
(operation, variables, data, errors), put this link in front of your
terminating link. It uses `gql_link`, which `graphql_flutter` and ferry
already depend on:

```dart
import 'dart:async';

import 'package:devconnect_manage_kit/devconnect_manage_kit.dart';
import 'package:gql/ast.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';

/// Reports each operation to DevConnect's GraphQL tab.
class DevConnectGqlLink extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    final name = request.operation.operationName;
    final definition = request.operation.document.definitions
        .whereType<OperationDefinitionNode>()
        .where((d) => name == null || d.name?.value == name)
        .firstOrNull;
    final operation = name ?? definition?.name?.value; // null → "anonymous"
    final id = DevConnect.reportGraphQLOperation(
      operationName: operation,
      operationType: definition?.type.name ?? 'query',
      variables: request.variables,
    );
    final watch = Stopwatch()..start();
    void report({Response? response, Object? error}) =>
        DevConnect.reportGraphQLResponse(
          operationId: id,
          operation: operation,
          latencyMs: watch.elapsedMilliseconds,
          data: response?.data,
          errors: response?.errors,
          error: error?.toString(),
        );
    return forward!(request).transform(
      StreamTransformer<Response, Response>.fromHandlers(
        handleData: (response, sink) {
          report(response: response);
          sink.add(response);
        },
        handleError: (error, stackTrace, sink) {
          report(error: error);
          sink.addError(error, stackTrace);
        },
      ),
    );
  }
}

// final link = Link.from([DevConnectGqlLink(), HttpLink('https://api.example.com/graphql')]);
```

Not using `gql_link`? `DevConnect.reportGraphQLOperation(...)` returns an
`operationId`; pass it to `DevConnect.reportGraphQLResponse(...)` with the
`data` / `errors` (or the transport `error`) when the result arrives.

### Logs

Auto-captured via Zone: print, debugPrint, logger, talker, logging, fimber, simple_logger.

```dart
DevConnect.log('User logged in');
DevConnect.debug('Token refreshed', tag: 'Auth');
DevConnect.warn('Rate limit approaching');
DevConnect.error('Payment failed', stackTrace: StackTrace.current.toString());
```

### State

Supports: Riverpod, BLoC, Provider/ChangeNotifier, GetX, MobX, Signals.

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
```

#### Controls from the desktop

State Inspector › **Controls** watches state paths with no app code. Restoring
a snapshot and dispatching an action call these handlers; set them after
`DevConnect.init`:

```dart
// Restore: apply a snapshot sent from the desktop
DevConnect.onStateRestore = (state) => store.restore(state);

// Dispatch action: the desktop sends a map such as {'type': 'LOGOUT'}
DevConnect.onReduxDispatch = (action) => store.dispatch(action);
```

A throw in either handler shows in the desktop's Console.

### Storage

Supports: SharedPreferences, Hive, Realm, SecureStorage, MMKV, ObjectBox, Sembast, sqflite, Floor.

Each library has 2 options: **auto** (wrap once, everything reported) or **manual** (you control what gets reported). Choose per library.

#### SharedPreferences

```dart
// Option 1: Auto — wrap once, all get/set/remove auto-reported
final prefs = DevConnectSharedPreferences.wrap(await SharedPreferences.getInstance());
prefs.setString('token', 'abc');  // auto-reported
prefs.getString('token');          // auto-reported
prefs.remove('token');             // auto-reported

// Option 2: Manual — report only what you want
final sp = DevConnect.sharedPreferencesReporter();
await prefs.setString('token', 'abc');
sp.reportWrite('token', 'abc');   // only this gets reported
```

#### Hive

```dart
// Option 1: Auto
final box = DevConnectHiveBox.wrap(await Hive.openBox('settings'));
box.put('darkMode', true);  // auto-reported
box.get('darkMode');         // auto-reported

// Option 2: Manual
final hive = DevConnect.hiveReporter();
await box.put('darkMode', true);
hive.reportWrite('darkMode', true);
```

#### SecureStorage

```dart
// Option 1: Auto (values masked by default)
final secure = DevConnectSecureStorage.wrap(FlutterSecureStorage());
await secure.write(key: 'token', value: 'secret');  // auto-reported as ***

// Option 2: Manual — control what value is shown
final reporter = DevConnect.secureStorageReporter();
await storage.write(key: 'token', value: 'secret');
reporter.reportWrite('token', value: '<hidden>');
```

#### MMKV

```dart
// Option 1: Auto
final mmkv = DevConnectMMKVWrapper.wrap(MMKV.defaultMMKV());
mmkv.encodeString('token', 'abc');  // auto-reported

// Option 2: Manual
final reporter = DevConnect.mmkvReporter();
mmkv.encodeString('token', 'abc');
reporter.reportWrite('token', value: 'abc');
```

#### Sembast

```dart
// Option 1: Auto
final store = DevConnectSembastStore.wrap(intMapStoreFactory.store('settings'), db);
await store.record(1).put({'theme': 'dark'});  // auto-reported

// Option 2: Manual
final reporter = DevConnect.sembastReporter();
await storeRef.record(1).put(db, {'theme': 'dark'});
reporter.reportWrite('settings:1', {'theme': 'dark'});
```

#### Realm, ObjectBox, Floor, sqflite (manual only)

```dart
// Realm
final realm = DevConnect.realmReporter();
realm.reportWrite('User', {'name': 'John', 'age': 25});
realm.reportRead('User', queryResults);
realm.reportDelete('User');

// ObjectBox
final obx = DevConnect.objectBoxReporter();
obx.reportWrite('User', {'name': 'John'});
obx.reportRead('User', queryResults);

// Floor (ORM on SQLite)
final floor = DevConnect.floorReporter();
floor.reportWrite('users', {'id': 1, 'name': 'John'});
floor.reportRead('SELECT * FROM users', results);

// sqflite
final sqf = DevConnect.sqfliteReporter();
sqf.reportWrite('INSERT INTO users', {'name': 'John'});
sqf.reportRead('SELECT * FROM users', results);
```

#### Generic (any key-value store)

```dart
final custom = DevConnectStorage(storageType: 'my_custom_store');
custom.reportWrite('key', 'value');
custom.reportRead('key', 'value');
custom.reportDelete('key');
```

### Database

Supports: Drift, Isar, sqflite.

```dart
// Drift
final driftReporter = DevConnect.driftReporter();
driftReporter.reportQuery('SELECT * FROM users', results);

// Isar
final isarReporter = DevConnect.isarReporter();
isarReporter.reportQuery('User', results);
```

### Performance

With `autoPerformance` (on by default) the desktop's **Perf** tab fills in on
its own: FPS, frame build and raster times, jank frames, CPU, memory,
threads and startup time. Report your own metrics too:

```dart
DevConnect.reportPerformanceMetric(metricType: 'fps', value: 58.5, label: 'Main Thread FPS');
```

### Benchmark

With `autoBenchmark` (on by default) the desktop's **Bench** tab times the
app's startup (Dart VM initialized, first frame, fully interactive) and each
stay in the background. Time your own flows step by step:

```dart
DevConnect.benchmarkStart('loadHome');
await fetchUser();
DevConnect.benchmarkStep('loadHome');
await fetchPosts();
DevConnect.benchmarkStop('loadHome');
```

### Errors

Uncaught errors are captured on their own (`autoError`, on by default):
framework errors (`FlutterError.onError`), uncaught async errors
(`PlatformDispatcher.onError`) and errors in the app's zone. Each shows in
the desktop's **Errors** tab with its stack trace.

### Memory Leaks

The leak detector (`autoMemoryLeak`, on by default) watches the heap's
growth and reports to the desktop's **Leaks** tab. Report your own:

```dart
DevConnect.reportMemoryLeak(
  leakType: 'growing_collection',
  objectName: 'imageCache',
  detail: 'Map grows without bound: 15,200 entries, expected under 500',
  severity: 'critical', // info, warning (default) or critical
  retainedSizeBytes: 48000000,
);
```

### Display

Send any value to watch in the desktop's **Display** tab; each call adds a
snapshot:

```dart
DevConnect.display(
  'Feature Flags',
  value: {'newCheckout': true, 'wishlist': false},
  preview: 'newCheckout on · wishlist off',
);
```

### Async Operations

Report the start and the end of async work; the desktop's **Async** tab
shows each with its duration:

```dart
DevConnect.reportAsyncOperation(
  operationType: 'async_task', // or background_job, saga_call, custom, ...
  description: 'fetchProducts',
  status: 'start',
);
final products = await api.fetchProducts();
DevConnect.reportAsyncOperation(
  operationType: 'async_task',
  description: 'fetchProducts',
  status: 'resolve', // or 'reject', with error: '...'
  duration: 312,
  result: {'items': products.length},
);
```

### Custom Commands

```dart
DevConnect.registerCommand('clearCache', (args) {
  return {'cleared': true};
});
```

Registered commands show up in the desktop's **Commands** tab, where you
run them with optional JSON args and see what they return (async handlers
are awaited; a throw shows as the error).

### Database Browser

Let the desktop's **Database** tab browse your SQLite tables and run SQL:

```dart
DevConnect.registerDatabase('app.db', db.rawQuery); // sqflite
```

Any `Future<List<Map<String, Object?>>> Function(String sql)` works (drift:
`(sql) async => [for (final r in await db.customSelect(sql).get()) r.data]`).
Results are capped at 1000 rows.

### Storage Editing

The desktop's **Storage** tab lists, edits, deletes and clears
SharedPreferences (through the wrapper above). For any other store:

```dart
DevConnect.registerStorage('hive:settings', DevConnectStorageAdapter(
  getAll: () => box.toMap().map((k, v) => MapEntry('$k', v)),
  set: box.put,
  remove: box.delete,
  clear: box.clear,
));
```

### Layout Inspector

Nothing to set up: the desktop's **Layout** tab captures a screenshot and
the widget tree, with each widget's bounds, properties and padding. Click
**Capture** whenever you want the current screen;
[the desktop guide](https://github.com/ridelinktechs/devconnect-manage-kit#layout-inspector)
covers picking elements, zooming and measuring.

### Hot Reload / Hot Restart from Desktop

Since **1.0.5** — let DevConnect Manage Tool trigger a hot-reload
(`server:reload`) or a hot-restart (`server:hot_restart`) on your
app from the desktop. Both default to `WidgetsBinding.reassembleApplication`,
the same path `flutter run -r` uses for hot-reload outside the IDE.

```dart
// Optional: wipe in-memory caches before the reload
DevConnect.onReloadRequest = () {
  myCache.clear();
  WidgetsBinding.instance.reassembleApplication();
};

// Optional: true hot-restart semantics (the Flutter IDE's heavier
// variant — tears down every State and remounts the root widget)
final appKey = GlobalKey();
DevConnect.onHotRestartRequest = () {
  appKey.currentState?.reassemble();  // or bump a state-version counter
};
```

> Works in debug builds only — production no-ops.

## Production Safety

Disabled by default in release builds via `kDebugMode` — zero runtime overhead.

```dart
// Explicitly disable
DevConnect.init(appName: 'MyApp', enabled: false);
```

## Links

- [Main Repository](https://github.com/ridelinktechs/devconnect-manage-kit)
- [Desktop App Download](https://github.com/ridelinktechs/devconnect-manage-kit/releases)
- [Full Documentation](https://github.com/ridelinktechs/devconnect-manage-kit#sdks)
- [Using the desktop app, page by page](https://github.com/ridelinktechs/devconnect-manage-kit#using-the-desktop-app)

## License

MIT - by [ridelinktechs](https://github.com/ridelinktechs)
