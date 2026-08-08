import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/models/storage/storage_entry.dart';
import 'package:devconnect_manage_tool/server/protocol/dc_message.dart';
import 'package:devconnect_manage_tool/server/ws_connection.dart';
import 'package:devconnect_manage_tool/server/ws_message_handler.dart';
import 'package:devconnect_manage_tool/server/ws_server.dart';

void main() {
  group('parseStorageTypeAndStoreId', () {
    test('bare "mmkv" returns mmkv with null storeId', () {
      final r = parseStorageTypeAndStoreId('mmkv');
      expect(r.storageType, StorageType.mmkv);
      expect(r.storeId, isNull);
    });

    test('"mmkv:user-storage" returns mmkv with storeId="user-storage"', () {
      final r = parseStorageTypeAndStoreId('mmkv:user-storage');
      expect(r.storageType, StorageType.mmkv);
      expect(r.storeId, 'user-storage');
    });

    test('"MMKV:Settings" is case-insensitive on the type, keeps label', () {
      final r = parseStorageTypeAndStoreId('MMKV:Settings');
      expect(r.storageType, StorageType.mmkv);
      expect(r.storeId, 'Settings');
    });

    test('two distinct MMKV labels do not collapse', () {
      final a = parseStorageTypeAndStoreId('mmkv:storeA');
      final b = parseStorageTypeAndStoreId('mmkv:storeB');
      expect(a.storageType, b.storageType);
      expect(a.storeId, isNot(b.storeId));
    });
  });

  group('StorageEntry dedup key (notifier-layer regression)', () {
    test('same (key, value, type) but different storeId → distinct entries', () {
      const a = StorageEntry(
        id: '1',
        deviceId: 'dev',
        storageType: StorageType.mmkv,
        storeId: 'storeA',
        key: 'token',
        value: 'abc',
        operation: 'write',
        timestamp: 1,
      );
      const b = StorageEntry(
        id: '2',
        deviceId: 'dev',
        storageType: StorageType.mmkv,
        storeId: 'storeB',
        key: 'token',
        value: 'abc',
        operation: 'write',
        timestamp: 2,
      );
      expect(a.key == b.key, isTrue);
      expect(a.storageType == b.storageType, isTrue);
      expect(a.storeId == b.storeId, isFalse);
    });
  });

  group('_handleStorage end-to-end', () {
    test('two MMKV stores with same key+data produce 2 entries', () async {
      final entries = await runHandleStorage([
        _msg(
          id: 'm1',
          payload: const {
            'storageType': 'mmkv:storeA',
            'key': 'token',
            'value': 'abc',
            'operation': 'write',
          },
        ),
        _msg(
          id: 'm2',
          payload: const {
            'storageType': 'mmkv:storeB',
            'key': 'token',
            'value': 'abc',
            'operation': 'write',
          },
        ),
      ]);

      expect(entries, hasLength(2));
      expect(entries.map((e) => e.storeId).toSet(), {'storeA', 'storeB'});
      // Same key, same value, same storageType — must be 2 rows,
      // not 1 (regression: the second write used to overwrite the first).
      expect(entries[0].key, 'token');
      expect(entries[1].key, 'token');
    });

    test('same store + same key + same value sent twice → 2 entries', () async {
      // Wire layer always emits one entry per incoming message —
      // dedup happens in StorageNotifier (see storage_notifier_test.dart).
      final entries = await runHandleStorage([
        _msg(
          id: 'm1',
          timestamp: 1,
          payload: const {
            'storageType': 'mmkv:storeA',
            'key': 'token',
            'value': 'abc',
            'operation': 'write',
          },
        ),
        _msg(
          id: 'm2',
          timestamp: 2,
          payload: const {
            'storageType': 'mmkv:storeA',
            'key': 'token',
            'value': 'abc',
            'operation': 'write',
          },
        ),
      ]);

      expect(entries, hasLength(2));
      expect(entries[0].storeId, 'storeA');
      expect(entries[1].storeId, 'storeA');
      expect(entries[0].key, entries[1].key);
      expect(entries[0].value, entries[1].value);
      expect(entries[0].id, isNot(entries[1].id));
    });
  });
}

DCMessage _msg({
  required String id,
  required Map<String, dynamic> payload,
  int timestamp = 1,
}) =>
    DCMessage(
      id: id,
      type: WsMessageTypes.clientStorageOperation,
      deviceId: 'dev',
      timestamp: timestamp,
      payload: payload,
    );

/// Drives [WsMessageHandler._handleMessage] for a list of storage
/// operations without standing up a real WsServer — wires the
/// handler's `onStorage` stream into a list.
Future<List<StorageEntry>> runHandleStorage(List<DCMessage> messages) async {
  final received = <StorageEntry>[];
  final completer = Completer<List<StorageEntry>>();

  // WsMessageHandler listens on `server.onMessage` and exposes `onStorage`.
  // We only need those two surfaces — fake the rest.
  final fakeServer = _FakeWsServer();
  final handler = WsMessageHandler(server: fakeServer);

  final sub = handler.onStorage.listen((e) {
    received.add(e);
    if (received.length == messages.length && !completer.isCompleted) {
      completer.complete(received);
    }
  });

  for (final m in messages) {
    fakeServer.emitMessage(m);
  }

  return completer.future.timeout(const Duration(seconds: 2), onTimeout: () {
    sub.cancel();
    handler.dispose();
    return received;
  });
}

/// Minimal [WsServer] stub. WsMessageHandler only reads `onMessage`,
/// `onConnection`, and `onDisconnection` from its server, so the rest
/// of WsServer's surface (HTTP bind, UDP beacon, etc.) is unused here.
class _FakeWsServer implements WsServer {
  final _msg = StreamController<DCMessage>.broadcast();
  final _conn = StreamController<DeviceInfo>.broadcast();
  final _disc = StreamController<String>.broadcast();

  void emitMessage(DCMessage m) => _msg.add(m);

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