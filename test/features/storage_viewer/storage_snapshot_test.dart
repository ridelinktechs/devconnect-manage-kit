import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/features/storage_viewer/provider/storage_providers.dart';
import 'package:devconnect_manage_tool/features/storage_viewer/provider/storage_snapshot_providers.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';
import 'package:devconnect_manage_tool/server/ws_message_handler.dart';

import '../../helpers/fake_ws_server.dart';

void main() {
  test('an edit keeps the type the app reads the value back as', () {
    expect(parseStorageEdit('42', 'old'), '42');
    expect(parseStorageEdit(' 7 ', 3), 7);
    expect(parseStorageEdit('2.5', 1.0), 2.5);
    expect(parseStorageEdit('true', false), true);
    expect(parseStorageEdit('nope', 1), 'nope');
    expect(parseStorageEdit('[1, 2]', const ['a']), [1, 2]);
    // New keys: plain text stays text, JSON objects / arrays are decoded.
    expect(parseStorageEdit('42', null), '42');
    expect(parseStorageEdit('{"id": 7}', null), {'id': 7});
    expect(parseStorageEdit('{broken', null), '{broken');
  });

  test('values show as one line of text', () {
    expect(storageValueText('abc'), 'abc');
    expect(storageValueText({'a': 1}), '{"a":1}');
    expect(storageValueText(null), 'null');
  });

  test('store contents land in snapshots, not the operation history', () async {
    final server = FakeWsServer();
    final handler = WsMessageHandler(server: server);
    final container = ProviderContainer(
      overrides: [wsMessageHandlerProvider.overrideWithValue(handler)],
    );
    addTearDown(() {
      handler.dispose();
      container.dispose();
    });
    container.read(storageSnapshotsProvider);
    container.read(storageEntriesProvider);

    server.emit(
      deviceMessage(WsMessageTypes.clientStorageAllData, {
        'storageType': 'mmkv:user',
        'entries': {'token': 'abc', 'launches': 3},
      }),
    );
    server.emit(
      deviceMessage(WsMessageTypes.clientStorageAllData, {
        'storageType': 'async_storage',
        'entries': <String, Object?>{},
        'error': 'boom',
      }),
    );
    await Future<void>.delayed(Duration.zero);

    final stores = container.read(storageSnapshotsProvider)['dev']!;
    expect(stores.keys, ['async_storage', 'mmkv:user']);
    expect(stores['mmkv:user']!.entries, {'token': 'abc', 'launches': 3});
    expect(stores['async_storage']!.error, 'boom');
    expect(container.read(storageEntriesProvider), isEmpty);

    handler.writeStorage('dev', 'mmkv:user', 'token', 'xyz');
    expect(server.sent.single.payload, {
      'storageType': 'mmkv:user',
      'key': 'token',
      'value': 'xyz',
    });
  });
}
