import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/features/database_viewer/presentation/pages/database_viewer_page.dart';
import 'package:devconnect_manage_tool/features/database_viewer/provider/database_providers.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/server/protocol/dc_message.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';
import 'package:devconnect_manage_tool/server/ws_message_handler.dart';

import '../../helpers/fake_ws_server.dart';

Map<String, dynamic> _col(
  String name,
  String type, {
  bool pk = false,
  bool nullable = true,
}) => {'name': name, 'type': type, 'isPrimaryKey': pk, 'isNullable': nullable};

final _schema = {
  'databases': [
    {
      'name': 'okicom.db',
      'tables': [
        {
          'name': 'users',
          'rowCount': 1284,
          'columns': [
            _col('id', 'INTEGER', pk: true, nullable: false),
            _col('email', 'TEXT', nullable: false),
            _col('name', 'TEXT'),
          ],
        },
        {'name': 'orders', 'rowCount': 5211, 'columns': []},
      ],
    },
    {
      'name': 'cache.db',
      'tables': [
        {'name': 'http_cache', 'rowCount': 311, 'columns': []},
      ],
    },
  ],
};

class _Page {
  final FakeWsServer server;

  _Page(this.server);

  void schema(Map<String, dynamic> payload) => server.emit(
    DCMessage(
      id: 'schema',
      type: WsMessageTypes.clientDatabaseSchema,
      deviceId: 'dev',
      timestamp: 1763600000000,
      payload: payload,
    ),
  );

  void answer(List<Map<String, dynamic>> rows, {String? error}) => server.emit(
    DCMessage(
      id: 'result${rows.length}${error ?? ''}',
      type: WsMessageTypes.clientDatabaseQueryResult,
      deviceId: 'dev',
      timestamp: 1763600001000,
      payload: {
        'columns': rows.isEmpty ? <String>[] : rows.first.keys.toList(),
        'rows': rows,
        'executionTimeMs': 12,
        'error': ?error,
      },
    ),
  );

  List<DCMessage> sent(String type) =>
      server.sent.where((m) => m.type == type).toList();
}

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
  container.read(databaseSchemasProvider);
  container.read(databaseQueryProvider);
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
            child: const Scaffold(body: DatabaseViewerPage()),
          ),
        ),
      ),
    ),
  );
  await _deliver(tester);
  return _Page(server);
}

