import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect_manage_kit/src/interceptors/graphql/devconnect_link.dart';

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
  @override
  String get operationName => 'TestQuery';

  @override
  Map<String, dynamic> get context => const {
        'operationType': 'query',
        'variables': {},
      };
}

void main() {
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
    });
  });
}
