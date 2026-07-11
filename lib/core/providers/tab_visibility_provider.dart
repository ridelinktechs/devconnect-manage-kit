import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/app_preferences.dart';

/// Keys matching sidebar route paths (without leading /)
enum TabKey { console, network, state, storage, database, performance, memoryLeaks, history, error }

class TabVisibilityNotifier extends StateNotifier<Set<TabKey>> {
  TabVisibilityNotifier() : super(_load());

  static const _key = 'tab_visibility';

  static Set<TabKey> _load() {
    final raw = AppPreferences().get<String>(_key);
    if (raw == null || raw.isEmpty) return TabKey.values.toSet();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return TabKey.values.toSet();
      final result = <TabKey>{};
      for (final entry in decoded) {
        if (entry is String) {
          for (final tab in TabKey.values) {
            if (tab.name == entry) {
              result.add(tab);
              break;
            }
          }
        }
      }
      // Defensive: if nothing matched (corrupt data), fall back to
      // "all enabled" rather than "all hidden" — better UX.
      return result.isEmpty ? TabKey.values.toSet() : result;
    } catch (_) {
      return TabKey.values.toSet();
    }
  }

  void _save() {
    final list = state.map((t) => t.name).toList(growable: false);
    AppPreferences().set(_key, jsonEncode(list));
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
    StateNotifierProvider<TabVisibilityNotifier, Set<TabKey>>(
  (ref) => TabVisibilityNotifier(),
);

/// Route path -> TabKey mapping for paths that don't match enum name directly
const _routeToTabKey = <String, TabKey>{
  'memory-leaks': TabKey.memoryLeaks,
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