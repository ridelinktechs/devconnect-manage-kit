import '../../devconnect_client.dart';

/// Auto-reporting wrapper for Sembast StoreRef.
///
/// ```dart
/// final store = DevConnectSembastStore.wrap(intMapStoreFactory.store('settings'), db);
/// await store.record(1).put({'theme': 'dark'}); // auto-reports write
/// await store.record(1).get();                    // auto-reports read
/// await store.record(1).delete();                 // auto-reports delete
/// ```
class DevConnectSembastStore {
  final dynamic _store;
  final dynamic _db;
  final String _storeName;

  DevConnectSembastStore._(this._store, this._db, this._storeName);

  /// Wrap a Sembast StoreRef + Database for auto-reporting.
  static DevConnectSembastStore wrap(dynamic store, dynamic db, [String? name]) {
    return DevConnectSembastStore._(store, db, name ?? 'sembast');
  }

  /// Get a record wrapper for auto-reporting.
  DevConnectSembastRecord record(dynamic key) {
    return DevConnectSembastRecord._(_store.record(key), _db, _storeName, key.toString());
  }

  Future<List<dynamic>> find(dynamic db, {dynamic finder}) async {
    final results = await _store.find(db, finder: finder);
    _report('read', '*', '${results.length} records');
    return results;
  }

  Future<int> delete(dynamic db, {dynamic finder}) async {
    final count = await _store.delete(db, finder: finder);
    _report('delete', '*', '$count deleted');
    return count;
  }

  void _report(String operation, String key, dynamic value) {
    DevConnectClient.safeReportStorageOperation(
      storageType: 'sembast',
      key: '$_storeName:$key',
      value: value,
      operation: operation,
    );
  }
}

class DevConnectSembastRecord {
  final dynamic _record;
  final dynamic _db;
  final String _storeName;
  final String _key;

  DevConnectSembastRecord._(this._record, this._db, this._storeName, this._key);

  Future<dynamic> get() async {
    final value = await _record.get(_db);
    DevConnectClient.safeReportStorageOperation(
      storageType: 'sembast',
      key: '$_storeName:$_key',
      value: value,
      operation: 'read',
    );
    return value;
  }

  Future<dynamic> put(dynamic value) async {
    final result = await _record.put(_db, value);
    DevConnectClient.safeReportStorageOperation(
      storageType: 'sembast',
      key: '$_storeName:$_key',
      value: value,
      operation: 'write',
    );
    return result;
  }

  Future<dynamic> delete() async {
    final result = await _record.delete(_db);
    DevConnectClient.safeReportStorageOperation(
      storageType: 'sembast',
      key: '$_storeName:$_key',
      operation: 'delete',
    );
    return result;
  }
}
