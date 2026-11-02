import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/app_preferences.dart';

/// Keys matching sidebar route paths (without leading /)
enum TabKey {
  console,
  network,
  state,
  storage,
  database,
  performance,
  memoryLeaks,
  history,
  error,
  benchmark,
  display,
  asyncOps,
  layout,
  commands,
  mockServer,
}

class TabVisibilityNotifier extends Notifier<Set<TabKey>> {
  static const _key = 'tab_visibility';

  /// Hidden tabs, so tabs added in later versions start out visible.
  static const _hiddenKey = 'tab_hidden';

  /// The tabs [_key] (a list of shown tabs) could name when it was written.
  static const _legacyTabs = {
    TabKey.console,
    TabKey.network,
    TabKey.state,
    TabKey.storage,
    TabKey.database,
    TabKey.performance,
    TabKey.memoryLeaks,
    TabKey.history,
    TabKey.error,
  };

  @override
  Set<TabKey> build() => _load();

  static Set<TabKey> _load() {
    final all = TabKey.values.toSet();
    final hidden = _decode(AppPreferences().get<String>(_hiddenKey));
    if (hidden != null) return all.difference(hidden);
    final shown = _decode(AppPreferences().get<String>(_key));
    // Defensive: if nothing matched (corrupt data), fall back to
    // "all enabled" rather than "all hidden" — better UX.
    if (shown == null || shown.isEmpty) return all;
    return all.difference(_legacyTabs.difference(shown));
  }

  /// The tabs named in a saved JSON list, or null if there is none.
  static Set<TabKey>? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return {
        for (final tab in TabKey.values)
          if (decoded.contains(tab.name)) tab,
      };
    } catch (_) {
      return null;
    }
  }

  void _save() {
    final hidden = [
      for (final t in TabKey.values)
        if (!state.contains(t)) t.name,
    ];
    AppPreferences().set(_hiddenKey, jsonEncode(hidden));
  }

  void toggle(TabKey tab) {
    if (state.contains(tab)) {
      state = {...state}..remove(tab);
    } else {
      state = {...state, tab};
    }
    _save();
  }

  void enable(TabKey tab) {
    state = {...state, tab};
    _save();
  }

  void disable(TabKey tab) {
    state = {...state}..remove(tab);
    _save();
  }

  bool isEnabled(TabKey tab) => state.contains(tab);
}

final tabVisibilityProvider =
    NotifierProvider<TabVisibilityNotifier, Set<TabKey>>(
  TabVisibilityNotifier.new,
);

/// Route path -> TabKey mapping for paths that don't match enum name directly
const _routeToTabKey = <String, TabKey>{
  'memory-leaks': TabKey.memoryLeaks,
  'errors': TabKey.error,
  'async': TabKey.asyncOps,
  'mock-server': TabKey.mockServer,
};

/// Helper to check if a route path is enabled
bool isTabEnabled(Set<TabKey> enabledTabs, String routePath) {
  final key = routePath.replaceAll('/', '');

  // Check special mappings first (e.g. memory-leaks -> memoryLeaks)
  final mapped = _routeToTabKey[key];
  if (mapped != null) return enabledTabs.contains(mapped);

  for (final tab in TabKey.values) {
    if (tab.name == key) return enabledTabs.contains(tab);
  }
  // All, Settings — always enabled
  return true;
}