import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/components/labels/tag_label.dart';
import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/features/storage_viewer/presentation/event_row/storage_entry_tile.dart';
import 'package:devconnect_manage_tool/features/storage_viewer/presentation/header/storage_filter_chip.dart';
import 'package:devconnect_manage_tool/features/storage_viewer/presentation/pages/storage_viewer_page.dart';
import 'package:devconnect_manage_tool/features/storage_viewer/provider/storage_providers.dart';
import 'package:devconnect_manage_tool/features/storage_viewer/provider/storage_snapshot_providers.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/server/protocol/dc_message.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';
import 'package:devconnect_manage_tool/server/ws_message_handler.dart';

import '../../helpers/fake_ws_server.dart';

var _seq = 0;

class _Page {
  final FakeWsServer server;
  final ProviderContainer container;

  _Page(this.server, this.container);

  /// The app reports a storage operation.
  void op(String storageType, String key, Object? value, String operation) =>
      server.emit(
        DCMessage(
          id: 'op${_seq++}',
          type: WsMessageTypes.clientStorageOperation,
          deviceId: 'dev',
          timestamp: 1763600000000 + _seq,
          payload: {
            'storageType': storageType,
            'key': key,
            'value': value,
            'operation': operation,
          },
        ),
      );

  /// The app reports a store's contents.
  void store(
    String storageType,
    Map<String, Object?> entries, {
    String? error,
  }) => server.emit(
    DCMessage(
      id: 'kv${_seq++}',
      type: WsMessageTypes.clientStorageAllData,
      deviceId: 'dev',
      timestamp: 1763600000000 + _seq,
      payload: {
        'storageType': storageType,
        'entries': entries,
        'error': ?error,
      },
    ),
  );

  /// What the desktop sent the device, of [type].
  List<DCMessage> sent(String type) =>
      server.sent.where((m) => m.type == type).toList();
}

/// The Storage page, the device connected unless [device] is false.
Future<_Page> _open(WidgetTester tester, {bool device = true}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final server = FakeWsServer();
  final handler = WsMessageHandler(server: server);
  final container = ProviderContainer(
    overrides: [wsMessageHandlerProvider.overrideWithValue(handler)],
  );
  addTearDown(() {
    container.dispose();
    handler.dispose();
  });
  container.read(connectedDevicesProvider);
  container.read(storageEntriesProvider);
  container.read(storageSnapshotsProvider);
  if (device) {
    server.connect(
      const DeviceInfo(
        deviceId: 'dev',
        deviceName: 'iPhone 15',
        platform: 'react_native',
        osVersion: 'iOS 18.0',
        appName: 'okicom',
        appVersion: '1.0.0',
      ),
    );
    container.read(selectedDeviceProvider.notifier).select('dev');
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const Scaffold(body: StorageViewerPage()),
          ),
        ),
      ),
    ),
  );
  await _deliver(tester);
  return _Page(server, container);
}

