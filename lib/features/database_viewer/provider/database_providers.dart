import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/storage/storage_entry.dart';

final databaseSchemaProvider =
    NotifierProvider<DatabaseSchemaNotifier, List<DatabaseSchema>>(
        DatabaseSchemaNotifier.new);

final selectedTableProvider =
    NotifierProvider<_SelectedTableNotifier, String?>(
  _SelectedTableNotifier.new,
);

class _SelectedTableNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? v) => state = v;
}

final queryResultProvider =
    NotifierProvider<QueryResultNotifier, QueryResult?>(
        QueryResultNotifier.new);

class DatabaseSchemaNotifier extends Notifier<List<DatabaseSchema>> {
  @override
  List<DatabaseSchema> build() => [];

  void setSchemas(List<DatabaseSchema> schemas) => state = schemas;
  void clear() => state = [];
}

class QueryResult {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final String? error;
  final int executionTimeMs;

  QueryResult({
    required this.columns,
    required this.rows,
    this.error,
    this.executionTimeMs = 0,
  });
}

class QueryResultNotifier extends Notifier<QueryResult?> {
  @override
  QueryResult? build() => null;

  void setResult(QueryResult result) => state = result;
  void clear() => state = null;
}