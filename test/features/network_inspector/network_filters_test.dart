import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/features/network_inspector/export/har.dart';
import 'package:devconnect_manage_tool/features/network_inspector/provider/network_providers.dart';
import 'package:devconnect_manage_tool/models/network/network_entry.dart';

NetworkEntry _entry({
  int status = 200,
  String? error,
  Object? requestBody,
  Object? responseBody,
}) => NetworkEntry(
  id: 'r',
  deviceId: 'd',
  method: 'post',
  url: 'https://api.example.com/users?page=2&tag=a&tag=b',
  statusCode: status,
  requestHeaders: const {'Content-Type': 'application/json'},
  responseHeaders: const {'content-type': 'application/json; charset=utf-8'},
  requestBody: requestBody,
  responseBody: responseBody,
  startTime: 1798000000000,
  duration: 120,
  error: error,
  isComplete: true,
);

void main() {
  test('status classes, errors including failed requests', () {
    expect(
      matchesStatus(_entry(status: 204), NetworkStatusFilter.success),
      isTrue,
    );
    expect(
      matchesStatus(_entry(status: 302), NetworkStatusFilter.redirect),
      isTrue,
    );
    expect(
      matchesStatus(_entry(status: 404), NetworkStatusFilter.error),
      isTrue,
    );
    expect(
      matchesStatus(_entry(status: 503), NetworkStatusFilter.error),
      isTrue,
    );
    expect(
      matchesStatus(
        _entry(status: 0, error: 'timeout'),
        NetworkStatusFilter.error,
      ),
      isTrue,
    );
    expect(
      matchesStatus(_entry(status: 200), NetworkStatusFilter.error),
      isFalse,
    );
  });

  test('body search sees both bodies, case-insensitively', () {
    final e = _entry(
      requestBody: {'email': 'An@Example.com'},
      responseBody: '{"token":"XYZ"}',
    );
    expect(networkBodyText(e), contains('an@example.com'));
    expect(networkBodyText(e), contains('xyz'));
  });

  test('exports HAR 1.2 entries', () {
    final har = buildHar([
      _entry(requestBody: {'name': 'An'}, responseBody: {'id': 1}, error: 'x'),
    ], creatorVersion: '1.0.6');
    final log = har['log'] as Map;
    expect(log['version'], '1.2');
    final entry = (log['entries'] as List).single as Map;
    expect(entry['startedDateTime'], '2026-12-23T04:26:40.000Z');
    expect(entry['time'], 120);

    final request = entry['request'] as Map;
    expect(request['method'], 'POST');
    expect(request['queryString'], [
      {'name': 'page', 'value': '2'},
      {'name': 'tag', 'value': 'a'},
      {'name': 'tag', 'value': 'b'},
    ]);
    expect(request['postData'], {
      'mimeType': 'application/json',
      'text': '{"name":"An"}',
    });

    final response = entry['response'] as Map;
    expect(response['status'], 200);
    expect((response['content'] as Map)['text'], '{"id":1}');
    expect(
      (response['content'] as Map)['mimeType'],
      startsWith('application/json'),
    );
    expect(entry['_error'], 'x');
  });
}
