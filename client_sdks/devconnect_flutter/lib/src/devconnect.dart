import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'devconnect_client.dart';
import 'interceptors/dio_interceptor.dart';
import 'interceptors/getx_interceptor.dart';
import 'interceptors/http_client_interceptor.dart';
import 'interceptors/log_interceptor.dart';
import 'interceptors/loggy_interceptor.dart';
import 'interceptors/navigation_observer.dart';
import 'reporters/drift_reporter.dart';
import 'reporters/isar_reporter.dart';
import 'reporters/log_reporter.dart';
import 'reporters/mmkv_reporter.dart';
import 'reporters/secure_storage_reporter.dart';
import 'reporters/signals_observer.dart';
import 'reporters/storage_reporter.dart';
import 'wrappers/isar_wrapper.dart';
import 'wrappers/realm_wrapper.dart';
import 'plugins/performance_monitor.dart' as perf_monitor;
import 'plugins/memory_leak_detector.dart' as memory_detector;
import 'plugins/app_benchmark.dart' as app_bench;
import 'plugins/error_monitor.dart' as error_monitor;

/// DevConnect Flutter SDK - Main entry point.
///
/// ## Minimal setup (captures ALL HTTP + ALL developer logs):
/// ```dart
/// void main() {
///   DevConnect.runApp(
///     appName: 'MyApp',
///     app: const MyApp(),
///   );
/// }
/// ```
///
/// ## Or manual setup:
/// ```dart
/// void main() async {
///   await DevConnect.init(appName: 'MyApp');
///   HttpOverrides.global = DevConnect.httpOverrides();
///   DevConnect.runZoned(() => runApp(const MyApp()));
/// }
/// ```
class DevConnect {
  DevConnect._();

  static DevConnectClient get client => DevConnectClient.instance;
  static DevConnectClient? get clientSafe => DevConnectClient.instanceSafe;
  static bool _initialized = false;
  static Future<void>? _initFuture;

  /// Safe no-op guard for release builds.
  /// Returns true if SDK is active (debug + initialized).
  static bool get _active => kDebugMode && _initialized;

  /// One-line setup: init + intercept ALL HTTP + capture ALL developer logs.
  ///
  /// ```dart
  /// void main() {
  ///   DevConnect.runApp(
  ///     appName: 'MyApp',
  ///     app: const MyApp(),
  ///   );
  /// }
  /// ```
  ///
  /// This single call:
  /// - Connects to DevConnect desktop
  /// - Intercepts ALL HTTP (http, Dio, Chopper, GraphQL, Firebase, OAuth2...)
  /// - Captures print(), debugPrint(), log() from dart:developer
  /// - Does NOT capture framework/system logs, only YOUR code's print statements
  /// One-line setup that wraps your runApp call.
  ///
  /// ```dart
  /// void main() async {
  ///   await DevConnect.initAndRunApp(
  ///     appName: 'MyApp',
  ///     runApp: () => runApp(const MyApp()),
  ///   );
  /// }
  /// ```
  ///
  /// This single call:
  /// - Connects to DevConnect desktop
  /// - Intercepts ALL HTTP (http, Dio, Chopper, GraphQL, Firebase, OAuth2...)
  /// - Captures print(), debugPrint(), log() from dart:developer
  /// - Does NOT capture framework/system logs, only YOUR code's print statements
  static Future<void> initAndRunApp({
    required String appName,
    required Future<void> Function() runApp,
    String appVersion = '1.0.0',
    String? versionCode,
    String? host,
    int port = 9090,
    bool auto_ = true,
    bool? enabled,
    bool autoInterceptHttp = true,
    bool autoInterceptLogs = true,
    /// Auto-start performance monitoring (default: true)
    bool autoPerformance = true,
    /// Auto-start memory leak detection (default: true)
    bool autoMemoryLeak = true,
    /// Auto-start app benchmark (default: true)
    bool autoBenchmark = true,
    /// Auto-start error monitoring (default: true)
    bool autoError = true,
  }) async {
    // Production kill-switch: completely no-op in release builds.
    if (!(enabled ?? kDebugMode)) {
      WidgetsFlutterBinding.ensureInitialized();
      await runApp();
      return;
    }

    // When autoInterceptLogs is true, EVERYTHING runs inside runZoned:
    //   ensureInitialized → monitors → init → runApp
    //   This ensures print() is captured AND no zone mismatch.
    //
    // IMPORTANT: Do NOT call WidgetsFlutterBinding.ensureInitialized()
    // before initAndRunApp. Put ALL your init (Firebase, prefs, etc.)
    // inside the runApp callback.
    if (autoInterceptLogs) {
      DevConnectLogInterceptor.runZoned(() async {
        WidgetsFlutterBinding.ensureInitialized();
        await _initAndRun(
          autoPerformance: autoPerformance,
          autoMemoryLeak: autoMemoryLeak,
          autoBenchmark: autoBenchmark,
          autoError: autoError,
          appName: appName,
          appVersion: appVersion,
          versionCode: versionCode,
          host: host,
          port: port,
          auto_: auto_,
          autoInterceptHttp: autoInterceptHttp,
          runApp: runApp,
        );
      });
    } else {
      WidgetsFlutterBinding.ensureInitialized();
      await _initAndRun(
        autoPerformance: autoPerformance,
        autoMemoryLeak: autoMemoryLeak,
        autoBenchmark: autoBenchmark,
        autoError: autoError,
        appName: appName,
        appVersion: appVersion,
        versionCode: versionCode,
        host: host,
        port: port,
        auto_: auto_,
        autoInterceptHttp: autoInterceptHttp,
        runApp: runApp,
      );
    }
  }

