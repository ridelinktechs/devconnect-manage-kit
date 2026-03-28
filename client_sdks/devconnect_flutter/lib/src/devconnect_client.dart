import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

typedef OnConnected = void Function();
typedef OnDisconnected = void Function();

class DevConnectClient {
  static DevConnectClient? _instance;
  static DevConnectClient get instance => _instance!;

  /// Returns instance or null if not yet initialized.
  /// Use this in interceptors/reporters that may run before init().
  static DevConnectClient? get instanceSafe => _instance;

  /// Pre-init message queue: messages sent before init() completes.
  static final List<Map<String, dynamic>> _preInitQueue = [];

  /// Send a message safely - queues if init() hasn't completed yet.
  /// Use this instead of instance.xxx() in interceptors/reporters.
  static void safeSend(String type, Map<String, dynamic> payload) {
    // No-op in release builds — zero overhead
    if (!kDebugMode) return;
    final inst = _instance;
    if (inst != null) {
      inst._send(type, payload);
    } else if (_preInitQueue.length < 500) {
      _preInitQueue.add({'type': type, 'payload': payload});
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
  /// Custom command handlers: command name -> handler
  final Map<String, dynamic Function(Map<String, dynamic>?)> _commandHandlers = {};
  /// Active benchmarks
  final Map<String, List<int>> _benchmarks = {}; // title -> [startTime, ...stepTimes]

  bool get isConnected => _connected;
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

  /// Get a stable device identifier using device_info_plus.
  /// Android: UUID from androidId + packageName
  /// iOS: identifierForVendor (already UUID)
  static Future<String> _getStableDeviceId(String appName) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        final id = android.id; // ANDROID_ID
        // Convert to UUID v5 format via Uuid.v5
        return const Uuid().v5(Namespace.url.value, '$id:$appName');
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        return ios.identifierForVendor ?? const Uuid().v5(Namespace.url.value, '$appName:${Platform.localHostname}');
      } else if (Platform.isMacOS) {
        final mac = await deviceInfo.macOsInfo;
        final guid = mac.systemGUID ?? mac.computerName;
        return const Uuid().v5(Namespace.url.value, '$guid:$appName');
      }
    } catch (_) {}
    // Fallback
    return const Uuid().v5(Namespace.url.value, '$appName:${Platform.localHostname}:${Platform.operatingSystem}');
  }

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
    int port = 9091,
    required String appName,
    String appVersion = '1.0.0',
    String? versionCode,
    String? deviceName,
    String platform = 'flutter',
    bool auto_ = true,
  }) async {
    final resolvedHost = host == null || host == 'auto'
        ? await _autoDetectHost(port)
        : host;

    final stableDeviceId = await _getStableDeviceId(appName);

    _instance = DevConnectClient._(
      host: resolvedHost,
      port: port,
      appName: appName,
      appVersion: appVersion,
      versionCode: versionCode,
      deviceName: deviceName ?? _defaultDeviceName(),
      deviceId: stableDeviceId,
      platform: platform,
      auto_: auto_,
    );
    await _instance!.connect();
    return _instance!;
  }

  static String _defaultDeviceName() {
    // Use localHostname for a meaningful device name (e.g., "Johns-iPhone")
    final hostname = Platform.localHostname;
    if (hostname.isNotEmpty && hostname != 'localhost') return hostname;
    if (Platform.isAndroid) return 'Android Device';
    if (Platform.isIOS) return 'iOS Device';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown Device';
  }

  /// UDP discovery port — server broadcasts beacons here.
  static const int _discoveryPort = 41234;

  /// XOR key for obfuscating cached data.
  static const String _cacheKey = 'DcN3t\$ecR7!';

  /// Cache file for last known server host.
  static File get _cacheFile =>
      File('${Directory.systemTemp.path}/.dc_session');

  /// XOR encrypt/decrypt with key.
  static String _xorCipher(String input, String key) {
    final output = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      output.writeCharCode(
          input.codeUnitAt(i) ^ key.codeUnitAt(i % key.length));
    }
    return output.toString();
  }

  /// Save discovered server host to cache file (encrypted).
  static Future<void> _saveHostCache(String host, int port) async {
    try {
      final plain = jsonEncode({
        'h': host,
        'p': port,
        't': DateTime.now().millisecondsSinceEpoch,
      });
      final encrypted = base64Encode(utf8.encode(_xorCipher(plain, _cacheKey)));
      await _cacheFile.writeAsString(encrypted);
    } catch (_) {}
  }

  /// Read cached server host (decrypted). Returns null if expired or missing.
  static Future<String?> _readHostCache(int port) async {
    try {
      if (!await _cacheFile.exists()) return null;
      final encrypted = await _cacheFile.readAsString();
      final decrypted =
          _xorCipher(utf8.decode(base64Decode(encrypted)), _cacheKey);
      final data = jsonDecode(decrypted) as Map<String, dynamic>;
      // Expire after 24 hours
      final cachedTime = data['t'] as int? ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - cachedTime > 24 * 3600000) {
        return null;
      }
      if (data['p'] != port) return null;
      return data['h'] as String?;
    } catch (_) {}
    return null;
  }

  /// Auto-detect the DevConnect desktop host IP.
  ///
  /// 0. Try cached host from last session (instant)
  /// 1. Race: UDP beacon vs known emulator/USB addresses (parallel)
  /// 2. Scan local subnet (real device WiFi)
  /// 3. Scan common subnets as fallback
  static Future<String> _autoDetectHost(int port) async {
    // 0. Try cached host from previous session (instant reconnect)
    final cached = await _readHostCache(port);
    if (cached != null && await _tryHost(cached, port, 500)) {
      return cached;
    }

    // 1. Race: UDP beacon + known hosts in parallel
    //    USB (adb reverse) → localhost/10.0.2.2 responds fast
    //    WiFi → UDP beacon responds fast
    //    Whoever wins first, we use it.
    final knownHosts = Platform.isAndroid
        ? ['10.0.2.2', '10.0.3.2', 'localhost', '127.0.0.1']
        : ['localhost', '127.0.0.1'];

    final raceFutures = <Future<String?>>[];

    // UDP beacon listener
    raceFutures.add(_listenForBeacon(port));

    // Known hosts (try all in parallel)
    for (final host in knownHosts) {
      raceFutures.add(
        _tryHost(host, port, 800).then((ok) => ok ? host : null),
      );
    }

    // Wait for first non-null result, or all to complete
    final raceResult = await _firstNonNull(raceFutures);
    if (raceResult != null) {
      await _saveHostCache(raceResult, port);
      return raceResult;
    }

    // 2. Scan device's own subnet (real device on same WiFi)
    try {
      final interfaces = await NetworkInterface.list();
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
              final found = await _scanSubnet(subnet, port);
              if (found != null) {
                await _saveHostCache(found, port);
                return found;
              }
            }
          }
        }
      }
    } catch (_) {}

    // 3. Scan common subnets as fallback
    for (final subnet in ['192.168.1', '192.168.0', '192.168.2', '10.0.0', '10.0.1', '172.16.0']) {
      final found = await _scanSubnet(subnet, port);
      if (found != null) {
        await _saveHostCache(found, port);
        return found;
      }
    }

    // Fallback
    return Platform.isAndroid ? '10.0.2.2' : 'localhost';
  }

  /// Returns the first non-null result from a list of futures.
  /// Waits for all to complete; returns first non-null in order.
  static Future<String?> _firstNonNull(List<Future<String?>> futures) async {
    final completer = Completer<String?>();
    int remaining = futures.length;

    for (final future in futures) {
      future.then((value) {
        if (value != null && !completer.isCompleted) {
          completer.complete(value);
        } else {
          remaining--;
          if (remaining == 0 && !completer.isCompleted) {
            completer.complete(null);
          }
        }
      }).catchError((_) {
        remaining--;
        if (remaining == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    return completer.future;
  }

  /// Listen for a UDP beacon from the DevConnect server.
  /// Server broadcasts {"type":"devconnect_beacon","port":9090,...}
  /// every 2 seconds. We listen for up to 3 seconds.
  static Future<String?> _listenForBeacon(int expectedPort) async {
    RawDatagramSocket? udp;
    try {
      udp = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _discoveryPort,
        reuseAddress: true,
      );

      final completer = Completer<String?>();
      final timer = Timer(const Duration(seconds: 3), () {
        if (!completer.isCompleted) completer.complete(null);
      });

      udp.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = udp!.receive();
          if (datagram != null && !completer.isCompleted) {
            try {
              final data = jsonDecode(utf8.decode(datagram.data));
              if (data['type'] == 'devconnect_beacon') {
                final serverPort = data['port'] as int?;
                if (serverPort == expectedPort) {
                  timer.cancel();
                  completer.complete(datagram.address.address);
                }
              }
            } catch (_) {}
          }
        }
      });

      return await completer.future;
    } catch (_) {
      return null;
    } finally {
      udp?.close();
    }
  }

  /// Try connecting to a single host with timeout.
  static Future<bool> _tryHost(String host, int port, int timeoutMs) async {
    try {
      final socket = await Socket.connect(host, port,
          timeout: Duration(milliseconds: timeoutMs));
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Scan a subnet (x.x.x.1 through x.x.x.30) in parallel.
  /// Returns first host that responds, or null.
  static Future<String?> _scanSubnet(String subnet, int port) async {
    final futures = <Future<String?>>[];
    for (int i = 1; i <= 30; i++) {
      final host = '$subnet.$i';
      futures.add(
        _tryHost(host, port, 400).then((ok) => ok ? host : null),
      );
    }
    final results = await Future.wait(futures);
    for (final result in results) {
      if (result != null) return result;
    }
    return null;
  }

  Future<void> connect() async {
    try {
      _socket = await WebSocket.connect('ws://$_host:$_port');
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
                final result = _commandHandlers[cmd]!(args);
                _send('client:custom:command_result', {
                  'command': cmd,
                  'result': result,
                }, correlationId: msg['correlationId'] as String?);
              }
            }
          } catch (_) {}
        },
        onDone: () {
          _connected = false;
          onDisconnected?.call();
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
        'sdkVersion': '1.0.0',
      },
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () async {
      if (!_connected) {
        // If auto mode, re-detect host on reconnect
        if (_auto) {
          _host = await _autoDetectHost(_port);
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

    final json = jsonEncode(message);
    if (_socket != null && _connected) {
      _socket!.add(json);
    } else if (_messageQueue.length < 1000) {
      _messageQueue.add(json);
    }
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
    Map<String, String>? headers,
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
    Map<String, String>? requestHeaders,
    Map<String, String>? responseHeaders,
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
    Map<String, String>? headers,
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
    Map<String, String>? requestHeaders,
    Map<String, String>? responseHeaders,
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
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _connected = false;
    await _socket?.close();
    _socket = null;
  }
}
