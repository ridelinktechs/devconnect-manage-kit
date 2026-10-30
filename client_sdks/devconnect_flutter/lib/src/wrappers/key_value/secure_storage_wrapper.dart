import '../../devconnect_client.dart';

/// Auto-reporting wrapper for flutter_secure_storage.
///
/// ```dart
/// final storage = DevConnectSecureStorage.wrap(FlutterSecureStorage());
/// await storage.write(key: 'token', value: 'secret'); // auto-reports write (masked)
/// await storage.read(key: 'token');                     // auto-reports read
/// await storage.delete(key: 'token');                   // auto-reports delete
/// ```
class DevConnectSecureStorage {
  final dynamic _inner;
  final bool maskValues;

  DevConnectSecureStorage._(this._inner, {this.maskValues = true});

  /// Wrap a FlutterSecureStorage instance for auto-reporting.
  static DevConnectSecureStorage wrap(dynamic storage, {bool maskValues = true}) {
    return DevConnectSecureStorage._(storage, maskValues: maskValues);
  }

  Future<void> write({required String key, required String? value}) async {
    await _inner.write(key: key, value: value);
    _report('write', key, maskValues ? '***' : value);
  }

  Future<String?> read({required String key}) async {
    final value = await _inner.read(key: key);
    _report('read', key, maskValues ? '***' : value);
    return value;
  }

  Future<void> delete({required String key}) async {
    await _inner.delete(key: key);
    _report('delete', key, null);
  }

  Future<void> deleteAll() async {
    await _inner.deleteAll();
    _report('clear', '*', null);
  }

  Future<Map<String, String>> readAll() async {
    final all = await _inner.readAll();
    _report('read', '*', maskValues ? '{...}' : all);
    return all;
  }

  Future<bool> containsKey({required String key}) => _inner.containsKey(key: key);

  void _report(String operation, String key, dynamic value) {
    DevConnectClient.safeReportStorageOperation(
      storageType: 'encrypted_storage',
      key: key,
      value: value,
      operation: operation,
    );
  }
}