  /// Internal: start monitors → connect → runApp
  static Future<void> _initAndRun({
    required bool autoPerformance,
    required bool autoMemoryLeak,
    required bool autoBenchmark,
    required bool autoError,
    required String appName,
    required String appVersion,
    required String? versionCode,
    required String? host,
    required int port,
    required bool auto_,
    required bool autoInterceptHttp,
    required Future<void> Function() runApp,
  }) async {
    // Monitoring plugins (binding is already initialized)
    if (autoPerformance) perf_monitor.startPerformanceMonitor();
    if (autoMemoryLeak) memory_detector.startMemoryLeakDetector();
    if (autoBenchmark) app_bench.setupAppBenchmark();
    if (autoError) error_monitor.startErrorMonitor();

    await init(
      appName: appName,
      appVersion: appVersion,
      versionCode: versionCode,
      host: host,
      port: port,
      auto_: auto_,
      enabled: true,
      autoPerformance: false,
      autoMemoryLeak: false,
      autoBenchmark: false,
    );

    // Intercept ALL HTTP traffic globally
    if (autoInterceptHttp) {
      HttpOverrides.global = DevConnectHttpOverrides();
    }

    await runApp();
  }

  /// Initialize DevConnect and connect to desktop app.
  ///
  /// [host] - Desktop IP. Leave null for auto-detect.
  /// [auto_] - Auto-detect host if [host] is null (default: true).
  static Future<void> init({
    required String appName,
    String appVersion = '1.0.0',
    String? versionCode,
    String? host,
    int port = 9090,
    String platform = 'flutter',
    bool auto_ = true,
    bool? enabled,
    /// Auto-start performance monitoring (default: true)
    bool autoPerformance = true,
    /// Auto-start memory leak detection (default: true)
    bool autoMemoryLeak = true,
    /// Auto-start app benchmark (default: true)
    bool autoBenchmark = true,
  }) async {
    // Production kill-switch: no-op in release builds by default.
    if (!(enabled ?? kDebugMode) || _initialized) return;
    _initFuture ??= _doInit(
      appName: appName,
      appVersion: appVersion,
      versionCode: versionCode,
      host: host,
      port: port,
      platform: platform,
      auto_: auto_,
      autoPerformance: autoPerformance,
      autoMemoryLeak: autoMemoryLeak,
      autoBenchmark: autoBenchmark,
    );
    return _initFuture;
  }

  static Future<void> _doInit({
    required String appName,
    String appVersion = '1.0.0',
    String? versionCode,
    String? host,
    int port = 9090,
    String platform = 'flutter',
    bool auto_ = true,
    bool autoPerformance = true,
    bool autoMemoryLeak = true,
    bool autoBenchmark = true,
  }) async {
    _initialized = true;

    await DevConnectClient.init(
      host: host,
      port: port,
      appName: appName,
      appVersion: appVersion,
      versionCode: versionCode,
      auto_: auto_,
      deviceName: Platform.localHostname,
      platform: platform,
    );

    // Auto-start monitoring plugins
    if (autoPerformance) perf_monitor.startPerformanceMonitor();
    if (autoMemoryLeak) memory_detector.startMemoryLeakDetector();
    if (autoBenchmark) app_bench.setupAppBenchmark();
  }

