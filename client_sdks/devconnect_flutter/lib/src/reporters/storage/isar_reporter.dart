import '../../devconnect_client.dart';

/// Reporter for Isar database operations that sends put/delete/query
/// events to DevConnect.
///
/// Usage:
/// ```dart
/// final reporter = DevConnect.isarReporter();
///
/// // After a put operation:
/// final id = await isar.users.put(user);
/// reporter.reportPut('users', id, data: user.toJson());
///
/// // After a query:
/// final results = await isar.users.where().findAll();
/// reporter.reportQuery('users',
///   filter: 'where().findAll()',
///   resultCount: results.length,
/// );
///
/// // After a delete:
/// await isar.users.delete(42);
/// reporter.reportDelete('users', 42);
/// ```
class DevConnectIsarReporter {
  /// Report an Isar put (insert/update) operation.
  ///
  /// [collection] - The Isar collection name (e.g., 'users').
  /// [id] - The ID of the inserted/updated object.
  /// [data] - The serialized object data (optional).
  void reportPut(String collection, dynamic id, {Map<String, dynamic>? data}) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: 'isar',
        key: collection,
        value: {
          'id': id,
          'operation': 'put',
          if (data != null) 'data': data,
        },
        operation: 'write',
      );
    } catch (_) {}
  }

  /// Report an Isar putAll (batch insert/update) operation.
  ///
  /// [collection] - The Isar collection name.
  /// [ids] - The IDs of the inserted/updated objects.
  /// [count] - Number of objects put.
  void reportPutAll(String collection, {List<dynamic>? ids, int? count}) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: 'isar',
        key: collection,
        value: {
          'operation': 'putAll',
          if (ids != null) 'ids': ids,
          'count': count ?? ids?.length ?? 0,
        },
        operation: 'write',
      );
    } catch (_) {}
  }

  /// Report an Isar delete operation.
  ///
  /// [collection] - The Isar collection name.
  /// [id] - The ID of the deleted object.
  void reportDelete(String collection, dynamic id) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: 'isar',
        key: collection,
        value: {
          'id': id,
          'operation': 'delete',
        },
        operation: 'delete',
      );
    } catch (_) {}
  }

  /// Report an Isar deleteAll / bulk delete operation.
  ///
  /// [collection] - The Isar collection name.
  /// [count] - Number of objects deleted.
  void reportDeleteAll(String collection, {int? count}) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: 'isar',
        key: collection,
        value: {
          'operation': 'deleteAll',
          if (count != null) 'count': count,
        },
        operation: 'delete',
      );
    } catch (_) {}
  }

  /// Report an Isar query operation.
  ///
  /// [collection] - The Isar collection name.
  /// [filter] - A description of the query filter applied.
  /// [resultCount] - Number of results returned.
  /// [duration] - How long the query took.
  void reportQuery(
    String collection, {
    String? filter,
    int? resultCount,
    Duration? duration,
  }) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: 'isar',
        key: collection,
        value: {
          'operation': 'query',
          if (filter != null) 'filter': filter,
          if (resultCount != null) 'resultCount': resultCount,
          if (duration != null) 'duration_ms': duration.inMilliseconds,
        },
        operation: 'read',
      );
    } catch (_) {}
  }

  /// Report an Isar clear / collection clear operation.
  ///
  /// [collection] - The Isar collection name.
  void reportClear(String collection) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: 'isar',
        key: collection,
        value: {
          'operation': 'clear',
        },
        operation: 'clear',
      );
    } catch (_) {}
  }

  /// Report an Isar watch / listener registration.
  ///
  /// [collection] - The Isar collection name.
  /// [filter] - Description of what is being watched.
  void reportWatch(String collection, {String? filter}) {
    try {
      DevConnectClient.safeLog(
        'Isar watch registered on $collection${filter != null ? ' ($filter)' : ''}',
        tag: 'Isar',
        metadata: {
          'collection': collection,
          if (filter != null) 'filter': filter,
        },
      );
    } catch (_) {}
  }
}
