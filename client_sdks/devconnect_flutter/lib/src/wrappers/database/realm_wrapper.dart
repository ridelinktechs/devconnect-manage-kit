import '../../devconnect_client.dart';

/// Auto-reporting wrapper for Realm database operations.
///
/// Since Realm is not a hard dependency, this uses duck-typing (dynamic).
///
/// ```dart
/// final realmWrapper = DevConnectRealm.wrap(realm);
///
/// // Writes — auto-reports
/// realmWrapper.write('User', () {
///   realm.add(User('John'));
/// });
///
/// // Queries — auto-reports
/// final users = realmWrapper.query('User', () => realm.all<User>().toList());
///
/// // Deletes — auto-reports
/// realmWrapper.delete('User', () {
///   realm.delete(user);
/// });
/// ```
class DevConnectRealm {
  final dynamic _inner;

  DevConnectRealm._(this._inner);

  /// Wrap a Realm instance for auto-reporting.
  static DevConnectRealm wrap(dynamic realm) {
    return DevConnectRealm._(realm);
  }

  /// Wrap a write/create/update operation.
  ///
  /// ```dart
  /// realmWrapper.write('User', () {
  ///   realm.add(User('John'));
  /// }, data: {'name': 'John'});
  /// ```
  T write<T>(String className, T Function() block, {Map<String, dynamic>? data}) {
    final result = block();
    DevConnectClient.safeReportStorageOperation(
      storageType: 'realm',
      key: className,
      value: data ?? {'operation': 'write'},
      operation: 'write',
    );
    return result;
  }

  /// Wrap an async write/create/update operation.
  Future<T> writeAsync<T>(String className, Future<T> Function() block, {Map<String, dynamic>? data}) async {
    final result = await block();
    DevConnectClient.safeReportStorageOperation(
      storageType: 'realm',
      key: className,
      value: data ?? {'operation': 'write'},
      operation: 'write',
    );
    return result;
  }

  /// Wrap a read operation. Alias for [query].
  ///
  /// ```dart
  /// final users = realmWrapper.read('User', () => realm.all<User>().toList());
  /// ```
  T read<T>(String className, T Function() block, {String? filter, int? resultCount}) {
    return query(className, block, filter: filter, resultCount: resultCount);
  }

  /// Wrap an async read operation. Alias for [queryAsync].
  Future<T> readAsync<T>(String className, Future<T> Function() block, {String? filter, int? resultCount}) async {
    return await queryAsync(className, block, filter: filter, resultCount: resultCount);
  }

  /// Wrap a query/read operation.
  ///
  /// ```dart
  /// final users = realmWrapper.query('User', () => realm.all<User>().toList());
  /// ```
  T query<T>(String className, T Function() block, {String? filter, int? resultCount}) {
    final result = block();
    DevConnectClient.safeReportStorageOperation(
      storageType: 'realm',
      key: className,
      value: {
        'operation': 'query',
        if (filter != null) 'filter': filter,
        if (resultCount != null) 'resultCount': resultCount,
      },
      operation: 'read',
    );
    return result;
  }

  /// Wrap an async query/read operation.
  Future<T> queryAsync<T>(String className, Future<T> Function() block, {String? filter, int? resultCount}) async {
    final result = await block();
    DevConnectClient.safeReportStorageOperation(
      storageType: 'realm',
      key: className,
      value: {
        'operation': 'query',
        if (filter != null) 'filter': filter,
        if (resultCount != null) 'resultCount': resultCount,
      },
      operation: 'read',
    );
    return result;
  }

  /// Wrap a delete operation.
  ///
  /// ```dart
  /// realmWrapper.delete('User', () {
  ///   realm.delete(user);
  /// });
  /// ```
  T delete<T>(String className, T Function() block, {dynamic id}) {
    final result = block();
    DevConnectClient.safeReportStorageOperation(
      storageType: 'realm',
      key: className,
      value: {
        'operation': 'delete',
        if (id != null) 'id': id,
      },
      operation: 'delete',
    );
    return result;
  }

  /// Wrap an async delete operation.
  Future<T> deleteAsync<T>(String className, Future<T> Function() block, {dynamic id}) async {
    final result = await block();
    DevConnectClient.safeReportStorageOperation(
      storageType: 'realm',
      key: className,
      value: {
        'operation': 'delete',
        if (id != null) 'id': id,
      },
      operation: 'delete',
    );
    return result;
  }

  /// Report a transaction with count of affected objects.
  void transaction(String description, {int? affectedObjects}) {
    DevConnectClient.safeReportStorageOperation(
      storageType: 'realm',
      key: description,
      value: {
        if (affectedObjects != null) 'affectedObjects': affectedObjects,
      },
      operation: 'write',
    );
  }

  /// Access the underlying Realm instance for direct operations.
  dynamic get inner => _inner;
}
