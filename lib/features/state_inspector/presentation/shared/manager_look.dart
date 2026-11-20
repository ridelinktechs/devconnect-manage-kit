import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../provider/state_providers.dart';

/// How a state library shows in the State Inspector: its name, glyph and
/// color, from the `stateManager` an SDK reports — `redux`, or a family and
/// a store such as `zustand:cart` and `ReactQuery::todos`.
class ManagerLook {
  /// The family as a filter key: lower case, no spaces or separators.
  final String key;
  final String label;

  /// The store, machine or query after the family, if any.
  final String? store;
  final IconData icon;
  final Color color;

  const ManagerLook({
    required this.key,
    required this.label,
    required this.store,
    required this.icon,
    required this.color,
  });

  factory ManagerLook.of(String type) {
    final cut = type.indexOf(':');
    final family = (cut < 0 ? type : type.substring(0, cut)).trim();
    final rest = cut < 0
        ? ''
        : type.substring(cut).replaceFirst(RegExp(r'^:+'), '').trim();
    final key = stateManagerKey(type);
    final (label, icon, color) = switch (key) {
      'redux' => ('Redux', LucideIcons.workflow, const Color(0xFF764ABC)),
      'mobx' => ('MobX', LucideIcons.eye, const Color(0xFFEA6618)),
      'zustand' => ('Zustand', LucideIcons.box, const Color(0xFF9A6A3E)),
      'jotai' => ('Jotai', LucideIcons.atom, const Color(0xFF0D9488)),
      'valtio' => ('Valtio', LucideIcons.scanEye, const Color(0xFFDB2777)),
      'xstate' => ('XState', LucideIcons.gitBranch, const Color(0xFF2563EB)),
      'apollo' => ('Apollo', LucideIcons.rocket, const Color(0xFF6E56CF)),
      'reactquery' || 'tanstack' || 'tanstackquery' => (
        'React Query',
        LucideIcons.refreshCw,
        const Color(0xFFE5484D),
      ),
      'signals' => ('Signals', LucideIcons.radio, const Color(0xFF10B981)),
      'riverpod' => ('Riverpod', LucideIcons.waves, const Color(0xFF0284C7)),
      'bloc' ||
      'cubit' => ('BLoC', LucideIcons.blocks, const Color(0xFF3B82F6)),
      'provider' => ('Provider', LucideIcons.package, const Color(0xFF0F766E)),
      'getx' => ('GetX', LucideIcons.zap, const Color(0xFF8B5CF6)),
      'stateflow' || 'viewmodel' || 'livedata' || 'compose' => (
        family.isEmpty ? 'ViewModel' : _title(family),
        LucideIcons.activity,
        const Color(0xFF0F9D58),
      ),
      _ => (
        family.isEmpty ? 'Unknown' : _title(family),
        LucideIcons.layers,
        const Color(0xFF8B949E),
      ),
    };
    return ManagerLook(
      key: key,
      label: label,
      store: rest.isEmpty ? null : rest,
      icon: icon,
      color: color,
    );
  }

  /// [color] for text, 4.5:1 on the app's surfaces in both themes.
  Color ink(bool isDark) => isDark
      ? Color.lerp(color, Colors.white, 0.35)!
      : Color.lerp(color, Colors.black, 0.35)!;

  static String _title(String s) => s[0].toUpperCase() + s.substring(1);
}
