import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../models/network/network_entry.dart';
import '../../../../models/performance/performance_entry.dart';
import '../../provider/performance_providers.dart';

/// Format bytes/MB value to human-readable with auto unit
String _formatMemory(double mb) {
  if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
  if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
  return '${(mb * 1024).toStringAsFixed(0)} KB';
}

/// Short value only (for metric card/pill)
String _formatMemoryValue(double mb) {
  if (mb >= 1024) return (mb / 1024).toStringAsFixed(1);
  if (mb >= 1) return mb.toStringAsFixed(1);
  return (mb * 1024).toStringAsFixed(0);
}

/// Unit only
String _formatMemoryUnit(double mb) {
  if (mb >= 1024) return 'GB';
  if (mb >= 1) return 'MB';
  return 'KB';
}

/// Format bytes/sec to human-readable speed
String _formatSpeed(double bytesPerSec) {
  if (bytesPerSec >= 1024 * 1024) return '${(bytesPerSec / 1024 / 1024).toStringAsFixed(1)} MB/s';
  if (bytesPerSec >= 1024) return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
  if (bytesPerSec > 0) return '${bytesPerSec.toStringAsFixed(0)} B/s';
  return '0';
}

class PerformancePage extends ConsumerStatefulWidget {
  const PerformancePage({super.key});

  @override
  ConsumerState<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends ConsumerState<PerformancePage> {
  bool _isRecording = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entries = ref.watch(filteredPerformanceEntriesProvider);

    if (entries.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.gauge,
        title: 'No Performance Data',
        subtitle: 'Connect an app with DevConnect SDK to start profiling',
      );
    }

    final fps = ref.watch(latestFpsProvider);
    final memory = ref.watch(latestMemoryProvider);
    final cpu = ref.watch(latestCpuProvider);
    final jankCount = ref.watch(jankFrameCountProvider);
    final fpsHistory = ref.watch(fpsHistoryProvider);
    final memoryHistory = ref.watch(memoryHistoryProvider);
    final cpuHistory = ref.watch(cpuHistoryProvider);
    final networkHistory = ref.watch(networkHistoryProvider);
    final activeRequests = ref.watch(activeNetworkRequestsProvider);
    final reqPerSec = ref.watch(networkRequestsPerSecondProvider);
    final avgResponse = ref.watch(avgResponseTimeProvider);
    final errorRate = ref.watch(networkErrorRateProvider);
    // New metrics
    final buildTimeHistory = ref.watch(frameBuildTimeHistoryProvider);
    final rasterTimeHistory = ref.watch(frameRasterTimeHistoryProvider);
    final startupTime = ref.watch(startupTimeProvider);
    final battery = ref.watch(latestBatteryProvider);
    final batteryEntry = ref.watch(latestBatteryEntryProvider);
    final batteryHistory = ref.watch(batteryHistoryProvider);
    final batteryDrainRate = ref.watch(batteryDrainRateProvider);
    final batteryTimeRemaining = ref.watch(batteryTimeRemainingProvider);
    final thermal = ref.watch(latestThermalProvider);
    final thermalEntry = ref.watch(latestThermalEntryProvider);
    final threadCount = ref.watch(latestThreadCountProvider);
    final threadHistory = ref.watch(threadCountHistoryProvider);
    final diskRead = ref.watch(latestDiskReadProvider);
    final diskWrite = ref.watch(latestDiskWriteProvider);
    final memAllocRate = ref.watch(latestMemAllocRateProvider);
    final anrCount = ref.watch(anrCountProvider);
    final jankEntries = ref.watch(filteredPerformanceEntriesProvider
        .select((list) => list.where((e) => e.metricType == PerformanceMetricType.jankFrame).toList()));

