import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/models/storage/storage_entry.dart';
import 'package:devconnect_manage_tool/server/protocol/dc_message.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';
import 'package:devconnect_manage_tool/server/ws_connection.dart';
import 'package:devconnect_manage_tool/server/ws_message_handler.dart';
import 'package:devconnect_manage_tool/server/ws_server.dart';
import 'package:devconnect_manage_tool/features/storage_viewer/provider/storage_providers.dart';

/// Pins the storage notifier's event-log semantics:
///
///   - Two distinct `message.id`s → 2 rows (even with identical content).
///   - Different storeId on the wire → 2 rows (regression for the
///     "instance id collapsed by parser" bug).
///
/// Id-based dedup already happens upstream: SDK `_send()` mints a fresh
/// UUID per call, and `WsMessageHandler._uniqueOneShotId` disambiguates
/// on retry. So at the notifier layer every entry is unique and we
/// just append.
void main() {
  late _Harness h;

  setUp(() {
    h = _Harness();
  });

  tearDown(() => h.dispose());

  test('same data + same timestamp, two distinct message.id → 2 rows', () async {
    // SDK generates a fresh id per call. Two `_send()` invocations →
    // two wire messages with different `id`. Even if the payload
    // (storageType/storeId/key/value/op/timestamp) is identical, the
    // notifier keeps both as separate events.
    await h.emit(_msg(id: 'a', timestamp: 1000));
    await h.emit(_msg(id: 'b', timestamp: 1000));

    expect(h.notifier.state, hasLength(2));
  });

  test('different storeId on the wire → 2 rows (regression)', () async {
    // The original bug: SDK MMKV reporter sends `mmkv:storeA` and
    // `mmkv:storeB`, but the server parser collapsed both to the same
    // `StorageType.mmkv` enum, causing the notifier to dedup. With the
    // `storeId` field carried through end-to-end, two distinct MMKV
    // instances produce two rows.
    await h.emit(_msg(id: 'a', storeId: 'storeA', timestamp: 1000));
    await h.emit(_msg(id: 'b', storeId: 'storeB', timestamp: 1000));

    expect(h.notifier.state, hasLength(2));
    expect(
      h.notifier.state.map((e) => e.storeId).toSet(),
      {'storeA', 'storeB'},
    );
  });
}

class _Harness {
  _Harness() {
    final fakeServer = _FakeWsServer();
    handler = WsMessageHandler(server: fakeServer);
    container = ProviderContainer(overrides: [
      wsMessageHandlerProvider.overrideWithValue(handler),
    ]);
    notifier = container.read(storageEntriesProvider.notifier);
    _server = fakeServer;
  }

  late final ProviderContainer container;
  late final WsMessageHandler handler;
  late final StorageNotifier notifier;
  late final _FakeWsServer _server;

  Future<void> emit(DCMessage m) async {
    _server.emit(m);
    // Drain microtasks so the broadcast stream propagates: server →
    // handler.onMessage → handler.onStorage → notifier.state.
    await Future<void>.delayed(Duration.zero);
  }

  void dispose() {
    notifier.cancelSubscription();
    handler.dispose();
    container.dispose();
  }
}

DCMessage _msg({
  String id = 'm',
  String deviceId = 'dev',
  StorageType storageType = StorageType.mmkv,
  String? storeId = 'storeA',
  String key = 'token',
  dynamic value = 'abc',
  String operation = 'write',
  required int timestamp,
}) {
  final wire = storeId == null
      ? storageTypeWire(storageType)
      : '${storageTypeWire(storageType)}:$storeId';
  return DCMessage(
    id: id,
    type: WsMessageTypes.clientStorageOperation,
    deviceId: deviceId,
    timestamp: timestamp,
    payload: {
      'storageType': wire,
      'key': key,
      'value': value,
      'operation': operation,
    },
  );
}

String storageTypeWire(StorageType type) => switch (type) {
      StorageType.mmkv => 'mmkv',
      _ => type.name,
    };

class _FakeWsServer implements WsServer {
  final _msg = StreamController<DCMessage>.broadcast();
  final _conn = StreamController<DeviceInfo>.broadcast();
  final _disc = StreamController<String>.broadcast();

  void emit(DCMessage m) => _msg.add(m);

  @override
  Stream<DCMessage> get onMessage => _msg.stream;
  @override
  Stream<DeviceInfo> get onConnection => _conn.stream;
  @override
  Stream<String> get onDisconnection => _disc.stream;

  @override
  Map<String, WsConnection> get connections => const {};
  @override
  bool get isRunning => false;
  @override
  int get port => 0;
  @override
  String get machineId => 'fake-machine';
  @override
  Future<void> start({int port = 0}) async {}
  @override
  Future<void> stop() async {}
  @override
  void sendToDevice(String deviceId, DCMessage message) {}

  @override
  noSuchMethod(Invocation invocation) => null;
}