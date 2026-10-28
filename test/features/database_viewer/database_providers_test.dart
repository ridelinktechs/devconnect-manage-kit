import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/features/database_viewer/provider/database_providers.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';
import 'package:devconnect_manage_tool/server/ws_message_handler.dart';

import '../../helpers/fake_ws_server.dart';

void main() {
  late FakeWsServer server;
  late WsMessageHandler handler;
  late ProviderContainer container;

  setUp(() {
    server = FakeWsServer();
    handler = WsMessageHandler(server: server);
    container = ProviderContainer(
      overrides: [wsMessageHandlerProvider.overrideWithValue(handler)],
    );
  });
  tearDown(() {
    handler.dispose();
    container.dispose();
  });

  test('parses the schema the SDKs send, skipping malformed entries', () async {
    container.read(databaseSchemasProvider.notifier).request('dev');
    expect(server.sent.single.type, WsMessageTypes.serverDatabaseRequestSchema);

    server.emit(
      deviceMessage(WsMessageTypes.clientDatabaseSchema, {
        'databases': [
          {
            'name': 'app.db',
            'tables': [
              {
                'name': 'users',
                'columns': [
                  {
                    'name': 'id',
                    'type': 'INTEGER',
                    'isPrimaryKey': true,
                    'isNullable': false,
                  },
                ],
                'rowCount': 3,
              },
            ],
          },
          {'name': 42},
        ],
      }),
    );

    await Future<void>.delayed(Duration.zero); // handler streams are async
    final schemas = container.read(databaseSchemasProvider)['dev']!;
    expect(schemas.single.name, 'app.db');
    final users = schemas.single.tables.single;
    expect((users.name, users.rowCount), ('users', 3));
    expect(users.columns.single.isPrimaryKey, isTrue);
  });

  test('a query is pending until its rows arrive', () async {
    final queries = container.read(databaseQueryProvider.notifier);
    queries.run('dev', 'app.db', 'SELECT * FROM users');
    expect(server.sent.single.payload, {
      'database': 'app.db',
      'sql': 'SELECT * FROM users',
    });
    expect(container.read(databaseQueryProvider)['dev']!.result, isNull);

    server.emit(
      deviceMessage(WsMessageTypes.clientDatabaseQueryResult, {
        'database': 'app.db',
        'columns': ['id', 'email'],
        'rows': [
          {'id': 1, 'email': 'a@b.c'},
        ],
        'truncated': true,
        'executionTimeMs': 4,
      }),
    );

    await Future<void>.delayed(Duration.zero);
    final result = container.read(databaseQueryProvider)['dev']!.result!;
    expect(result.columns, ['id', 'email']);
    expect(result.rows.single['email'], 'a@b.c');
    expect((result.truncated, result.executionTimeMs), (true, 4));
  });

  // testWidgets for its fake clock.
  testWidgets('an app that never answers ends in an error', (tester) async {
    container
        .read(databaseQueryProvider.notifier)
        .run('dev', 'app.db', 'SELECT 1', noResponse: 'No response');
    await tester.pump(DatabaseQueryNotifier.timeout);
    expect(
      container.read(databaseQueryProvider)['dev']!.result!.error,
      'No response',
    );
  });
}
