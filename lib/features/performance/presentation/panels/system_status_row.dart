import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/performance/performance_entry.dart';
import '../badges/system_chip.dart';

/// Wraps the system-level [SystemChip]s (startup, battery, thermal,
/// disk R/W, ANR). Renders a single header row + `Wrap` of chips so
/// the row reflows naturally when the panel is narrow.
class SystemStatusRow extends StatelessWidget {
  final bool isDark;
  final double? startupTime;
  final double? battery;
  final PerformanceEntry? batteryEntry;
  final List<PerformanceEntry> batteryHistory;
  final double? batteryDrainRate;
  final double? batteryTimeRemaining;
  final double? thermal;
  final PerformanceEntry? thermalEntry;
  final double? diskRead;
  final double? diskWrite;
  final int anrCount;

  const SystemStatusRow({
    super.key,
    required this.isDark,
    required this.startupTime,
    required this.battery,
    required this.batteryEntry,
    required this.batteryHistory,
    required this.batteryDrainRate,
    required this.batteryTimeRemaining,
    required this.thermal,
    required this.thermalEntry,
    required this.diskRead,
    required this.diskWrite,
    required this.anrCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? ColorTokens.darkSurface : Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.activity, size: 12,
                  color: isDark ? Colors.white38 : Colors.black38),
              const SizedBox(width: 6),
              Text(
                S.of(context).systemStatus,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black45,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (startupTime != null)
                SystemChip(
                  icon: LucideIcons.rocket,
                  label: S.of(context).startup,
                  value: startupTime! >= 1000
                      ? '${(startupTime! / 1000).toStringAsFixed(1)}s'
                      : '${startupTime!.toInt()}ms',
                  color: startupTime! < 2000
                      ? ColorTokens.chartGreen
                      : startupTime! < 5000
                          ? ColorTokens.chartAmber
                          : ColorTokens.chartRed,
                  isDark: isDark,
                ),
              if (battery != null && battery! < 0)
                SystemChip(
                  icon: LucideIcons.batteryWarning,
                  label: S.of(context).battery,
                  value: 'N/A',
                  detail: S.of(context).emulator,
                  color: Colors.grey,
                  isDark: isDark,
                ),
              if (battery != null && battery! >= 0)
                SystemChip(
                  icon: battery! > 80
                      ? LucideIcons.batteryFull
                      : battery! > 30
                          ? LucideIcons.batteryMedium
                          : LucideIcons.batteryLow,
                  label: S.of(context).battery,
                  value: '${battery!.toInt()}%',
                  detail: _batteryDetail(context),
                  color: battery! > 30
                      ? ColorTokens.chartGreen
                      : battery! > 15
                          ? ColorTokens.chartAmber
                          : ColorTokens.chartRed,
                  isDark: isDark,
                ),
              if (batteryDrainRate != null && batteryDrainRate! > 0)
                SystemChip(
                  icon: LucideIcons.trendingDown,
                  label: S.of(context).drainRate,
                  value: '${batteryDrainRate!.toStringAsFixed(2)}%/min',
                  detail: batteryTimeRemaining != null
                      ? _formatTimeRemaining(batteryTimeRemaining!)
                      : null,
                  color: batteryDrainRate! < 0.5
                      ? ColorTokens.chartGreen
                      : batteryDrainRate! < 1.5
                          ? ColorTokens.chartAmber
                          : ColorTokens.chartRed,
                  isDark: isDark,
                ),
              if (thermal != null)
                SystemChip(
                  icon: LucideIcons.thermometer,
                  label: S.of(context).thermal,
                  value: _thermalLabel(context, thermal!),
                  detail: thermalEntry?.metadata?['temperatureC'] != null
                      ? '${(thermalEntry!.metadata!['temperatureC'] as num).toStringAsFixed(1)}°C'
                      : null,
                  color: _thermalColor(thermal!),
                  isDark: isDark,
                ),
              if (diskRead != null)
                SystemChip(
                  icon: LucideIcons.hardDriveDownload,
                  label: S.of(context).diskRead,
                  value: '${diskRead!.toStringAsFixed(1)} MB',
                  color: ColorTokens.chartBlue,
                  isDark: isDark,
                ),
              if (diskWrite != null)
                SystemChip(
                  icon: LucideIcons.hardDriveUpload,
                  label: S.of(context).diskWrite,
                  value: '${diskWrite!.toStringAsFixed(1)} MB',
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                ),
              if (anrCount > 0)
                SystemChip(
                  icon: LucideIcons.octagonAlert,
                  label: S.of(context).anr,
                  value: '$anrCount',
                  color: ColorTokens.chartRed,
                  isDark: isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String? _batteryDetail(BuildContext context) {
    if (batteryEntry?.metadata?['charging'] == true) return S.of(context).charging;
    if (batteryDrainRate != null && batteryDrainRate! > 0 && batteryTimeRemaining != null) {
      return '~${_formatTimeRemaining(batteryTimeRemaining!)} left';
    }
    return null;
  }

  String _formatTimeRemaining(double minutes) {
    if (minutes >= 60) {
      final h = (minutes / 60).floor();
      final m = (minutes % 60).round();
      return '${h}h${m > 0 ? ' ${m}m' : ''}';
    }
    return '${minutes.round()}m';
  }

  String _thermalLabel(BuildContext context, double state) {
    if (state <= 0) return S.of(context).normal;
    if (state <= 1) return S.of(context).fair;
    if (state <= 2) return S.of(context).serious;
    return S.of(context).critical;
  }

  Color _thermalColor(double state) {
    if (state <= 0) return ColorTokens.chartGreen;
    if (state <= 1) return ColorTokens.chartAmber;
    if (state <= 2) return ColorTokens.chartRed;
    return const Color(0xFFDC2626);
  }
}