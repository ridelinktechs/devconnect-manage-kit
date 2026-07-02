import 'dart:convert';

/// Convert a raw log message into a one-line preview suitable for
/// list-row titles and search-result previews.
///
/// Special handling for JSON objects/arrays so the user sees something
/// like `Object {3 keys: foo, bar, baz}` instead of just `{` (the first
/// character of the pretty-printed payload that the SDK sent over the
/// wire, which the list-row `maxLines: 1` would otherwise truncate to).
///
/// Non-JSON messages are returned unchanged.
String summarizeLogMessage(String message) {
  final trimmed = message.trimLeft();
  if (trimmed.isEmpty) return message;
  if (trimmed[0] != '{' && trimmed[0] != '[') return message;

  // Skip expensive JSON parsing for very large payloads — decoding a
  // multi-MB log synchronously on the main thread can cause noticeable
  // jank.  In practice a JSON preview is not useful for such payloads.
  if (trimmed.length > 5000) return message;

  // Try to parse as JSON — RN's `toStr` (and Flutter's `jsonEncode`) ship
  // pretty-printed payloads, so we can't rely on a single line.
  dynamic parsed;
  try {
    parsed = jsonDecode(trimmed);
  } catch (_) {
    return message; // not valid JSON — show the original text
  }

  if (parsed is Map) {
    final keys = parsed.keys.cast<String>().toList();
    if (keys.isEmpty) return 'Object {}';
    final preview = keys.take(3).join(', ');
    final more = keys.length > 3 ? ', …' : '';
    return 'Object {${keys.length} key${keys.length == 1 ? '' : 's'}: $preview$more}';
  }
  if (parsed is List) {
    if (parsed.isEmpty) return 'Array []';
    return 'Array [${parsed.length}]';
  }
  return message;
}
