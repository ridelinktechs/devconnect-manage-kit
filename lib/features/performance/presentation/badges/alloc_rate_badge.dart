import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';

/// "±X.X/s" memory allocation rate badge shown next to the memory
/// chart's current-value column. Amber when |rate|>1, green otherwise.
class AllocRateBadge extends StatelessWidget {
  final double rate;
  final bool isDark;

  const AllocRateBadge({
    super.key,
    required this.rate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = rate >= 0;
    final color = rate.abs() > 1
        ? ColorTokens.chartAmber
        : ColorTokens.chartGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${isPositive ? '+' : ''}${rate.toStringAsFixed(1)}/s',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}