  /// Run a callback in a Zone that captures print() and debugPrint().
  ///
  /// Only captures developer-placed print statements, NOT framework logs.
  ///
  /// ```dart
  /// DevConnect.runZoned(() {
  ///   runApp(const MyApp());
  /// });
  /// ```
  static R runZoned<R>(R Function() body) {
    return DevConnectLogInterceptor.runZoned(body);
  }

  // ---- HTTP Interceptors ----

  /// Global HttpOverrides - intercepts ALL HTTP in the entire app.
  ///
  /// Captures: http package, Dio, Chopper, Retrofit, GraphQL (graphql_flutter,
  /// ferry, artemis), Firebase REST, OAuth2, image loading, gRPC-web, and ANY
  /// library that uses dart:io HttpClient under the hood.
  ///
  /// ```dart
  /// HttpOverrides.global = DevConnect.httpOverrides();
  /// ```
  static DevConnectHttpOverrides httpOverrides() {
    return DevConnectHttpOverrides();
  }

  /// Dio-specific interceptor for granular control.
  ///
  /// Use this if you want to intercept only specific Dio instances
  /// instead of all HTTP globally.
  ///
  /// ```dart
  /// dio.interceptors.add(DevConnect.dioInterceptor());
  /// ```
  static DevConnectDioInterceptor dioInterceptor() {
    return DevConnectDioInterceptor();
  }

  // ---- Navigation ----

  static DevConnectNavigationObserver navigationObserver() {
    return DevConnectNavigationObserver();
  }

  // ---- Logging ----

  static DevConnectLogger logger([String? tag]) {
    return DevConnectLogger(tag: tag);
  }

  static void log(String message,
      {String? tag, Map<String, dynamic>? metadata}) {
    if (!_active) return;
    client.log(message, tag: tag, metadata: metadata);
  }

  static void debug(String message,
      {String? tag, Map<String, dynamic>? metadata}) {
    if (!_active) return;
    client.debug(message, tag: tag, metadata: metadata);
  }

  static void warn(String message,
      {String? tag, Map<String, dynamic>? metadata}) {
    if (!_active) return;
    client.warn(message, tag: tag, metadata: metadata);
  }

  static void error(String message,
      {String? tag, String? stackTrace, Map<String, dynamic>? metadata}) {
    if (!_active) return;
    client.error(message,
        tag: tag, stackTrace: stackTrace, metadata: metadata);
  }

  // ---- GetX / GetConnect ----

  /// GetConnect request modifier that captures outgoing HTTP requests.
  ///
  /// ```dart
  /// httpClient.addRequestModifier(DevConnect.getConnectModifier());
  /// ```
  static dynamic Function(dynamic) getConnectModifier() {
    return DevConnectGetConnectInterceptor().requestModifier();
  }

  /// GetConnect response modifier that captures HTTP responses.
  ///
  /// ```dart
  /// httpClient.addResponseModifier(DevConnect.getConnectResponseModifier());
  /// ```
  static dynamic Function(dynamic, dynamic) getConnectResponseModifier() {
    return DevConnectGetConnectInterceptor().responseModifier();
  }

  /// Returns a GetConnect interceptor instance for full control.
  ///
  /// ```dart
  /// final interceptor = DevConnect.getConnectInterceptor();
  /// httpClient.addRequestModifier(interceptor.requestModifier());
  /// httpClient.addResponseModifier(interceptor.responseModifier());
  /// ```
  static DevConnectGetConnectInterceptor getConnectInterceptor() {
    return DevConnectGetConnectInterceptor();
  }

  // ---- Storage ----

  static DevConnectStorage sharedPreferencesReporter() {
    return const DevConnectStorage(storageType: 'shared_preferences');
  }

  static DevConnectStorage hiveReporter() {
    return const DevConnectStorage(storageType: 'hive');
  }

  /// Reporter for Realm database operations.
  ///
  /// ```dart
  /// final reporter = DevConnect.realmReporter();
  /// reporter.reportWrite('User', {'name': 'John', 'age': 25});
  /// reporter.reportRead('User', results);
  /// reporter.reportDelete('User');
  /// ```
  static DevConnectStorage realmReporter() {
    return const DevConnectStorage(storageType: 'realm');
  }

  /// Reporter for ObjectBox database operations.
  static DevConnectStorage objectBoxReporter() {
    return const DevConnectStorage(storageType: 'objectbox');
  }

