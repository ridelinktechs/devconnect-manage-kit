import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../models/log/log_entry.dart';

/// Accent color for each log level. Centralized here so the toolbar
/// filter chip + the entry row's left border + the detail panel's
/// stack trace tint all stay in sync.
Color levelColor(LogLevel level) {
  switch (level) {
    case LogLevel.debug:
      return ColorTokens.logDebug;
    case LogLevel.info:
      return ColorTokens.logInfo;
    case LogLevel.warn:
      return ColorTokens.logWarn;
    case LogLevel.error:
      return ColorTokens.logError;
  }
}

/// [level]'s color for text, at least 4.5:1 on the Console's surfaces: the
/// accent itself in dark mode, Primer's deeper shade in light mode.
Color levelInk(LogLevel level, {required bool isDark}) => switch (level) {
  LogLevel.debug => isDark ? const Color(0xFF9198A1) : const Color(0xFF59636E),
  LogLevel.info => isDark ? ColorTokens.logInfo : const Color(0xFF0969DA),
  LogLevel.warn => isDark ? ColorTokens.logWarn : const Color(0xFF9A6700),
  LogLevel.error => isDark ? ColorTokens.logError : const Color(0xFFCF222E),
};

/// The glyph that names [level] next to its color.
IconData levelIcon(LogLevel level) => switch (level) {
  LogLevel.debug => LucideIcons.bug,
  LogLevel.info => LucideIcons.info,
  LogLevel.warn => LucideIcons.triangleAlert,
  LogLevel.error => LucideIcons.circleX,
};
