import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/features/round/provider/round_providers.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/models/round/mock_entry.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';
import 'package:devconnect_manage_tool/server/ws_message_handler.dart';

import '../../helpers/fake_ws_server.dart';

MockRule _rule(String id, {String url = '/users'}) => MockRule(
  id: id,
  name: id,
  method: 'GET',
  urlPattern: url,
  statusCode: 200,
  headers: const {},
  body: '{}',
  enabled: true,
  hitCount: 0,
  updatedAt: 0,
);

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

  Future<void> send(String type, Map<String, dynamic> payload) async {
    server.emit(deviceMessage(type, payload));
    await Future<void>.delayed(Duration.zero);
  }

  group('GraphQL', () {
    const op = WsMessageTypes.clientGraphqlOperation;
    const res = WsMessageTypes.clientGraphqlResponse;

    test('an operation and its response make one row', () async {
      container.read(graphqlEntriesProvider);
      await send(op, {
        'operationId': 'o1',
        'operation': 'GetUser',
        'type': 'query',
        'variables': {'id': 1},
      });
      await send(res, {
        'operationId': 'o1',
        'operation': 'GetUser',
        'latencyMs': 42,
        'data': {'user': 'An'},
      });
      final entry = container.read(graphqlEntriesProvider).single;
      expect(entry.isComplete, isTrue);
      expect(entry.variables, {'id': 1});
      expect(entry.data, {'user': 'An'});
      expect(entry.latencyMs, 42);
    });

    test('pairs a response that arrives before its operation', () async {
      container.read(graphqlEntriesProvider);
      await send(res, {
        'operationId': 'o1',
        'operation': 'Save',
        'latencyMs': 5,
      });
      await send(op, {
        'operationId': 'o1',
        'operation': 'Save',
        'type': 'mutation',
        'variables': {'x': 1},
      });
      final entry = container.read(graphqlEntriesProvider).single;
      expect(entry.isComplete, isTrue);
      expect(entry.type, 'mutation');
      expect(entry.variables, {'x': 1});
    });

    test('without an operationId, a response goes to the oldest waiting '
        'operation of that name', () async {
      container.read(graphqlEntriesProvider);
      await send(op, {
        'operation': 'GetUser',
        'variables': {'id': 1},
      });
      await send(op, {
        'operation': 'GetUser',
        'variables': {'id': 2},
      });
      await send(res, {'operation': 'GetUser', 'latencyMs': 9});
      expect(
        container
            .read(graphqlEntriesProvider)
            .map((e) => (e.variables['id'], e.isComplete)),
        [(1, true), (2, false)],
      );
    });

    test('older Android payloads still show up', () async {
      container.read(graphqlEntriesProvider);
      // Class name as the type, variables stringified by org.json.
      await send(op, {
        'operation': 'GetUser',
        'type': 'GetUserQuery',
        'variables': '{}',
      });
      final entry = container.read(graphqlEntriesProvider).single;
      expect(entry.type, 'query');
      expect(entry.variables, isEmpty);
    });
  });

  group('gRPC', () {
    test('start and end make one row with a readable status', () async {
      container.read(grpcEntriesProvider);
      // Older Android SDKs send no callId.
      await send(WsMessageTypes.clientGrpcCallStart, {
        'service': 'UserService',
        'method': 'GetUser',
      });
      await send(WsMessageTypes.clientGrpcCallEnd, {
        'service': 'UserService',
        'method': 'GetUser',
        'latencyMs': 12,
        'status': 'OK',
        'requestBytes': 10,
        'responseBytes': 20,
      });
      final call = container.read(grpcEntriesProvider).single;
      expect(call.status, 'ok');
      expect(call.latencyMs, 12);
      expect(call.metadata, containsPair('statusCode', 'OK'));
      expect(call.metadata, containsPair('responseBytes', 20));
    });

    test('pairs by callId and maps failure codes to error', () async {
      container.read(grpcEntriesProvider);
      for (final id in ['c1', 'c2']) {
        await send(WsMessageTypes.clientGrpcCallStart, {
          'callId': id,
          'service': 'S',
          'method': 'M',
        });
      }
      await send(WsMessageTypes.clientGrpcCallEnd, {
        'callId': 'c2',
        'service': 'S',
        'method': 'M',
        'status': 'UNAVAILABLE',
      });
      expect(container.read(grpcEntriesProvider).map((c) => c.status), [
        null,
        'error',
      ]);
    });
  });

  test('WebSocket frames read the SDKs\' direction and close keys', () async {
    container.read(websocketEntriesProvider);
    const url = 'wss://api.example.com/live';
    // No connectionId: everything still lands on one connection.
    await send(WsMessageTypes.clientWebsocketOpen, {'url': url});
    await send(WsMessageTypes.clientWebsocketFrame, {
      'url': url,
      'direction': 'send',
      'payload': 'hi',
    });
    await send(WsMessageTypes.clientWebsocketFrame, {
      'url': url,
      'direction': 'receive',
      'payload': {'n': 1},
    });
    await send(WsMessageTypes.clientWebsocketClose, {
      'url': url,
      'code': 1000,
      'reason': 'bye',
    });
    final frames = container.read(websocketEntriesProvider);
    expect(frames.map((f) => f.direction), [
      'open',
      'sent',
      'received',
      'close',
    ]);
    expect(frames.map((f) => f.connectionId).toSet(), hasLength(1));
    expect(frames[2].payload, '{"n":1}');
    expect((frames.last.closeCode, frames.last.closeReason), (1000, 'bye'));
  });

  test('devices sent the mock rules are kept in step', () async {
    final rules = container.read(mockRulesProvider.notifier)
      ..add(_rule('a'))
      ..add(_rule('b'));
    final sync = container.read(mockRulesSyncProvider.notifier)..push('dev');
    List<int> pushed() => [
      for (final m in server.sent) (m.payload['rules'] as List).length,
    ];
    expect(server.sent.last.type, WsMessageTypes.serverMockRulesInstall);
    expect(pushed(), [2]);

    rules.toggle('a', false); // the whole list again, with the flag
    expect((server.sent.last.payload['rules'] as List).first['enabled'], false);
    rules.remove('b');
    expect(pushed(), [2, 2, 1]);

    // The SDK forgets its rules when the app restarts.
    server.connect(
      const DeviceInfo(
        deviceId: 'dev',
        deviceName: 'iPhone',
        platform: 'react_native',
        osVersion: 'iOS 18.0',
        appName: 'okicom',
        appVersion: '1.0.0',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(pushed(), [2, 2, 1, 1]);

    sync.clear('dev');
    expect(pushed().last, 0);
    rules.add(_rule('c'));
    expect(pushed(), hasLength(5)); // no longer kept in step
  });

  test('mock audit keeps the request\'s real URL', () async {
    container
        .read(mockRulesProvider.notifier)
        .add(_rule('a', url: r'/users/\d+'));
    container.read(mockAuditEntriesProvider);
    await send(WsMessageTypes.clientMockedRequest, {
      'ruleId': 'a',
      'url': 'https://api.example.com/users/42',
      'method': 'GET',
      'status': 200,
    });
    final entry = container.read(mockAuditEntriesProvider).single;
    expect(entry.url, 'https://api.example.com/users/42');
    expect(entry.matchedRuleName, 'a');
  });
}
