import 'dart:convert';

final _identifier = RegExp(r'^[A-Za-z_$][\w$]*$');

/// JSONPath-style path of a child of [parent] (`''` is the root):
/// `user.name`, `items[0]`, `headers["content-type"]`.
String jsonChildPath(String parent, Object? key) {
  if (key is int) return '$parent[$key]';
  final k = '$key';
  if (_identifier.hasMatch(k)) return parent.isEmpty ? k : '$parent.$k';
  return '$parent[${jsonEncode(k)}]';
}

/// Where [query] shows up in [data]: the paths whose key or (primitive)
/// value contains it, case-insensitively, in document order — and every
/// container holding one, which the tree expands to reveal them.
({List<String> matches, Set<String> ancestors}) jsonSearch(
  Object? data,
  String query, {
  int limit = 500,
}) {
  final q = query.trim().toLowerCase();
  final matches = <String>[];
  final ancestors = <String>{};
  if (q.isEmpty) return (matches: matches, ancestors: ancestors);

  bool walk(Object? value, String path, String? key) {
    if (matches.length >= limit) return false;
    if (value is Map || value is List) {
      var found = key != null && key.toLowerCase().contains(q);
      if (found) matches.add(path);
      final entries = value is Map
          ? value.entries.map((e) => (e.key, e.value, '${e.key}'))
          : (value as List).indexed.map((e) => (e.$1, e.$2, null));
      var below = false;
      for (final (k, v, label) in entries) {
        if (walk(v, jsonChildPath(path, k), label)) below = true;
      }
      if (below) ancestors.add(path);
      return found || below;
    }
    final hit =
        (key != null && key.toLowerCase().contains(q)) ||
        '$value'.toLowerCase().contains(q);
    if (hit) matches.add(path);
    return hit;
  }

  walk(data, '', null);
  return (matches: matches, ancestors: ancestors);
}

/// Columns of a list of objects shown as a table: every key, in the order
/// first seen. Null unless every row is an object.
List<String>? jsonTableColumns(Object? data) {
  if (data is! List || data.isEmpty || data.any((r) => r is! Map)) return null;
  return {
    for (final row in data.cast<Map>()) ...row.keys.map((k) => '$k'),
  }.toList();
}

/// A table cell's text: strings as they are, objects and lists as JSON.
String jsonCellText(Object? value) {
  if (value is Map || value is List) {
    try {
      return jsonEncode(value);
    } catch (_) {}
  }
  return value is String ? value : '$value';
}

/// Indexes of the [rows] with a cell containing [query], case-insensitively;
/// every index for an empty query.
List<int> jsonTableFilter(List rows, String query) {
  final q = query.trim().toLowerCase();
  return [
    for (final (i, row) in rows.cast<Map>().indexed)
      if (q.isEmpty ||
          row.values.any((v) => jsonCellText(v).toLowerCase().contains(q)))
        i,
  ];
}

/// [rows] as CSV (RFC 4180): a header of [columns], then one line per row;
/// a missing key is an empty cell.
String jsonTableCsv(List<Map> rows, List<String> columns) {
  String field(String s) =>
      s.contains(RegExp(r'[",\r\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  return [
    columns.map(field).join(','),
    for (final row in rows)
      columns
          .map((c) => row.containsKey(c) ? field(jsonCellText(row[c])) : '')
          .join(','),
  ].join('\r\n');
}
