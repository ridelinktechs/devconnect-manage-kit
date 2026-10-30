import 'dart:async';
import 'dart:convert';

import '../core/constants/ws_constants.dart';
import '../core/utils/network/network_service_detector.dart';
import '../core/utils/network/network_url_utils.dart';
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

part 'handlers/display_messages.dart';
part 'handlers/log_messages.dart';
part 'handlers/network_messages.dart';
part 'handlers/performance_messages.dart';
part 'handlers/round_messages.dart';
part 'handlers/state_messages.dart';
part 'handlers/storage_messages.dart';

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
  final _customCommandsController = StreamController<Map<String, dynamic>>.broadcast();
  final _databaseSchemaController = StreamController<Map<String, dynamic>>.broadcast();
  final _storageSnapshotController = StreamController<Map<String, dynamic>>.broadcast();
  final _layoutController = StreamController<Map<String, dynamic>>.broadcast();
  final _databaseQueryController = StreamController<Map<String, dynamic>>.broadcast();
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

  /// `{deviceId, commands}`: the custom commands a device's app registered.
  Stream<Map<String, dynamic>> get onCustomCommands =>
      _customCommandsController.stream;

  /// `{deviceId, width, height, screenshot, root}`: the app's screen and
  /// view tree.
  Stream<Map<String, dynamic>> get onLayoutSnapshot => _layoutController.stream;

  /// `{deviceId, storageType, entries, error?}`: a store's current contents.
  Stream<Map<String, dynamic>> get onStorageSnapshot =>
      _storageSnapshotController.stream;

  /// `{deviceId, databases}`: the app's registered databases and tables.
  Stream<Map<String, dynamic>> get onDatabaseSchema =>
      _databaseSchemaController.stream;

  /// `{deviceId, database, columns, rows, truncated, error, executionTimeMs}`.
  Stream<Map<String, dynamic>> get onDatabaseQueryResult =>
      _databaseQueryController.stream;
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

  /// Requests still waiting for their other half, oldest first, keyed by
  /// device + operation (GraphQL) or device + service/method (gRPC): how
  /// a response finds its request when an older SDK sends no
  /// `operationId` / `callId`.
  final _pendingGraphql = <String, List<String>>{};
  final _pendingGrpc = <String, List<String>>{};

  /// Source-map cache. Each SDK upload is identified by `mapId`
  /// (typically `<bundle>:<buildId>`); re-uploads of the same map are
  /// dropped on the desktop so we only decode once. The decoded map
  /// is then used by the Error stack panel to symbolicate minified
  /// frames.
  final _sourceMaps = <String, Map<String, dynamic>>{}; // mapId -> decoded JSON

  /// Mint a unique id for a one-shot entry (log, state, storage, etc.).
  /// Unlike network round-trips these don't have a `start`/`complete`
  /// pair, so we just guarantee that no two entries ever share the
  /// same id — if `message.id` was already seen, disambiguate.
  String _uniqueOneShotId(String messageId) {
    if (_seenMessageIds.add(messageId)) {
      _trimSeenMessageIds();
      return messageId;
    }
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
        _handleStorage(message);
        break;
      case WsMessageTypes.clientLayoutSnapshot:
        _layoutController.add({
          'deviceId': message.deviceId,
          ...message.payload,
        });
        break;
      case WsMessageTypes.clientStorageAllData:
        _storageSnapshotController.add({
          'deviceId': message.deviceId,
          ...message.payload,
        });
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
      case WsMessageTypes.clientCustomCommands:
        _customCommandsController.add({
          'deviceId': message.deviceId,
          'commands': [
            for (final c in message.payload['commands'] as List? ?? const [])
              if (c is String) c,
          ],
        });
        break;
      case WsMessageTypes.clientDatabaseSchema:
        _databaseSchemaController.add({
          'deviceId': message.deviceId,
          ...message.payload,
        });
        break;
      case WsMessageTypes.clientDatabaseQueryResult:
        _databaseQueryController.add({
          'deviceId': message.deviceId,
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

  /// Sends a custom command to the app. Returns the id the SDKs echo back
  /// as `correlationId` in `client:custom:command_result`.
  String sendCustomCommand(String deviceId, String command, {Map<String, dynamic>? args}) {
    final id = _uuid.v4();
    server.sendToDevice(deviceId, DCMessage(
      id: id,
      type: WsMessageTypes.serverCustomCommand,
      deviceId: 'server',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {'command': command, if (args != null) 'args': args},
      correlationId: id,
    ));
    return id;
  }

  void _command(String deviceId, String type, [Map<String, dynamic> payload = const {}]) {
    server.sendToDevice(deviceId, DCMessage(
      id: _uuid.v4(),
      type: type,
      deviceId: 'server',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: payload,
    ));
  }

  /// Asks the app for the contents of its registered stores (or just
  /// [storageType]); each comes back as `client:storage:all_data`.
  void requestStorage(String deviceId, {String? storageType}) => _command(
      deviceId, WsMessageTypes.serverStorageRequestAll,
      {'storageType': ?storageType});

  void writeStorage(String deviceId, String storageType, String key, Object? value) =>
      _command(deviceId, WsMessageTypes.serverStorageWrite,
          {'storageType': storageType, 'key': key, 'value': value});

  void deleteStorage(String deviceId, String storageType, String key) => _command(
      deviceId, WsMessageTypes.serverStorageDelete,
      {'storageType': storageType, 'key': key});

  void clearStorage(String deviceId, String storageType) => _command(
      deviceId, WsMessageTypes.serverStorageClear, {'storageType': storageType});

  /// Asks the app for its screen and view tree (`client:layout:snapshot`).
  void captureLayout(String deviceId) =>
      _command(deviceId, WsMessageTypes.serverLayoutCapture);

  /// Opens [url] in the app, as a deep link.
  void openUrl(String deviceId, String url) =>
      _command(deviceId, WsMessageTypes.serverOpenUrl, {'url': url});

  /// Opens the React Native dev menu.
  void showDevMenu(String deviceId) =>
      _command(deviceId, WsMessageTypes.serverDevMenu);

  /// Applies network conditions to the app's own HTTP traffic.
  void setNetworkConditions(String deviceId, {int latencyMs = 0, bool offline = false}) =>
      _command(deviceId, WsMessageTypes.serverNetworkThrottle,
          {'latencyMs': latencyMs, 'offline': offline});

  /// Has the app send [entry]'s request again.
  void replayRequest(NetworkEntry entry) => _command(
      entry.deviceId, WsMessageTypes.serverNetworkReplay, {
        'requestId': entry.id,
        'method': entry.method,
        'url': entry.url,
        'headers': entry.requestHeaders,
        'body': ?entry.requestBody,
      });

  /// Asks the app for the tables of every database it registered; they
  /// come back as `client:database:schema`.
  void requestDatabaseSchema(String deviceId) {
    server.sendToDevice(deviceId, DCMessage(
      id: _uuid.v4(),
      type: WsMessageTypes.serverDatabaseRequestSchema,
      deviceId: 'server',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: const {},
    ));
  }

  /// Runs [sql] on the app's [database]; the rows come back as
  /// `client:database:query_result`.
  void queryDatabase(String deviceId, String database, String sql) {
    server.sendToDevice(deviceId, DCMessage(
      id: _uuid.v4(),
      type: WsMessageTypes.serverDatabaseQuery,
      deviceId: 'server',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {'database': database, 'sql': sql},
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

  /// Round 4: clear every mock rule on the SDK side — an empty rule list,
  /// which every SDK applies (none handles a separate clear message).
  void clearMockRules(String deviceId) => installMockRules(deviceId, const []);

  /// Read-only snapshot of the cached source maps. Used by the Error
  /// inspector to symbolicate stack frames; safe to call from any
  /// isolate.
  Map<String, Map<String, dynamic>> snapshotSourceMaps() =>
      Map.unmodifiable(_sourceMaps);

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
    _customCommandsController.close();
    _databaseSchemaController.close();
    _storageSnapshotController.close();
    _layoutController.close();
    _databaseQueryController.close();
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
