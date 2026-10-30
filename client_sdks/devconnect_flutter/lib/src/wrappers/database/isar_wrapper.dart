import '../../devconnect_client.dart';

/// Auto-reporting wrapper for Isar database operations.
///
/// Since Isar is not a hard dependency, this uses duck-typing (dynamic).
///
/// ```dart
/// final isarWrapper = DevConnectIsar.wrap(isar);
///
/// // Put — auto-reports
/// final id = isarWrapper.put('users', () => isar.users.put(user));
///
/// // Query — auto-reports
/// final users = isarWrapper.query('users', () => isar.users.where().findAll());
///
/// // Delete — auto-reports
/// isarWrapper.delete('users', () => isar.users.delete(userId), id: userId);
/// ```
class DevConnectIsar {
  final dynamic _inner;

  DevConnectIsar._(this._inner);

  /// Wrap an Isar instance for auto-reporting.
  static DevConnectIsar wrap(dynamic isar) {
    return DevConnectIsar._(isar);
  }

  /// Wrap a read operation. Alias for [query].
  ///
  /// ```dart
  /// final users = isarWrapper.read('users', () => isar.users.where().findAll());
  /// ```
  T read<T>(String collection, T Function() block, {String? filter}) {
    return query(collection, block, filter: filter);
  }

  /// Wrap an async read operation. Alias for [queryAsync].
  Future<T> readAsync<T>(String collection, Future<T> Function() block, {String? filter}) async {
    return await queryAsync(collection, block, filter: filter);
  }

  /// Wrap a query/read operation.
  ///
  /// ```dart
  /// final id = isarWrapper.put('users', () => isar.users.put(user));
  /// ```
  T put<T>(String collection, T Function() block, {Map<String, dynamic>? data}) {
    final result = block();
    DevConnectClient.safeReportStorageOperation(
      storageType: 'isar',
      key: collection,
      value: {
        'id': result,
        'operation': 'put',
        if (data != null) 'data': data,
      },
      operation: 'write',
    );
    return result;
  }

  /// Wrap an async put (insert/update) operation.
  Future<T> putAsync<T>(String collection, Future<T> Function() block, {Map<String, dynamic>? data}) async {
    final result = await block();
    DevConnectClient.safeReportStorageOperation(
      storageType: 'isar',
      key: collection,
      value: {
        'id': result,
        'operation': 'put',
        if (data != null) 'data': data,
      },
      operation: 'write',
    );
    return result;
  }

  /// Wrap a putAll (batch insert/update) operation.
  ///
  /// ```dart
  /// final ids = isarWrapper.putAll('users', () => isar.users.putAll([u1, u2]));
  /// ```
  T putAll<T>(String collection, T Function() block) {
    final result = block();
    DevConnectClient.safeReportStorageOperation(
      storageType: 'isar',
      key: collection,
      value: {
        'operation': 'putAll',
        if (result is List) 'count': result.length,
      },
      operation: 'write',
    );
    return result;
  }

  /// Wrap a query/read operation.
  ///
  /// ```dart
  /// final users = isarWrapper.query('users',
  ///   () => isar.users.where().findAll(),
  ///   filter: 'where().findAll()',
  /// );
  /// ```
  T query<T>(String collection, T Function() block, {String? filter}) {
    final result = block();
    DevConnectClient.safeReportStorageOperation(
      storageType: 'isar',
      key: collection,
      value: {
        'operation': 'query',
        if (filter != null) 'filter': filter,
        if (result is List) 'resultCount': result.length,
      },
      operation: 'read',
    );
    return result;
  }

  /// Wrap an async query/read operation.
  Future<T> queryAsync<T>(String collection, Future<T> Function() block, {String? filter}) async {
    final result = await block();
    DevConnectClient.safeReportStorageOperation(
      storageType: 'isar',
      key: collection,
      value: {
        'operation': 'query',
        if (filter != null) 'filter': filter,
        if (result is List) 'resultCount': result.length,
      },
      operation: 'read',
    );
    return result;
  }

  /// Wrap a delete operation.
  ///
  /// ```dart
  /// isarWrapper.delete('users', () => isar.users.delete(42), id: 42);
  /// ```
  T delete<T>(String collection, T Function() block, {dynamic id}) {
    final result = block();
    DevConnectClient.safeReportStorageOperation(
      storageType: 'isar',
      key: collection,
      value: {
        'operation': 'delete',
        if (id != null) 'id': id,
      },
      operation: 'delete',
    );
    return result;
  }

  /// Wrap an async delete operation.
  Future<T> deleteAsync<T>(String collection, Future<T> Function() block, {dynamic id}) async {
    final result = await block();
    DevConnectClient.safeReportStorageOperation(
      storageType: 'isar',
      key: collection,
      value: {
        'operation': 'delete',
        if (id != null) 'id': id,
      },
      operation: 'delete',
    );
    return result;
  }

  /// Wrap a deleteAll (bulk delete) operation.
  T deleteAll<T>(String collection, T Function() block) {
    final result = block();
    DevConnectClient.safeReportStorageOperation(
      storageType: 'isar',
      key: collection,
      value: {
        'operation': 'deleteAll',
        if (result is int) 'count': result,
      },
      operation: 'delete',
    );
    return result;
  }

  /// Wrap a clear (collection clear) operation.
  T clear<T>(String collection, T Function() block) {
    final result = block();
    DevConnectClient.safeReportStorageOperation(
      storageType: 'isar',
      key: collection,
      value: {'operation': 'clear'},
      operation: 'clear',
    );
    return result;
  }

  /// Access the underlying Isar instance for direct operations.
  dynamic get inner => _inner;
}
