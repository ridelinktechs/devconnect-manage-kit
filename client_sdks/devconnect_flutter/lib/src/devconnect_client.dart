import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import 'core/device_identity.dart';
import 'core/host_discovery.dart';
import 'layout_inspector.dart';
import 'core/server_commands.dart' as server_commands;
import 'storage_adapter.dart';
import 'version.dart';

typedef OnConnected = void Function();
typedef OnDisconnected = void Function();

class DevConnectClient {
  static DevConnectClient? _instance;
  static DevConnectClient get instance => _instance!;

  /// Returns instance or null if not yet initialized.
  /// Use this in interceptors/reporters that may run before init().
  static DevConnectClient? get instanceSafe => _instance;

  /// Key-value stores the desktop can edit, by storage type. Static: the
  /// storage wrappers may be created before the client.
  static final Map<String, DevConnectStorageAdapter> _storages = {};

  static void registerStorage(
          String storageType, DevConnectStorageAdapter adapter) =>
      _storages[storageType] = adapter;

  /// Desktop-set network conditions, applied by `DevConnectHttpOverrides`.
  static int _latencyMs = 0;
  static bool _offline = false;

  @visibleForTesting
  static void setNetworkConditions({int latencyMs = 0, bool offline = false}) {
    _latencyMs = latencyMs < 0 ? 0 : latencyMs;
    _offline = offline;
  }

  @visibleForTesting
  static Map<String, DevConnectStorageAdapter> get storages =>
      Map.unmodifiable(_storages);

