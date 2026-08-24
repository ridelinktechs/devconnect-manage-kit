import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/app_preferences.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'themeMode';

  @override
  ThemeMode build() => _load();

  static ThemeMode _load() {
    final raw = AppPreferences().get<String>(_key);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  void _set(ThemeMode mode) {
    state = mode;
    AppPreferences().set(_key, mode.name);
  }

  void toggle() {
    _set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  void setDark() => _set(ThemeMode.dark);
  void setLight() => _set(ThemeMode.light);
  void setSystem() => _set(ThemeMode.system);
}

/// Auto-scroll direction: true = scroll to bottom (newest at bottom),
/// false = scroll to top (newest at top)
enum ScrollDirection { bottom, top }

class _ScrollDirectionNotifier extends Notifier<ScrollDirection> {
  @override
  ScrollDirection build() => ScrollDirection.bottom;

  void set(ScrollDirection v) => state = v;
}

final scrollDirectionProvider =
    NotifierProvider<_ScrollDirectionNotifier, ScrollDirection>(
  _ScrollDirectionNotifier.new,
);

/// Sidebar collapsed state
class _SidebarCollapsedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
  void toggle() => state = !state;
}

final sidebarCollapsedProvider =
    NotifierProvider<_SidebarCollapsedNotifier, bool>(
  _SidebarCollapsedNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════
// Detail view preferences (persisted)
// ═══════════════════════════════════════════════════════════════════

/// Default body view mode for detail panels (Tree / JSON / Code).
enum BodyViewMode { tree, json, code }

class BodyViewModeNotifier extends Notifier<BodyViewMode> {
  @override
  BodyViewMode build() => _load();

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
    NotifierProvider<BodyViewModeNotifier, BodyViewMode>(
  BodyViewModeNotifier.new,
);

/// View mode for the metadata block in detail panels. Independent from
/// [bodyViewModeProvider] so switching the metadata render style doesn't
/// flip the message block above it (and vice versa).
class _MetadataViewModeNotifier extends Notifier<BodyViewMode> {
  @override
  BodyViewMode build() => BodyViewMode.tree;

  void set(BodyViewMode v) => state = v;
}

final metadataViewModeProvider =
    NotifierProvider<_MetadataViewModeNotifier, BodyViewMode>(
  _MetadataViewModeNotifier.new,
);

/// Whether tab switching animation is enabled in detail panels.
class TabAnimationEnabledNotifier extends Notifier<bool> {
  @override
  bool build() =>
      AppPreferences().get<bool>('tabAnimationEnabled', true) ?? true;

  void set(bool v) {
    state = v;
    AppPreferences().set('tabAnimationEnabled', v);
  }
}

final tabAnimationEnabledProvider =
    NotifierProvider<TabAnimationEnabledNotifier, bool>(
  TabAnimationEnabledNotifier.new,
);

/// Tab switching animation duration (ms). Only used when enabled.
class TabAnimationDurationNotifier extends Notifier<int> {
  @override
  int build() =>
      (AppPreferences().get<int>('tabAnimationDurationMs', 300) ?? 300)
          .clamp(0, 2000);

  void set(int ms) {
    final clamped = ms.clamp(0, 2000);
    state = clamped;
    AppPreferences().set('tabAnimationDurationMs', clamped);
  }
}

final tabAnimationDurationProvider =
    NotifierProvider<TabAnimationDurationNotifier, int>(
  TabAnimationDurationNotifier.new,
);

/// Resolved animation duration honoring the enabled flag.
/// Returns [Duration.zero] when disabled so TabController skips the tween.
final tabAnimationProvider = Provider<Duration>((ref) {
  final enabled = ref.watch(tabAnimationEnabledProvider);
  if (!enabled) return Duration.zero;
  final ms = ref.watch(tabAnimationDurationProvider);
  return Duration(milliseconds: ms);
});


/// Whether smooth scrolling (inertia/momentum) is enabled for scrollable widgets.
class SmoothScrollEnabledNotifier extends Notifier<bool> {
  @override
  bool build() =>
      AppPreferences().get<bool>('smoothScrollEnabled', false) ?? false;

  void set(bool v) {
    state = v;
    AppPreferences().set('smoothScrollEnabled', v);
  }
}

final smoothScrollEnabledProvider =
    NotifierProvider<SmoothScrollEnabledNotifier, bool>(
  SmoothScrollEnabledNotifier.new,
);

/// How long the smooth scroll animation runs (in milliseconds).
class SmoothScrollDurationNotifier extends Notifier<int> {
  @override
  int build() =>
      AppPreferences().get<int>('smoothScrollDuration', 250) ?? 250;

  void set(int v) {
    state = v;
    AppPreferences().set('smoothScrollDuration', v);
  }
}

final smoothScrollDurationProvider =
    NotifierProvider<SmoothScrollDurationNotifier, int>(
  SmoothScrollDurationNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════
// Server start error (transient, not persisted)
// ═══════════════════════════════════════════════════════════════════

/// Holds the last server start failure message, or null when healthy.
/// Written by callers of [WsServer.start]; consumed by the settings UI.
class _ServerStartErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? v) => state = v;
}

final serverStartErrorProvider =
    NotifierProvider<_ServerStartErrorNotifier, String?>(
  _ServerStartErrorNotifier.new,
);