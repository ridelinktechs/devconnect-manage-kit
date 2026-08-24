import 'dart:async';
import 'dart:convert';

import '../core/constants/ws_constants.dart';
import '../core/utils/network_service_detector.dart';
import '../core/utils/network_url_utils.dart';
import '../models/device_info.dart';
import '../models/log/log_entry.dart';
import '../models/log/error_event.dart';
import '../models/network/network_entry.dart';
import '../models/state/state_change.dart';
import '../models/display/display_entry.dart';
import '../models/performance/performance_entry.dart';
import '../models/storage/storage_entry.dart';
import '../models/round/state_round_entry.dart';
import '../models/round/protocol_entry.dart';
import '../models/round/mock_entry.dart';
import 'protocol/dc_message.dart';
import 'ws_server.dart';
import 'package:uuid/uuid.dart';

/// Parses the wire `storageType` string into the [StorageType] enum
/// plus an optional instance/namespace [storeId].
///
/// SDKs may send `<type>:<storeId>` to distinguish between multiple
/// instances of the same backend — e.g. two MMKV instances
/// (`mmkv:user-storage` and `mmkv:settings`). Bare `<type>` strings
/// leave [storeId] null. The base type match is case-insensitive; the
/// label is preserved verbatim. Unrecognised bases fall back to
/// [StorageType.sharedPreferences] (same behaviour as the legacy parser).
({StorageType storageType, String? storeId}) parseStorageTypeAndStoreId(
    String raw) {
  final lower = raw.toLowerCase();
  final colon = lower.indexOf(':');
  String base;
  String? label;
  if (colon >= 0) {
    base = lower.substring(0, colon);
    final tail = raw.substring(colon + 1).trim();
    label = tail.isEmpty ? null : tail;
  } else {
    base = lower;
  }

  final StorageType type;
  switch (base) {
    case 'async_storage':
    case 'asyncstorage':
      type = StorageType.asyncStorage;
      break;
    case 'shared_preferences':
    case 'sharedpreferences':
      type = StorageType.sharedPreferences;
      break;
    case 'hive':
      type = StorageType.hive;
      break;
    case 'sqlite':
      type = StorageType.sqlite;
      break;
    case 'realm':
      type = StorageType.realm;
      break;
    case 'objectbox':
      type = StorageType.objectbox;
      break;
    case 'floor':
      type = StorageType.floor;
      break;
    case 'sembast':
      type = StorageType.sembast;
      break;
    case 'sqflite':
      type = StorageType.sqflite;
      break;
    case 'watermelondb':
      type = StorageType.watermelondb;
      break;
    case 'encrypted_storage':
    case 'encryptedstorage':
      type = StorageType.encryptedStorage;
      break;
    case 'sqldelight':
      type = StorageType.sqldelight;
      break;
    case 'mmkv':
      type = StorageType.mmkv;
      break;
    default:
      type = StorageType.sharedPreferences;
      break;
  }
  return (storageType: type, storeId: label);
}

class WsMessageHandler {
  final WsServer server;

  final _logController = StreamController<LogEntry>.broadcast();
  final _networkController = StreamController<NetworkEntry>.broadcast();
  final _stateController = StreamController<StateChange>.broadcast();
  final _storageController = StreamController<StorageEntry>.broadcast();
  final _deviceController = StreamController<DeviceInfo>.broadcast();
  final _disconnectController = StreamController<String>.broadcast();
  final _benchmarkController = StreamController<Map<String, dynamic>>.broadcast();
  final _benchmarkStepController = StreamController<Map<String, dynamic>>.broadcast();
  final _stateSnapshotController = StreamController<Map<String, dynamic>>.broadcast();
  final _customResultController = StreamController<Map<String, dynamic>>.broadcast();
  final _performanceController = StreamController<PerformanceEntry>.broadcast();
  final _memoryLeakController = StreamController<MemoryLeakEntry>.broadcast();
  final _displayController = StreamController<DisplayEntry>.broadcast();
  final _asyncOpController = StreamController<AsyncOperationEntry>.broadcast();
  final _errorController = StreamController<ErrorEvent>.broadcast();

  // Round 2-5 streams.
  final _stateRoundController = StreamController<StateRoundEntry>.broadcast();
  final _graphqlController = StreamController<GraphqlEntry>.broadcast();
  final _websocketController = StreamController<WebsocketFrameEntry>.broadcast();
  final _grpcController = StreamController<GrpcCallEntry>.broadcast();
  final _mockAuditController = StreamController<MockedRequestEntry>.broadcast();

  Stream<LogEntry> get onLog => _logController.stream;
  Stream<NetworkEntry> get onNetwork => _networkController.stream;
  Stream<StateChange> get onState => _stateController.stream;
  Stream<StorageEntry> get onStorage => _storageController.stream;
  Stream<DeviceInfo> get onDeviceConnected => _deviceController.stream;
  Stream<String> get onDeviceDisconnected => _disconnectController.stream;
  Stream<Map<String, dynamic>> get onBenchmark => _benchmarkController.stream;
  Stream<Map<String, dynamic>> get onBenchmarkStep => _benchmarkStepController.stream;
  Stream<Map<String, dynamic>> get onStateSnapshot => _stateSnapshotController.stream;
  Stream<Map<String, dynamic>> get onCustomResult => _customResultController.stream;
  Stream<PerformanceEntry> get onPerformance => _performanceController.stream;
  Stream<MemoryLeakEntry> get onMemoryLeak => _memoryLeakController.stream;
  Stream<DisplayEntry> get onDisplay => _displayController.stream;
  Stream<AsyncOperationEntry> get onAsyncOperation => _asyncOpController.stream;
  Stream<ErrorEvent> get onError => _errorController.stream;
  Stream<StateRoundEntry> get onStateRound => _stateRoundController.stream;
  Stream<GraphqlEntry> get onGraphql => _graphqlController.stream;
  Stream<WebsocketFrameEntry> get onWebsocket => _websocketController.stream;
  Stream<GrpcCallEntry> get onGrpc => _grpcController.stream;
  Stream<MockedRequestEntry> get onMockAudit => _mockAuditController.stream;

