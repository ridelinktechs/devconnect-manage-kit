import 'dart:convert';
import 'dart:io';

import 'package:devconnect_manage_kit/devconnect_manage_kit.dart';
import 'package:devconnect_manage_kit/src/core/server_commands.dart';
import 'package:flutter_test/flutter_test.dart';

/// Payloads of the queued (pre-init) `client:network:request_complete`s.
List<Map<String, dynamic>> _completed() => [
      for (final m in DevConnectClient.queuedMessages)
        if (m['type'] == 'client:network:request_complete')
          m['payload'] as Map<String, dynamic>,
    ];

void main() {
  late HttpServer server;
  late Uri orders;
  final received = <String>[];

  setUp(() async {
    DevConnectClient.queuedMessages.clear();
    DevConnectClient.setNetworkConditions();
    received.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    orders = Uri.parse('http://127.0.0.1:${server.port}/orders');
    server.listen((request) async {
      received.add(await utf8.decoder.bind(request).join());
      request.response
        ..statusCode = 201
        ..headers.contentType = ContentType.json
        ..write('{"id":42}');
      await request.response.close();
    });
  });
  tearDown(() async {
    DevConnectClient.setNetworkConditions();
    await server.close(force: true);
  });

  Future<T> withSdk<T>(Future<T> Function() body) =>
      HttpOverrides.runWithHttpOverrides(body, DevConnect.httpOverrides());

  Future<HttpClientResponse> post(HttpClient client, String body) async {
    final request = await client.postUrl(orders);
    request.headers.contentType = ContentType.json;
    request.write(body);
    return request.close();
  }

  test('a response that is only drained still completes, request body and all',
      () async {
    await withSdk(() async {
      final client = HttpClient();
      await (await post(client, '{"item":"tea"}')).drain<void>();
      client.close();
    });
    final done = _completed();
    expect(done, hasLength(1));
    expect(done.single['statusCode'], 201);
    expect(done.single['requestBody'], {'item': 'tea'});
  });

  test('a replay is reported like any request, and sends the same body',
      () async {
    await withSdk(() => replayRequest({
          'method': 'POST',
          'url': '$orders',
          'headers': {'content-type': 'application/json'},
          'body': {'item': 'tea'},
        }));
    expect(received, ['{"item":"tea"}']);
    expect(_completed().single['statusCode'], 201);
  });

  test('simulated latency counts in the reported duration', () async {
    DevConnectClient.setNetworkConditions(latencyMs: 300);
    await withSdk(() async {
      final client = HttpClient();
      await utf8.decoder.bind(await post(client, '{}')).join();
      client.close();
    });
    expect(_completed().single['duration'], greaterThanOrEqualTo(300));
  });

  test('a request the simulated offline network refuses is reported failed',
      () async {
    DevConnectClient.setNetworkConditions(offline: true);
    await expectLater(
      withSdk(() async {
        final client = HttpClient();
        try {
          await post(client, '{}');
        } finally {
          client.close();
        }
      }),
      throwsA(isA<SocketException>()),
    );
    expect(received, isEmpty);
    final done = _completed().single;
    expect(done['statusCode'], 0);
    expect(done['error'], contains('simulated'));
  });
}
