import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/preferences/app_preferences.dart';
import 'package:devconnect_manage_tool/core/providers/tab_visibility_provider.dart';

void main() {
  Future<void> clear() async {
    await AppPreferences().set('tab_visibility', null);
    await AppPreferences().set('tab_hidden', null);
  }

  setUp(clear);
  tearDown(clear);

  test('a list saved before new tabs existed keeps the new tabs visible', () {
    AppPreferences().set('tab_visibility', jsonEncode(['console', 'network']));
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final shown = container.read(tabVisibilityProvider);
    expect(shown, containsAll([TabKey.console, TabKey.network]));
    expect(shown, containsAll([TabKey.benchmark, TabKey.mockServer]));
    expect(shown.contains(TabKey.state), isFalse);
    expect(shown.contains(TabKey.error), isFalse);
  });

  test('toggles are saved as the hidden tabs and read back', () {
    final first = ProviderContainer();
    first.read(tabVisibilityProvider.notifier).toggle(TabKey.layout);
    first.dispose();

    expect(jsonDecode(AppPreferences().get<String>('tab_hidden')!), ['layout']);
    final second = ProviderContainer();
    addTearDown(second.dispose);
    expect(second.read(tabVisibilityProvider).contains(TabKey.layout), false);
    expect(second.read(tabVisibilityProvider).length, TabKey.values.length - 1);
  });

  test('routes map onto their tab keys', () {
    final shown = TabKey.values.toSet()
      ..removeAll([TabKey.error, TabKey.asyncOps, TabKey.mockServer]);
    expect(isTabEnabled(shown, '/errors'), isFalse);
    expect(isTabEnabled(shown, '/async'), isFalse);
    expect(isTabEnabled(shown, '/mock-server'), isFalse);
    expect(isTabEnabled(shown, '/layout'), isTrue);
    expect(isTabEnabled(shown, '/all'), isTrue);
  });
}
