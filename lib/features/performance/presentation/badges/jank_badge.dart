import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../models/performance/performance_entry.dart';

/// Red count badge with a rich tooltip summarizing the recent jank
/// frames — average/max duration + a per-frame breakdown with optional
/// `B:` (build) / `R:` (raster) split if the SDK reported them.
class JankBadge extends StatelessWidget {
  final int count;
  final bool isDark;
  final List<PerformanceEntry> entries;

  const JankBadge({
    super.key,
    required this.count,
    required this.isDark,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final avgMs = entries.isEmpty
        ? 0.0
        : entries.fold<double>(0, (s, e) => s + e.value) / entries.length;
    final maxMs = entries.isEmpty
        ? 0.0
        : entries.fold<double>(0, (s, e) => math.max(s, e.value));
    final recent = entries.length > 5 ? entries.sublist(entries.length - 5) : entries;

    final lines = <String>[
      'Slow Frames: $count',
      'Avg: ${avgMs.toStringAsFixed(1)}ms  Max: ${maxMs.toStringAsFixed(1)}ms',
      '',
      ...recent.reversed.map((e) {
        final build = e.metadata?['buildDuration'] as num?;
        final raster = e.metadata?['rasterDuration'] as num?;
        final parts = <String>['${e.value.toStringAsFixed(1)}ms'];
        if (build != null) parts.add('B:${build.toStringAsFixed(0)}');
        if (raster != null) parts.add('R:${raster.toStringAsFixed(0)}');
        return parts.join('  ');
      }),
    ];

    return Tooltip(
      richMessage: TextSpan(
        text: lines.join('\n'),
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.white : Colors.black87,
          height: 1.5,
        ),
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2333) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorTokens.chartRed.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12),
        ],
      ),
      waitDuration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: ColorTokens.chartRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.triangleAlert, size: 8, color: ColorTokens.chartRed),
            const SizedBox(width: 3),
            Text(
              '$count',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: ColorTokens.chartRed),
            ),
          ],
        ),
      ),
    );
  }
}