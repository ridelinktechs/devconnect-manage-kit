import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// Neutral pill with a thin border — used for storage types ("ASYNC",
/// "SECURE") where the operation badge ([OpBadge]) already carries the
/// dominant color cue.
class TypeBadge extends StatelessWidget {
  final String label;
  const TypeBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF4A4A4A);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppConstants.monoFontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
