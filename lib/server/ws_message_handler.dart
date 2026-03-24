import 'dart:async';

import '../core/constants/ws_constants.dart';
import '../models/device_info.dart';
import '../models/log/log_entry.dart';
import '../models/network/network_entry.dart';
import '../models/state/state_change.dart';
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

  Stream<LogEntry> get onLog => _logController.stream;
  Stream<NetworkEntry> get onNetwork => _networkController.stream;
  Stream<StateChange> get onState => _stateController.stream;
  Stream<StorageEntry> get onStorage => _storageController.stream;
  Stream<DeviceInfo> get onDeviceConnected => _deviceController.stream;
  Stream<String> get onDeviceDisconnected => _disconnectController.stream;
  Stream<Map<String, dynamic>> get onBenchmark => _benchmarkController.stream;
  Stream<Map<String, dynamic>> get onStateSnapshot => _stateSnapshotController.stream;
  Stream<Map<String, dynamic>> get onCustomResult => _customResultController.stream;

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
  }
}
