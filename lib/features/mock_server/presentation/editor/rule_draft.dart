import 'dart:convert';

import '../../../../models/round/mock_entry.dart';

/// A box of the rule editor.
enum RuleField {
  name,
  method,
  url,
  status,
  delay,
  headers,
  body,
  devices,
  expires,
}

/// ISO-8601 the way all three SDKs parse it: a `T`, optional seconds and
/// fraction, then `Z`, `±hh:mm` or nothing (the device's local time).
final _isoTime = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2})(?:\.\d{1,9})?)?'
  r'(?:Z|[+-](?:[01]\d|2[0-3]):[0-5]\d)?$',
);

/// Whether [at] is ISO-8601 that names a real moment. Dart alone would
/// roll 2026-13-45 over into 2027, where Android refuses it.
bool _isRealIsoTime(String at) {
  final m = _isoTime.firstMatch(at);
  if (m == null) return false;
  final [y, mo, d, h, mi] = [for (var i = 1; i <= 5; i++) int.parse(m[i]!)];
  final s = int.parse(m[6] ?? '0');
  final t = DateTime.utc(y, mo, d, h, mi, s);
  return (t.year, t.month, t.day, t.hour, t.minute, t.second) ==
      (y, mo, d, h, mi, s);
}

/// The rule editor's content, each box as the text in it, so it can be
/// compared, checked and saved apart from the widgets.
class RuleDraft {
  final String name;
  final String method;
  final String url;
  final String status;
  final String delay;
  final String headers;
  final String body;
  final String devices;
  final String expires;

  const RuleDraft({
    required this.name,
    required this.method,
    required this.url,
    required this.status,
    required this.delay,
    required this.headers,
    required this.body,
    required this.devices,
    required this.expires,
  });

  /// [rule] as the editor shows it; a JSON body is indented.
  factory RuleDraft.of(MockRule rule) {
    final md = rule.metadata ?? const <String, dynamic>{};
    final scope = md['scope'];
    final ids = scope is Map ? scope['deviceIds'] : null;
    return RuleDraft(
      name: rule.name,
      method: rule.method.toUpperCase(),
      url: rule.urlPattern,
      status: '${rule.statusCode}',
      delay: '${md['delayMs'] ?? ''}',
      headers: rule.headers.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n'),
      body: prettyJsonOr(rule.body),
      devices: ids is List ? ids.join(', ') : '',
      expires: '${md['expiresAt'] ?? ''}',
    );
  }

  String text(RuleField field) => switch (field) {
    RuleField.name => name,
    RuleField.method => method,
    RuleField.url => url,
    RuleField.status => status,
    RuleField.delay => delay,
    RuleField.headers => headers,
    RuleField.body => body,
    RuleField.devices => devices,
    RuleField.expires => expires,
  };

  /// The boxes whose text differs from [saved].
  Set<RuleField> changesFrom(RuleDraft saved) => {
    for (final f in RuleField.values)
      if (text(f) != saved.text(f)) f,
  };

  /// Why [field] can't be saved as it is, or null when it can.
  String? errorOf(RuleField field) {
    switch (field) {
      case RuleField.url:
        final pattern = url.trim();
        if (pattern.isEmpty) return 'Enter a pattern; .* matches every URL';
        try {
          RegExp(pattern);
        } on FormatException catch (e) {
          return 'Not a valid regex: ${e.message}';
        }
        return null;
      case RuleField.status:
        final code = int.tryParse(status.trim());
        return code == null || code < 100 || code > 599
            ? 'Use a status code from 100 to 599'
            : null;
      case RuleField.delay:
        final ms = delay.trim();
        if (ms.isEmpty) return null;
        final n = int.tryParse(ms);
        return n == null || n < 0 ? 'Use whole milliseconds, 0 or more' : null;
      case RuleField.headers:
        final lines = headers.split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          if (line.indexOf(':') <= 0) return 'Line ${i + 1} needs key: value';
        }
        return null;
      case RuleField.expires:
        final at = expires.trim();
        if (at.isEmpty) return null;
        return _isRealIsoTime(at)
            ? null
            : 'Use ISO-8601, e.g. 2026-12-31T23:59:59Z';
      case RuleField.name ||
          RuleField.method ||
          RuleField.body ||
          RuleField.devices:
        return null;
    }
  }

  /// The boxes that can't be saved yet, top to bottom.
  List<RuleField> get invalid => [
    for (final f in RuleField.values)
      if (errorOf(f) != null) f,
  ];

  /// [rule] with this draft's values. Metadata the editor doesn't show,
  /// such as header matchers, is kept.
  MockRule applyTo(MockRule rule, {required int now}) {
    final md = {...?rule.metadata}
      ..remove('delayMs')
      ..remove('scope')
      ..remove('expiresAt');
    final ms = int.tryParse(delay.trim());
    if (ms != null) md['delayMs'] = ms;
    final ids = [
      for (final id in devices.split(','))
        if (id.trim().isNotEmpty) id.trim(),
    ];
    if (ids.isNotEmpty) md['scope'] = {'deviceIds': ids};
    if (expires.trim().isNotEmpty) md['expiresAt'] = expires.trim();
    return rule.copyWith(
      name: name.trim(),
      method: method,
      urlPattern: url.trim(),
      statusCode: int.parse(status.trim()),
      headers: parseHeaderLines(headers),
      body: body,
      updatedAt: now,
      metadata: md.isEmpty ? null : md,
      clearMetadata: md.isEmpty,
    );
  }
}

/// `key: value` lines as a map; blank lines are skipped.
Map<String, String> parseHeaderLines(String text) => {
  for (final line in text.split('\n'))
    if (line.indexOf(':') > 0)
      line.substring(0, line.indexOf(':')).trim(): line
          .substring(line.indexOf(':') + 1)
          .trim(),
};

/// Whether [raw] parses as JSON.
bool isJson(String raw) {
  try {
    jsonDecode(raw);
    return true;
  } on FormatException {
    return false;
  }
}

/// [raw] indented by two spaces when it is JSON, otherwise unchanged.
String prettyJsonOr(String raw) {
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
  } on FormatException {
    return raw;
  }
}
