import 'dart:io';

import 'package:devconnect_manage_kit/devconnect_manage_kit.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bits of SharedPreferences the wrapper relies on.
class _FakePrefs {
  final Map<String, Object> values = {'token': 'abc', 'launches': 3};
  Set<String> getKeys() => values.keys.toSet();
  Object? get(String key) => values[key];
  Future<bool> setString(String k, String v) async => _put(k, v);
  Future<bool> setInt(String k, int v) async => _put(k, v);
  Future<bool> setDouble(String k, double v) async => _put(k, v);
  Future<bool> setBool(String k, bool v) async => _put(k, v);
  Future<bool> setStringList(String k, List<String> v) async => _put(k, v);
  Future<bool> remove(String k) async => values.remove(k) != null;
  Future<bool> clear() async {
    values.clear();
    return true;
  }

  bool _put(String k, Object v) {
    values[k] = v;
    return true;
  }
}

void main() {
  tearDown(() => DevConnectClient.setNetworkConditions());

  test('offline fails requests like a device without network', () async {
    DevConnectClient.setNetworkConditions(offline: true);
    await expectLater(
      DevConnectClient.applyNetworkConditions(Uri.parse('https://api.x.dev/a')),
      throwsA(isA<SocketException>()),
    );
  });

  test('latency holds requests back', () async {
    DevConnectClient.setNetworkConditions(latencyMs: 120);
    final watch = Stopwatch()..start();
    await DevConnectClient.applyNetworkConditions(Uri.parse('https://x.dev'));
    expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(100));
  });

  test('wrapped SharedPreferences can be listed and edited', () async {
    final prefs = _FakePrefs();
    DevConnectSharedPreferences.wrap(prefs);
    final adapter = DevConnectClient.storages['shared_preferences']!;

    expect(await adapter.getAll(), {'token': 'abc', 'launches': 3});
    await adapter.set('launches', 4);
    await adapter.set('ratio', 0.5);
    await adapter.set('flags', ['a', 1]);
    await adapter.set('profile', {'id': 7});
    await adapter.remove('token');
    expect(prefs.values, {
      'launches': 4,
      'ratio': 0.5,
      'flags': ['a', '1'],
      'profile': '{"id":7}',
    });
    await adapter.clear();
    expect(prefs.values, isEmpty);
  });
}