  late final StreamSubscription<DCMessage> _messageSub;
  late final StreamSubscription<DeviceInfo> _connectionSub;
  late final StreamSubscription<String> _disconnectionSub;

  /// State for an open round-trip (start seen, complete still pending).
  /// All messages — start, complete, success, error — of a single
  /// logical request share the same canonical id.
  ///
  /// Key = canonical id (which we mint once per round-trip).
  /// Value = the bare `requestId` so we can look up "is this requestId
  /// currently busy with another open round-trip?" when a new message
  /// arrives.
  final _openTrips = <String, String>{}; // canonicalId -> base requestId
  int _networkSeq = 0;
  final _uuid = const Uuid();

  /// Tracks ids we've already emitted for one-shot entries (log, state,
  /// storage, performance, display, async, error). If a client reuses
  /// the same `message.id` across two messages — e.g. a retried log or
  /// a state snapshot sent twice — we disambiguate so the row in the
  /// UI list stays a distinct entry.
  final _seenMessageIds = <String>{};
  int _genericSeq = 0;

  /// Round-trip bookkeeping for WebSocket connections. Keyed by
  /// `connectionId` so we can pair `ws_open` with the matching
  /// `ws_close` (close code/reason are surfaced on the close entry).
  /// Trimmed to a hard cap to avoid unbounded growth from long-lived
  /// sockets.
  final _openWebsocketConnections = <String, String>{}; // connectionId -> url
  int _wsConnectionSeq = 0;

  /// Round-trip bookkeeping for gRPC calls (Android splits one call
  /// into `_start` + `_end`). Keyed by `callId`, same dedup pattern as
  /// `_openTrips` for network requests.
  final _openGrpcCalls = <String, String>{}; // canonicalId -> callId
  int _grpcSeq = 0;

  /// Source-map cache. Each SDK upload is identified by `mapId`
  /// (typically `<bundle>:<buildId>`); re-uploads of the same map are
  /// dropped on the desktop so we only decode once. The decoded map
  /// is then used by the Error stack panel to symbolicate minified
  /// frames.
  final _sourceMaps = <String, Map<String, dynamic>>{}; // mapId -> decoded JSON

  /// Build a unique id for one logical network request.
  ///
  /// One round-trip = one start + one complete (whether success or
  /// error) sharing a `requestId`. All messages of that round-trip
  /// must emit the SAME id so the provider can merge them into a
  /// single row.
  ///
  /// When two genuinely concurrent requests arrive with the same
  /// `requestId`, the first start mints `base` as the canonical id and
  /// marks it open; the second start sees the open trip and mints a
  /// fresh disambiguated id (also marked open). Each round-trip's
  /// complete then finds its own canonical id via the open-trips map.
  String _uniqueNetworkId(DCMessage message, Map<String, dynamic> payload) {
    final raw = payload['requestId'] as String?;
    final base = (raw != null && raw.isNotEmpty) ? raw : message.id;
    final isComplete =
        message.type == WsMessageTypes.clientNetworkRequestComplete;
    final canonical = _mintOrReuseCanonical(base, isComplete);
    if (!isComplete) {
      // Start — register the round-trip as open so the matching
      // complete can find it. Also remember the base for dedup.
      _openTrips[canonical] = base;
    } else {
      // Complete — drop the open-trip entry. If no open trip existed
      // (orphan complete or disambiguated start whose complete we
      // also disambiguated), nothing to remove.
      _openTrips.remove(canonical);
    }
    _trimOpenTrips();
    return canonical;
  }

  /// For a start: if no round-trip is currently open for this base,
  /// mint a fresh canonical id and remember it as open. If another
  /// round-trip is already open for the same base, disambiguate and
  /// remember a fresh id.
  ///
  /// For a complete: locate the open round-trip for this base and
  /// reuse its canonical id (this is the start→complete round-trip
  /// case). If no open trip exists (orphan complete), mint a fresh
  /// canonical id and don't open a trip (it'll just stand alone).
  String _mintOrReuseCanonical(String base, bool isComplete) {
    if (!isComplete) {
      // Find any existing open trip for this base.
      final existing = _existingOpenCanonicalForBase(base);
      if (existing != null && _isOpenFor(existing)) {
        return _disambiguate(base);
      }
      return base;
    }
    // Complete: find the open round-trip for this base.
    final existing = _existingOpenCanonicalForBase(base);
    if (existing != null) {
      return existing;
    }
    return base;
  }

  String? _existingOpenCanonicalForBase(String base) {
    for (final entry in _openTrips.entries) {
      if (entry.value == base) return entry.key;
    }
    return null;
  }

  bool _isOpenFor(String canonical) => _openTrips.containsKey(canonical);