    return Column(
      children: [
        // Profiler toolbar
        _ProfilerToolbar(
          isDark: isDark,
          isRecording: _isRecording,
          fps: fps,
          memory: memory,
          cpu: cpu,
          jankCount: jankCount,
          onToggleRecording: () => setState(() => _isRecording = !_isRecording),
          onClear: () {
            ref.read(performanceEntriesProvider.notifier).clear();
          },
        ),
        // Profiler charts stacked vertically like Android Studio
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            children: [
              // FPS chart row
              _ProfilerChartRow(
                title: 'FPS',
                icon: LucideIcons.monitor,
                color: ColorTokens.chartGreen,
                isDark: isDark,
                currentValue: fps != null ? fps.toStringAsFixed(0) : '--',
                unit: 'fps',
                statusColor: _fpsStatusColor(fps),
                chart: _ProfilerLineChart(
                  entries: fpsHistory,
                  color: ColorTokens.chartGreen,
                  isDark: isDark,
                  maxY: 120,
                  targetLine: 60,
                  targetLabel: '60 fps',
                  unit: 'fps',
                ),
                badge: jankCount > 0
                    ? _JankBadge(count: jankCount, isDark: isDark, entries: jankEntries)
                    : null,
              ),
              // Frame Build Time — only show if data exists
              if (buildTimeHistory.isNotEmpty) ...[
                _chartDivider(isDark),
                _ProfilerChartRow(
                  title: 'Build',
                  icon: LucideIcons.hammer,
                  color: const Color(0xFF06B6D4),
                  isDark: isDark,
                  currentValue: buildTimeHistory.last.value.toStringAsFixed(1),
                  unit: 'ms',
                  statusColor: _frameTimeColor(buildTimeHistory.last.value),
                  chart: _ProfilerLineChart(
                    entries: buildTimeHistory,
                    color: const Color(0xFF06B6D4),
                    isDark: isDark,
                    targetLine: 16,
                    unit: 'ms',
                  ),
                ),
              ],
              // Frame Raster (GPU render) Time — only show if data exists (Flutter SDK only)
              if (rasterTimeHistory.isNotEmpty) ...[
                _chartDivider(isDark),
                _ProfilerChartRow(
                  title: 'GPU',
                  icon: LucideIcons.paintbrush,
                  color: const Color(0xFFEC4899),
                  isDark: isDark,
                  currentValue: rasterTimeHistory.last.value.toStringAsFixed(1),
                  unit: 'ms',
                  statusColor: _frameTimeColor(rasterTimeHistory.last.value),
                  chart: _ProfilerLineChart(
                    entries: rasterTimeHistory,
                    color: const Color(0xFFEC4899),
                    isDark: isDark,
                    targetLine: 16,
                    unit: 'ms',
                  ),
                ),
              ],
              _chartDivider(isDark),
              // CPU chart row
              _ProfilerChartRow(
                title: 'CPU',
                icon: LucideIcons.cpu,
                color: ColorTokens.chartAmber,
                isDark: isDark,
                currentValue: cpu != null ? cpu.toStringAsFixed(1) : '--',
                unit: '%',
                statusColor: _cpuStatusColor(cpu),
                chart: _ProfilerLineChart(
                  entries: cpuHistory,
                  color: ColorTokens.chartAmber,
                  isDark: isDark,
                  maxY: 100,
                  unit: '%',
                ),
              ),
              _chartDivider(isDark),
              // Memory chart row
              _ProfilerChartRow(
                title: 'Memory',
                icon: LucideIcons.memoryStick,
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
                currentValue: memory != null
                    ? _formatMemoryValue(memory)
                    : '--',
                unit: memory != null ? _formatMemoryUnit(memory) : 'MB',
                statusColor: const Color(0xFF8B5CF6),
                chart: _ProfilerLineChart(
                  entries: memoryHistory,
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  fillColor: const Color(0xFF8B5CF6),
                  showArea: true,
                  unit: memory != null ? _formatMemoryUnit(memory) : 'MB',
                ),
                badge: memAllocRate != null
                    ? _AllocRateBadge(rate: memAllocRate, isDark: isDark)
                    : null,
              ),
              _chartDivider(isDark),
              // Network chart row
              _ProfilerNetworkRow(
                isDark: isDark,
                networkHistory: networkHistory,
                activeRequests: activeRequests,
                reqPerSec: reqPerSec,
                avgResponse: avgResponse,
                errorRate: errorRate,
                downloadSpeed: ref.watch(networkDownloadSpeedProvider),
                uploadSpeed: ref.watch(networkUploadSpeedProvider),
              ),
              // Thread Count — only show if data exists
              if (threadHistory.isNotEmpty) ...[
                _chartDivider(isDark),
                _ProfilerChartRow(
                  title: 'Threads',
                  icon: LucideIcons.gitBranch,
                  color: const Color(0xFF14B8A6),
                  isDark: isDark,
                  currentValue: threadCount?.toString() ?? '--',
                  unit: '',
                  statusColor: const Color(0xFF14B8A6),
                  chart: _ProfilerLineChart(
                    entries: threadHistory,
                    color: const Color(0xFF14B8A6),
                    isDark: isDark,
                    unit: '',
                  ),
                ),
              ],
              // System Status — only show if any data available
              if (startupTime != null || battery != null || thermal != null ||
                  diskRead != null || diskWrite != null || anrCount > 0) ...[
                _chartDivider(isDark),
                _SystemStatusRow(
                  isDark: isDark,
                  startupTime: startupTime,
                  battery: battery,
                  batteryEntry: batteryEntry,
                  batteryHistory: batteryHistory,
                  batteryDrainRate: batteryDrainRate,
                  batteryTimeRemaining: batteryTimeRemaining,
                  thermal: thermal,
                  thermalEntry: thermalEntry,
                  diskRead: diskRead,
                  diskWrite: diskWrite,
                  anrCount: anrCount,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _chartDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.04),
    );
  }

  Color _fpsStatusColor(double? fps) {
    if (fps == null) return Colors.grey;
    if (fps >= 55) return ColorTokens.chartGreen;
    if (fps >= 30) return ColorTokens.chartAmber;
    return ColorTokens.chartRed;
  }

  Color _cpuStatusColor(double? cpu) {
    if (cpu == null) return Colors.grey;
    if (cpu <= 30) return ColorTokens.chartGreen;
    if (cpu <= 60) return ColorTokens.chartAmber;
    return ColorTokens.chartRed;
  }

  Color _frameTimeColor(double? ms) {
    if (ms == null) return Colors.grey;
    if (ms <= 8) return ColorTokens.chartGreen;
    if (ms <= 16) return ColorTokens.chartAmber;
    return ColorTokens.chartRed;
  }
}

// ---- Profiler Toolbar ----

class _ProfilerToolbar extends StatelessWidget {
  final bool isDark;
  final bool isRecording;
  final double? fps;
  final double? memory;
  final double? cpu;
  final int jankCount;
  final VoidCallback onToggleRecording;
  final VoidCallback onClear;

  const _ProfilerToolbar({
    required this.isDark,
    required this.isRecording,
    required this.fps,
    required this.memory,
    required this.cpu,
    required this.jankCount,
    required this.onToggleRecording,
    required this.onClear,
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
          _ToolbarButton(
            icon: isRecording ? LucideIcons.circle : LucideIcons.play,
            tooltip: isRecording ? 'Stop Recording' : 'Start Recording',
            isDark: isDark,
            color: isRecording ? ColorTokens.chartRed : null,
            filled: isRecording,
            onTap: onToggleRecording,
          ),
          const SizedBox(width: 4),
          _ToolbarButton(
            icon: LucideIcons.trash2,
            tooltip: 'Clear',
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
          _MetricPill(
            label: 'FPS',
            value: fps?.toStringAsFixed(0) ?? '--',
            color: _fpsColor(fps),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _MetricPill(
            label: 'MEM',
            value: memory != null ? _formatMemory(memory!) : '--',
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _MetricPill(
            label: 'CPU',
            value: cpu != null ? '${cpu!.toStringAsFixed(0)}%' : '--',
            color: ColorTokens.chartAmber,
            isDark: isDark,
          ),
          if (jankCount > 0) ...[
            const SizedBox(width: 8),
            _MetricPill(
              label: 'SLOW',
              value: '$jankCount',
              color: ColorTokens.chartRed,
              isDark: isDark,
            ),
          ],
          const Spacer(),
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

  Color _fpsColor(double? fps) {
    if (fps == null) return Colors.grey;
    if (fps >= 55) return ColorTokens.chartGreen;
    if (fps >= 30) return ColorTokens.chartAmber;
    return ColorTokens.chartRed;
  }
}

// ---- Metric Pill (toolbar) ----

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Profiler Chart Row (stacked like Android Studio) ----

class _ProfilerChartRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isDark;
  final String currentValue;
  final String unit;
  final Color statusColor;
  final Widget chart;
  final Widget? badge;

  const _ProfilerChartRow({
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

// ---- Jank Badge with tooltip ----

class _JankBadge extends StatelessWidget {
  final int count;
  final bool isDark;
  final List<PerformanceEntry> entries;

  const _JankBadge({required this.count, required this.isDark, required this.entries});

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

// ---- Alloc Rate Badge ----

class _AllocRateBadge extends StatelessWidget {
  final double rate;
  final bool isDark;

  const _AllocRateBadge({required this.rate, required this.isDark});

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

// ---- System Status Row (battery, thermal, disk, startup, ANR) ----

class _SystemStatusRow extends StatelessWidget {
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

  const _SystemStatusRow({
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
                'System Status',
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
                _SystemChip(
                  icon: LucideIcons.rocket,
                  label: 'Startup',
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
                _SystemChip(
                  icon: LucideIcons.batteryWarning,
                  label: 'Battery',
                  value: 'N/A',
                  detail: 'Emulator',
                  color: Colors.grey,
                  isDark: isDark,
                ),
              if (battery != null && battery! >= 0)
                _SystemChip(
                  icon: battery! > 80
                      ? LucideIcons.batteryFull
                      : battery! > 30
                          ? LucideIcons.batteryMedium
                          : LucideIcons.batteryLow,
                  label: 'Battery',
                  value: '${battery!.toInt()}%',
                  detail: _batteryDetail(),
                  color: battery! > 30
                      ? ColorTokens.chartGreen
                      : battery! > 15
                          ? ColorTokens.chartAmber
                          : ColorTokens.chartRed,
                  isDark: isDark,
                ),
              if (batteryDrainRate != null && batteryDrainRate! > 0)
                _SystemChip(
                  icon: LucideIcons.trendingDown,
                  label: 'Drain Rate',
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
                _SystemChip(
                  icon: LucideIcons.thermometer,
                  label: 'Thermal',
                  value: _thermalLabel(thermal!),
                  detail: thermalEntry?.metadata?['temperatureC'] != null
                      ? '${(thermalEntry!.metadata!['temperatureC'] as num).toStringAsFixed(1)}°C'
                      : null,
                  color: _thermalColor(thermal!),
                  isDark: isDark,
                ),
              if (diskRead != null)
                _SystemChip(
                  icon: LucideIcons.hardDriveDownload,
                  label: 'Disk Read',
                  value: '${diskRead!.toStringAsFixed(1)} MB',
                  color: ColorTokens.chartBlue,
                  isDark: isDark,
                ),
              if (diskWrite != null)
                _SystemChip(
                  icon: LucideIcons.hardDriveUpload,
                  label: 'Disk Write',
                  value: '${diskWrite!.toStringAsFixed(1)} MB',
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                ),
              if (anrCount > 0)
                _SystemChip(
                  icon: LucideIcons.octagonAlert,
                  label: 'ANR',
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

  String? _batteryDetail() {
    if (batteryEntry?.metadata?['charging'] == true) return 'Charging';
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

  String _thermalLabel(double state) {
    if (state <= 0) return 'Normal';
    if (state <= 1) return 'Fair';
    if (state <= 2) return 'Serious';
    return 'Critical';
  }

  Color _thermalColor(double state) {
    if (state <= 0) return ColorTokens.chartGreen;
    if (state <= 1) return ColorTokens.chartAmber;
    if (state <= 2) return ColorTokens.chartRed;
    return const Color(0xFFDC2626);
  }
}

// ---- System Chip ----

class _SystemChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final Color color;
  final bool isDark;

  const _SystemChip({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      detail!,
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Network Row ----

class _ProfilerNetworkRow extends StatelessWidget {
  final bool isDark;
  final List<NetworkEntry> networkHistory;
  final int activeRequests;
  final double reqPerSec;
  final double? avgResponse;
  final double errorRate;
  final double downloadSpeed;
  final double uploadSpeed;

  const _ProfilerNetworkRow({
    required this.isDark,
    required this.networkHistory,
    required this.activeRequests,
    required this.reqPerSec,
    required this.avgResponse,
    required this.errorRate,
    required this.downloadSpeed,
    required this.uploadSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
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
                Icon(LucideIcons.globe, size: 14,
                    color: ColorTokens.chartBlue.withValues(alpha: 0.7)),
                const SizedBox(height: 4),
                Text(
                  'Network',
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
                    '${networkHistory.length} reqs',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: ColorTokens.chartBlue,
                      height: 1,
                    ),
                  ),
                ),
                const Spacer(),
                if (activeRequests > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: ColorTokens.chartBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$activeRequests live',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: ColorTokens.chartBlue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Network chart area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Column(
                children: [
                  // Network stat pills
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _NetStatChip(
                        label: 'req/s',
                        value: reqPerSec.toStringAsFixed(1),
                        color: ColorTokens.chartBlue,
                        isDark: isDark,
                      ),
                      _NetStatChip(
                        label: 'avg',
                        value: avgResponse != null
                            ? '${avgResponse!.toStringAsFixed(0)}ms'
                            : '--',
                        color: ColorTokens.chartGreen,
                        isDark: isDark,
                      ),
                      _NetStatChip(
                        label: 'err',
                        value: '${errorRate.toStringAsFixed(1)}%',
                        color: errorRate > 0
                            ? ColorTokens.chartRed
                            : ColorTokens.chartGreen,
                        isDark: isDark,
                      ),
                      _NetStatChip(
                        label: '↓',
                        value: _formatSpeed(downloadSpeed),
                        color: ColorTokens.chartGreen,
                        isDark: isDark,
                      ),
                      _NetStatChip(
                        label: '↑',
                        value: _formatSpeed(uploadSpeed),
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Network waterfall chart
                  Expanded(
                    child: networkHistory.length < 2
                        ? Center(
                            child: Text(
                              'Waiting for requests...',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                            ),
                          )
                        : CustomPaint(
                            size: Size.infinite,
                            painter: _NetworkWaterfallPainter(
                              entries: networkHistory,
                              isDark: isDark,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Net Stat Chip ----

class _NetStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _NetStatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Profiler Line Chart (shared, with hover tooltip) ----

class _ProfilerLineChart extends StatefulWidget {
  final List<PerformanceEntry> entries;
  final Color color;
  final bool isDark;
  final double? maxY;
  final double? targetLine;
  final String? targetLabel;
  final Color? fillColor;
  final bool showArea;
  final String unit;

  const _ProfilerLineChart({
    required this.entries,
    required this.color,
    required this.isDark,
    this.maxY,
    this.targetLine,
    this.targetLabel,
    this.fillColor,
    this.showArea = false,
    this.unit = '',
  });

  @override
  State<_ProfilerLineChart> createState() => _ProfilerLineChartState();
}

class _ProfilerLineChartState extends State<_ProfilerLineChart> {
  Offset? _hoverPos;

  @override
  Widget build(BuildContext context) {
    if (widget.entries.length < 2) {
      return Center(
        child: Text(
          'Waiting for data...',
          style: TextStyle(
            fontSize: 11,
            color: widget.isDark ? Colors.white30 : Colors.black26,
          ),
        ),
      );
    }
    return MouseRegion(
      onHover: (e) => setState(() => _hoverPos = e.localPosition),
      onExit: (_) => setState(() => _hoverPos = null),
      child: CustomPaint(
        size: Size.infinite,
        painter: _ProfilerLinePainter(
          entries: widget.entries,
          color: widget.color,
          isDark: widget.isDark,
          maxY: widget.maxY,
          targetLine: widget.targetLine,
          fillColor: widget.fillColor ?? widget.color,
          showArea: widget.showArea,
          hoverPos: _hoverPos,
          unit: widget.unit,
        ),
      ),
    );
  }
}

// ---- Profiler Line Painter ----

class _ProfilerLinePainter extends CustomPainter {
  final List<PerformanceEntry> entries;
  final Color color;
  final bool isDark;
  final double? maxY;
  final double? targetLine;
  final Color fillColor;
  final bool showArea;
  final Offset? hoverPos;
  final String unit;

  _ProfilerLinePainter({
    required this.entries,
    required this.color,
    required this.isDark,
    this.maxY,
    this.targetLine,
    required this.fillColor,
    required this.showArea,
    this.hoverPos,
    this.unit = '',
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;

    final data = entries.length > 120
        ? entries.sublist(entries.length - 120)
        : entries;

    final computedMaxY = maxY ??
        data.fold<double>(0, (m, e) => math.max(m, e.value)) * 1.2;
    if (computedMaxY <= 0) return;

    final w = size.width;
    final h = size.height;
    final stepX = w / (data.length - 1);

    // Subtle grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 3; i++) {
      final y = h * i / 3;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Target line
    if (targetLine != null) {
      final targetY = h - (targetLine! / computedMaxY) * h;
      final dashPaint = Paint()
        ..color = ColorTokens.chartGreen.withValues(alpha: 0.3)
        ..strokeWidth = 1;

      const dashWidth = 4.0;
      const dashSpace = 3.0;
      double startX = 0;
      while (startX < w) {
        canvas.drawLine(
          Offset(startX, targetY),
          Offset(math.min(startX + dashWidth, w), targetY),
          dashPaint,
        );
        startX += dashWidth + dashSpace;
      }

      final tp = TextPainter(
        text: TextSpan(
          text: '${targetLine!.toInt()}',
          style: TextStyle(
            fontSize: 8,
            color: ColorTokens.chartGreen.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(w - tp.width - 2, targetY - tp.height - 1));
    }

    // Build path
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = h - (data[i].value / computedMaxY).clamp(0.0, 1.0) * h;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Fill gradient
    fillPath.lineTo((data.length - 1) * stepX, h);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: showArea
          ? [fillColor.withValues(alpha: 0.35), fillColor.withValues(alpha: 0.05)]
          : [fillColor.withValues(alpha: 0.18), fillColor.withValues(alpha: 0.01)],
    );

    canvas.drawPath(
      fillPath,
      Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Latest value dot with glow
    final lastX = (data.length - 1) * stepX;
    final lastY = h - (data.last.value / computedMaxY).clamp(0.0, 1.0) * h;

    canvas.drawCircle(
      Offset(lastX, lastY), 5,
      Paint()..color = color.withValues(alpha: 0.2),
    );
    canvas.drawCircle(
      Offset(lastX, lastY), 3,
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(lastX, lastY), 1.5,
      Paint()..color = Colors.white,
    );

    // Min/max labels on right edge
    final maxVal = data.fold<double>(0, (m, e) => math.max(m, e.value));
    final minVal = data.fold<double>(maxVal, (m, e) => math.min(m, e.value));
    _drawEdgeLabel(canvas, w, 2, maxVal.toStringAsFixed(0), isDark);
    _drawEdgeLabel(canvas, w, h - 10, minVal.toStringAsFixed(0), isDark);

    // ---- Hover crosshair + tooltip ----
    if (hoverPos != null && hoverPos!.dx >= 0 && hoverPos!.dx <= w) {
      _drawHoverTooltip(canvas, size, data, stepX, computedMaxY);
    }
  }

  void _drawHoverTooltip(
    Canvas canvas, Size size,
    List<PerformanceEntry> data, double stepX, double computedMaxY,
  ) {
    final w = size.width;
    final h = size.height;
    final hx = hoverPos!.dx;

    // Snap to nearest data point
    int idx = (hx / stepX).round().clamp(0, data.length - 1);
    final entry = data[idx];
    final snapX = idx * stepX;
    final snapY = h - (entry.value / computedMaxY).clamp(0.0, 1.0) * h;

    // Vertical crosshair line
    canvas.drawLine(
      Offset(snapX, 0), Offset(snapX, h),
      Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15)
        ..strokeWidth = 1,
    );

    // Highlight dot
    canvas.drawCircle(Offset(snapX, snapY), 5, Paint()..color = color.withValues(alpha: 0.3));
    canvas.drawCircle(Offset(snapX, snapY), 3.5, Paint()..color = color);
    canvas.drawCircle(Offset(snapX, snapY), 1.5, Paint()..color = Colors.white);

    // Tooltip text
    final valueStr = entry.value.toStringAsFixed(1);
    final timeAgo = _formatTimeAgo(entry.timestamp);
    final label = entry.metadata?['label'] as String?;
    final tooltipText = '$valueStr${unit.isNotEmpty ? ' $unit' : ''}  $timeAgo';

    final tp = TextPainter(
      text: TextSpan(
        text: tooltipText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Second line for label/metadata
    TextPainter? tp2;
    if (label != null && label.isNotEmpty) {
      tp2 = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 9,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    final tooltipW = math.max(tp.width, tp2?.width ?? 0) + 16;
    final tooltipH = tp.height + (tp2 != null ? tp2.height + 4 : 0) + 12;

    // Position tooltip: prefer right of crosshair, flip if near edge
    double tx = snapX + 10;
    if (tx + tooltipW > w - 4) tx = snapX - tooltipW - 10;
    double ty = snapY - tooltipH - 8;
    if (ty < 2) ty = snapY + 12;

    // Tooltip background
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tx, ty, tooltipW, tooltipH),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = (isDark ? const Color(0xFF1C2333) : Colors.white).withValues(alpha: 0.95),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    tp.paint(canvas, Offset(tx + 8, ty + 6));
    tp2?.paint(canvas, Offset(tx + 8, ty + 6 + tp.height + 2));
  }

  String _formatTimeAgo(int timestampMs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - timestampMs;
    if (diff < 1000) return 'now';
    if (diff < 60000) return '${(diff / 1000).round()}s ago';
    if (diff < 3600000) return '${(diff / 60000).round()}m ago';
    return '${(diff / 3600000).round()}h ago';
  }

  void _drawEdgeLabel(Canvas canvas, double x, double y, String text, bool isDark) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 8,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.25),
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width - 2, y));
  }

  @override
  bool shouldRepaint(covariant _ProfilerLinePainter old) =>
      entries != old.entries ||
      hoverPos != old.hoverPos;
}

// ---- Network Waterfall Painter ----

class _NetworkWaterfallPainter extends CustomPainter {
  final List<NetworkEntry> entries;
  final bool isDark;

  _NetworkWaterfallPainter({required this.entries, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    // Show last 60 requests as horizontal bars
    final data = entries.length > 60
        ? entries.sublist(entries.length - 60)
        : entries;

    final w = size.width;
    final h = size.height;
    final barH = math.max(2.0, (h / data.length).clamp(2.0, 6.0));
    final gap = math.max(0.5, ((h - barH * data.length) / data.length).clamp(0.5, 2.0));

    // Find time range for x-axis
    final minTime = data.first.startTime;
    final maxTime = data.last.endTime ?? data.last.startTime + 1000;
    final timeRange = math.max(1, maxTime - minTime);

    for (int i = 0; i < data.length; i++) {
      final entry = data[i];
      final y = i * (barH + gap);
      if (y + barH > h) break;

      final startX = ((entry.startTime - minTime) / timeRange * w).clamp(0.0, w);
      final endX = entry.endTime != null
          ? ((entry.endTime! - minTime) / timeRange * w).clamp(startX, w)
          : w; // Still in-flight

      final barWidth = math.max(2.0, endX - startX);

      Color barColor;
      if (entry.error != null) {
        barColor = ColorTokens.chartRed;
      } else if (entry.statusCode >= 400) {
        barColor = ColorTokens.chartRed;
      } else if (entry.statusCode >= 300) {
        barColor = ColorTokens.chartAmber;
      } else if (!entry.isComplete) {
        barColor = ColorTokens.chartBlue.withValues(alpha: 0.4);
      } else {
        barColor = ColorTokens.chartBlue;
      }

      // Duration-based opacity (longer = more opaque)
      final dur = entry.duration ?? 500;
      final opacity = (dur / 2000.0).clamp(0.3, 1.0);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX, y, barWidth, barH),
          const Radius.circular(1),
        ),
        Paint()..color = barColor.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkWaterfallPainter old) =>
      entries.length != old.entries.length;
}

// ---- Toolbar Button ----

class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final Color? color;
  final bool filled;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    this.color,
    this.filled = false,
    required this.onTap,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.color ??
        (_hovered
            ? (widget.isDark ? Colors.white70 : Colors.black54)
            : Colors.grey[500]);

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hovered
                  ? (widget.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: widget.filled
                ? Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  )
                : Icon(widget.icon, size: 14, color: iconColor),
          ),
        ),
      ),
    );
  }
}