  /// Holds a request back by the desktop-set latency, or fails it the way
  /// an offline device does. DevConnect's own connection is exempt — else
  /// "offline" would cut the desktop off from turning it back on.
  static Future<void> applyNetworkConditions(Uri url) async {
    final self = _instance;
    if (self != null && url.host == self._host && url.port == self._port) {
      return;
    }
    if (_offline) {
      throw const SocketException(
          'Network is unreachable (simulated by DevConnect)');
    }
    if (_latencyMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: _latencyMs));
    }
  }

  /// Pre-init message queue: messages sent before init() completes.
  static final List<Map<String, dynamic>> _preInitQueue = [];

  /// Messages waiting for init(), as `{type, payload}`; tests read what
  /// the SDK sent from here.
  @visibleForTesting
  static List<Map<String, dynamic>> get queuedMessages => _preInitQueue;

  /// Send a message safely - queues if init() hasn't completed yet.
  /// Use this instead of instance.xxx() in interceptors/reporters.
  static void safeSend(String type, Map<String, dynamic> payload) {
    // No-op in release builds — zero overhead
    if (!kDebugMode) return;
    try {
      final inst = _instance;
      if (inst != null) {
        inst._send(type, payload);
      } else if (_preInitQueue.length < 500) {
        _preInitQueue.add({'type': type, 'payload': payload});
      }
    } catch (_) {
      // Encoding error — retry without body fields
      try {
        final stripped = Map<String, dynamic>.from(payload)
          ..remove('requestBody')
          ..remove('responseBody');
        stripped['_bodyDropped'] = true;
        final inst = _instance;
        if (inst != null) {
          inst._send(type, stripped);
        } else if (_preInitQueue.length < 500) {
          _preInitQueue.add({'type': type, 'payload': stripped});
        }
      } catch (_) {}
    }
  }

  WebSocket? _socket;
  String _host;
  final int _port;
  final String _appName;
  final String _appVersion;
  final String? _versionCode;
  final String _deviceName;
  final String _platform;
  final bool _auto;
  final _uuid = const Uuid();
  late final String _deviceId;
  bool _connected = false;
  Timer? _reconnectTimer;
  final List<String> _messageQueue = [];

  OnConnected? onConnected;
  OnDisconnected? onDisconnected;

  /// Called when desktop dispatches a Redux/BLoC action into the app
  void Function(Map<String, dynamic> action)? onReduxDispatch;
  /// Called when desktop restores a state snapshot
  void Function(Map<String, dynamic> state)? onStateRestore;
  /// Called when desktop asks the app to reload itself.
  /// The default implementation uses Flutter's [WidgetsBinding.reassembleApplication]
  /// (the same mechanism `flutter run -r` uses for hot-reload outside the IDE).
  /// Override this to provide a custom reload strategy — e.g. tear down the
  /// navigator and re-run the app — when the default isn't sufficient.
  void Function()? onReloadRequest;
  /// Called when desktop asks the app to perform a *hot restart* (heavier
  /// than [onReloadRequest] — equivalent to killing and re-launching the
  /// app while keeping the Dart isolate alive). See [onHotRestartRequest]
  /// in the public `DevConnect` API for details.
  void Function()? onHotRestartRequest;
  /// Custom command handlers: command name -> handler
  final Map<String, dynamic Function(Map<String, dynamic>?)> _commandHandlers = {};

  /// Databases the desktop's Database tab can query: name -> SQL runner.
  final Map<String, Future<List<Map<String, Object?>>> Function(String sql)>
      _databases = {};

  /// Custom server-message handlers registered by SDK plugins
  /// (e.g. layout inspector, mock server interceptor). Keyed by the
  /// `type` field of the incoming WebSocket message.
  final Map<String, List<void Function(Map<String, dynamic>)>> _serverHandlers = {};

  /// Register a handler for a custom `server:*` message. Multiple
  /// handlers per type are allowed and fire in registration order.
  /// Handlers that throw are swallowed so a buggy plugin cannot break
  /// the message loop.
  void registerServerHandler(
      String type, void Function(Map<String, dynamic> msg) handler) {
    _serverHandlers.putIfAbsent(type, () => []).add(handler);
  }
  /// Active benchmarks
  final Map<String, List<int>> _benchmarks = {}; // title -> [startTime, ...stepTimes]

  bool get isConnected => _connected;
  String get deviceId => _deviceId;
  String get host => _host;
  int get port => _port;

  DevConnectClient._({
    required String host,
    required int port,
    required String appName,
    required String appVersion,
    String? versionCode,
    required String deviceName,
    required String deviceId,
    String platform = 'flutter',
    bool auto_ = true,
  })  : _host = host,
        _port = port,
        _appName = appName,
        _appVersion = appVersion,
        _versionCode = versionCode,
        _deviceName = deviceName,
        _platform = platform,
        _auto = auto_,
        _deviceId = deviceId;

  /// Initialize DevConnect client.
  ///
  /// [host] - Desktop app IP. Leave null or 'auto' for auto-detection.
  /// [port] - WebSocket port (default 9090).
  /// [auto_] - If true (default), auto-detect host when [host] is null/'auto'.
  ///
  /// Auto-detection order:
  /// 1. Android emulator -> 10.0.2.2
  /// 2. iOS simulator -> localhost
  /// 3. Real device -> tries localhost, then common gateway IPs
  static Future<DevConnectClient> init({
    String? host,
    int port = 9090,
    required String appName,
    String appVersion = '1.0.0',
    String? versionCode,
    String? deviceName,
    String platform = 'flutter',
    bool auto_ = true,
  }) async {
    final stableDeviceId = await getStableDeviceId(appName);

    final client = _instance = DevConnectClient._(
      host: host ?? 'auto',
      port: port,
      appName: appName,
      appVersion: appVersion,
      versionCode: versionCode,
      deviceName: deviceName ?? defaultDeviceName(),
      deviceId: stableDeviceId,
      platform: platform,
      auto_: auto_,
    );
    unawaited(() async {
      if (client._host == 'auto') client._host = await autoDetectHost(port);
      await client.connect();
    }());
    return client;
  }

  Future<void> connect() async {
    try {
      // shortcut: a socket that connects after the timeout is left open.
      _socket = await WebSocket.connect('ws://$_host:$_port',
              customClient: wsHttpClient)
          .timeout(const Duration(seconds: 5));
      _connected = true;

      // Flush pre-init queue (messages from interceptors before init)
      if (_preInitQueue.isNotEmpty) {
        for (final msg in _preInitQueue) {
          _send(msg['type'] as String, msg['payload'] as Map<String, dynamic>);
        }
        _preInitQueue.clear();
      }

      // Flush instance message queue (messages during connecting)
      if (_messageQueue.isNotEmpty) {
        for (final json in _messageQueue) {
          _socket!.add(json);
        }
        _messageQueue.clear();
      }

      _socket!.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            final type = msg['type'] as String?;

            if (type == 'server:hello') {
              // Capture the server's stable machineId so the next launch can
              // verify the cached host really points at *this* desktop and
              // not some other device that happened to claim the same IP.
              final payload = msg['payload'] as Map<String, dynamic>?;
              final serverMachineId = payload?['machineId'] as String?;
              if (serverMachineId != null && serverMachineId.isNotEmpty) {
                unawaited(
                    saveHostCache(_host, _port, serverMachineId));
              }
              _sendHandshake();
            } else if (type == 'server:handshake_ack') {
              onConnected?.call();
            } else if (type == 'server:redux:dispatch') {
              final action = msg['payload']?['action'] as Map<String, dynamic>?;
              if (action != null) onReduxDispatch?.call(action);
            } else if (type == 'server:state:restore') {
              final state = msg['payload']?['state'] as Map<String, dynamic>?;
              if (state != null) onStateRestore?.call(state);
            } else if (type == 'server:custom:command') {
              final cmd = msg['payload']?['command'] as String?;
              final args = msg['payload']?['args'] as Map<String, dynamic>?;
              if (cmd != null && _commandHandlers.containsKey(cmd)) {
                final correlationId = msg['correlationId'] as String?;
                // Async handlers resolve before the result goes back; a throw
                // (sync or async) is reported as the error.
                Future.sync(() => _commandHandlers[cmd]!(args)).then(
                  (result) => _send('client:custom:command_result', {
                    'command': cmd,
                    'result': result,
                  }, correlationId: correlationId),
                  onError: (Object e) => _send('client:custom:command_result', {
                    'command': cmd,
                    'error': e.toString(),
                  }, correlationId: correlationId),
                );
              }
            } else if (type is String && type.startsWith('server:storage:')) {
              unawaited(_handleStorageCommand(
                  type, (msg['payload'] as Map?)?.cast<String, dynamic>() ?? {}));
            } else if (type == 'server:open_url') {
              final url = msg['payload']?['url'] as String?;
              if (url != null) server_commands.openUrl(url);
            } else if (type == 'server:network:throttle') {
              final payload = msg['payload'] as Map?;
              setNetworkConditions(
                latencyMs: (payload?['latencyMs'] as num?)?.toInt() ?? 0,
                offline: payload?['offline'] == true,
              );
            } else if (type == 'server:network:replay') {
              unawaited(server_commands.replayRequest(
                  (msg['payload'] as Map?)?.cast<String, dynamic>() ?? {}));
            } else if (type == 'server:layout:capture') {
              final correlationId = msg['correlationId'] as String?;
              unawaited(captureLayout().then(
                (snapshot) => _send('client:layout:snapshot', snapshot,
                    correlationId: correlationId),
                onError: (Object e) => _send('client:layout:snapshot',
                    {'error': e.toString()}, correlationId: correlationId),
              ));
            } else if (type == 'server:database:request_schema') {
              final correlationId = msg['correlationId'] as String?;
              unawaited(_databaseSchemas().then((databases) => _send(
                  'client:database:schema', {'databases': databases},
                  correlationId: correlationId)));
            } else if (type == 'server:database:query') {
              final payload = msg['payload'] as Map<String, dynamic>?;
              final correlationId = msg['correlationId'] as String?;
              unawaited(_runDatabaseQuery(
                payload?['database'] as String?,
                payload?['sql'] as String? ?? '',
              ).then((result) => _send('client:database:query_result', result,
                  correlationId: correlationId)));
            } else if (type == 'server:reload') {
              // Desktop asking the app to reload itself.
              // Flutter offers no public hot-reload API outside the IDE, so we
              // use `reassembleApplication` — the same mechanism Flutter's
              // own dev tools use — to rebuild the entire widget tree from
              // scratch. Works in debug mode only.
              _reloadApp();
            } else if (type == 'server:hot_restart') {
              // Heavier counterpart of `server:reload` — the "Hot Restart"
              // button from the Flutter IDE. By default we still call
              // `reassembleApplication` (Flutter has no public kill-and-
              // relaunch API), but apps can register `onHotRestartRequest`
              // to actually wipe state and remount their root MaterialApp.
              _hotRestartApp();
            } else if (_serverHandlers.containsKey(type)) {
              // Plugin-registered handlers (layout inspector, mock server,
              // etc.). Fire in registration order; swallow exceptions so
              // a buggy plugin can't kill the message loop.
              final handlers = _serverHandlers[type];
              if (handlers != null) {
                final payload = msg['payload'] as Map<String, dynamic>?;
                for (final h in handlers) {
                  try { h(payload ?? const {}); } catch (_) {}
                }
              }
            }
          } catch (_) {}
        },
        onDone: () {
          _connected = false;
          try { onDisconnected?.call(); } catch (_) {}
          _scheduleReconnect();
        },
        onError: (_) {
          _connected = false;
          _scheduleReconnect();
        },
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _sendHandshake() {
    _send('client:handshake', {
      'deviceInfo': {
        'deviceId': _deviceId,
        'deviceName': _deviceName,
        'platform': _platform,
        'osVersion': Platform.operatingSystemVersion,
        'appName': _appName,
        'appVersion': _appVersion,
        if (_versionCode != null) 'versionCode': _versionCode,
        'sdkVersion': devConnectSdkVersion,
      },
    });
    _announceCommands();
  }

  /// Tells the desktop which custom commands it can run (Commands panel).
  void _announceCommands() {
    _send('client:custom:commands', {'commands': _commandHandlers.keys.toList()});
  }

  /// Default handler for [WsMessageTypes.serverReload].
  ///
  /// Flutter has no public hot-reload API accessible from runtime, but the
  /// dev tools (and `flutter run -r`) trigger a full widget rebuild by
  /// calling [WidgetsBinding.reassembleApplication]. We use the same path —
  /// it fires `didChangeAppLifecycleState`-like notifications down the tree
  /// so any `StatefulWidget` can re-initialize. Works in debug builds only.
  void _reloadApp() {
    if (onReloadRequest != null) {
      onReloadRequest!();
      return;
    }
    try {
      WidgetsBinding.instance.reassembleApplication();
    } catch (_) {
      // WidgetsBinding not initialized yet (init() called too early) — ignore.
    }
  }

  /// Default handler for [WsMessageTypes.serverHotRestart].
  ///
  /// The Flutter IDE's "Hot Restart" tears down every `State` and re-runs
  /// `main()` — we can't do that from a runtime SDK (no public kill-and-
  /// relaunch API), so by default we just delegate to [reassembleApplication]
  /// for parity with [server:reload]. Apps that need true state-reset
  /// semantics register [onHotRestartRequest] to remount their root widget.
  void _hotRestartApp() {
    if (onHotRestartRequest != null) {
      onHotRestartRequest!();
      return;
    }
    try {
      WidgetsBinding.instance.reassembleApplication();
    } catch (_) {
      // WidgetsBinding not initialized yet — ignore.
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () async {
      if (!_connected) {
        // If auto mode, re-detect host on reconnect
        if (_auto) {
          _host = await autoDetectHost(_port);
        }
        connect();
      }
    });
  }

  void _send(String type, Map<String, dynamic> payload,
      {String? correlationId}) {
    final message = {
      'id': _uuid.v4(),
      'type': type,
      'deviceId': _deviceId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': payload,
      if (correlationId != null) 'correlationId': correlationId,
    };

    String json;
    try {
      json = jsonEncode(message);
    } catch (e) {
      // Body contains non-serializable data — sanitize and retry
      message['payload'] = sanitizeForJson(payload);
      try {
        json = jsonEncode(message);
      } catch (_) {
        return; // Give up completely
      }
    }
    if (_socket != null && _connected) {
      _socket!.add(json);
    } else if (_messageQueue.length < 1000) {
      _messageQueue.add(json);
    }
  }

  /// Makes [value] JSON-encodable: maps and lists keep their shape, and
  /// only the values jsonEncode rejects (a DateTime, a custom object)
  /// become strings. A map or list met again inside itself becomes
  /// `<cycle>`; past 32 levels or 10,000 values the copy stops with `…`.
  @visibleForTesting
  static dynamic sanitizeForJson(dynamic value, [int depth = 0]) {
    final path = Set<Object>.identity();
    var left = 10000;
    dynamic copy(dynamic value, int depth) {
      if (left-- <= 0) return '…';
      if (value is Map || value is Iterable) {
        if (depth >= 32) return '…';
        if (!path.add(value)) return '<cycle>';
        final out = value is Map
            ? <String, dynamic>{
                for (final e in value.entries.takeWhile((_) => left >= 0))
                  '${e.key}': copy(e.value, depth + 1),
              }
            : [
                for (final v in value.takeWhile((_) => left >= 0))
                  copy(v, depth + 1),
              ];
        path.remove(value);
        return out;
      }
      try {
        jsonEncode(value);
        return value;
      } catch (_) {
        try {
          return value.toString();
        } catch (_) {
          return '<unserializable>';
        }
      }
    }

    return copy(value, depth);
  }

  // --- Safe static API (for interceptors/reporters that may run before init) ---

  static void safeLog(String message, {String? tag, Map<String, dynamic>? metadata}) {
    safeSend('client:log', {
      'level': 'info',
      'message': message,
      if (tag != null) 'tag': tag,
      if (metadata != null) 'metadata': metadata,
    });
  }

  static void safeSendLog({
    required String level,
    required String message,
    String? tag,
    String? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    safeSend('client:log', {
      'level': level,
      'message': message,
      if (tag != null) 'tag': tag,
      if (stackTrace != null) 'stackTrace': stackTrace,
      if (metadata != null) 'metadata': metadata,
    });
  }

  static void safeReportNetworkStart({
    required String requestId,
    required String method,
    required String url,
    // `dynamic` (not `String`) so nested Map/List header values can
    // survive — the desktop inspector JSON-encodes them for display.
    // Calling .toString() on a `{apiKey: 'x'}` value would render as
    // `{apiKey: x}` and lose structure.
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    safeSend('client:network:request_start', {
      'requestId': requestId,
      'method': method,
      'url': url,
      'startTime': DateTime.now().millisecondsSinceEpoch,
      if (headers != null) 'requestHeaders': headers,
      if (body != null) 'requestBody': body,
    });
  }

  static void safeReportNetworkComplete({
    required String requestId,
    required String method,
    required String url,
    required int statusCode,
    required int startTime,
    Map<String, dynamic>? requestHeaders,
    Map<String, dynamic>? responseHeaders,
    dynamic requestBody,
    dynamic responseBody,
    String? error,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    safeSend('client:network:request_complete', {
      'requestId': requestId,
      'method': method,
      'url': url,
      'statusCode': statusCode,
      'startTime': startTime,
      'endTime': now,
      'duration': now - startTime,
      if (requestHeaders != null) 'requestHeaders': requestHeaders,
      if (responseHeaders != null) 'responseHeaders': responseHeaders,
      if (requestBody != null) 'requestBody': requestBody,
      if (responseBody != null) 'responseBody': responseBody,
      if (error != null) 'error': error,
    });
  }

  static void safeReportStateChange({
    required String stateManager,
    required String action,
    Map<String, dynamic>? previousState,
    Map<String, dynamic>? nextState,
    List<Map<String, dynamic>>? diff,
  }) {
    safeSend('client:state:change', {
      'stateManager': stateManager,
      'action': action,
      if (previousState != null) 'previousState': previousState,
      if (nextState != null) 'nextState': nextState,
      if (diff != null) 'diff': diff,
    });
  }

  static void safeReportStorageOperation({
    required String storageType,
    required String key,
    dynamic value,
    required String operation,
  }) {
    safeSend('client:storage:operation', {
      'storageType': storageType,
      'key': key,
      if (value != null) 'value': value,
      'operation': operation,
    });
  }

  // --- Public API ---

  /// Internal method used by log interceptor.
  void sendLog({
    required String level,
    required String message,
    String? tag,
    String? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _send('client:log', {
      'level': level,
      'message': message,
      if (tag != null) 'tag': tag,
      if (stackTrace != null) 'stackTrace': stackTrace,
      if (metadata != null) 'metadata': metadata,
    });
  }

  void log(String message, {String? tag, Map<String, dynamic>? metadata}) {
    _send('client:log', {
      'level': 'info',
      'message': message,
      if (tag != null) 'tag': tag,
      if (metadata != null) 'metadata': metadata,
    });
  }

  void debug(String message, {String? tag, Map<String, dynamic>? metadata}) {
    _send('client:log', {
      'level': 'debug',
      'message': message,
      if (tag != null) 'tag': tag,
      if (metadata != null) 'metadata': metadata,
    });
  }

  void warn(String message, {String? tag, Map<String, dynamic>? metadata}) {
    _send('client:log', {
      'level': 'warn',
      'message': message,
      if (tag != null) 'tag': tag,
      if (metadata != null) 'metadata': metadata,
    });
  }

  void error(String message,
      {String? tag, String? stackTrace, Map<String, dynamic>? metadata}) {
    _send('client:log', {
      'level': 'error',
      'message': message,
      if (tag != null) 'tag': tag,
      if (stackTrace != null) 'stackTrace': stackTrace,
      if (metadata != null) 'metadata': metadata,
    });
  }

  void reportNetworkStart({
    required String requestId,
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    _send('client:network:request_start', {
      'requestId': requestId,
      'method': method,
      'url': url,
      'startTime': DateTime.now().millisecondsSinceEpoch,
      if (headers != null) 'requestHeaders': headers,
      if (body != null) 'requestBody': body,
    });
  }

  void reportNetworkComplete({
    required String requestId,
    required String method,
    required String url,
    required int statusCode,
    required int startTime,
    Map<String, dynamic>? requestHeaders,
    Map<String, dynamic>? responseHeaders,
    dynamic requestBody,
    dynamic responseBody,
    String? error,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _send('client:network:request_complete', {
      'requestId': requestId,
      'method': method,
      'url': url,
      'statusCode': statusCode,
      'startTime': startTime,
      'endTime': now,
      'duration': now - startTime,
      if (requestHeaders != null) 'requestHeaders': requestHeaders,
      if (responseHeaders != null) 'responseHeaders': responseHeaders,
      if (requestBody != null) 'requestBody': requestBody,
      if (responseBody != null) 'responseBody': responseBody,
      if (error != null) 'error': error,
    });
  }

  void reportStateChange({
    required String stateManager,
    required String action,
    Map<String, dynamic>? previousState,
    Map<String, dynamic>? nextState,
    List<Map<String, dynamic>>? diff,
  }) {
    _send('client:state:change', {
      'stateManager': stateManager,
      'action': action,
      if (previousState != null) 'previousState': previousState,
      if (nextState != null) 'nextState': nextState,
      if (diff != null) 'diff': diff,
    });
  }

  void reportStorageOperation({
    required String storageType,
    required String key,
    dynamic value,
    required String operation,
  }) {
    _send('client:storage:operation', {
      'storageType': storageType,
      'key': key,
      if (value != null) 'value': value,
      'operation': operation,
    });
  }

  // ---- State snapshot ----

  void sendStateSnapshot({
    required String stateManager,
    required Map<String, dynamic> state,
  }) {
    _send('client:state:snapshot', {
      'stateManager': stateManager,
      'state': state,
    });
  }

  // ---- Benchmark API ----

  void benchmarkStart(String title) {
    _benchmarks[title] = [DateTime.now().millisecondsSinceEpoch];
  }

  void benchmarkStep(String title) {
    _benchmarks[title]?.add(DateTime.now().millisecondsSinceEpoch);
  }

  void benchmarkStop(String title) {
    final times = _benchmarks.remove(title);
    if (times == null || times.isEmpty) return;

    final startTime = times.first;
    final endTime = DateTime.now().millisecondsSinceEpoch;
    final steps = <Map<String, dynamic>>[];
    for (int i = 1; i < times.length; i++) {
      steps.add({
        'title': 'step $i',
        'timestamp': times[i],
        'delta': times[i] - times[i - 1],
      });
    }

    _send('client:benchmark', {
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'duration': endTime - startTime,
      'steps': steps,
    });
  }

  // ---- Performance Profiling ----

  void reportPerformanceMetric({
    required String metricType,
    required double value,
    String? label,
    Map<String, dynamic>? metadata,
  }) {
    _send('client:performance:metric', {
      'metricType': metricType,
      'value': value,
      if (label != null) 'label': label,
      if (metadata != null) 'metadata': metadata,
    });
  }

  void reportMemoryLeak({
    required String leakType,
    required String objectName,
    required String detail,
    String severity = 'warning',
    String? stackTrace,
    int? retainedSizeBytes,
    Map<String, dynamic>? metadata,
  }) {
    _send('client:memory:leak', {
      'leakType': leakType,
      'objectName': objectName,
      'detail': detail,
      'severity': severity,
      if (stackTrace != null) 'stackTrace': stackTrace,
      if (retainedSizeBytes != null) 'retainedSizeBytes': retainedSizeBytes,
      if (metadata != null) 'metadata': metadata,
    });
  }

  // ---- Custom Display ----

  /// Send a custom display value to DevConnect desktop.
  ///
  /// ```dart
  /// DevConnect.instance.display(
  ///   'User Profile',
  ///   value: {'name': 'John', 'age': 30},
  ///   preview: 'John, 30',
  ///   image: 'base64-encoded-image-string',
  /// );
  /// ```
  void display(
    String name, {
    dynamic value,
    String? preview,
    String? image,
    Map<String, dynamic>? metadata,
  }) {
    _send('client:display', {
      'name': name,
      if (value != null) 'value': value,
      if (preview != null) 'preview': preview,
      if (image != null) 'image': image,
      if (metadata != null) 'metadata': metadata,
    });
  }

  // ---- Async Operations (Saga/Task tracking) ----

  /// Report an async operation (saga step, background task, etc.).
  ///
  /// ```dart
  /// DevConnect.instance.reportAsyncOperation(
  ///   operationType: 'saga_call',
  ///   description: 'Fetching user data',
  ///   status: 'start',
  ///   sagaName: 'userSaga',
  /// );
  ///
  /// // Later, when it completes:
  /// DevConnect.instance.reportAsyncOperation(
  ///   operationType: 'saga_call',
  ///   description: 'Fetching user data',
  ///   status: 'resolve',
  ///   sagaName: 'userSaga',
  ///   duration: 350,
  ///   result: {'userId': 123},
  /// );
  /// ```
  void reportAsyncOperation({
    required String operationType,
    required String description,
    required String status,
    int? duration,
    String? sagaName,
    String? error,
    dynamic result,
    Map<String, dynamic>? metadata,
  }) {
    _send('client:async:operation', {
      'operationType': operationType,
      'description': description,
      'status': status,
      if (duration != null) 'duration': duration,
      if (sagaName != null) 'sagaName': sagaName,
      if (error != null) 'error': error,
      if (result != null) 'result': result,
      if (metadata != null) 'metadata': metadata,
    });
  }

  // ---- Custom commands ----

  void registerCommand(
      String name, dynamic Function(Map<String, dynamic>?) handler) {
    _commandHandlers[name] = handler;
    // Before connecting, the handshake announces every command so far.
    if (_connected) _announceCommands();
  }

  // ---- Storage, deep links, replay ----

  Future<void> _handleStorageCommand(String type, Map<String, dynamic> p) =>
      server_commands.handleStorageCommand(_storages, _send, type, p);

  // ---- Databases ----

  void registerDatabase(String name,
      Future<List<Map<String, Object?>>> Function(String sql) query) {
    _databases[name] = query;
  }

  Future<List<Map<String, dynamic>>> _databaseSchemas() =>
      server_commands.databaseSchemas(_databases);

  /// SQLite tables with their columns and row counts; empty if unreadable.
  @visibleForTesting
  static Future<List<Map<String, dynamic>>> sqliteTables(
          Future<List<Map<String, Object?>>> Function(String sql) query) =>
      server_commands.sqliteTables(query);

  Future<Map<String, dynamic>> _runDatabaseQuery(
          String? database, String sql) =>
      server_commands.runDatabaseQuery(_databases, database, sql);

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _connected = false;
    await _socket?.close();
    _socket = null;
  }
}
