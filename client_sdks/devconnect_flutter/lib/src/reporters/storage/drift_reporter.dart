import '../../devconnect_client.dart';

/// Reporter for Drift (moor) database queries that wraps a QueryExecutor
/// and reports SQL queries to DevConnect.
///
/// Usage:
/// ```dart
/// @DriftDatabase(tables: [Todos])
/// class AppDatabase extends _$AppDatabase {
///   AppDatabase(QueryExecutor e) : super(DevConnect.driftQueryExecutor(e));
/// }
/// ```
///
/// Or report queries manually:
/// ```dart
/// final reporter = DevConnect.driftReporter();
/// reporter.reportQuery(
///   sql: 'SELECT * FROM users WHERE id = ?',
///   args: [42],
///   duration: Duration(milliseconds: 5),
/// );
/// ```
class DevConnectDriftReporter {
  /// Report a SQL query execution to DevConnect.
  ///
  /// [sql] - The SQL statement that was executed.
  /// [args] - The bound arguments for the query.
  /// [duration] - How long the query took.
  /// [rowCount] - Number of rows returned or affected.
  /// [error] - Error message if the query failed.
  void reportQuery({
    required String sql,
    List<dynamic>? args,
    Duration? duration,
    int? rowCount,
    String? error,
  }) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: 'drift',
        key: _extractTableName(sql),
        value: {
          'sql': sql,
          if (args != null && args.isNotEmpty) 'args': _serializeArgs(args),
          if (duration != null) 'duration_ms': duration.inMilliseconds,
          if (rowCount != null) 'rowCount': rowCount,
          if (error != null) 'error': error,
        },
        operation: _classifyOperation(sql),
      );
    } catch (_) {}
  }

  /// Report a database transaction.
  void reportTransaction({
    required String action,
    Duration? duration,
    String? error,
  }) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: 'drift',
        key: 'transaction',
        value: {
          'action': action,
          if (duration != null) 'duration_ms': duration.inMilliseconds,
          if (error != null) 'error': error,
        },
        operation: 'transaction',
      );
    } catch (_) {}
  }

  /// Report a batch operation.
  void reportBatch({
    required int statementCount,
    Duration? duration,
    String? error,
  }) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: 'drift',
        key: 'batch',
        value: {
          'statementCount': statementCount,
          if (duration != null) 'duration_ms': duration.inMilliseconds,
          if (error != null) 'error': error,
        },
        operation: 'batch',
      );
    } catch (_) {}
  }

  static String _classifyOperation(String sql) {
    final upper = sql.trimLeft().toUpperCase();
    if (upper.startsWith('SELECT')) return 'read';
    if (upper.startsWith('INSERT')) return 'write';
    if (upper.startsWith('UPDATE')) return 'write';
    if (upper.startsWith('DELETE')) return 'delete';
    if (upper.startsWith('CREATE')) return 'write';
    if (upper.startsWith('DROP')) return 'delete';
    if (upper.startsWith('ALTER')) return 'write';
    return 'query';
  }

  static String _extractTableName(String sql) {
    try {
      final upper = sql.trimLeft().toUpperCase();
      // SELECT ... FROM table
      final fromMatch = RegExp(r'FROM\s+[`"\[]?(\w+)', caseSensitive: false)
          .firstMatch(upper);
      if (fromMatch != null) return fromMatch.group(1)!.toLowerCase();

      // INSERT INTO table
      final insertMatch = RegExp(r'INTO\s+[`"\[]?(\w+)', caseSensitive: false)
          .firstMatch(upper);
      if (insertMatch != null) return insertMatch.group(1)!.toLowerCase();

      // UPDATE table
      final updateMatch = RegExp(r'UPDATE\s+[`"\[]?(\w+)', caseSensitive: false)
          .firstMatch(upper);
      if (updateMatch != null) return updateMatch.group(1)!.toLowerCase();

      // DELETE FROM table
      final deleteMatch = RegExp(r'DELETE\s+FROM\s+[`"\[]?(\w+)',
              caseSensitive: false)
          .firstMatch(upper);
      if (deleteMatch != null) return deleteMatch.group(1)!.toLowerCase();

      // CREATE TABLE table
      final createMatch = RegExp(r'TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?[`"\[]?(\w+)',
              caseSensitive: false)
          .firstMatch(upper);
      if (createMatch != null) return createMatch.group(1)!.toLowerCase();
    } catch (_) {}
    return 'unknown';
  }

  static List<dynamic> _serializeArgs(List<dynamic> args) {
    return args.map((arg) {
      if (arg == null) return null;
      if (arg is num || arg is bool || arg is String) return arg;
      if (arg is List<int>) return '<blob:${arg.length} bytes>';
      return arg.toString();
    }).toList();
  }
}