  /// Reporter for Floor database operations (ORM on SQLite).
  static DevConnectStorage floorReporter() {
    return const DevConnectStorage(storageType: 'floor');
  }

  /// Reporter for Sembast NoSQL database operations.
  static DevConnectStorage sembastReporter() {
    return const DevConnectStorage(storageType: 'sembast');
  }

  /// Reporter for sqflite database operations.
  static DevConnectStorage sqfliteReporter() {
    return const DevConnectStorage(storageType: 'sqflite');
  }

  /// Reporter for flutter_secure_storage read/write/delete operations.
  ///
  /// Values are masked by default for security.
  ///
  /// ```dart
  /// final reporter = DevConnect.secureStorageReporter();
  /// reporter.reportWrite('token', value: 'abc123');
  /// reporter.reportRead('token', value: token);
  /// reporter.reportDelete('token');
  /// ```
  static DevConnectSecureStorageReporter secureStorageReporter({
    bool maskValues = true,
  }) {
    return DevConnectSecureStorageReporter(maskValues: maskValues);
  }

  /// Reporter for MMKV key-value storage operations.
  ///
  /// ```dart
  /// final reporter = DevConnect.mmkvReporter();
  /// reporter.reportWrite('username', value: 'john');
  /// reporter.reportRead('username', value: username);
  /// reporter.reportDelete('username');
  /// ```
  static DevConnectMmkvReporter mmkvReporter({String? mmkvId}) {
    return DevConnectMmkvReporter(mmkvId: mmkvId);
  }

  // ---- Database ----

  /// Reporter for Drift (moor) database queries.
  ///
  /// ```dart
  /// final reporter = DevConnect.driftReporter();
  /// reporter.reportQuery(sql: 'SELECT * FROM users', duration: elapsed);
  /// ```
  static DevConnectDriftReporter driftReporter() {
    return DevConnectDriftReporter();
  }

  /// Wraps a Drift QueryExecutor to automatically report all SQL queries.
  ///
  /// ```dart
  /// @DriftDatabase(tables: [Todos])
  /// class AppDatabase extends _$AppDatabase {
  ///   AppDatabase(QueryExecutor e) : super(DevConnect.driftQueryExecutor(e));
  /// }
  /// ```
  static DevConnectDriftExecutor driftQueryExecutor(dynamic innerExecutor) {
    return DevConnectDriftExecutor(innerExecutor);
  }

  /// Reporter for Isar database operations.
  ///
  /// ```dart
  /// final reporter = DevConnect.isarReporter();
  /// reporter.reportPut('users', id, data: user.toJson());
  /// reporter.reportQuery('users', filter: 'where().findAll()', resultCount: 10);
  /// reporter.reportDelete('users', 42);
  /// ```
  static DevConnectIsarReporter isarReporter() {
    return DevConnectIsarReporter();
  }

  /// Auto-reporting wrapper for Isar database operations.
  ///
  /// ```dart
  /// final isarWrapper = DevConnect.isarWrapper();
  /// final id = isarWrapper.put('users', () => isar.users.put(user));
  /// final users = isarWrapper.query('users', () => isar.users.where().findAll());
  /// isarWrapper.delete('users', () => isar.users.delete(42), id: 42);
  /// ```
  ///
  /// Or wrap the instance directly:
  /// ```dart
  /// final w = DevConnectIsar.wrap(isar);
  /// final id = w.put('users', () => isar.users.put(user));
  /// ```
  static DevConnectIsar isarWrapper() {
    return DevConnectIsar.wrap(null);
  }

  /// Auto-reporting wrapper for Realm database operations.
  ///
  /// ```dart
  /// final realmWrapper = DevConnect.realmWrapper();
  /// realmWrapper.write('User', () { realm.add(User('John')); });
  /// final users = realmWrapper.query('User', () => realm.all<User>().toList());
  /// realmWrapper.delete('User', () { realm.delete(user); });
  /// ```
  ///
  /// Or wrap the instance directly:
  /// ```dart
  /// final w = DevConnectRealm.wrap(realm);
  /// w.write('User', () { realm.add(User('John')); });
  /// ```
  static DevConnectRealm realmWrapper() {
    return DevConnectRealm.wrap(null);
  }

  // ---- State Management ----

