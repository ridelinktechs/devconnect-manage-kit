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

  // Cheap shape check before paying the cost of a full JSON decode.
  // For very large payloads, return a simple cover without key names.
  const largePayloadThreshold = 1000;
  if (trimmed.length > largePayloadThreshold) {
    final kb = (trimmed.length / 1024).toStringAsFixed(1);
    if (trimmed[0] == '{') return 'Object {…} ($kb KB)';
    return 'Array […] ($kb KB)';
  }

  dynamic parsed;
  try {
    parsed = jsonDecode(trimmed);
  } catch (_) {
    return message;
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