/// Two frames: device messages reach providers on a microtask, after the
/// first one.
Future<void> _deliver(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Future<void> _openKeyValue(WidgetTester tester) async {
  await tester.tap(find.text('Key-Value'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The chip labelled [label] in the header.
StorageFilterChip _chip(WidgetTester tester, String label) =>
    tester.widget<StorageFilterChip>(
      find.byWidgetPredicate((w) => w is StorageFilterChip && w.label == label),
    );

Finder get _cards => find.byType(StorageEntryTile);

void main() {
  testWidgets('before the app reports anything, History says what will '
      'appear', (tester) async {
    await _open(tester);
    expect(find.text('No storage data'), findsOneWidget);
    expect(_cards, findsNothing);
  });

  testWidgets('each operation is a card with its operation, storage and '
      'store, app and device, key, value shape and value', (tester) async {
    final page = await _open(tester);
    page
      ..op('async_storage', 'user.profile', {'id': 42, 'name': 'Ada'}, 'write')
      ..op('mmkv:settings', 'locale', 'vi', 'read')
      ..op('async_storage', 'auth.token', null, 'delete');
    await _deliver(tester);

    expect(_cards, findsNWidgets(3));
    Finder inCard(String key, Finder f) => find.descendant(
      of: find.ancestor(of: find.text(key), matching: _cards),
      matching: f,
    );
    expect(inCard('user.profile', find.text('WRITE')), findsOneWidget);
    expect(inCard('user.profile', find.text('AsyncStorage')), findsOneWidget);
    expect(
      inCard('user.profile', find.text('okicom · iPhone 15')),
      findsOneWidget,
    );
    expect(inCard('user.profile', find.text('Map · 2 keys')), findsOneWidget);
    expect(
      inCard('user.profile', find.text('{"id":42,"name":"Ada"}')),
      findsOneWidget,
    );
    expect(inCard('locale', find.text('READ')), findsOneWidget);
    expect(inCard('locale', find.text('MMKV · settings')), findsOneWidget);
    expect(inCard('auth.token', find.text('DELETE')), findsOneWidget);
    expect(
      inCard('auth.token', find.text('—')),
      findsOneWidget,
      reason: 'a delete has no value to show',
    );
  });

  testWidgets('a chip per operation and storage type shows its count and '
      'hides what it switches off, without losing the count', (tester) async {
    final page = await _open(tester);
    page
      ..op('async_storage', 'a', 1, 'write')
      ..op('async_storage', 'b', 2, 'write')
      ..op('mmkv', 'c', 3, 'read')
      ..op('async_storage', 'a', null, 'delete');
    await _deliver(tester);

    expect(_chip(tester, 'WRITE').count, 2);
    expect(_chip(tester, 'READ').count, 1);
    expect(_chip(tester, 'DELETE').count, 1);
    expect(_chip(tester, 'AsyncStorage').count, 3);
    expect(_chip(tester, 'MMKV').count, 1);
    expect(
      find.byWidgetPredicate(
        (w) => w is StorageFilterChip && w.label == 'Hive',
      ),
      findsNothing,
      reason: 'only storages the app used get a chip',
    );

    await tester.tap(find.text('WRITE').first);
    await tester.pump();
    expect(_chip(tester, 'WRITE').isActive, isFalse);
    expect(_chip(tester, 'WRITE').count, 2);
    expect(page.container.read(filteredStorageEntriesProvider).length, 2);

    await tester.tap(find.text('MMKV').first);
    await tester.pump();
    expect(_chip(tester, 'MMKV').isActive, isFalse);
    expect(
      page.container
          .read(filteredStorageEntriesProvider)
          .map((e) => e.operation),
      ['delete'],
    );
  });

  testWidgets('the search filters by key or value', (tester) async {
    final page = await _open(tester);
    page
      ..op('async_storage', 'user.name', 'Ada', 'write')
      ..op('async_storage', 'theme', 'dark', 'write');
    await _deliver(tester);

    await tester.enterText(find.byType(TextField).first, 'dark');
    await tester.pump();
    expect(_cards, findsOneWidget);
    expect(find.text('theme'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'user');
    await tester.pump();
    expect(find.text('user.name'), findsOneWidget);
    expect(find.text('theme'), findsNothing);
  });

  testWidgets('when the filters hide everything, the empty History offers '
      'to drop each one with how many come back', (tester) async {
    final page = await _open(tester);
    page
      ..op('async_storage', 'auth.token', 'x', 'write')
      ..op('async_storage', 'auth.token', null, 'delete')
      ..op('mmkv', 'theme', 'dark', 'read');
    await _deliver(tester);

    await tester.enterText(find.byType(TextField).first, 'auth');
    await tester.pump();
    await tester.tap(find.text('WRITE').first);
    await tester.pump();
    await tester.tap(find.text('DELETE').first);
    await tester.pump();

    expect(_cards, findsNothing);
    expect(find.text('No operations match'), findsOneWidget);
    expect(find.text('Show all operations'), findsOneWidget);
    expect(find.text('Clear search'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget, reason: 'the two auth.token ops');
    expect(find.text('+1'), findsOneWidget, reason: 'the theme read');

    await tester.tap(find.text('Show all operations'));
    await tester.pump();
    expect(_cards, findsNWidgets(2));
    expect(_chip(tester, 'WRITE').isActive, isTrue);
    expect(_chip(tester, 'DELETE').isActive, isTrue);
  });

  testWidgets('picking an operation opens its detail; Copy value copies it '
      'and the close button closes it', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final page = await _open(tester);
    page.op('mmkv:user', 'profile', {'id': 7}, 'write');
    await _deliver(tester);

    await tester.tap(_cards);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('WRITE · MMKV · user'), findsOneWidget);
    expect(find.text('Storage'), findsWidgets);
    expect(find.text('okicom · iPhone 15'), findsWidgets);

    await tester.tap(find.byTooltip('Copy value'));
    await tester.pump();
    expect(copied, ['{\n  "id": 7\n}']);
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    expect(find.text('WRITE · MMKV · user'), findsNothing);
    expect(page.container.read(selectedStorageIdProvider), isNull);
  });

  testWidgets('Clear all empties the history', (tester) async {
    final page = await _open(tester);
    page.op('async_storage', 'a', 1, 'write');
    await _deliver(tester);
    expect(_cards, findsOneWidget);

    await tester.tap(find.byTooltip('Clear all'));
    await tester.pump();
    expect(_cards, findsNothing);
    expect(find.text('No storage data'), findsOneWidget);
  });

  testWidgets('with no device, Key-Value asks for one', (tester) async {
    await _open(tester, device: false);
    await _openKeyValue(tester);
    expect(
      find.text(
        'Select a device in the bottom bar to see and edit its storage.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Key-Value asks the app for its stores, shows each as a tab '
      'with its key count, and lists the picked store\'s keys sorted with '
      'their types', (tester) async {
    final page = await _open(tester);
    await _openKeyValue(tester);
    expect(page.sent(WsMessageTypes.serverStorageRequestAll), hasLength(1));

    page
      ..store('async_storage', {
        'session.count': 17,
        'push.enabled': false,
        'user': {'id': 1},
        'note': null,
        'screen': 'Home',
      })
      ..store('mmkv:settings', {'locale': 'vi'});
    await _deliver(tester);

    expect(find.text('AsyncStorage'), findsOneWidget);
    expect(find.text('MMKV · settings'), findsOneWidget);
    final keys = [
      for (final t in tester.widgetList<Text>(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == 'KeyValueRow',
          ),
          matching: find.byType(Text),
        ),
      ))
        if ([
          'session.count',
          'push.enabled',
          'user',
          'note',
          'screen',
        ].contains(t.data))
          t.data,
    ];
    expect(keys, ['note', 'push.enabled', 'screen', 'session.count', 'user']);
    for (final type in ['number', 'bool', 'json', 'null', 'string']) {
      expect(
        find.descendant(of: find.byType(TagLabel), matching: find.text(type)),
        findsOneWidget,
        reason: type,
      );
    }

    await tester.tap(find.text('MMKV · settings'));
    await tester.pump();
    expect(find.text('locale'), findsOneWidget);
    expect(find.text('session.count'), findsNothing);

    await tester.tap(find.byTooltip('Reload'));
    await tester.pump();
    expect(page.sent(WsMessageTypes.serverStorageRequestAll), hasLength(2));
  });

  testWidgets('the key filter narrows the table and says when nothing '
      'matches', (tester) async {
    final page = await _open(tester);
    await _openKeyValue(tester);
    page.store('async_storage', {'auth.token': 'x', 'theme': 'dark'});
    await _deliver(tester);

    await tester.enterText(find.byType(TextField).first, 'them');
    await tester.pump();
    expect(find.text('theme'), findsOneWidget);
    expect(find.text('auth.token'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pump();
    expect(find.text('No keys match'), findsOneWidget);
  });

  testWidgets('an edit keeps the value\'s type, delete sends the key, and '
      'Clear all asks first', (tester) async {
    final page = await _open(tester);
    await _openKeyValue(tester);
    page.store('async_storage', {'session.count': 17, 'theme': 'dark'});
    await _deliver(tester);

    Finder rowAction(String key, String tooltip) => find.descendant(
      of: find.ancestor(
        of: find.text(key),
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == 'KeyValueRow',
        ),
      ),
      matching: find.byTooltip(tooltip),
    );

    await tester.tap(rowAction('session.count', 'Edit value'));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.last, '18');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final write = page.sent(WsMessageTypes.serverStorageWrite).single;
    expect(write.payload, {
      'storageType': 'async_storage',
      'key': 'session.count',
      'value': 18,
    });

    await tester.tap(rowAction('theme', 'Delete key'));
    await tester.pump();
    expect(page.sent(WsMessageTypes.serverStorageDelete).single.payload, {
      'storageType': 'async_storage',
      'key': 'theme',
    });

    await tester.tap(find.byTooltip('Clear all'));
    await tester.pumpAndSettle();
    expect(page.sent(WsMessageTypes.serverStorageClear), isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, 'Clear all'));
    await tester.pumpAndSettle();
    expect(page.sent(WsMessageTypes.serverStorageClear).single.payload, {
      'storageType': 'async_storage',
    });
  });

  testWidgets('Add key writes a new key, a JSON object as an object', (
    tester,
  ) async {
    final page = await _open(tester);
    await _openKeyValue(tester);
    page.store('async_storage', {'theme': 'dark'});
    await _deliver(tester);

    await tester.tap(find.byTooltip('Add key'));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.first, 'flags');
    await tester.enterText(fields.last, '{"beta": true}');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(page.sent(WsMessageTypes.serverStorageWrite).single.payload, {
      'storageType': 'async_storage',
      'key': 'flags',
      'value': {'beta': true},
    });
  });

  testWidgets('a store\'s error shows above its table, without a misleading '
      '"no match"', (tester) async {
    final page = await _open(tester);
    await _openKeyValue(tester);
    page.store('mmkv', {}, error: 'MMKV is not initialised yet.');
    await _deliver(tester);

    expect(find.text('MMKV is not initialised yet.'), findsOneWidget);
    expect(find.text('No keys match'), findsNothing);
    expect(find.text('No data'), findsNothing);
  });
}
