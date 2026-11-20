import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:devconnect_manage_kit/devconnect_manage_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late WebSocket app;
  final replies = <String, Completer<Map<String, dynamic>>>{};
  var sent = 0;
  final queries = <String>[];
  var rowCount = 0;

  /// Sends [type] to the app; completes with the payload of its reply.
  Future<Map<String, dynamic>> ask(String type,
      [Map<String, dynamic>? payload]) {
    final id = '${sent++}';
    final reply = replies[id] = Completer();
    app.add(
        jsonEncode({'type': type, 'correlationId': id, 'payload': payload}));
    return reply.future.timeout(const Duration(seconds: 5));
  }

  setUpAll(() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final connected = Completer<WebSocket>();
    server.listen((request) async =>
        connected.complete(await WebSocketTransformer.upgrade(request)));
    final client = await DevConnectClient.init(
      appName: 'test',
      host: '127.0.0.1',
      port: server.port,
      auto_: false,
    );
    client.registerDatabase('app.db', (sql) async {
      queries.add(sql);
      if (sql.startsWith('SELECT * FROM (') && sql.contains('DELETE')) {
        throw StateError('syntax error');
      }
      return [
        for (var i = 0; i < rowCount; i++) {'id': i},
      ];
    });
    app = await connected.future;
    app.listen((data) {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      replies
          .remove(message['correlationId'])
          ?.complete(message['payload'] as Map<String, dynamic>);
    });
  });

  test('a layout capture that fails still answers, with the error', () async {
    // Without a WidgetsBinding the capture throws.
    expect(await ask('server:layout:capture'), {'error': isA<String>()});
  });

  test('a SELECT reads one row past the limit, other statements run as is',
      () async {
    Future<Map<String, dynamic>> run(String sql) =>
        ask('server:database:query', {'database': 'app.db', 'sql': sql});

    rowCount = 1001;
    final select = await run('select id from t; \n');
    expect(queries.last, 'SELECT * FROM (\nselect id from t\n) LIMIT 1001');
    expect((select['rows'] as List).length, 1000);
    expect(select['truncated'], isTrue);
    expect(select['columns'], ['id']);

    await run('WITH x AS (SELECT 1) SELECT * FROM x');
    expect(queries.last,
        'SELECT * FROM (\nWITH x AS (SELECT 1) SELECT * FROM x\n) LIMIT 1001');

    rowCount = 3;
    final pragma = await run('PRAGMA table_info(t)');
    expect(queries.last, 'PRAGMA table_info(t)');
    expect((pragma['rows'] as List).length, 3);
    expect(pragma['truncated'], isFalse);

    final delete = await run('WITH x AS (SELECT 1) DELETE FROM t');
    expect(queries.last, 'WITH x AS (SELECT 1) DELETE FROM t');
    expect(delete['error'], isNull);
  });
}
