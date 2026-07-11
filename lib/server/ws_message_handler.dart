import 'dart:async';

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
import 'protocol/dc_message.dart';
import 'ws_server.dart';
import 'package:uuid/uuid.dart';

class WsMessageHandler {
  final WsServer server;

  final _logController = StreamController<LogEntry>.broadcast();
  final _networkController = StreamController<NetworkEntry>.broadcast();
  final _stateController = StreamController<StateChange>.broadcast();
  final _storageController = StreamController<StorageEntry>.broadcast();
  final _deviceController = StreamController<DeviceInfo>.broadcast();
  final _disconnectController = StreamController<String>.broadcast();
  final _benchmarkController = StreamController<Map<String, dynamic>>.broadcast();
  final _stateSnapshotController = StreamController<Map<String, dynamic>>.broadcast();
  final _customResultController = StreamController<Map<String, dynamic>>.broadcast();
  final _performanceController = StreamController<PerformanceEntry>.broadcast();
  final _memoryLeakController = StreamController<MemoryLeakEntry>.broadcast();
  final _displayController = StreamController<DisplayEntry>.broadcast();
  final _asyncOpController = StreamController<AsyncOperationEntry>.broadcast();
  final _errorController = StreamController<ErrorEvent>.broadcast();

  Stream<LogEntry> get onLog => _logController.stream;
  Stream<NetworkEntry> get onNetwork => _networkController.stream;
  Stream<StateChange> get onState => _stateController.stream;
  Stream<StorageEntry> get onStorage => _storageController.stream;
  Stream<DeviceInfo> get onDeviceConnected => _deviceController.stream;
  Stream<String> get onDeviceDisconnected => _disconnectController.stream;
  Stream<Map<String, dynamic>> get onBenchmark => _benchmarkController.stream;
  Stream<Map<String, dynamic>> get onStateSnapshot => _stateSnapshotController.stream;
  Stream<Map<String, dynamic>> get onCustomResult => _customResultController.stream;
  Stream<PerformanceEntry> get onPerformance => _performanceController.stream;
  Stream<MemoryLeakEntry> get onMemoryLeak => _memoryLeakController.stream;
  Stream<DisplayEntry> get onDisplay => _displayController.stream;
  Stream<AsyncOperationEntry> get onAsyncOperation => _asyncOpController.stream;
  Stream<ErrorEvent> get onError => _errorController.stream;

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
    final entry = StorageEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      storageType: _parseStorageType(p['storageType'] as String? ?? ''),
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

  StorageType _parseStorageType(String type) {
    final lower = type.toLowerCase();

    // Handle "mmkv:label" format from SDK (e.g. "mmkv:user-storage")
    if (lower.startsWith('mmkv')) return StorageType.mmkv;

    switch (lower) {
      case 'async_storage':
      case 'asyncstorage':
        return StorageType.asyncStorage;
      case 'shared_preferences':
      case 'sharedpreferences':
        return StorageType.sharedPreferences;
      case 'hive':
        return StorageType.hive;
      case 'sqlite':
        return StorageType.sqlite;
      case 'realm':
        return StorageType.realm;
      case 'objectbox':
        return StorageType.objectbox;
      case 'floor':
        return StorageType.floor;
      case 'sembast':
        return StorageType.sembast;
      case 'sqflite':
        return StorageType.sqflite;
      case 'watermelondb':
        return StorageType.watermelondb;
      case 'encrypted_storage':
      case 'encryptedstorage':
        return StorageType.encryptedStorage;
      case 'sqldelight':
        return StorageType.sqldelight;
      default:
        return StorageType.sharedPreferences;
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

  Map<String, String> _castStringMap(dynamic map) {
    if (map is Map) {
      return map.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return {};
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
    _stateSnapshotController.close();
    _customResultController.close();
    _performanceController.close();
    _memoryLeakController.close();
    _displayController.close();
    _asyncOpController.close();
    _errorController.close();
  }
}
