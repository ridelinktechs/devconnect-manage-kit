import '../../devconnect_client.dart';

/// Auto-reporting wrapper for Hive Box.
///
/// ```dart
/// final box = DevConnectHiveBox.wrap(await Hive.openBox('settings'));
/// box.put('darkMode', true);  // auto-reports write
/// box.get('darkMode');         // auto-reports read
/// box.delete('darkMode');      // auto-reports delete
/// ```
class DevConnectHiveBox {
  final dynamic _inner;
  final String _label;

  DevConnectHiveBox._(this._inner, this._label);

  /// Wrap a Hive Box for auto-reporting.
  static DevConnectHiveBox wrap(dynamic box, [String? label]) {
    return DevConnectHiveBox._(box, label ?? box.name ?? 'hive');
  }

  dynamic get(dynamic key, {dynamic defaultValue}) {
    final value = _inner.get(key, defaultValue: defaultValue);
    _report('read', key.toString(), value);
    return value;
  }

  Future<void> put(dynamic key, dynamic value) async {
    await _inner.put(key, value);
    _report('write', key.toString(), value);
  }

  Future<void> putAll(Map<dynamic, dynamic> entries) async {
    await _inner.putAll(entries);
    for (final e in entries.entries) {
      _report('write', e.key.toString(), e.value);
    }
  }

  Future<void> delete(dynamic key) async {
    await _inner.delete(key);
    _report('delete', key.toString(), null);
  }

  Future<void> deleteAll(Iterable<dynamic> keys) async {
    await _inner.deleteAll(keys);
    for (final k in keys) {
      _report('delete', k.toString(), null);
    }
  }

  Future<int> clear() async {
    final count = await _inner.clear();
    _report('clear', '*', null);
    return count;
  }

  // ---- Passthrough ----

  bool containsKey(dynamic key) => _inner.containsKey(key);
  Iterable<dynamic> get keys => _inner.keys;
  Iterable<dynamic> get values => _inner.values;
  int get length => _inner.length;
  bool get isEmpty => _inner.isEmpty;
  bool get isNotEmpty => _inner.isNotEmpty;
  Future<void> close() => _inner.close();

  void _report(String operation, String key, dynamic value) {
    DevConnectClient.safeReportStorageOperation(
      storageType: 'hive',
      key: '$_label:$key',
      value: value,
      operation: operation,
    );
  }
}
