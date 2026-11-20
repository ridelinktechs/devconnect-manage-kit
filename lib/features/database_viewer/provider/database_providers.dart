import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/storage/storage_entry.dart';
import '../../../server/providers/server_providers.dart';

/// Each device's registered databases and their tables, as last reported
/// (`client:database:schema`). A device missing from the map hasn't
/// answered yet — older SDKs never will.
final databaseSchemasProvider =
    NotifierProvider<
      DatabaseSchemasNotifier,
      Map<String, List<DatabaseSchema>>
    >(DatabaseSchemasNotifier.new);

class DatabaseSchemasNotifier
    extends Notifier<Map<String, List<DatabaseSchema>>> {
  @override
  Map<String, List<DatabaseSchema>> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onDatabaseSchema.listen((m) {
      state = {
        ...state,
        m['deviceId'] as String: [
          for (final d in m['databases'] as List? ?? const []) ?_parse(d),
        ],
      };
    });
    ref.onDispose(sub.cancel);
    return const {};
  }

  /// Asks [deviceId]'s app for its databases (again).
  void request(String deviceId) =>
      ref.read(wsMessageHandlerProvider).requestDatabaseSchema(deviceId);

  /// Comes from the app's SDK: skip a malformed entry rather than drop all.
  static DatabaseSchema? _parse(Object? json) {
    try {
      return DatabaseSchema.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

class QueryResult {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final String? error;
  final int executionTimeMs;

  /// The app left rows out (it sends at most 1000).
  final bool truncated;

  QueryResult({
    required this.columns,
    required this.rows,
    this.error,
    this.executionTimeMs = 0,
    this.truncated = false,
  });

  factory QueryResult.fromPayload(Map<String, dynamic> p) => QueryResult(
    columns: [for (final c in p['columns'] as List? ?? const []) '$c'],
    rows: [
      for (final r in p['rows'] as List? ?? const [])
        if (r is Map) r.cast<String, dynamic>(),
    ],
    error: p['error'] as String?,
    executionTimeMs: (p['executionTimeMs'] as num?)?.toInt() ?? 0,
    truncated: p['truncated'] == true,
  );
}

/// The last query run on a device; [result] is null while it runs.
class DatabaseQuery {
  final String database;
  final String sql;
  final QueryResult? result;

  const DatabaseQuery(this.database, this.sql, [this.result]);
}

/// Each device's last query, by device id.
final databaseQueryProvider =
    NotifierProvider<DatabaseQueryNotifier, Map<String, DatabaseQuery>>(
      DatabaseQueryNotifier.new,
    );

class DatabaseQueryNotifier extends Notifier<Map<String, DatabaseQuery>> {
  /// An app without database support never answers.
  static const timeout = Duration(seconds: 15);

  @override
  Map<String, DatabaseQuery> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onDatabaseQueryResult.listen((m) {
      final deviceId = m['deviceId'] as String;
      final pending = state[deviceId];
      if (pending == null) return;
      _settle(deviceId, pending, QueryResult.fromPayload(m));
    });
    ref.onDispose(sub.cancel);
    return const {};
  }

  void run(String deviceId, String database, String sql, {String? noResponse}) {
    ref.read(wsMessageHandlerProvider).queryDatabase(deviceId, database, sql);
    final query = DatabaseQuery(database, sql);
    state = {...state, deviceId: query};
    Timer(timeout, () {
      if (!ref.mounted || !identical(state[deviceId], query)) return;
      _settle(
        deviceId,
        query,
        QueryResult(columns: const [], rows: const [], error: noResponse),
      );
    });
  }

  void _settle(String deviceId, DatabaseQuery query, QueryResult result) {
    state = {
      ...state,
      deviceId: DatabaseQuery(query.database, query.sql, result),
    };
  }
}