/// Wrapping query executor that reports all SQL operations to DevConnect.
///
/// This uses duck-typing to wrap any Drift QueryExecutor without depending
/// on the Drift package directly.
///
/// Usage:
/// ```dart
/// // Wrap your existing executor:
/// final executor = DevConnectDriftExecutor(NativeDatabase.memory());
/// ```
class DevConnectDriftExecutor {
  final dynamic _inner;
  final DevConnectDriftReporter _reporter;

  DevConnectDriftExecutor(this._inner) : _reporter = DevConnectDriftReporter();

  DevConnectDriftReporter get reporter => _reporter;

  /// Proxies to inner executor's runSelect and reports the query.
  Future<List<Map<String, Object?>>> runSelect(
      String statement, List<Object?> args) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await _inner.runSelect(statement, args) as List<Map<String, Object?>>;
      stopwatch.stop();
      _reporter.reportQuery(
        sql: statement,
        args: args,
        duration: stopwatch.elapsed,
        rowCount: result.length,
      );
      return result;
    } catch (e) {
      stopwatch.stop();
      _reporter.reportQuery(
        sql: statement,
        args: args,
        duration: stopwatch.elapsed,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Proxies to inner executor's runInsert and reports the query.
  Future<int> runInsert(String statement, List<Object?> args) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await _inner.runInsert(statement, args) as int;
      stopwatch.stop();
      _reporter.reportQuery(
        sql: statement,
        args: args,
        duration: stopwatch.elapsed,
      );
      return result;
    } catch (e) {
      stopwatch.stop();
      _reporter.reportQuery(
        sql: statement,
        args: args,
        duration: stopwatch.elapsed,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Proxies to inner executor's runUpdate and reports the query.
  Future<int> runUpdate(String statement, List<Object?> args) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await _inner.runUpdate(statement, args) as int;
      stopwatch.stop();
      _reporter.reportQuery(
        sql: statement,
        args: args,
        duration: stopwatch.elapsed,
        rowCount: result,
      );
      return result;
    } catch (e) {
      stopwatch.stop();
      _reporter.reportQuery(
        sql: statement,
        args: args,
        duration: stopwatch.elapsed,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Proxies to inner executor's runDelete and reports the query.
  Future<int> runDelete(String statement, List<Object?> args) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await _inner.runDelete(statement, args) as int;
      stopwatch.stop();
      _reporter.reportQuery(
        sql: statement,
        args: args,
        duration: stopwatch.elapsed,
        rowCount: result,
      );
      return result;
    } catch (e) {
      stopwatch.stop();
      _reporter.reportQuery(
        sql: statement,
        args: args,
        duration: stopwatch.elapsed,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Proxies to inner executor's runCustom and reports the query.
  Future<void> runCustom(String statement, [List<Object?>? args]) async {
    final stopwatch = Stopwatch()..start();
    try {
      await _inner.runCustom(statement, args ?? []);
      stopwatch.stop();
      _reporter.reportQuery(
        sql: statement,
        args: args,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      _reporter.reportQuery(
        sql: statement,
        args: args,
        duration: stopwatch.elapsed,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Forward any other calls to the inner executor via noSuchMethod.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // ignore: avoid_dynamic_calls
    return Function.apply(
      // ignore: avoid_dynamic_calls
      (invocation.isGetter)
          ? () => _inner.noSuchMethod(invocation)
          : _inner.noSuchMethod(invocation),
      [],
    );
  }
}
