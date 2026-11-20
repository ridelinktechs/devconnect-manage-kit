import 'dart:convert';

import '../../../models/network/network_entry.dart';

/// [entries] as an HTTP Archive (HAR 1.2), for Chrome DevTools, Charles or
/// Postman. Failed requests carry the error in `_error`.
Map<String, dynamic> buildHar(
  List<NetworkEntry> entries, {
  String creatorVersion = '',
}) => {
  'log': {
    'version': '1.2',
    'creator': {'name': 'DevConnect Manage Tool', 'version': creatorVersion},
    'entries': [for (final e in entries) _entry(e)],
  },
};

Map<String, dynamic> _entry(NetworkEntry e) {
  final time = e.duration ?? (e.endTime == null ? 0 : e.endTime! - e.startTime);
  final requestText = _text(e.requestBody);
  final responseText = _text(e.responseBody);
  return {
    'startedDateTime': DateTime.fromMillisecondsSinceEpoch(
      e.startTime,
      isUtc: true,
    ).toIso8601String(),
    'time': time,
    'request': {
      'method': e.method.toUpperCase(),
      'url': e.url,
      'httpVersion': 'HTTP/1.1',
      'headers': _headers(e.requestHeaders),
      'queryString': [
        for (final MapEntry(:key, :value)
            in (Uri.tryParse(e.url)?.queryParametersAll ?? const {}).entries)
          for (final v in value) {'name': key, 'value': v},
      ],
      'cookies': const [],
      'headersSize': -1,
      'bodySize': requestText?.length ?? 0,
      if (requestText != null)
        'postData': {
          'mimeType': _contentType(e.requestHeaders) ?? 'application/json',
          'text': requestText,
        },
    },
    'response': {
      'status': e.statusCode,
      'statusText': '',
      'httpVersion': 'HTTP/1.1',
      'headers': _headers(e.responseHeaders),
      'cookies': const [],
      'content': {
        'size': responseText?.length ?? 0,
        'mimeType': _contentType(e.responseHeaders) ?? '',
        'text': ?responseText,
      },
      'redirectURL': '',
      'headersSize': -1,
      'bodySize': responseText?.length ?? -1,
    },
    'cache': const {},
    'timings': {'send': 0, 'wait': time, 'receive': 0},
    '_error': ?e.error,
  };
}

List<Map<String, String>> _headers(Map<String, String> headers) => [
  for (final MapEntry(:key, :value) in headers.entries)
    {'name': key, 'value': value},
];

String? _contentType(Map<String, String> headers) => headers.entries
    .where((h) => h.key.toLowerCase() == 'content-type')
    .firstOrNull
    ?.value;

String? _text(Object? body) {
  if (body == null) return null;
  if (body is String) return body;
  try {
    return jsonEncode(body);
  } catch (_) {
    return '$body';
  }
}
