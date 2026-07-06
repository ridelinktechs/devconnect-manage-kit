import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// Small mono-font tag chip — rendered inline on log entries and
/// at the top of the detail panel's "Tag" section.
class TagBadge extends StatelessWidget {
  final String tag;

  const TagBadge({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontFamily: AppConstants.monoFontFamily,
          fontSize: 10,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }
}