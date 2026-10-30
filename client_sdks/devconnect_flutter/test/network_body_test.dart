import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:devconnect_manage_kit/devconnect_manage_kit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Payloads of the queued (pre-init) messages of [type].
List<Map<String, dynamic>> _sent(String type) => [
      for (final m in DevConnectClient.queuedMessages)
        if (m['type'] == type) m['payload'] as Map<String, dynamic>,
    ];

/// The bits of Dio's RequestOptions the interceptor reads.
class _DioOptions {
  _DioOptions(this.data);
  final method = 'POST';
  final uri = Uri.parse('https://api.x.dev/files');
  final headers = <String, dynamic>{};
  final extra = <String, dynamic>{};
  final Object? data;
}

/// The bits of Dio's Response the interceptor reads.
class _DioResponse {
  _DioResponse(this.requestOptions, this.data);
  final _DioOptions requestOptions;
  final statusCode = 200;
  final Object? headers = null;
  final Object? data;
}

/// The bits of DioException the interceptor reads.
class _DioError {
  _DioError(this.requestOptions, this.response);
  final _DioOptions requestOptions;
  final _DioResponse response;
  final message = 'failed';
}

class _DioHandler {
  void next(Object? value) {}
}

void main() {
  setUp(() => DevConnectClient.queuedMessages.clear());

  test('HttpOverrides reports big bodies and event streams by their size',
      () async {
    const big = 3 << 20; // past the 1 MB cap
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await request.drain<void>();
      final response = request.response;
      switch (request.uri.path) {
        case '/big':
          response.add(Uint8List(big));
        case '/events':
          response.headers.contentType = ContentType('text', 'event-stream');
          response.write('data: hi\n\n');
        case '/gif':
          response.headers.contentType = ContentType('image', 'gif');
          response.write('GIF89a'); // valid UTF-8, binary all the same
        default:
          response.headers.contentType = ContentType.json;
          response.write('{"ok":true}');
      }
      await response.close();
    });

    await HttpOverrides.runWithHttpOverrides(() async {
      final client = HttpClient();
      Future<int> received(String path, [List<int>? body]) async {
        final request = await client
            .postUrl(Uri.parse('http://127.0.0.1:${server.port}$path'));
        if (body != null) request.add(body);
        final response = await request.close();
        return response.fold<int>(0, (n, chunk) => n + chunk.length);
      }

      // The app still gets every byte.
      expect(await received('/big'), big);
      expect(await received('/events'), 10);
      expect(await received('/gif'), 6);
      expect(await received('/json', Uint8List(big)), 11);
      client.close();
    }, DevConnectHttpOverrides());

    final reports = _sent('client:network:request_complete');
    expect(reports.map((r) => r['responseBody']), [
      '<$big bytes, cut>',
      '<event stream, 10 bytes>',
      '6 bytes', // the desktop shows `N bytes` as a binary body
      {'ok': true},
    ]);
    expect(reports.last['requestBody'], '<$big bytes, cut>');
  });

  test('Dio reports raw bytes by their size and JSON lists as JSON', () {
    final dio = DevConnectDioInterceptor();
    final upload = _DioOptions(Uint8List(3 << 20));
    dio.onRequest(upload, _DioHandler());
    dio.onResponse(_DioResponse(upload, Uint8List(5 << 20)), _DioHandler());
    dio.onError(
        _DioError(upload, _DioResponse(upload, Uint8List(7))), _DioHandler());
    final list = _DioOptions(null);
    dio.onRequest(list, _DioHandler());
    dio.onResponse(
        _DioResponse(list, jsonDecode('[1, {"id": 2}]')), _DioHandler());

    expect(_sent('client:network:request_start').first['requestBody'],
        '3145728 bytes');
    final reports = _sent('client:network:request_complete');
    expect(reports[0]['requestBody'], '3145728 bytes');
    expect(reports[0]['responseBody'], '5242880 bytes');
    expect(reports[1]['responseBody'], '7 bytes');
    expect(reports[2]['responseBody'], [
      1,
      {'id': 2},
    ]);
  });
}
