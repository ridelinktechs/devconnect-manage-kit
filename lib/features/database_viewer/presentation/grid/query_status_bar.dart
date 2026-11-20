import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/format/duration_format.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// The bar under the grid, like a database client's: how many rows came
/// back (and that the app left some out), how long the query took, and the
/// database it ran on.
class QueryStatusBar extends StatelessWidget {
  final int rows;
  final bool truncated;
  final int ms;
  final String database;

  const QueryStatusBar({
    super.key,
    required this.rows,
    required this.truncated,
    required this.ms,
    required this.database,
  });

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final loc = S.of(context);
    final muted = TextStyle(
      fontSize: 11.5,
      color: p.textMuted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final rule = Container(
      width: 1,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: p.border,
    );
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: p.isDark ? ColorTokens.darkBackground : Colors.white,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          Text(loc.dbRows(rows), style: muted),
          if (truncated) ...[
            const SizedBox(width: 8),
            Text(
              loc.dbTruncated(rows),
              style: muted.copyWith(
                color: p.isDark ? ColorTokens.warning : const Color(0xFF9A6700),
              ),
            ),
          ],
          rule,
          Text(
            formatDuration(ms),
            style: chromeMono(context, size: 11, color: p.textMuted),
          ),
          const Spacer(),
          if (database.isNotEmpty)
            Text(
              database,
              style: chromeMono(context, size: 11, color: p.textMuted),
            ),
        ],
      ),
    );
  }
}
