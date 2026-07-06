import 'dart:convert';

/// Truncated, single-line preview of a storage entry's value. Maps
/// and Lists render as their JSON encoding (also truncated); scalars
/// render via `toString()`. Matches the live tile row exactly so
/// tiles + detail panel stay in sync.
String storageValuePreview(dynamic value) {
  final v = value;
  if (v == null) return 'null';
  if (v is Map || v is List) {
    final s = jsonEncode(v);
    return s.length > 80 ? '${s.substring(0, 80)}...' : s;
  }
  final s = v.toString();
  return s.length > 80 ? '${s.substring(0, 80)}...' : s;
}

/// Compact stats line used by the metadata footer + the JSON-mode
/// empty state. Returns the cardinality / char count summary.
String storageValueStats(dynamic value) {
  final v = value;
  if (v == null) return 'null';
  if (v is Map) {
    final n = v.length;
    return '$n ${n == 1 ? 'key' : 'keys'} · ${v.values.length} values';
  }
  if (v is List) return '${v.length} items';
  final s = v.toString();
  if (s.length > 24) return '${s.length} chars';
  return s;
}

/// Human-readable shape label (mirrors the in-app bento grid).
String storageShapeOf(dynamic value) {
  if (value == null) return 'null';
  if (value is Map) {
    return 'Map · ${value.length} ${value.length == 1 ? "key" : "keys"}';
  }
  if (value is List) {
    return 'List · ${value.length} ${value.length == 1 ? "item" : "items"}';
  }
  if (value is String) {
    if (value.isEmpty) return 'String · empty';
    final t = value.trim();
    if ((t.startsWith('{') && t.endsWith('}')) ||
        (t.startsWith('[') && t.endsWith(']'))) {
      return 'String · JSON-shaped';
    }
    return 'String';
  }
  return value.runtimeType.toString();
}