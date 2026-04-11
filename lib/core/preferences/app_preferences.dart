import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Simple file-backed preferences store.
///
/// Loads lazily via [init]; reads are synchronous after init, writes persist
/// asynchronously. Safe to call before [init] — reads return defaults, writes
/// are buffered in memory.
class AppPreferences {
  AppPreferences._internal();
  static final AppPreferences _instance = AppPreferences._internal();
  factory AppPreferences() => _instance;

  File? _file;
  Map<String, dynamic> _data = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationSupportDirectory();
      _file = File('${dir.path}/preferences.json');
      if (await _file!.exists()) {
        final text = await _file!.readAsString();
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) {
          _data = decoded;
        }
      }
    } catch (_) {
      _data = {};
    } finally {
      _initialized = true;
    }
  }

  T? get<T>(String key, [T? defaultValue]) {
    final v = _data[key];
    if (v is T) return v;
    return defaultValue;
  }

  Future<void> set(String key, dynamic value) async {
    _data[key] = value;
    await _save();
  }

  Future<void> _save() async {
    final file = _file;
    if (file == null) return;
    try {
      await file.writeAsString(jsonEncode(_data));
    } catch (_) {}
  }
}
