import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';

/// 130px-tall left-label + chart row used by FPS / CPU / MEM / Build /
/// GPU / Threads. Left column (72px) renders icon + uppercase title
/// + tinted current-value + optional [badge] pinned at the bottom.
/// Right column hosts the supplied [chart] widget.
class ProfilerChartRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isDark;
  final String currentValue;
  final String unit;
  final Color statusColor;
  final Widget chart;
  final Widget? badge;

  const ProfilerChartRow({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.currentValue,
    required this.unit,
    required this.chart,
    required this.statusColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      color: isDark ? ColorTokens.darkSurface : Colors.white,
      child: Row(
        children: [
          // Left label panel
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black45,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$currentValue $unit',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      height: 1,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const Spacer(),
                  badge!,
                ],
              ],
            ),
          ),
          // Chart area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: chart,
            ),
          ),
        ],
      ),
    );
  }
}