  /// Observer for signals / flutter_signals that reports signal value changes.
  ///
  /// ```dart
  /// final observer = DevConnect.signalsObserver();
  /// observer.reportChange('counter', newValue: counter.value);
  /// // Or auto-observe:
  /// observer.observe('counter', counter);
  /// ```
  static DevConnectSignalsObserver signalsObserver() {
    return DevConnectSignalsObserver();
  }

  static void reportStateChange({
    required String stateManager,
    required String action,
    Map<String, dynamic>? previousState,
    Map<String, dynamic>? nextState,
    List<Map<String, dynamic>>? diff,
  }) {
    if (!_active) return;
    client.reportStateChange(
      stateManager: stateManager,
      action: action,
      previousState: previousState,
      nextState: nextState,
      diff: diff,
    );
  }

  // ---- Performance ----

  static void reportPerformanceMetric({
    required String metricType,
    required double value,
    String? label,
    Map<String, dynamic>? metadata,
  }) {
    if (!_active) return;
    client.reportPerformanceMetric(
      metricType: metricType,
      value: value,
      label: label,
      metadata: metadata,
    );
  }

  static void reportMemoryLeak({
    required String leakType,
    required String objectName,
    required String detail,
    String severity = 'warning',
    String? stackTrace,
    int? retainedSizeBytes,
    Map<String, dynamic>? metadata,
  }) {
    if (!_active) return;
    client.reportMemoryLeak(
      leakType: leakType,
      objectName: objectName,
      detail: detail,
      severity: severity,
      stackTrace: stackTrace,
      retainedSizeBytes: retainedSizeBytes,
      metadata: metadata,
    );
  }

  // ---- Connection ----

  /// Check if currently connected to DevConnect desktop.
  static bool get isConnected => clientSafe?.isConnected ?? false;

  /// Disconnect from DevConnect desktop.
  static Future<void> disconnect() async {
    await clientSafe?.disconnect();
  }

  // ---- Storage ----

  /// Report a storage operation (read/write/delete).
  ///
  /// ```dart
  /// DevConnect.reportStorageOperation(
  ///   storageType: 'shared_preferences',
  ///   key: 'theme',
  ///   value: 'dark',
  ///   operation: 'write',
  /// );
  /// ```
  static void reportStorageOperation({
    required String storageType,
    required String key,
    dynamic value,
    required String operation,
  }) {
    if (!_active) return;
    client.reportStorageOperation(
      storageType: storageType,
      key: key,
      value: value,
      operation: operation,
    );
  }

  // ---- State Snapshot ----

  /// Send a full state snapshot to desktop (for saving/restoring later).
  ///
  /// ```dart
  /// DevConnect.sendStateSnapshot(
  ///   stateManager: 'riverpod',
  ///   state: {'counter': 42, 'user': userMap},
  /// );
  /// ```
  static void sendStateSnapshot({
    required String stateManager,
    required Map<String, dynamic> state,
  }) {
    if (!_active) return;
    client.sendStateSnapshot(stateManager: stateManager, state: state);
  }

  /// Set handler for state restore from desktop.
  ///
  /// ```dart
  /// DevConnect.onStateRestore((state) {
  ///   ref.read(appStateProvider.notifier).restore(state);
  /// });
  /// ```
  static set onStateRestore(void Function(Map<String, dynamic> state)? handler) {
    if (!_active) return;
    clientSafe?.onStateRestore = handler;
  }

  /// Set custom handler for "reload" requests from the desktop.
  ///
  /// By default, the SDK calls [WidgetsBinding.reassembleApplication] — which
  /// triggers a full widget rebuild (the same mechanism `flutter run -r`
  /// uses for hot-reload outside the IDE). Override this when you need
  /// finer control, e.g. to wipe in-memory caches before the rebuild:
  ///
  /// ```dart
  /// DevConnect.onReloadRequest = () {
  ///   cache.clear();
  ///   // default reassemble is *not* called when you set a custom handler
  ///   WidgetsBinding.instance.reassembleApplication();
  /// };
  /// ```
  static set onReloadRequest(void Function()? handler) {
    if (!_active) return;
    clientSafe?.onReloadRequest = handler;
  }