Future<void> _deliver(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// Lets a query's no-answer timer run out.
Future<void> _drain(WidgetTester tester) =>
    tester.pump(DatabaseQueryNotifier.timeout + const Duration(seconds: 1));

Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

final _rows = [
  {'id': 1, 'email': 'ada@example.com', 'name': 'Ada Lovelace'},
  {'id': 2, 'email': 'grace@example.com', 'name': null},
];

void main() {
  testWidgets('with no device connected, the page says to connect one', (
    tester,
  ) async {
    await _open(tester, device: false);
    expect(
      find.text('Connect a device to browse its databases.'),
      findsOneWidget,
    );
  });

  testWidgets('it asks the app for its databases and lists each with its '
      'tables and their row counts', (tester) async {
    final page = await _open(tester);
    expect(page.sent(WsMessageTypes.serverDatabaseRequestSchema), hasLength(1));
    page.schema(_schema);
    await _deliver(tester);

    expect(find.text('okicom.db'), findsOneWidget);
    expect(find.text('cache.db'), findsOneWidget);
    expect(find.text('users'), findsOneWidget);
    expect(find.text('1,284'), findsOneWidget, reason: 'grouped digits');
    expect(find.text('5,211'), findsOneWidget);

    await tester.enterText(_field('Filter tables'), 'ord');
    await tester.pump();
    expect(find.text('orders'), findsOneWidget);
    expect(find.text('users'), findsNothing);
    expect(find.text('cache.db'), findsNothing, reason: 'no table matches');
  });

  testWidgets('with no database registered, the sidebar says how to add '
      'one', (tester) async {
    final page = await _open(tester);
    page.schema({'databases': <Object>[]});
    await _deliver(tester);
    expect(
      find.textContaining('DevConnect.registerDatabase(name, query)'),
      findsOneWidget,
    );
  });

  testWidgets('picking a table previews it on its database; the rows come '
      'back as a grid with types, the key, NULL and a status bar', (
    tester,
  ) async {
    final page = await _open(tester);
    page.schema(_schema);
    await _deliver(tester);

    await tester.tap(find.text('users'));
    await tester.pump();
    final query = page.sent(WsMessageTypes.serverDatabaseQuery).single;
    expect(query.payload, {
      'database': 'okicom.db',
      'sql': 'SELECT * FROM "users" LIMIT 50;',
    });
    expect(find.text('3 columns  ·  1,284 rows'), findsOneWidget);

    page.answer(_rows);
    await _deliver(tester);
    expect(find.text('id  INTEGER', findRichText: true), findsOneWidget);
    expect(find.text('email  TEXT', findRichText: true), findsOneWidget);
    expect(find.byIcon(LucideIcons.keyRound), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.text('NULL'), findsOneWidget);
    expect(find.text('2 rows'), findsOneWidget);
    expect(find.text('12ms'), findsOneWidget);
    expect(find.text('okicom.db'), findsNWidgets(2), reason: 'status bar too');
    await _drain(tester);
  });

  testWidgets('⌘↵ and Ctrl+Enter run what the editor holds', (tester) async {
    final page = await _open(tester);
    page.schema(_schema);
    await _deliver(tester);

    await tester.enterText(
      _field('SELECT * FROM table_name LIMIT 100'),
      'SELECT count(*) FROM users;',
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    expect(page.sent(WsMessageTypes.serverDatabaseQuery).single.payload, {
      'database': 'okicom.db',
      'sql': 'SELECT count(*) FROM users;',
    });

    page.answer([
      {'count(*)': 1284},
    ]);
    await _deliver(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(page.sent(WsMessageTypes.serverDatabaseQuery), hasLength(2));
    await _drain(tester);
  });

  testWidgets('Run sends the query, and a failed one shows the database\'s '
      'error', (tester) async {
    final page = await _open(tester);
    page.schema(_schema);
    await _deliver(tester);

    await tester.enterText(
      _field('SELECT * FROM table_name LIMIT 100'),
      'SELECT totl FROM orders;',
    );
    await tester.tap(find.text('Run'));
    await tester.pump();
    expect(page.sent(WsMessageTypes.serverDatabaseQuery), hasLength(1));

    page.answer(const [], error: 'no such column: totl');
    await _deliver(tester);
    expect(find.text('no such column: totl'), findsOneWidget);
    await _drain(tester);
  });

  testWidgets('Structure lists the picked table\'s columns with their type, '
      'key and nullability', (tester) async {
    final page = await _open(tester);
    page.schema(_schema);
    await _deliver(tester);
    await tester.tap(find.text('users'));
    await tester.pump();

    await tester.tap(find.text('Structure'));
    await tester.pump();
    expect(find.text('primary_key'), findsOneWidget);
    expect(find.text('INTEGER'), findsOneWidget);
    expect(
      find.text('YES'),
      findsNWidgets(2),
      reason:
          'id is the key; '
          'name may be null',
    );
    expect(find.text('NO'), findsNWidgets(2));
    expect(
      find.text('SELECT * FROM "users" LIMIT 50;'),
      findsNothing,
      reason: 'the editor gives way to the structure',
    );

    await tester.tap(find.text('Data'));
    await tester.pump();
    expect(find.text('SELECT * FROM "users" LIMIT 50;'), findsOneWidget);
    await _drain(tester);
  });

  testWidgets('double-clicking a cell copies its value', (tester) async {
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
    page.schema(_schema);
    await _deliver(tester);
    await tester.tap(find.text('users'));
    await tester.pump();
    page.answer(_rows);
    await _deliver(tester);

    final cell = find.text('grace@example.com');
    await tester.tap(cell);
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(cell);
    await tester.pump();
    expect(copied, ['grace@example.com']);
    await tester.pump(const Duration(seconds: 3));
    await _drain(tester);
  });
}
