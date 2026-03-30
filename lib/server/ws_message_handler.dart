import 'dart:async';

import '../core/constants/ws_constants.dart';
import '../models/device_info.dart';
import '../models/log/log_entry.dart';
import '../models/network/network_entry.dart';
import '../models/state/state_change.dart';
import '../models/display/display_entry.dart';
import '../models/performance/performance_entry.dart';
import '../models/storage/storage_entry.dart';
import 'protocol/dc_message.dart';
import 'ws_server.dart';

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

  late final StreamSubscription<DCMessage> _messageSub;
  late final StreamSubscription<DeviceInfo> _connectionSub;
  late final StreamSubscription<String> _disconnectionSub;

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

  void _handleLog(DCMessage message) {
    final entry = LogEntry(
      id: message.id,
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
    final entry = NetworkEntry(
      id: p['requestId'] as String? ?? message.id,
      deviceId: message.deviceId,
      method: p['method'] as String? ?? 'GET',
      url: p['url'] as String? ?? '',
      statusCode: p['statusCode'] as int? ?? 0,
      requestHeaders: _castStringMap(p['requestHeaders']),
      responseHeaders: _castStringMap(p['responseHeaders']),
      requestBody: p['requestBody'],
      responseBody: p['responseBody'],
      startTime: p['startTime'] as int? ?? message.timestamp,
      endTime: p['endTime'] as int?,
      duration: p['duration'] as int?,
      error: p['error'] as String?,
      isComplete: message.type == WsMessageTypes.clientNetworkRequestComplete,
      source: p['source'] as String? ?? 'app',
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
      id: message.id,
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
      id: message.id,
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
    switch (type.toLowerCase()) {
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
      default:
        return StorageType.sharedPreferences;
    }
  }

  void _handlePerformance(DCMessage message) {
    final p = message.payload;
    final entry = PerformanceEntry(
      id: message.id,
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
      id: message.id,
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
      id: message.id,
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
      id: message.id,
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
  }
}
