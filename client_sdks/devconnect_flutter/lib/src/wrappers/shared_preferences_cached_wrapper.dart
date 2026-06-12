import '../devconnect_client.dart';

/// Auto-reporting wrapper for [SharedPreferencesWithCache] (Flutter 2.3+).
///
/// Reads are synchronous (from in-memory cache), writes are async.
/// Recommended when you need fast synchronous reads.
///
/// ```dart
/// final prefs = await DevConnectSharedPreferencesCached.create(
///   cacheOptions: const SharedPreferencesWithCacheOptions(
///     allowList: {'token', 'theme', 'launch_count'},
///   ),
/// );
/// prefs.getString('token');              // sync read from cache
/// await prefs.setString('token', 'abc'); // async write to cache + disk
/// await prefs.remove('token');           // async delete
/// ```
class DevConnectSharedPreferencesCached {
  final dynamic _inner;

  DevConnectSharedPreferencesCached._(this._inner);

  /// Wrap an already-created [SharedPreferencesWithCache] instance.
  ///
  /// ```dart
  /// final sp = await SharedPreferencesWithCache.create(
  ///   cacheOptions: SharedPreferencesWithCacheOptions(),
  /// );
  /// final prefs = DevConnectSharedPreferencesCached.wrap(sp);
  /// ```
  static DevConnectSharedPreferencesCached wrap(dynamic prefs) {
    return DevConnectSharedPreferencesCached._(prefs);
  }

  // ---- Read (synchronous, from cache) ----

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

  Object? get(String key) {
    final value = _inner.get(key);
    _report('read', key, value);
    return value;
  }

  bool containsKey(String key) {
    return _inner.containsKey(key) as bool;
  }

  Set<String> get keys => _inner.keys as Set<String>;

  // ---- Write (async, to cache + platform) ----

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

  // ---- Delete ----

  Future<void> remove(String key) async {
    await _inner.remove(key);
    _report('delete', key, null);
  }

  Future<void> clear() async {
    await _inner.clear();
    _report('clear', '*', null);
  }

  // ---- Cache management ----

  /// Refresh the in-memory cache with latest platform values.
  Future<void> reloadCache() async {
    await _inner.reloadCache();
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
