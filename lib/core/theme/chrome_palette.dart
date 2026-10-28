import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Colors for the app chrome: the title-bar pills, their popovers and the
/// device bar. Primer-derived to sit with the app's GitHub-style surfaces.
/// Text pairs are ≥ 4.5:1 in both themes; amber is the only accent and
/// only ever means "update available".
class ChromePalette {
  final bool isDark;
  final Color pill;
  final Color pillActive;
  final Color surface;
  final Color border;
  final Color hover;
  final Color selected;
  final Color codeBg;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color accentBg;
  final Color success;
  final Color shadow;

  const ChromePalette._({
    required this.isDark,
    required this.pill,
    required this.pillActive,
    required this.surface,
    required this.border,
    required this.hover,
    required this.selected,
    required this.codeBg,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.accentBg,
    required this.success,
    required this.shadow,
  });

  static const _dark = ChromePalette._(
    isDark: true,
    pill: Color(0xD91F242B),
    pillActive: Color(0xFF262C36),
    surface: Color(0xFF1C2128),
    border: Color(0xFF30363D),
    hover: Color(0x0FFFFFFF),
    selected: Color(0xFF21262D),
    codeBg: Color(0xFF0D1117),
    text: Color(0xFFE6EDF3),
    textMuted: Color(0xFF9198A1),
    accent: Color(0xFFFBBF24),
    accentBg: Color(0x29FBBF24),
    success: Color(0xFF3FB950),
    shadow: Color(0x99000000),
  );

  static const _light = ChromePalette._(
    isDark: false,
    pill: Color(0xEBFFFFFF),
    pillActive: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFD1D9E0),
    hover: Color(0x0A1F2328),
    selected: Color(0xFFF6F8FA),
    codeBg: Color(0xFFF6F8FA),
    text: Color(0xFF1F2328),
    textMuted: Color(0xFF59636E),
    accent: Color(0xFF9A6700),
    accentBg: Color(0xFFFFF8C5),
    success: Color(0xFF1A7F37),
    shadow: Color(0x261F2328),
  );

  static ChromePalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}

/// Glyph and brand color of a handshake `platform`. Brand colors are
/// darkened in light mode to keep 3:1 against their tinted tile.
(IconData, Color) platformLook(String platform, {required bool isDark}) =>
    switch (platform.toLowerCase()) {
      'flutter' => (
        LucideIcons.smartphone,
        isDark ? const Color(0xFF54C5F8) : const Color(0xFF02569B),
      ),
      'react_native' || 'reactnative' => (
        LucideIcons.atom,
        isDark ? const Color(0xFF61DAFB) : const Color(0xFF087EA4),
      ),
      'android' => (
        LucideIcons.tablet,
        isDark ? const Color(0xFF3DDC84) : const Color(0xFF0F9D58),
      ),
      _ => (LucideIcons.monitor, const Color(0xFF8B949E)),
    };

/// The app's mono face (JetBrains Mono via the theme's label styles), with
/// system monospace fallbacks while it loads or when offline.
TextStyle chromeMono(
  BuildContext context, {
  required double size,
  required Color color,
  FontWeight weight = FontWeight.w500,
}) => (Theme.of(context).textTheme.labelMedium ?? const TextStyle()).copyWith(
  fontSize: size,
  color: color,
  fontWeight: weight,
  height: 1.4,
  fontFamilyFallback: const ['Menlo', 'Consolas', 'monospace'],
);
