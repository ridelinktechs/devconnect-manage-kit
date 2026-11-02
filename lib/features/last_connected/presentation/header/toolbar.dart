import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../settings/presentation/tips/page_guide_button.dart';

class Toolbar extends StatelessWidget {
  final int sessionCount;
  final VoidCallback onClearAll;

  const Toolbar({
    super.key,
    required this.sessionCount,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.history, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text(
            'Last Connected',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const PageGuideButton(route: '/history'),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ColorTokens.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$sessionCount',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ColorTokens.primary,
              ),
            ),
          ),
          const Spacer(),
          if (sessionCount > 0)
            GestureDetector(
              onTap: onClearAll,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: ColorTokens.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ColorTokens.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.trash2,
                        size: 12,
                        color: ColorTokens.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ColorTokens.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
