import 'dart:convert';

import '../devconnect_client.dart';
import '../storage_adapter.dart';

/// Auto-reporting wrapper for SharedPreferences.
///
/// ```dart
/// final prefs = DevConnectSharedPreferences.wrap(
///   await SharedPreferences.getInstance(),
/// );
/// prefs.setString('token', 'abc'); // auto-reports write
/// prefs.getString('token');         // auto-reports read
/// prefs.remove('token');            // auto-reports delete
/// ```
class DevConnectSharedPreferences {
  final dynamic _inner;

  DevConnectSharedPreferences._(this._inner);

  /// Wrap a SharedPreferences instance for auto-reporting.
  static DevConnectSharedPreferences wrap(dynamic prefs) {
    final wrapped = DevConnectSharedPreferences._(prefs);
    // Lets the desktop's Storage tab list and edit it; edits go through the
    // wrapper so they're reported like the app's own.
    DevConnectClient.registerStorage(
      'shared_preferences',
      DevConnectStorageAdapter(
        getAll: () => {
          for (final key in prefs.getKeys() as Set<String>) key: prefs.get(key),
        },
        set: (key, value) => switch (value) {
          final String v => wrapped.setString(key, v),
          final int v => wrapped.setInt(key, v),
          final double v => wrapped.setDouble(key, v),
          final bool v => wrapped.setBool(key, v),
          final List<dynamic> v =>
            wrapped.setStringList(key, [for (final e in v) '$e']),
          _ => wrapped.setString(key, jsonEncode(value)),
        },
        remove: wrapped.remove,
        clear: wrapped.clear,
      ),
    );
    return wrapped;
  }

  // ---- Write ----

  Future<bool> setString(String key, String value) async {
    final result = await _inner.setString(key, value);
    _report('write', key, value);
    return result;
  }

  Future<bool> setInt(String key, int value) async {
    final result = await _inner.setInt(key, value);
    _report('write', key, value);
    return result;
  }

  Future<bool> setDouble(String key, double value) async {
    final result = await _inner.setDouble(key, value);
    _report('write', key, value);
    return result;
  }

  Future<bool> setBool(String key, bool value) async {
    final result = await _inner.setBool(key, value);
    _report('write', key, value);
    return result;
  }

  Future<bool> setStringList(String key, List<String> value) async {
    final result = await _inner.setStringList(key, value);
    _report('write', key, value);
    return result;
  }

  // ---- Read ----

  String? getString(String key) {
    final value = _inner.getString(key);
    _report('read', key, value);
    return value;
  }

  int? getInt(String key) {
    final value = _inner.getInt(key);
    _report('read', key, value);
    return value;
  }

  double? getDouble(String key) {
    final value = _inner.getDouble(key);
    _report('read', key, value);
    return value;
  }

  bool? getBool(String key) {
    final value = _inner.getBool(key);
    _report('read', key, value);
    return value;
  }

  List<String>? getStringList(String key) {
    final value = _inner.getStringList(key);
    _report('read', key, value);
    return value;
  }

  dynamic get(String key) {
    final value = _inner.get(key);
    _report('read', key, value);
    return value;
  }

  // ---- Delete ----

  Future<bool> remove(String key) async {
    final result = await _inner.remove(key);
    _report('delete', key, null);
    return result;
  }

  Future<bool> clear() async {
    final result = await _inner.clear();
    _report('clear', '*', null);
    return result;
  }

  // ---- Passthrough ----

  Set<String> getKeys() => _inner.getKeys();
  bool containsKey(String key) => _inner.containsKey(key);

  void _report(String operation, String key, dynamic value) {
    DevConnectClient.safeReportStorageOperation(
      storageType: 'shared_preferences',
      key: key,
      value: value,
      operation: operation,
    );
  }
}
