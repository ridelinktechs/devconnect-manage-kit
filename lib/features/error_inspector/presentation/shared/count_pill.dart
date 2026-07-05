import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// Neutral rounded pill that displays a single number in a mono font.
/// Used in the Error Inspector header next to a label like "Errors" or
/// "Fatal" to surface the live count without competing with severity
/// colors elsewhere on the page.
class CountPill extends StatelessWidget {
  final int count;

  const CountPill({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: AppConstants.monoFontFamily,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }
}