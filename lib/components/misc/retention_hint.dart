import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/color_tokens.dart';

/// Count pill + optional "Showing N of M" hint used by per-feature
/// toolbars. Mirrors the pattern from the All Events header so the UX
/// stays consistent across pages.
///
/// - Pill always shows `count` and, when [limit] is set, the cap label
///   (e.g. `87 / 100`).
/// - When [total] > [count] (i.e. the source list was longer than the
///   cap and oldest entries were dropped), a small note `Showing N of M`
///   is rendered below the pill in muted grey so the user knows older
///   entries are hidden.
class RetentionHint extends StatelessWidget {
  /// Visible entry count after capping.
  final int count;

  /// Source list length BEFORE capping. When > [count], a "Showing N
  /// of M" note is rendered.
  final int total;

  /// User-configured retention cap. `null` = no cap; pill shows just
  /// `count` and the note is hidden (nothing is being trimmed).
  final int? limit;

  /// Human label for the cap (e.g. `100`, `1K`, `Unlimited`).
  final String limitLabel;

  const RetentionHint({
    super.key,
    required this.count,
    required this.total,
    required this.limit,
    required this.limitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTrimmed = limit != null && total > count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: ColorTokens.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            limit == null ? '$count' : '$count / $limitLabel',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ColorTokens.primary,
            ),
          ),
        ),
        if (isTrimmed) ...[
          const SizedBox(height: 2),
          Text(
            'Showing $count of $total',
            style: TextStyle(
              fontSize: 9,
              fontFamily: AppConstants.monoFontFamily,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }
}