  /// Set custom handler for "hot restart" requests from the desktop.
  ///
  /// Hot restart is the heavier variant of reload — the Flutter IDE
  /// distinguishes:
  /// - **Hot reload**  (`server:reload`): re-execute the widget tree,
  ///   **preserve state**. Wired to [onReloadRequest].
  /// - **Hot restart** (`server:hot_restart`): tear down every `State`,
  ///   **reset state**, then re-bootstrap. Wired to this hook.
  ///
  /// The default implementation of both calls [WidgetsBinding.reassembleApplication]
  /// for the same reason (Flutter offers no public kill-and-relaunch API),
  /// so to get true state-reset semantics — what the IDE does — apps must
  /// register this hook and remount their root widget themselves:
  ///
  /// ```dart
  /// final appKey = GlobalKey();
  ///
  /// // Wrap your root widget in a key you control
  /// DevConnect.onHotRestartRequest = () {
  ///   appKey.currentState?.reassemble();
  ///   // or use a state-version counter to force a rebuild
  /// };
  /// ```
  static set onHotRestartRequest(void Function()? handler) {
    if (!_active) return;
    clientSafe?.onHotRestartRequest = handler;
  }

  // ---- Benchmark ----

  /// Start a benchmark timer.
  ///
  /// ```dart
  /// DevConnect.benchmarkStart('loadUserData');
  /// await fetchUser();
  /// DevConnect.benchmarkStep('loadUserData');
  /// await fetchPosts();
  /// DevConnect.benchmarkStop('loadUserData');
  /// ```
  static void benchmarkStart(String title) {
    if (!_active) return;
    client.benchmarkStart(title);
  }

  static void benchmarkStep(String title) {
    if (!_active) return;
    client.benchmarkStep(title);
  }

  static void benchmarkStop(String title) {
    if (!_active) return;
    client.benchmarkStop(title);
  }

  // ---- Custom Commands ----

  /// Register a custom command that desktop can trigger.
  ///
  /// ```dart
  /// DevConnect.registerCommand('clearCache', (args) {
  ///   prefs.clear();
  ///   return {'success': true};
  /// });
  /// ```
  static void registerCommand(
    String name,
    dynamic Function(Map<String, dynamic>?) handler,
  ) {
    if (!_active) return;
    client.registerCommand(name, handler);
  }

  // ---- Network (manual) ----

  /// Manually report a network request start.
  /// Useful when auto-interception is not used.
  static void reportNetworkStart({
    required String requestId,
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!_active) return;
    client.reportNetworkStart(
      requestId: requestId,
      method: method,
      url: url,
      headers: headers,
      body: body,
    );
  }

  /// Manually report a network request completion.
  static void reportNetworkComplete({
    required String requestId,
    required String method,
    required String url,
    required int statusCode,
    required int startTime,
    Map<String, String>? requestHeaders,
    Map<String, String>? responseHeaders,
    dynamic requestBody,
    dynamic responseBody,
    String? error,
  }) {
    if (!_active) return;
    client.reportNetworkComplete(
      requestId: requestId,
      method: method,
      url: url,
      statusCode: statusCode,
      startTime: startTime,
      requestHeaders: requestHeaders,
      responseHeaders: responseHeaders,
      requestBody: requestBody,
      responseBody: responseBody,
      error: error,
    );
  }

  // ---- Custom Display ----

  /// Send a custom display value to DevConnect desktop.
  static void display(
    String name, {
    dynamic value,
    String? preview,
    String? image,
    Map<String, dynamic>? metadata,
  }) {
    if (!_active) return;
    client.display(name,
        value: value,
        preview: preview,
        image: image,
        metadata: metadata);
  }

  // ---- Async Operations ----

  /// Report an async operation (saga step, background task, etc.).
  static void reportAsyncOperation({
    required String operationType,
    required String description,
    required String status,
    int? duration,
    String? sagaName,
    String? error,
    dynamic result,
    Map<String, dynamic>? metadata,
  }) {
    if (!_active) return;
    client.reportAsyncOperation(
      operationType: operationType,
      description: description,
      status: status,
      duration: duration,
      sagaName: sagaName,
      error: error,
      result: result,
      metadata: metadata,
    );
  }

  // ---- Loggy ----

  /// Returns a LoggyPrinter-compatible printer that sends logs to DevConnect.
  ///
  /// ```dart
  /// Loggy.initLoggy(
  ///   logPrinter: DevConnect.loggyPrinter(),
  /// );
  /// ```
  ///
  /// Chain with another printer:
  /// ```dart
  /// Loggy.initLoggy(
  ///   logPrinter: DevConnect.loggyPrinter(innerPrinter: const PrettyPrinter()),
  /// );
  /// ```
  static DevConnectLoggyPrinter loggyPrinter({dynamic innerPrinter}) {
    return DevConnectLoggyPrinter(innerPrinter: innerPrinter);
  }
}
