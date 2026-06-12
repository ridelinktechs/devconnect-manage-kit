import '../devconnect_client.dart';

/// Auto-reporting wrapper for [SharedPreferencesAsync] (Flutter 2.3+).
///
/// All reads are async (no cache). Use this when you don't need
/// synchronous access or when external processes may modify preferences.
///
/// ```dart
/// final prefs = DevConnectSharedPreferencesAsync.wrap(
///   SharedPreferencesAsync(),
/// );
/// await prefs.setString('token', 'abc'); // auto-reports write
/// await prefs.getString('token');         // auto-reports read
/// await prefs.remove('token');            // auto-reports delete
/// ```
class DevConnectSharedPreferencesAsync {
  final dynamic _inner;

  DevConnectSharedPreferencesAsync._(this._inner);

  /// Wrap a [SharedPreferencesAsync] instance for auto-reporting.
  static DevConnectSharedPreferencesAsync wrap(dynamic prefs) {
    return DevConnectSharedPreferencesAsync._(prefs);
  }

  // ---- Write ----

  Future<void> setString(String key, String value) async {
    await _inner.setString(key, value);
    _report('write', key, value);
  }

  Future<void> setInt(String key, int value) async {
    await _inner.setInt(key, value);
    _report('write', key, value);
  }

  Future<void> setDouble(String key, double value) async {
    await _inner.setDouble(key, value);
    _report('write', key, value);
  }

  Future<void> setBool(String key, bool value) async {
    await _inner.setBool(key, value);
    _report('write', key, value);
  }

  Future<void> setStringList(String key, List<String> value) async {
    await _inner.setStringList(key, value);
    _report('write', key, value);
  }

  // ---- Read ----

  Future<String?> getString(String key) async {
    final value = await _inner.getString(key);
    _report('read', key, value);
    return value;
  }

  Future<int?> getInt(String key) async {
    final value = await _inner.getInt(key);
    _report('read', key, value);
    return value;
  }

  Future<double?> getDouble(String key) async {
    final value = await _inner.getDouble(key);
    _report('read', key, value);
    return value;
  }

  Future<bool?> getBool(String key) async {
    final value = await _inner.getBool(key);
    _report('read', key, value);
    return value;
  }

  Future<List<String>?> getStringList(String key) async {
    final value = await _inner.getStringList(key);
    _report('read', key, value);
    return value;
  }

  Future<Map<String, Object?>> getAll({Set<String>? allowList}) async {
    final value = allowList != null
        ? await _inner.getAll(allowList: allowList)
        : await _inner.getAll();
    for (final entry in value.entries) {
      _report('read', entry.key, entry.value);
    }
    return value;
  }

  Future<Set<String>> getKeys({Set<String>? allowList}) async {
    return allowList != null
        ? await _inner.getKeys(allowList: allowList)
        : await _inner.getKeys();
  }

  Future<bool> containsKey(String key) async {
    return await _inner.containsKey(key);
  }

  // ---- Delete ----

  Future<void> remove(String key) async {
    await _inner.remove(key);
    _report('delete', key, null);
  }

  Future<void> clear({Set<String>? allowList}) async {
    if (allowList != null) {
      await _inner.clear(allowList: allowList);
    } else {
      await _inner.clear();
    }
    _report('clear', '*', null);
  }

  // ---- Reporting ----

  void _report(String operation, String key, dynamic value) {
    DevConnectClient.safeReportStorageOperation(
      storageType: 'shared_preferences',
      key: key,
      value: value,
      operation: operation,
    );
  }
}
