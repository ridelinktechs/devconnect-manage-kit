import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../storage_adapter.dart';

/// Reads / writes / deletes / clears a registered storage, then sends its
/// contents back.
Future<void> handleStorageCommand(
    Map<String, DevConnectStorageAdapter> storages,
    void Function(String type, Map<String, dynamic> payload) send,
    String type,
    Map<String, dynamic> p) async {
  final storageType = p['storageType'] as String?;
  final targets = storageType == null
      ? storages.entries.toList()
      : [
          if (storages[storageType] case final adapter?)
            MapEntry(storageType, adapter),
        ];
  for (final MapEntry(key: name, value: adapter) in targets) {
    try {
      final key = p['key'] as String? ?? '';
      switch (type) {
        case 'server:storage:write':
          await adapter.set(key, p['value']);
        case 'server:storage:delete':
          await adapter.remove(key);
        case 'server:storage:clear':
          await adapter.clear();
      }
      send('client:storage:all_data',
          {'storageType': name, 'entries': await adapter.getAll()});
    } catch (e) {
      send('client:storage:all_data',
          {'storageType': name, 'entries': {}, 'error': e.toString()});
    }
  }
}

/// Delivers [url] the way the engine delivers a deep link, so the app's
/// Router (or Navigator's onGenerateRoute) handles it.
void openUrl(String url) {
  ServicesBinding.instance.channelBuffers.push(
    SystemChannels.navigation.name,
    SystemChannels.navigation.codec.encodeMethodCall(
        MethodCall('pushRouteInformation', {'location': url, 'state': null})),
    (_) {},
  );
}

/// Sends a captured request again through `HttpClient`, which
/// `DevConnectHttpOverrides` intercepts, so the replay shows up too.
Future<void> replayRequest(Map<String, dynamic> p) async {
  final url = Uri.tryParse(p['url'] as String? ?? '');
  if (url == null) return;
  final method = (p['method'] as String? ?? 'GET').toUpperCase();
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, url);
    (p['headers'] as Map?)?.forEach((k, v) {
      if ('$k'.toLowerCase() != 'content-length') {
        request.headers.set('$k', '$v');
      }
    });
    final body = p['body'];
    if (body != null && method != 'GET' && method != 'HEAD') {
      request.write(body is String ? body : jsonEncode(body));
    }
    await (await request.close()).drain<void>();
  } catch (_) {
    // Reported like any other failed request.
  } finally {
    client.close();
  }
}

/// Rows past this are left out of a query result, which says `truncated`.
const _maxQueryRows = 1000;

Future<List<Map<String, dynamic>>> databaseSchemas(
        Map<String, Future<List<Map<String, Object?>>> Function(String sql)>
            databases) async =>
    [
      for (final MapEntry(key: name, value: query) in databases.entries)
        {'name': name, 'tables': await sqliteTables(query)},
    ];

/// SQLite tables with their columns and row counts; empty if unreadable.
Future<List<Map<String, dynamic>>> sqliteTables(
    Future<List<Map<String, Object?>>> Function(String sql) query) async {
  try {
    final names = await query("SELECT name FROM sqlite_master WHERE "
        "type = 'table' AND name NOT LIKE 'sqlite_%' "
        "AND name <> 'android_metadata' ORDER BY name");
    return [
      for (final row in names)
        await () async {
          final table = '${row['name']}';
          final quoted = '"${table.replaceAll('"', '""')}"';
          final columns = await query('PRAGMA table_info($quoted)');
          final count = await query('SELECT COUNT(*) AS c FROM $quoted');
          return {
            'name': table,
            'columns': [
              for (final c in columns)
                {
                  'name': '${c['name']}',
                  'type': '${c['type'] ?? ''}',
                  'isPrimaryKey': ((c['pk'] as num?) ?? 0) > 0,
                  'isNullable': ((c['notnull'] as num?) ?? 0) == 0,
                },
            ],
            'rowCount': count.isEmpty ? 0 : count.first['c'],
          };
        }(),
    ];
  } catch (_) {
    return [];
  }
}

Future<Map<String, dynamic>> runDatabaseQuery(
    Map<String, Future<List<Map<String, Object?>>> Function(String sql)>
        databases,
    String? database,
    String sql) async {
  final stopwatch = Stopwatch()..start();
  final result = <String, dynamic>{'database': database};
  try {
    final query = databases[database] ?? databases.values.firstOrNull;
    if (query == null) {
      throw StateError(
          'No database registered with DevConnect.registerDatabase');
    }
    final select =
        RegExp(r'^\s*(select|with)\b', caseSensitive: false).hasMatch(sql);
    final inner = sql.replaceFirst(RegExp(r'[\s;]+$'), '');
    List<Map<String, Object?>> rows;
    try {
      rows = await query(select
          ? 'SELECT * FROM (\n$inner\n) LIMIT ${_maxQueryRows + 1}'
          : sql);
    } catch (_) {
      if (!select) rethrow;
      rows = await query(sql);
    }
    result
      ..['columns'] = rows.isEmpty ? <String>[] : rows.first.keys.toList()
      ..['rows'] = [
        for (final row in rows.take(_maxQueryRows))
          {
            for (final MapEntry(:key, :value) in row.entries)
              key: value is List<int> ? '<blob ${value.length} bytes>' : value,
          },
      ]
      ..['truncated'] = rows.length > _maxQueryRows;
  } catch (e) {
    result
      ..['columns'] = <String>[]
      ..['rows'] = <Map<String, dynamic>>[]
      ..['error'] = e.toString();
  }
  return result..['executionTimeMs'] = stopwatch.elapsedMilliseconds;
}