  String _disambiguate(String base) {
    final seq = (++_networkSeq).toRadixString(36);
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rand = _uuid.v4().substring(0, 4);
    return '$base-$micros-$seq-$rand';
  }

  void _trimOpenTrips() {
    if (_openTrips.length <= 2048) return;
    final drop = _openTrips.length - 1024;
    final keys = _openTrips.keys.toList(growable: false);
    for (var i = 0; i < drop; i++) {
      _openTrips.remove(keys[i]);
    }
  }

  /// Mint a unique id for a one-shot entry (log, state, storage, etc.).
  /// Unlike network round-trips these don't have a `start`/`complete`
  /// pair, so we just guarantee that no two entries ever share the
  /// same id — if `message.id` was already seen, disambiguate.
  String _uniqueOneShotId(String messageId) {
    if (_seenMessageIds.add(messageId)) return messageId;
    final seq = (++_genericSeq).toRadixString(36);
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rand = _uuid.v4().substring(0, 4);
    final newId = '$messageId-$micros-$seq-$rand';
    _seenMessageIds.add(newId);
    _trimSeenMessageIds();
    return newId;
  }

  void _trimSeenMessageIds() {
    if (_seenMessageIds.length <= 4096) return;
    final drop = _seenMessageIds.length - 2048;
    final keys = _seenMessageIds.toList(growable: false);
    for (var i = 0; i < drop; i++) {
      _seenMessageIds.remove(keys[i]);
    }
  }

  WsMessageHandler({required this.server}) {
    _messageSub = server.onMessage.listen(_handleMessage);
    _connectionSub = server.onConnection.listen((device) => _deviceController.add(device));
    _disconnectionSub = server.onDisconnection.listen((id) => _disconnectController.add(id));
  }

  void _handleMessage(DCMessage message) {
    switch (message.type) {
      case WsMessageTypes.clientLog:
        _handleLog(message);
        break;
      case WsMessageTypes.clientNetworkRequestStart:
      case WsMessageTypes.clientNetworkRequestComplete:
        _handleNetwork(message);
        break;
      case WsMessageTypes.clientStateChange:
        _handleState(message);
        break;
      case WsMessageTypes.clientStorageOperation:
      case WsMessageTypes.clientStorageAllData:
        _handleStorage(message);
        break;
      case WsMessageTypes.clientBenchmark:
        _benchmarkController.add({
          'deviceId': message.deviceId,
          ...message.payload,
        });
        break;
      case WsMessageTypes.clientStateSnapshot:
        _stateSnapshotController.add({
          'deviceId': message.deviceId,
          ...message.payload,
        });
        break;
      case WsMessageTypes.clientPerformanceMetric:
        _handlePerformance(message);
        break;
      case WsMessageTypes.clientMemoryLeak:
        _handleMemoryLeak(message);
        break;
      case WsMessageTypes.clientDisplay:
        _handleDisplay(message);
        break;
      case WsMessageTypes.clientAsyncOperation:
        _handleAsyncOperation(message);
        break;
      case WsMessageTypes.clientError:
      case WsMessageTypes.clientCrash:
        _handleError(message);
        break;
      case WsMessageTypes.clientCustom:
      case WsMessageTypes.clientCustomCommandResult:
        _customResultController.add({
          'deviceId': message.deviceId,
          'correlationId': message.correlationId,
          ...message.payload,
        });
        break;
      case WsMessageTypes.clientBlocChange:
      case WsMessageTypes.clientProviderUpdate:
      case WsMessageTypes.clientReactQueryChange:
      case WsMessageTypes.clientApolloOperation:
        _handleStateRound(message);
        break;
      case WsMessageTypes.clientGraphqlOperation:
      case WsMessageTypes.clientGraphqlResponse:
        _handleGraphql(message);
        break;
      case WsMessageTypes.clientWebsocketOpen:
      case WsMessageTypes.clientWebsocketFrame:
      case WsMessageTypes.clientWebsocketClose:
        _handleWebsocket(message);
        break;
      case WsMessageTypes.clientGrpcCallStart:
      case WsMessageTypes.clientGrpcCallEnd:
      case WsMessageTypes.clientGrpcCall:
        _handleGrpc(message);
        break;
      case WsMessageTypes.clientBenchmarkStep:
        _handleBenchmarkStep(message);
        break;
      case WsMessageTypes.clientMockedRequest:
        _handleMockAudit(message);
        break;
      case WsMessageTypes.clientSourceMapUpload:
        _handleSourceMap(message);
        break;
    }
  }

  // ---- Server -> Client commands ----

