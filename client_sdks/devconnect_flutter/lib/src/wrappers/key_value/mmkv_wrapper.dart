import '../../devconnect_client.dart';

/// Auto-reporting wrapper for MMKV (Flutter).
///
/// ```dart
/// final storage = DevConnectMMKVWrapper.wrap(MMKV.defaultMMKV());
/// storage.encodeString('token', 'abc'); // auto-reports write
/// storage.decodeString('token');         // auto-reports read
/// storage.removeValue('token');          // auto-reports delete
/// ```
class DevConnectMMKVWrapper {
  final dynamic _inner;
  final String _label;

  DevConnectMMKVWrapper._(this._inner, this._label);

  /// Wrap an MMKV instance for auto-reporting.
  static DevConnectMMKVWrapper wrap(dynamic mmkv, [String? label]) {
    return DevConnectMMKVWrapper._(mmkv, label ?? 'mmkv');
  }

  // ---- Write ----

  bool encodeString(String key, String value) {
    final result = _inner.encodeString(key, value);
    _report('write', key, value);
    return result;
  }

  bool encodeInt(String key, int value) {
    final result = _inner.encodeInt(key, value);
    _report('write', key, value);
    return result;
  }

  bool encodeBool(String key, bool value) {
    final result = _inner.encodeBool(key, value);
    _report('write', key, value);
    return result;
  }

  bool encodeDouble(String key, double value) {
    final result = _inner.encodeDouble(key, value);
    _report('write', key, value);
    return result;
  }

  // ---- Read ----

  String? decodeString(String key) {
    final value = _inner.decodeString(key);
    _report('read', key, value);
    return value;
  }

  int decodeInt(String key, {int defaultValue = 0}) {
    final value = _inner.decodeInt(key, defaultValue: defaultValue);
    _report('read', key, value);
    return value;
  }

  bool decodeBool(String key, {bool defaultValue = false}) {
    final value = _inner.decodeBool(key, defaultValue: defaultValue);
    _report('read', key, value);
    return value;
  }

  double decodeDouble(String key, {double defaultValue = 0.0}) {
    final value = _inner.decodeDouble(key, defaultValue: defaultValue);
    _report('read', key, value);
    return value;
  }

  // ---- Delete ----

  void removeValue(String key) {
    _inner.removeValue(key);
    _report('delete', key, null);
  }

  void clearAll() {
    _inner.clearAll();
    _report('clear', '*', null);
  }

  // ---- Passthrough ----

  bool containsKey(String key) => _inner.containsKey(key);

  void _report(String operation, String key, dynamic value) {
    DevConnectClient.safeReportStorageOperation(
      storageType: 'mmkv',
      key: '$_label:$key',
      value: value,
      operation: operation,
    );
  }
}
