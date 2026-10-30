import 'dart:convert';

import 'package:flutter/painting.dart';

/// The Layout tab's colors.
abstract final class LayoutColors {
  // Box model tints, as browser devtools draw them.
  static const content = Color(0xFF6FA8DC);
  static const padding = Color(0xFF93C47D);
  static const margin = Color(0xFFF6B26B);

  static const measure = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);

  /// The selection accent: the hue of the app's selected rows, solid.
  static Color accent(bool isDark) =>
      isDark ? const Color(0xFF14B8A6) : const Color(0xFF0EA5E9);
}

const prettyJson = JsonEncoder.withIndent('  ');

/// A length in dp: whole, or to one decimal.
String formatDp(double v) =>
    v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);

String formatSize(Rect r) => '${formatDp(r.width)} × ${formatDp(r.height)}';
