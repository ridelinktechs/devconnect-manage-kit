import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect_manage_kit/devconnect_manage_kit.dart';
import 'package:devconnect_manage_kit/src/interceptors/network/graphql/devconnect_link.dart';

/// Payloads of the queued (pre-init) messages of [type].
List<Map<String, dynamic>> _sent(String type) => [
      for (final m in DevConnectClient.queuedMessages)
        if (m['type'] == type) m['payload'] as Map<String, dynamic>,
    ];

/// Shaped like gql_exec's GraphQLError / ErrorLocation.
class _GqlError {
  final message = 'User not found';
  final path = ['user', 0];
  final locations = [_GqlLocation()];
}

class _GqlLocation {
  final line = 3;
  final column = 5;
}

/// Records the forwarder that an inner link receives, so the test can
/// assert that DevConnectLink does not pass itself as the forwarder
/// (which would cause infinite recursion in a real Link chain).
class _SpyNextLink implements DevConnectLinkBase {
  final List<DevConnectLinkBase?> forwardersReceived = [];
  int callCount = 0;

  @override
  Stream<DevConnectResponse> request(DevConnectRequest request,
      [DevConnectLinkBase? next]) async* {
    callCount++;
    forwardersReceived.add(next);
    yield DevConnectResponse(
      data: const {'ok': true},
      context: const {},
    );
  }
}

class _FakeRequest implements DevConnectRequest {
  _FakeRequest([this.operationName = 'TestQuery']);

  @override
  final String? operationName;

  @override
  String get operationType => 'query';

  @override
  Map<String, dynamic> get variables => const {'id': 7};
}

void main() {
  setUp(() => DevConnectClient.queuedMessages.clear());

  group('DevConnectLink.request', () {
    test('passes null/no self as forwarder to the inner link', () async {
      // Bug: `yield* next.request(request, next)` passes the inner link
      // ITSELF as the forwarder. In a real gql_link chain, the inner
      // link then calls `forwarder.request(...)` → infinite recursion.
      // The fix is to invoke the inner link without passing `next`
      // (i.e. forwarder should be null, signalling chain termination).
      final spy = _SpyNextLink();
      final link = DevConnectLink();

      final responses = <DevConnectResponse>[];
      await link
          .request(_FakeRequest(), spy)
          .forEach(responses.add);

      expect(responses, hasLength(1));
      expect(spy.callCount, 1,
          reason: 'Inner link must be invoked exactly once, not recursively');
      expect(spy.forwardersReceived.single, isNull,
          reason: 'Inner link must not be passed DevConnectLink or itself '
              'as the forwarder — that triggers infinite recursion in a '
              'real gql_link chain.');

      final operation = _sent('client:graphql_operation').single;
      expect(operation, {
        'operationId': isA<String>(),
        'operation': 'TestQuery',
        'type': 'query',
        'variables': {'id': 7},
      });
      final response = _sent('client:graphql_response').single;
      expect(response, {
        'operationId': operation['operationId'],
        'operation': 'TestQuery',
        'latencyMs': isA<int>(),
        'data': {'ok': true},
      });
    });

    test('names anonymous operations "anonymous"', () async {
      await DevConnectLink().request(_FakeRequest(null), _SpyNextLink()).drain<void>();
      await DevConnectLink().request(_FakeRequest(''), _SpyNextLink()).drain<void>();

      expect(_sent('client:graphql_operation').map((p) => p['operation']),
          ['anonymous', 'anonymous']);
      expect(_sent('client:graphql_response').map((p) => p['operation']),
          ['anonymous', 'anonymous']);
    });

    test('emits synthetic error when no inner link is provided', () async {
      final link = DevConnectLink();

      final errors = <Object>[];
      final completer = Completer<void>();
      link.request(_FakeRequest(), null).listen(
        (_) {},
        onError: (e) {
          if (!completer.isCompleted) {
            errors.add(e);
            completer.complete();
          }
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
      );
      await completer.future.timeout(const Duration(seconds: 1));

      expect(errors, hasLength(1));
      expect(errors.single, isA<StateError>());
      expect(errors.single.toString(), contains('No downstream Link'));
      expect(_sent('client:graphql_response').single['operationId'],
          _sent('client:graphql_operation').single['operationId']);
    });
  });

  group('DevConnect GraphQL API', () {
    test('reportGraphQLResponse closes the operation with data and errors',
        () {
      final id = DevConnect.reportGraphQLOperation(
        operationName: 'GetUser',
        operationType: 'query',
        variables: {'id': 7},
      );
      DevConnect.reportGraphQLResponse(
        operationId: id,
        operation: 'GetUser',
        latencyMs: 12,
        data: {'user': null},
        errors: [_GqlError(), {'message': 'raw map'}],
      );

      expect(_sent('client:graphql_operation').single['operationId'], id);
      expect(_sent('client:graphql_response').single, {
        'operationId': id,
        'operation': 'GetUser',
        'latencyMs': 12,
        'data': {'user': null},
        'errors': [
          {
            'message': 'User not found',
            'path': ['user', 0],
            'locations': [
              {'line': 3, 'column': 5},
            ],
          },
          {'message': 'raw map'},
        ],
      });
    });

    test('the sanitizer keeps nested maps and lists as JSON, not strings', () {
      final when = DateTime.utc(2026, 1, 2);
      expect(
        DevConnectClient.sanitizeForJson({
          'variables': {
            'when': when,
            'ids': [1, when],
            'filter': {'active': true},
          },
        }),
        {
          'variables': {
            'when': when.toString(),
            'ids': [1, when.toString()],
            'filter': {'active': true},
          },
        },
      );
    });

    test('the sanitizer marks cycles and finishes on a graph with branches',
        () {
      final loop = <String, dynamic>{'id': 0};
      loop['self'] = loop;
      final shared = {'id': 1};
      expect(
        DevConnectClient.sanitizeForJson({
          'loop': loop,
          'twice': [shared, shared], // shared, but not inside itself
        }),
        {
          'loop': {'id': 0, 'self': '<cycle>'},
          'twice': [shared, shared],
        },
      );

      // Every node lists every node: copied once per path, that's 10^32.
      final nodes = [for (var i = 0; i < 10; i++) <String, dynamic>{'id': i}];
      for (final node in nodes) {
        node['neighbors'] = [...nodes];
      }
      final watch = Stopwatch()..start();
      final json =
          jsonEncode(DevConnectClient.sanitizeForJson({'nodes': nodes}));
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      expect(json, allOf(contains('"<cycle>"'), contains('"…"')));

      // The walk stops at the budget instead of padding the rest with `…`.
      final flat = DevConnectClient.sanitizeForJson(List.filled(1 << 20, 0));
      expect([flat.length, flat.last], [10000, '…']);
    });
  });
}