  /// Dispatch a Redux action to the app
  void dispatchReduxAction(String deviceId, Map<String, dynamic> action) {
    server.sendToDevice(deviceId, DCMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: WsMessageTypes.serverReduxDispatch,
      deviceId: 'server',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {'action': action},
    ));
  }

  /// Restore state snapshot on the app
  void restoreState(String deviceId, Map<String, dynamic> state) {
    server.sendToDevice(deviceId, DCMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: WsMessageTypes.serverStateRestore,
      deviceId: 'server',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {'state': state},
    ));
  }

  /// Send a custom command to the app
  void sendCustomCommand(String deviceId, String command, {Map<String, dynamic>? args}) {
    server.sendToDevice(deviceId, DCMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: WsMessageTypes.serverCustomCommand,
      deviceId: 'server',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {'command': command, if (args != null) 'args': args},
    ));
  }

  /// Ask the connected device app to reload itself.
  /// On Flutter: triggers full widget rebuild (`reassembleApplication`).
  /// On React Native: triggers Metro reload (`DevSettings.reload()`).
  /// On Android: recreates the host activity.
  void triggerReload(String deviceId) {
    server.sendToDevice(deviceId, DCMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: WsMessageTypes.serverReload,
      deviceId: 'server',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: const {},
    ));
  }

  /// "Hot restart" — a heavier variant of [triggerReload].
  /// Primarily a Flutter-only concept: the official hot-restart tears down
  /// every `State` (the same way killing and re-launching the app does)
  /// without losing the Dart isolate. We surface it on the wire so the UI
  /// can offer the same Hot Reload / Hot Restart pair that the Flutter IDE
  /// does. Non-Flutter SDKs fall back to the same behaviour as
  /// [triggerReload] (RN reloads Metro, Android recreates the activity).
  void triggerHotRestart(String deviceId) {
    server.sendToDevice(deviceId, DCMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: WsMessageTypes.serverHotRestart,
      deviceId: 'server',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: const {},
    ));
  }

  /// Broadcast reload to every connected device.
  /// Pass [hotRestart] = true to send the heavier `server:hot_restart`
  /// message instead of the standard `server:reload`.
  void broadcastReload({bool hotRestart = false}) {
    for (final conn in server.connections.values) {
      if (hotRestart) {
        triggerHotRestart(conn.deviceInfo.deviceId);
      } else {
        triggerReload(conn.deviceInfo.deviceId);
      }
    }
  }

  /// Round 4: replace the SDK's mock-rule list with [rules].
  void installMockRules(String deviceId, List<MockRule> rules) {
    server.sendToDevice(deviceId, DCMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: WsMessageTypes.serverMockRulesInstall,
      deviceId: 'server',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {
        'rules': rules.map((r) => r.toWireJson()).toList(),
      },
    ));
  }

  /// Round 4: clear every mock rule on the SDK side.
  void clearMockRules(String deviceId) {
    server.sendToDevice(deviceId, DCMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: WsMessageTypes.serverMockRulesClear,
      deviceId: 'server',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: const {},
    ));
  }

  /// Round 4: toggle a single mock rule without re-sending the whole list.
  void toggleMockRule(String deviceId, String ruleId, bool enabled) {
    server.sendToDevice(deviceId, DCMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: WsMessageTypes.serverMockRuleToggle,
      deviceId: 'server',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {'ruleId': ruleId, 'enabled': enabled},
    ));
  }

  void _handleLog(DCMessage message) {
    final entry = LogEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      level: _parseLogLevel(message.payload['level'] as String? ?? 'info'),
      message: message.payload['message'] as String? ?? '',
      timestamp: message.timestamp,
      metadata: message.payload['metadata'] as Map<String, dynamic>?,
      stackTrace: message.payload['stackTrace'] as String?,
      tag: message.payload['tag'] as String?,
    );
    _logController.add(entry);
  }

  void _handleNetwork(DCMessage message) {
    final p = message.payload;
    final reqHeaders = _castStringMap(p['requestHeaders']);
    final resHeaders = _castStringMap(p['responseHeaders']);
    final reqBody = p['requestBody'];
    final resBody = p['responseBody'];
    final url = normalizeNetworkUrl(p['url'] as String?);
    final detected = detectService(url,
        headers: {...reqHeaders, ...resHeaders}, body: reqBody);
    final entry = NetworkEntry(
      id: _uniqueNetworkId(message, p),
      deviceId: message.deviceId,
      method: p['method'] as String? ?? 'GET',
      url: url,
      statusCode: p['statusCode'] as int? ?? 0,
      requestHeaders: reqHeaders,
      responseHeaders: resHeaders,
      requestBody: reqBody,
      responseBody: resBody,
      startTime: p['startTime'] as int? ?? message.timestamp,
      endTime: p['endTime'] as int?,
      duration: p['duration'] as int?,
      error: p['error'] as String?,
      isComplete: message.type == WsMessageTypes.clientNetworkRequestComplete,
      source: p['source'] as String? ?? 'app',
      serviceName: detected?.name,
      serviceAction: detected?.action,
      via: p['via'] as String? ?? NetworkVia.unknown,
    );
    _networkController.add(entry);
  }

  void _handleState(DCMessage message) {
    final p = message.payload;
    final diffList = (p['diff'] as List<dynamic>?)
            ?.map(
              (d) =>
                  StateDiffEntry.fromJson(d as Map<String, dynamic>),
            )
            .toList() ??
        [];

    final entry = StateChange(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      stateManagerType: p['stateManager'] as String? ?? 'unknown',
      actionName: p['action'] as String? ?? '',
      previousState:
          (p['previousState'] as Map<String, dynamic>?) ?? {},
      nextState: (p['nextState'] as Map<String, dynamic>?) ?? {},
      diff: diffList,
      timestamp: message.timestamp,
    );
    _stateController.add(entry);
  }

  void _handleStorage(DCMessage message) {
    final p = message.payload;
    final parsed = parseStorageTypeAndStoreId(
      p['storageType'] as String? ?? '',
    );
    final entry = StorageEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      storageType: parsed.storageType,
      storeId: parsed.storeId,
      key: p['key'] as String? ?? '',
      value: p['value'],
      operation: p['operation'] as String? ?? 'read',
      timestamp: message.timestamp,
    );
    _storageController.add(entry);
  }

  LogLevel _parseLogLevel(String level) {
    switch (level.toLowerCase()) {
      case 'debug':
        return LogLevel.debug;
      case 'warn':
      case 'warning':
        return LogLevel.warn;
      case 'error':
        return LogLevel.error;
      default:
        return LogLevel.info;
    }
  }

  void _handlePerformance(DCMessage message) {
    final p = message.payload;
    final entry = PerformanceEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      metricType: _parseMetricType(p['metricType'] as String? ?? 'fps'),
      value: (p['value'] as num?)?.toDouble() ?? 0.0,
      timestamp: message.timestamp,
      metadata: p['metadata'] as Map<String, dynamic>?,
    );
    _performanceController.add(entry);
  }

  void _handleMemoryLeak(DCMessage message) {
    final p = message.payload;
    final entry = MemoryLeakEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      leakType: _parseLeakType(p['leakType'] as String? ?? 'custom'),
      objectName: p['objectName'] as String? ?? '',
      detail: p['detail'] as String? ?? '',
      severity: _parseLeakSeverity(p['severity'] as String? ?? 'warning'),
      timestamp: message.timestamp,
      stackTrace: p['stackTrace'] as String?,
      retainedSizeBytes: p['retainedSizeBytes'] as int?,
      metadata: p['metadata'] as Map<String, dynamic>?,
    );
    _memoryLeakController.add(entry);
  }

  PerformanceMetricType _parseMetricType(String type) {
    switch (type) {
      case 'fps': return PerformanceMetricType.fps;
      case 'frameBuildTime': case 'frame_build_time': return PerformanceMetricType.frameBuildTime;
      case 'frameRasterTime': case 'frame_raster_time': return PerformanceMetricType.frameRasterTime;
      case 'memoryUsage': case 'memory_usage': return PerformanceMetricType.memoryUsage;
      case 'memoryPeak': case 'memory_peak': return PerformanceMetricType.memoryPeak;
      case 'memoryAllocationRate': case 'memory_allocation_rate': return PerformanceMetricType.memoryAllocationRate;
      case 'cpuUsage': case 'cpu_usage': return PerformanceMetricType.cpuUsage;
      case 'jankFrame': case 'jank_frame': return PerformanceMetricType.jankFrame;
      case 'networkActivity': case 'network_activity': return PerformanceMetricType.networkActivity;
      case 'startupTime': case 'startup_time': return PerformanceMetricType.startupTime;
      case 'batteryLevel': case 'battery_level': return PerformanceMetricType.batteryLevel;
      case 'thermalState': case 'thermal_state': return PerformanceMetricType.thermalState;
      case 'threadCount': case 'thread_count': return PerformanceMetricType.threadCount;
      case 'diskRead': case 'disk_read': return PerformanceMetricType.diskRead;
      case 'diskWrite': case 'disk_write': return PerformanceMetricType.diskWrite;
      case 'anr': return PerformanceMetricType.anr;
      default: return PerformanceMetricType.fps;
    }
  }

  MemoryLeakType _parseLeakType(String type) {
    switch (type) {
      case 'undisposedController': return MemoryLeakType.undisposedController;
      case 'undisposedStream': return MemoryLeakType.undisposedStream;
      case 'undisposedTimer': return MemoryLeakType.undisposedTimer;
      case 'undisposedAnimationController': return MemoryLeakType.undisposedAnimationController;
      case 'widgetLeak': return MemoryLeakType.widgetLeak;
      case 'growingCollection': return MemoryLeakType.growingCollection;
      default: return MemoryLeakType.custom;
    }
  }

  void _handleDisplay(DCMessage message) {
    final p = message.payload;
    final entry = DisplayEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      name: p['name'] as String? ?? 'Display',
      timestamp: message.timestamp,
      value: p['value'],
      preview: p['preview'] as String?,
      image: p['image'] as String?,
      metadata: p['metadata'] as Map<String, dynamic>?,
    );
    _displayController.add(entry);
  }

  void _handleAsyncOperation(DCMessage message) {
    final p = message.payload;
    final entry = AsyncOperationEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      operationType: _parseAsyncOpType(p['operationType'] as String? ?? 'custom'),
      description: p['description'] as String? ?? '',
      status: _parseAsyncOpStatus(p['status'] as String? ?? 'start'),
      timestamp: message.timestamp,
      duration: p['duration'] as int?,
      sagaName: p['sagaName'] as String?,
      error: p['error'] as String?,
      result: p['result'],
      metadata: p['metadata'] as Map<String, dynamic>?,
    );
    _asyncOpController.add(entry);
  }

  void _handleError(DCMessage message) {
    final p = message.payload;
    final entry = ErrorEvent(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      platform: _parseErrorPlatform(p['platform'] as String? ?? 'js'),
      severity: _parseErrorSeverity(p['severity'] as String? ?? 'error'),
      message: p['message'] as String? ?? '',
      timestamp: message.timestamp,
      stackTrace: p['stackTrace'] as String?,
      source: p['source'] as String?,
      deviceInfo: p['deviceInfo'] as String?,
      metadata: p['metadata'] as Map<String, dynamic>?,
    );
    _errorController.add(entry);
  }

  // ---- Round 2-5 handlers ----

  void _handleStateRound(DCMessage message) {
    final p = message.payload;
    final manager = switch (message.type) {
      WsMessageTypes.clientBlocChange => 'bloc',
      WsMessageTypes.clientProviderUpdate => 'provider',
      WsMessageTypes.clientReactQueryChange => 'react_query',
      WsMessageTypes.clientApolloOperation => 'apollo',
      _ => p['manager'] as String? ?? 'unknown',
    };
    final entry = StateRoundEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      manager: manager,
      action: p['action'] as String? ?? '',
      previousState:
          (p['previousState'] as Map?)?.cast<String, dynamic>() ?? const {},
      nextState:
          (p['nextState'] as Map?)?.cast<String, dynamic>() ?? const {},
      timestamp: message.timestamp,
      metadata: p['metadata'] as Map<String, dynamic>?,
    );
    _stateRoundController.add(entry);
  }

  void _handleGraphql(DCMessage message) {
    final p = message.payload;
    final id = _uniqueOneShotId(message.id);
    if (message.type == WsMessageTypes.clientGraphqlOperation) {
      final entry = GraphqlEntry(
        id: id,
        deviceId: message.deviceId,
        operation: p['operation'] as String? ?? 'anonymous',
        type: p['type'] as String? ?? 'query',
        variables: (p['variables'] as Map?)?.cast<String, dynamic>() ?? const {},
        isComplete: false,
        cacheHit: p['cacheHit'] as bool? ?? false,
        timestamp: message.timestamp,
        metadata: p['metadata'] as Map<String, dynamic>?,
      );
      _graphqlController.add(entry);
      return;
    }
    final entry = GraphqlEntry(
      id: id,
      deviceId: message.deviceId,
      operation: p['operation'] as String? ?? 'anonymous',
      type: p['type'] as String? ?? 'query',
      variables: (p['variables'] as Map?)?.cast<String, dynamic>() ?? const {},
      isComplete: true,
      latencyMs: p['latencyMs'] as int?,
      cacheHit: p['cacheHit'] as bool? ?? false,
      data: (p['data'] as Map?)?.cast<String, dynamic>(),
      errors: (p['errors'] as List?)
          ?.whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(),
      error: p['error'] as String?,
      timestamp: message.timestamp,
      metadata: p['metadata'] as Map<String, dynamic>?,
    );
    _graphqlController.add(entry);
  }

  void _handleWebsocket(DCMessage message) {
    final p = message.payload;
    final rawConnectionId = p['connectionId'] as String?;
    final url = p['url'] as String? ?? '';
    String connectionId;
    String direction;
    switch (message.type) {
      case WsMessageTypes.clientWebsocketOpen:
        direction = 'open';
        // SDKs are required to send a `connectionId`; if they don't,
        // mint one so the panel can still group later frames/close.
        connectionId = (rawConnectionId != null && rawConnectionId.isNotEmpty)
            ? rawConnectionId
            : _mintWebsocketConnectionId(url);
        _openWebsocketConnections[connectionId] = url;
        _trimWebsocketConnections();
        break;
      case WsMessageTypes.clientWebsocketClose:
        direction = 'close';
        connectionId = (rawConnectionId != null && rawConnectionId.isNotEmpty)
            ? rawConnectionId
            : _mintWebsocketConnectionId(url);
        _openWebsocketConnections.remove(connectionId);
        break;
      default:
        direction = p['direction'] as String? ?? 'sent';
        // Frames: fall back to the only open socket for this URL if
        // the SDK didn't attach a connectionId (older SDKs).
        connectionId = (rawConnectionId != null && rawConnectionId.isNotEmpty)
            ? rawConnectionId
            : _existingConnectionIdForUrl(url) ?? _mintWebsocketConnectionId(url);
        break;
    }
    final entry = WebsocketFrameEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      url: url,
      connectionId: connectionId,
      direction: direction,
      payload: p['payload'] as String? ?? '',
      sizeBytes: (p['sizeBytes'] as num?)?.toInt() ?? 0,
      timestamp: message.timestamp,
      closeCode: p['closeCode'] as int?,
      closeReason: p['closeReason'] as String?,
      metadata: p['metadata'] as Map<String, dynamic>?,
    );
    _websocketController.add(entry);
  }

  /// Mint a deterministic connection id from the URL when an SDK
  /// doesn't supply one. Uses the URL as-is so multiple events for the
  /// same socket collapse to a single id.
  String _mintWebsocketConnectionId(String url) {
    final seq = (++_wsConnectionSeq).toRadixString(36);
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return 'ws-$url-$micros-$seq';
  }

  String? _existingConnectionIdForUrl(String url) {
    for (final entry in _openWebsocketConnections.entries) {
      if (entry.value == url) return entry.key;
    }
    return null;
  }

  void _trimWebsocketConnections() {
    if (_openWebsocketConnections.length <= 512) return;
    final drop = _openWebsocketConnections.length - 256;
    final keys = _openWebsocketConnections.keys.toList(growable: false);
    for (var i = 0; i < drop; i++) {
      _openWebsocketConnections.remove(keys[i]);
    }
  }

  void _handleGrpc(DCMessage message) {
    final p = message.payload;
    // Legacy single-event format (`client:grpc_call` with all fields
    // on one message) passes through unchanged.
    if (message.type == WsMessageTypes.clientGrpcCall) {
      final entry = GrpcCallEntry(
        id: _uniqueOneShotId(message.id),
        deviceId: message.deviceId,
        service: p['service'] as String? ?? '',
        method: p['method'] as String? ?? '',
        request: p['request'] as String? ?? '',
        response: p['response'] as String?,
        timestamp: message.timestamp,
        latencyMs: p['latencyMs'] as int?,
        status: p['status'] as String?,
        error: p['error'] as String?,
        metadata: p['metadata'] as Map<String, dynamic>?,
      );
      _grpcController.add(entry);
      return;
    }
    // Split start/end format (Android). Round-trip merge identical in
    // shape to network round-trips: a shared `callId` ties them
    // together; the canonical id stays stable so the panel renders
    // both halves as a single row.
    final callId = p['callId'] as String? ?? message.id;
    final isEnd = message.type == WsMessageTypes.clientGrpcCallEnd;
    final canonical = _grpcCanonicalId(callId, isEnd);
    if (isEnd) {
      _openGrpcCalls.remove(canonical);
    }
    final entry = GrpcCallEntry(
      id: canonical,
      deviceId: message.deviceId,
      service: p['service'] as String? ?? '',
      method: p['method'] as String? ?? '',
      request: p['request'] as String? ?? '',
      response: p['response'] as String?,
      timestamp: message.timestamp,
      latencyMs: p['latencyMs'] as int?,
      status: p['status'] as String?,
      error: p['error'] as String?,
      metadata: p['metadata'] as Map<String, dynamic>?,
    );
    _grpcController.add(entry);
  }

  /// Round-trip id for split gRPC start/end events. Same shape as
  /// network round-trip — first start mints `callId` as canonical,
  /// end reuses it; concurrent same-callId disambiguates.
  String _grpcCanonicalId(String callId, bool isEnd) {
    if (isEnd) {
      final existing = _existingOpenGrpcCanonical(callId);
      if (existing != null) return existing;
      return callId;
    }
    final existing = _existingOpenGrpcCanonical(callId);
    if (existing != null) return _disambiguateGrpc(callId);
    _openGrpcCalls[callId] = callId;
    _trimOpenGrpcCalls();
    return callId;
  }

  String? _existingOpenGrpcCanonical(String callId) {
    for (final entry in _openGrpcCalls.entries) {
      if (entry.value == callId) return entry.key;
    }
    return null;
  }

  String _disambiguateGrpc(String base) {
    final seq = (++_grpcSeq).toRadixString(36);
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$base-$micros-$seq';
  }

  void _trimOpenGrpcCalls() {
    if (_openGrpcCalls.length <= 512) return;
    final drop = _openGrpcCalls.length - 256;
    final keys = _openGrpcCalls.keys.toList(growable: false);
    for (var i = 0; i < drop; i++) {
      _openGrpcCalls.remove(keys[i]);
    }
  }

  /// Per-step benchmark events. The Flutter SDK emits these between
  /// the `client:benchmark` summary start and end to mark individual
  /// checkpoints (frame samples, screen transitions). Forward each as
  /// a standalone event on the benchmark stream so the panel can
  /// render a chip timeline even before the parent summary arrives.
  void _handleBenchmarkStep(DCMessage message) {
    final p = message.payload;
    final payload = {
      'deviceId': message.deviceId,
      'benchmarkId': p['benchmarkId'] as String? ?? '',
      'title': p['title'] as String? ?? '',
      'timestamp': p['timestamp'] as int? ?? message.timestamp,
      'delta': p['delta'] as int?,
    };
    _benchmarkStepController.add(payload);
  }

  /// Decode and cache a source map. RN bundlers ship `.map` files at
  /// production build time; the SDK uploads them once per bundle/build
  /// and the desktop uses the cached JSON to symbolicate minified
  /// stack frames in the Errors tab.
  void _handleSourceMap(DCMessage message) {
    final p = message.payload;
    final mapId = p['mapId'] as String?;
    final raw = p['map'];
    if (mapId == null || mapId.isEmpty || raw == null) return;
    if (_sourceMaps.containsKey(mapId)) return;
    final decoded = raw is Map
        ? raw.cast<String, dynamic>()
        : _tryDecodeMapString(raw);
    if (decoded == null) return;
    _sourceMaps[mapId] = decoded;
    _trimSourceMaps();
  }

  /// A few SDKs stringify the map before sending; recover it lazily
  /// so the wire format stays flexible.
  Map<String, dynamic>? _tryDecodeMapString(dynamic raw) {
    if (raw is! String) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
    return null;
  }

  void _trimSourceMaps() {
    if (_sourceMaps.length <= 32) return;
    final drop = _sourceMaps.length - 16;
    final keys = _sourceMaps.keys.toList(growable: false);
    for (var i = 0; i < drop; i++) {
      _sourceMaps.remove(keys[i]);
    }
  }

  /// Read-only snapshot of the cached source maps. Used by the Error
  /// inspector to symbolicate stack frames; safe to call from any
  /// isolate.
  Map<String, Map<String, dynamic>> snapshotSourceMaps() =>
      Map.unmodifiable(_sourceMaps);

  void _handleMockAudit(DCMessage message) {
    final p = message.payload;
    final entry = MockedRequestEntry.fromAuditPayload(
      p,
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      timestamp: message.timestamp,
    );
    _mockAuditController.add(entry);
  }

  ErrorPlatform _parseErrorPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'android': return ErrorPlatform.android;
      case 'ios': return ErrorPlatform.ios;
      case 'native': return ErrorPlatform.native;
      default: return ErrorPlatform.js;
    }
  }

  ErrorSeverity _parseErrorSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'fatal': return ErrorSeverity.fatal;
      case 'crash': return ErrorSeverity.crash;
      case 'warning': return ErrorSeverity.warning;
      case 'info': return ErrorSeverity.info;
      default: return ErrorSeverity.error;
    }
  }

  AsyncOperationType _parseAsyncOpType(String type) {
    switch (type) {
      case 'saga_take': return AsyncOperationType.sagaTake;
      case 'saga_put': return AsyncOperationType.sagaPut;
      case 'saga_call': return AsyncOperationType.sagaCall;
      case 'saga_fork': return AsyncOperationType.sagaFork;
      case 'saga_all': return AsyncOperationType.sagaAll;
      case 'saga_race': return AsyncOperationType.sagaRace;
      case 'saga_select': return AsyncOperationType.sagaSelect;
      case 'saga_delay': return AsyncOperationType.sagaDelay;
      case 'async_task': return AsyncOperationType.asyncTask;
      case 'background_job': return AsyncOperationType.backgroundJob;
      default: return AsyncOperationType.custom;
    }
  }

  AsyncOperationStatus _parseAsyncOpStatus(String status) {
    switch (status) {
      case 'resolve': return AsyncOperationStatus.resolve;
      case 'reject': return AsyncOperationStatus.reject;
      default: return AsyncOperationStatus.start;
    }
  }

  MemoryLeakSeverity _parseLeakSeverity(String severity) {
    switch (severity) {
      case 'info': return MemoryLeakSeverity.info;
      case 'critical': return MemoryLeakSeverity.critical;
      default: return MemoryLeakSeverity.warning;
    }
  }

  /// Coerce a JSON-decoded map (keys/values are `dynamic`) into a flat
  /// `Map<String, String>`. Header values from RN SDKs are sometimes
  /// objects or arrays (e.g. `map: { apiKey: 'xxx' }`); calling `.toString()`
  /// on those would yield `[object Object]` (JS-style) or a noisy
  /// `{key: value}` rendering (Dart-style). JSON-encode nested types so
  /// the UI can render them as inspectable JSON. Primitives pass through
  /// unchanged — no quotes around `42` or `true`.
  Map<String, String> _castStringMap(dynamic map) {
    if (map is! Map) return {};
    return map.map((k, v) => MapEntry(k.toString(), _stringifyHeaderValue(v)));
  }

  /// Render a single header value as a string the UI can show. Handles
  /// three layers of defense so an object/array header survives intact
  /// end-to-end:
  ///   1. Real `Map`/`List` Dart values → pretty-print JSON (the SDK
  ///      sent a structured value, e.g. `map: { apiKey: 'x' }`).
  ///   2. Strings that look like JSON (start with `{`/`[`, end with
  ///      `}`/`]`) → try to parse and pretty-print. This catches the
  ///      case where the SDK pre-stringified via `JSON.stringify` before
  ///      sending over WS.
  ///   3. Strings that are unrecoverable (e.g. the literal
  ///      `[object Object]` from JS's `String(obj)`) → label them as
  ///      `<unrecoverable object>` so the user knows the original shape
  ///      is gone, but at least they don't see a useless placeholder.
  String _stringifyHeaderValue(dynamic v) {
    if (v == null) return '';
    if (v is String) return _decodeMaybeJsonString(v);
    if (v is num || v is bool) return v.toString();
    if (v is List || v is Map) {
      try {
        return const JsonEncoder.withIndent('  ').convert(v);
      } catch (_) {
        try {
          return jsonEncode(v);
        } catch (_) {
          return v.toString();
        }
      }
    }
    return v.toString();
  }

  /// If [s] looks like a JSON document (object or array), try to parse
  /// and pretty-print it. Otherwise return [s] verbatim. Strings that
  /// are unrecoverable object literals (`[object Object]`) get labeled
  /// so the user knows the original value was lost upstream.
  String _decodeMaybeJsonString(String s) {
    final t = s.trim();
    final looksLikeObject = t.startsWith('{') && t.endsWith('}');
    final looksLikeArray = t.startsWith('[') && t.endsWith(']');
    if (looksLikeObject || looksLikeArray) {
      try {
        final decoded = jsonDecode(t);
        if (decoded is Map || decoded is List) {
          return const JsonEncoder.withIndent('  ').convert(decoded);
        }
      } catch (_) {}
    }
    // JS's String(obj) on a plain object produces the literal
    // "[object Object]". There's no way to recover the original, so
    // label it clearly so the user knows the SDK stripped the value.
    if (s == '[object Object]') return '<unrecoverable object>';
    return s;
  }

  void dispose() {
    _messageSub.cancel();
    _connectionSub.cancel();
    _disconnectionSub.cancel();
    _logController.close();
    _networkController.close();
    _stateController.close();
    _storageController.close();
    _deviceController.close();
    _disconnectController.close();
    _benchmarkController.close();
    _benchmarkStepController.close();
    _stateSnapshotController.close();
    _customResultController.close();
    _performanceController.close();
    _memoryLeakController.close();
    _displayController.close();
    _asyncOpController.close();
    _errorController.close();
    _stateRoundController.close();
    _graphqlController.close();
    _websocketController.close();
    _grpcController.close();
    _mockAuditController.close();
  }
}
