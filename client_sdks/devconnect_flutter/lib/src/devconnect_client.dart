import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import 'layout_inspector.dart';
import 'storage_adapter.dart';
import 'version.dart';

typedef OnConnected = void Function();
typedef OnDisconnected = void Function();

/// Cached host + the server's stable machineId for identity verification.
class _CachedHost {
  final String host;
  final String machineId;
  const _CachedHost(this.host, this.machineId);
}

/// Hands out dart:io's own HttpClient, whatever overrides are installed.
class _NoHttpOverrides extends HttpOverrides {}

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
    int port = 9090,
    required String appName,
    String appVersion = '1.0.0',
    String? versionCode,
    String? deviceName,
    String platform = 'flutter',
    bool auto_ = true,
  }) async {
    final stableDeviceId = await _getStableDeviceId(appName);

    final client = _instance = DevConnectClient._(
      host: host ?? 'auto',
      port: port,
      appName: appName,
      appVersion: appVersion,
      versionCode: versionCode,
      deviceName: deviceName ?? _defaultDeviceName(),
      deviceId: stableDeviceId,
      platform: platform,
      auto_: auto_,
    );
    unawaited(() async {
      if (client._host == 'auto') client._host = await _autoDetectHost(port);
      await client.connect();
    }());
    return client;
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

  /// Opens DevConnect's own sockets past any HttpOverrides: through
  /// `DevConnectHttpOverrides` they would show up as the app's requests.
  static final _wsHttpClient =
      HttpOverrides.runWithHttpOverrides(HttpClient.new, _NoHttpOverrides());

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

  /// Save discovered server host to cache file (encrypted), keyed by host +
  /// machineId so stale entries from a different desktop can be invalidated.
  static Future<void> _saveHostCache(
      String host, int port, String? machineId) async {
    try {
      final plain = jsonEncode({
        'h': host,
        'p': port,
        't': DateTime.now().millisecondsSinceEpoch,
        if (machineId != null) 'm': machineId,
      });
      final encrypted = base64Encode(utf8.encode(_xorCipher(plain, _cacheKey)));
      await _cacheFile.writeAsString(encrypted);
    } catch (_) {}
  }

  /// Delete cached host entry. Used when verification fails — so the next
  /// connect falls through to fresh discovery rather than reusing the
  /// stale entry.
  static Future<void> _clearHostCache() async {
    try {
      if (await _cacheFile.exists()) await _cacheFile.delete();
    } catch (_) {}
  }

  /// Read cached server host (decrypted). Returns null if expired, missing,
  /// or if the cache doesn't carry a machineId (legacy entries are ignored
  /// since they can't be verified).
  static Future<_CachedHost?> _readHostCache(int port) async {
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
      final host = data['h'] as String?;
      final machineId = data['m'] as String?;
      // Require machineId — legacy caches without it cannot be verified and
      // would re-introduce the simulator/device-swap bug we are fixing.
      if (host == null || machineId == null || machineId.isEmpty) return null;
      return _CachedHost(host, machineId);
    } catch (_) {}
    return null;
  }

  /// Verify a cached host by opening a short-lived WebSocket and checking
  /// that the server announces the machineId we cached. This prevents the
  /// case where the cached IP now points at a different device or another
  /// service that just happens to listen on the same port.
  ///
  /// Returns true only when the server's `server:hello.machineId` matches
  /// [expectedMachineId]; false on connect failure, timeout, or mismatch.
  static Future<bool> _verifyCachedHost(
      String host, int port, String expectedMachineId) async {
    WebSocket? probe;
    try {
      probe = await WebSocket.connect('ws://$host:$port',
              customClient: _wsHttpClient)
          .timeout(const Duration(milliseconds: 1500));

      final helloCompleter = Completer<String?>();
      final sub = probe.listen(
        (data) {
          if (helloCompleter.isCompleted) return;
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            if (msg['type'] == 'server:hello') {
              final payload = msg['payload'] as Map<String, dynamic>?;
              helloCompleter.complete(payload?['machineId'] as String?);
            }
          } catch (_) {}
        },
        onError: (_) {
          if (!helloCompleter.isCompleted) helloCompleter.complete(null);
        },
        onDone: () {
          if (!helloCompleter.isCompleted) helloCompleter.complete(null);
        },
        cancelOnError: true,
      );

      final announcedId = await helloCompleter.future
          .timeout(const Duration(milliseconds: 1500));
      unawaited(sub.cancel());
      return announcedId != null && announcedId == expectedMachineId;
    } catch (_) {
      return false;
    } finally {
      try {
        await probe?.close();
      } catch (_) {}
    }
  }

  /// Auto-detect the DevConnect desktop host IP.
  ///
  /// 0. Try cached host from last session (instant)
  /// 1. Race: UDP beacon vs known emulator/USB addresses (parallel)
  /// 2. Scan local subnet (real device WiFi)
  /// 3. Scan common subnets as fallback
  static Future<String> _autoDetectHost(int port) async {
    // 0. Try cached host from previous session (instant reconnect).
    //    We verify the server's stable machineId matches what we cached —
    //    this catches the case where the cached IP now points at a
    //    different device (e.g. switched from iOS Simulator to a real
    //    iPhone, or back, after the Mac's address changed).
    final cached = await _readHostCache(port);
    if (cached != null) {
      if (await _verifyCachedHost(cached.host, port, cached.machineId)) {
        return cached.host;
      }
      // Stale or wrong machine — invalidate so the next discovery wins.
      await _clearHostCache();
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
      await _saveHostCache(raceResult, port, null);
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
                await _saveHostCache(found, port, null);
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
        await _saveHostCache(found, port, null);
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
      StreamSubscription<RawSocketEvent>? subscription;

      final timer = Timer(const Duration(seconds: 3), () {
        if (!completer.isCompleted) {
          subscription?.cancel();
          completer.complete(null);
        }
      });

      subscription = udp.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = udp!.receive();
          if (datagram != null && !completer.isCompleted) {
            try {
              final data = jsonDecode(utf8.decode(datagram.data));
              if (data['type'] == 'devconnect_beacon') {
                final serverPort = data['port'] as int?;
                if (serverPort == expectedPort) {
                  timer.cancel();
                  subscription?.cancel();
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
      // shortcut: a socket that connects after the timeout is left open.
      _socket = await WebSocket.connect('ws://$_host:$_port',
              customClient: _wsHttpClient)
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
                    _saveHostCache(_host, _port, serverMachineId));
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
              if (url != null) _openUrl(url);
            } else if (type == 'server:network:throttle') {
              final payload = msg['payload'] as Map?;
              setNetworkConditions(
                latencyMs: (payload?['latencyMs'] as num?)?.toInt() ?? 0,
                offline: payload?['offline'] == true,
              );
            } else if (type == 'server:network:replay') {
              unawaited(_replayRequest(
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

  /// Reads / writes / deletes / clears a registered storage, then sends its
  /// contents back.
  Future<void> _handleStorageCommand(
      String type, Map<String, dynamic> p) async {
    final storageType = p['storageType'] as String?;
    final targets = storageType == null
        ? _storages.entries.toList()
        : [
            if (_storages[storageType] case final adapter?)
              MapEntry(storageType, adapter),
          ];
    for (final MapEntry(key: name, value: adapter) in targets) {
      try {
        final key = p['key'] as String? ?? '';
        switch (type) {
          case 'server:storage:write':
            await adapter.set(key, p['value']);
          case 'server:storage:delete':
            await adapter.remove(key);
          case 'server:storage:clear':
            await adapter.clear();
        }
        _send('client:storage:all_data',
            {'storageType': name, 'entries': await adapter.getAll()});
      } catch (e) {
        _send('client:storage:all_data',
            {'storageType': name, 'entries': {}, 'error': e.toString()});
      }
    }
  }

  /// Delivers [url] the way the engine delivers a deep link, so the app's
  /// Router (or Navigator's onGenerateRoute) handles it.
  static void _openUrl(String url) {
    ServicesBinding.instance.channelBuffers.push(
      SystemChannels.navigation.name,
      SystemChannels.navigation.codec.encodeMethodCall(MethodCall(
          'pushRouteInformation', {'location': url, 'state': null})),
      (_) {},
    );
  }

  /// Sends a captured request again through `HttpClient`, which
  /// `DevConnectHttpOverrides` intercepts, so the replay shows up too.
  static Future<void> _replayRequest(Map<String, dynamic> p) async {
    final url = Uri.tryParse(p['url'] as String? ?? '');
    if (url == null) return;
    final method = (p['method'] as String? ?? 'GET').toUpperCase();
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, url);
      (p['headers'] as Map?)?.forEach((k, v) {
        if ('$k'.toLowerCase() != 'content-length') {
          request.headers.set('$k', '$v');
        }
      });
      final body = p['body'];
      if (body != null && method != 'GET' && method != 'HEAD') {
        request.write(body is String ? body : jsonEncode(body));
      }
      await (await request.close()).drain<void>();
    } catch (_) {
      // Reported like any other failed request.
    } finally {
      client.close();
    }
  }

  // ---- Databases ----

  void registerDatabase(String name,
      Future<List<Map<String, Object?>>> Function(String sql) query) {
    _databases[name] = query;
  }

  /// Rows past this are left out of a query result, which says `truncated`.
  static const _maxQueryRows = 1000;

  Future<List<Map<String, dynamic>>> _databaseSchemas() async => [
        for (final MapEntry(key: name, value: query) in _databases.entries)
          {'name': name, 'tables': await sqliteTables(query)},
      ];

  /// SQLite tables with their columns and row counts; empty if unreadable.
  @visibleForTesting
  static Future<List<Map<String, dynamic>>> sqliteTables(
      Future<List<Map<String, Object?>>> Function(String sql) query) async {
    try {
      final names = await query("SELECT name FROM sqlite_master WHERE "
          "type = 'table' AND name NOT LIKE 'sqlite_%' "
          "AND name <> 'android_metadata' ORDER BY name");
      return [
        for (final row in names)
          await () async {
            final table = '${row['name']}';
            final quoted = '"${table.replaceAll('"', '""')}"';
            final columns = await query('PRAGMA table_info($quoted)');
            final count = await query('SELECT COUNT(*) AS c FROM $quoted');
            return {
              'name': table,
              'columns': [
                for (final c in columns)
                  {
                    'name': '${c['name']}',
                    'type': '${c['type'] ?? ''}',
                    'isPrimaryKey': ((c['pk'] as num?) ?? 0) > 0,
                    'isNullable': ((c['notnull'] as num?) ?? 0) == 0,
                  },
              ],
              'rowCount': count.isEmpty ? 0 : count.first['c'],
            };
          }(),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _runDatabaseQuery(
      String? database, String sql) async {
    final stopwatch = Stopwatch()..start();
    final result = <String, dynamic>{'database': database};
    try {
      final query = _databases[database] ?? _databases.values.firstOrNull;
      if (query == null) {
        throw StateError(
            'No database registered with DevConnect.registerDatabase');
      }
      final select =
          RegExp(r'^\s*(select|with)\b', caseSensitive: false).hasMatch(sql);
      final inner = sql.replaceFirst(RegExp(r'[\s;]+$'), '');
      List<Map<String, Object?>> rows;
      try {
        rows = await query(select
            ? 'SELECT * FROM (\n$inner\n) LIMIT ${_maxQueryRows + 1}'
            : sql);
      } catch (_) {
        if (!select) rethrow;
        rows = await query(sql);
      }
      result
        ..['columns'] = rows.isEmpty ? <String>[] : rows.first.keys.toList()
        ..['rows'] = [
          for (final row in rows.take(_maxQueryRows))
            {
              for (final MapEntry(:key, :value) in row.entries)
                key: value is List<int> ? '<blob ${value.length} bytes>' : value,
            },
        ]
        ..['truncated'] = rows.length > _maxQueryRows;
    } catch (e) {
      result
        ..['columns'] = <String>[]
        ..['rows'] = <Map<String, dynamic>>[]
        ..['error'] = e.toString();
    }
    return result..['executionTimeMs'] = stopwatch.elapsedMilliseconds;
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _connected = false;
    await _socket?.close();
    _socket = null;
  }
}
