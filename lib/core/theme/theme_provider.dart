import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/app_preferences.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark);

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setDark() => state = ThemeMode.dark;
  void setLight() => state = ThemeMode.light;
}

/// Auto-scroll direction: true = scroll to bottom (newest at bottom),
/// false = scroll to top (newest at top)
enum ScrollDirection { bottom, top }

final scrollDirectionProvider = StateProvider<ScrollDirection>(
  (ref) => ScrollDirection.bottom,
);

/// Sidebar collapsed state
final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

// ═══════════════════════════════════════════════════════════════════
// Detail view preferences (persisted)
// ═══════════════════════════════════════════════════════════════════

/// Default body view mode for detail panels (Tree / JSON / Code).
enum BodyViewMode { tree, json, code }

class BodyViewModeNotifier extends StateNotifier<BodyViewMode> {
  BodyViewModeNotifier() : super(_load());

  static BodyViewMode _load() {
    final raw = AppPreferences().get<String>('bodyViewMode');
    switch (raw) {
      case 'json':
        return BodyViewMode.json;
      case 'code':
        return BodyViewMode.code;
      default:
        return BodyViewMode.tree;
    }
  }

  void set(BodyViewMode mode) {
    state = mode;
    AppPreferences().set('bodyViewMode', mode.name);
  }
}

final bodyViewModeProvider =
    StateNotifierProvider<BodyViewModeNotifier, BodyViewMode>(
  (ref) => BodyViewModeNotifier(),
);

/// Whether tab switching animation is enabled in detail panels.
class TabAnimationEnabledNotifier extends StateNotifier<bool> {
  TabAnimationEnabledNotifier()
      : super(AppPreferences().get<bool>('tabAnimationEnabled', true) ?? true);

  void set(bool v) {
    state = v;
    AppPreferences().set('tabAnimationEnabled', v);
  }
}

final tabAnimationEnabledProvider =
    StateNotifierProvider<TabAnimationEnabledNotifier, bool>(
  (ref) => TabAnimationEnabledNotifier(),
);

/// Tab switching animation duration (ms). Only used when enabled.
class TabAnimationDurationNotifier extends StateNotifier<int> {
  TabAnimationDurationNotifier()
      : super(
          (AppPreferences().get<int>('tabAnimationDurationMs', 300) ?? 300)
              .clamp(0, 2000),
        );

  void set(int ms) {
    final clamped = ms.clamp(0, 2000);
    state = clamped;
    AppPreferences().set('tabAnimationDurationMs', clamped);
  }
}

final tabAnimationDurationProvider =
    StateNotifierProvider<TabAnimationDurationNotifier, int>(
  (ref) => TabAnimationDurationNotifier(),
);

/// Resolved animation duration honoring the enabled flag.
/// Returns [Duration.zero] when disabled so TabController skips the tween.
final tabAnimationProvider = Provider<Duration>((ref) {
  final enabled = ref.watch(tabAnimationEnabledProvider);
  if (!enabled) return Duration.zero;
  final ms = ref.watch(tabAnimationDurationProvider);
  return Duration(milliseconds: ms);
});

// ═══════════════════════════════════════════════════════════════════
// Server start error (transient, not persisted)
// ═══════════════════════════════════════════════════════════════════

/// Holds the last server start failure message, or null when healthy.
/// Written by callers of [WsServer.start]; consumed by the settings UI.
final serverStartErrorProvider = StateProvider<String?>((ref) => null);
