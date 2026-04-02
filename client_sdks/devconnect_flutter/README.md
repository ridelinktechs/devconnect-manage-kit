# DevConnect Manage Kit — Flutter SDK

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](../../LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.0-02569B?logo=flutter)](https://flutter.dev)

Debug your Flutter app with [DevConnect Manage Tool](https://github.com/ridelinktechs/devconnect-manage-kit) — network, state, logs, storage, database, performance — all in one desktop tool.

## Install

```yaml
# pubspec.yaml
dependencies:
  devconnect_flutter: ^1.0.0
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
// Dio (optional, for extra detail)
dio.interceptors.add(DevConnect.dioInterceptor());
```

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

```dart
DevConnect.reportPerformanceMetric(metricType: 'fps', value: 58.5, label: 'Main Thread FPS');
```

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

## Production Safety

Disabled by default in release builds via `kDebugMode` — zero runtime overhead.

```dart
// Explicitly disable
DevConnect.init(appName: 'MyApp', enabled: false);
```

## Links

- [Main Repository](https://github.com/ridelinktechs/devconnect-manage-kit)
- [Desktop App Download](https://github.com/ridelinktechs/devconnect-manage-kit/releases)
- [Full Documentation](https://github.com/ridelinktechs/devconnect-manage-kit#flutter-sdk)

## License

MIT - by [ridelinktechs](https://github.com/ridelinktechs)
