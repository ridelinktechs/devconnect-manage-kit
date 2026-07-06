import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../shared/format/memory.dart';
import '../shared/status_colors.dart';
import 'metric_pill.dart';
import 'toolbar_button.dart';

/// Top 44px-tall bar of the Performance page — record/stop/clear +
/// live FPS/MEM/CPU/SLOW pills + optional screenshot button + brand
/// label on the right.
class ProfilerToolbar extends StatelessWidget {
  final bool isDark;
  final bool isRecording;
  final double? fps;
  final double? memory;
  final double? cpu;
  final int jankCount;
  final VoidCallback onToggleRecording;
  final VoidCallback onClear;
  final VoidCallback? onScreenshot;

  const ProfilerToolbar({
    super.key,
    required this.isDark,
    required this.isRecording,
    required this.fps,
    required this.memory,
    required this.cpu,
    required this.jankCount,
    required this.onToggleRecording,
    required this.onClear,
    this.onScreenshot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : ColorTokens.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          // Recording indicator
          ToolbarButton(
            icon: isRecording ? LucideIcons.circle : LucideIcons.play,
            tooltip: isRecording ? S.of(context).stopRecording : S.of(context).startRecording,
            isDark: isDark,
            color: isRecording ? ColorTokens.chartRed : null,
            filled: isRecording,
            onTap: onToggleRecording,
          ),
          const SizedBox(width: 4),
          ToolbarButton(
            icon: LucideIcons.trash2,
            tooltip: S.of(context).clear,
            isDark: isDark,
            onTap: onClear,
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 20,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
          const SizedBox(width: 12),
          // Live metric pills
          MetricPill(
            label: 'FPS',
            value: fps?.toStringAsFixed(0) ?? '--',
            color: fpsStatusColor(fps),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          MetricPill(
            label: 'MEM',
            value: memory != null ? formatMemory(memory!) : '--',
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          MetricPill(
            label: 'CPU',
            value: cpu != null ? '${cpu!.toStringAsFixed(0)}%' : '--',
            color: ColorTokens.chartAmber,
            isDark: isDark,
          ),
          if (jankCount > 0) ...[
            const SizedBox(width: 8),
            MetricPill(
              label: 'SLOW',
              value: '$jankCount',
              color: ColorTokens.chartRed,
              isDark: isDark,
            ),
          ],
          const Spacer(),
          if (onScreenshot != null) ...[
            ToolbarButton(
              icon: LucideIcons.camera,
              tooltip: S.of(context).captureAsImage,
              isDark: isDark,
              onTap: onScreenshot!,
            ),
            const SizedBox(width: 4),
          ],
          Icon(
            LucideIcons.gauge,
            size: 14,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
          const SizedBox(width: 6),
          Text(
            'Performance Profiler',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}