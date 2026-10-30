import '../../devconnect_client.dart';

/// Reporter for MMKV key-value storage that sends read/write/delete
/// events to DevConnect.
///
/// Usage:
/// ```dart
/// final mmkv = MMKV.defaultMMKV();
/// final reporter = DevConnect.mmkvReporter();
///
/// // After writing:
/// mmkv.encodeString('username', 'john');
/// reporter.reportWrite('username', value: 'john');
///
/// // After reading:
/// final username = mmkv.decodeString('username');
/// reporter.reportRead('username', value: username);
///
/// // After deleting:
/// mmkv.removeValue('username');
/// reporter.reportDelete('username');
/// ```
class DevConnectMmkvReporter {
  final String? mmkvId;

  const DevConnectMmkvReporter({this.mmkvId});

  String get _storageType => mmkvId != null ? 'mmkv:$mmkvId' : 'mmkv';

  /// Report a read from MMKV storage.
  ///
  /// [key] - The MMKV key that was read.
  /// [value] - The value that was read.
  /// [valueType] - The type of value (e.g., 'string', 'int', 'bool', 'bytes').
  void reportRead(String key, {dynamic value, String? valueType}) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: _storageType,
        key: key,
        value: valueType != null
            ? {'value': _toSerializable(value), 'type': valueType}
            : _toSerializable(value),
        operation: 'read',
      );
    } catch (_) {}
  }

  /// Report a write to MMKV storage.
  ///
  /// [key] - The MMKV key that was written.
  /// [value] - The value that was written.
  /// [valueType] - The type of value (e.g., 'string', 'int', 'bool', 'bytes').
  void reportWrite(String key, {dynamic value, String? valueType}) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: _storageType,
        key: key,
        value: valueType != null
            ? {'value': _toSerializable(value), 'type': valueType}
            : _toSerializable(value),
        operation: 'write',
      );
    } catch (_) {}
  }

  /// Report a delete from MMKV storage.
  ///
  /// [key] - The MMKV key that was deleted.
  void reportDelete(String key) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: _storageType,
        key: key,
        operation: 'delete',
      );
    } catch (_) {}
  }

  /// Report clearing all values from this MMKV instance.
  void reportClear() {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: _storageType,
        key: '*',
        operation: 'clear',
      );
    } catch (_) {}
  }

  /// Report a containsKey check.
  ///
  /// [key] - The key that was checked.
  /// [exists] - Whether the key exists.
  void reportContainsKey(String key, {required bool exists}) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: _storageType,
        key: key,
        value: {'exists': exists},
        operation: 'read',
      );
    } catch (_) {}
  }

  /// Report the total count of keys in this MMKV instance.
  void reportCount(int count) {
    try {
      DevConnectClient.safeReportStorageOperation(
        storageType: _storageType,
        key: '*',
        value: {'count': count},
        operation: 'read',
      );
    } catch (_) {}
  }

  static dynamic _toSerializable(dynamic value) {
    if (value == null) return null;
    if (value is num || value is bool || value is String) return value;
    if (value is List<int>) return '<bytes:${value.length}>';
    if (value is List) return value.map(_toSerializable).toList();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _toSerializable(v)));
    }
    return value.toString();
  }
}
