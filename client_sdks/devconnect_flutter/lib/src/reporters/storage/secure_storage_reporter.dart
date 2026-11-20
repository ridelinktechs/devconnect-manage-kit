import '../../devconnect_client.dart';

/// Reporter for flutter_secure_storage that sends read/write/delete
/// events to DevConnect.
///
/// Usage:
/// ```dart
/// final secureStorage = FlutterSecureStorage();
/// final reporter = DevConnect.secureStorageReporter();
///
/// // After writing:
/// await secureStorage.write(key: 'token', value: 'abc123');
/// reporter.reportWrite('token', value: '***masked***');
///
/// // After reading:
/// final token = await secureStorage.read(key: 'token');
/// reporter.reportRead('token', value: token != null ? '***present***' : null);
///
/// // After deleting:
/// await secureStorage.delete(key: 'token');
/// reporter.reportDelete('token');
/// ```
///
/// By default, values are masked for security. Set [maskValues] to false
/// to report actual values (NOT recommended for production).
class DevConnectSecureStorageReporter {
  final bool maskValues;

  const DevConnectSecureStorageReporter({this.maskValues = true});

  /// Report a read from secure storage.
  ///
  /// [key] - The storage key that was read.
  /// [value] - The value that was read (will be masked if [maskValues] is true).
  void reportRead(String key, {dynamic value}) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: 'secure_storage',
        key: key,
        value: _processValue(value),
        operation: 'read',
      );
    } catch (_) {}
  }

  /// Report a write to secure storage.
  ///
  /// [key] - The storage key that was written.
  /// [value] - The value that was written (will be masked if [maskValues] is true).
  void reportWrite(String key, {dynamic value}) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: 'secure_storage',
        key: key,
        value: _processValue(value),
        operation: 'write',
      );
    } catch (_) {}
  }

  /// Report a delete from secure storage.
  ///
  /// [key] - The storage key that was deleted.
  void reportDelete(String key) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: 'secure_storage',
        key: key,
        operation: 'delete',
      );
    } catch (_) {}
  }

  /// Report a deleteAll / clear operation on secure storage.
  void reportDeleteAll() {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: 'secure_storage',
        key: '*',
        operation: 'clear',
      );
    } catch (_) {}
  }

  /// Report a containsKey check on secure storage.
  ///
  /// [key] - The storage key that was checked.
  /// [exists] - Whether the key exists.
  void reportContainsKey(String key, {required bool exists}) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: 'secure_storage',
        key: key,
        value: {'exists': exists},
        operation: 'read',
      );
    } catch (_) {}
  }

  /// Report a readAll operation on secure storage.
  ///
  /// [count] - Number of entries returned.
  void reportReadAll({int? count}) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: 'secure_storage',
        key: '*',
        value: {
          if (count != null) 'count': count,
          if (maskValues) 'masked': true,
        },
        operation: 'read',
      );
    } catch (_) {}
  }

  dynamic _processValue(dynamic value) {
    if (value == null) return null;
    if (!maskValues) return value;
    if (value is String) {
      if (value.isEmpty) return '<empty>';
      return '<${value.length} chars>';
    }
    return '<masked>';
  }
}
