import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/performance/performance_entry.dart';
import '../../provider/performance_providers.dart';
import '../badges/alloc_rate_badge.dart';
import '../badges/jank_badge.dart';
import '../charts/profiler_line_chart.dart';
import '../header/profiler_toolbar.dart';
import '../panels/profiler_chart_row.dart';
import '../panels/profiler_network_row.dart';
import '../panels/system_status_row.dart';
import '../shared/format/memory.dart';
import '../shared/status_colors.dart';

/// ═══════════════════════════════════════════════════════════════════
/// Performance Page — profiler with stacked chart panels like
/// Android Studio. Composes [ProfilerToolbar] (top) + a vertical
/// scroll of [ProfilerChartRow] / [ProfilerNetworkRow] /
/// [SystemStatusRow] inside a [RepaintBoundary] (for screenshot
/// capture).
/// ═══════════════════════════════════════════════════════════════════

class PerformancePage extends ConsumerStatefulWidget {
  const PerformancePage({super.key});

  @override
  ConsumerState<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends ConsumerState<PerformancePage> {
  bool _isRecording = true;
  final _contentKey = GlobalKey();
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _takeScreenshot() async {
    try {
      final boundary = _contentKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();
      final fileName =
          'devconnect_performance_${DateTime.now().millisecondsSinceEpoch}.png';
      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'PNG Image', extensions: ['png']),
        ],
      );
      if (location == null) return;
      final path = location.path;
      await File(path).writeAsBytes(pngBytes);
      if (mounted) showScreenshotSavedToast(context, filePath: path);
    } catch (_) {
      if (mounted) showCopiedToast(context, label: S.of(context).screenshotFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entries = ref.watch(filteredPerformanceEntriesProvider);

    if (entries.isEmpty) {
      return EmptyState(
        icon: LucideIcons.gauge,
        title: S.of(context).noPerformanceData,
        subtitle: S.of(context).connectAppToProfile,
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
        ProfilerToolbar(
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
          onScreenshot: _takeScreenshot,
        ),
        // Profiler charts stacked vertically like Android Studio
        Expanded(
          child: RepaintBoundary(
            key: _contentKey,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              children: [
                // FPS chart row
                ProfilerChartRow(
                  title: 'FPS',
                  icon: LucideIcons.monitor,
                  color: ColorTokens.chartGreen,
                  isDark: isDark,
                  currentValue: fps != null ? fps.toStringAsFixed(0) : '--',
                  unit: 'fps',
                  statusColor: fpsStatusColor(fps),
                  chart: ProfilerLineChart(
                    entries: fpsHistory,
                    color: ColorTokens.chartGreen,
                    isDark: isDark,
                    maxY: 120,
                    targetLine: 60,
                    targetLabel: '60 fps',
                    unit: 'fps',
                  ),
                  badge: jankCount > 0
                      ? JankBadge(count: jankCount, isDark: isDark, entries: jankEntries)
                      : null,
                ),
                // Frame Build Time — only show if data exists
                if (buildTimeHistory.isNotEmpty) ...[
                  _chartDivider(isDark),
                  ProfilerChartRow(
                    title: 'Build',
                    icon: LucideIcons.hammer,
                    color: const Color(0xFF06B6D4),
                    isDark: isDark,
                    currentValue: buildTimeHistory.last.value.toStringAsFixed(1),
                    unit: 'ms',
                    statusColor: frameTimeColor(buildTimeHistory.last.value),
                    chart: ProfilerLineChart(
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
                  ProfilerChartRow(
                    title: 'GPU',
                    icon: LucideIcons.paintbrush,
                    color: const Color(0xFFEC4899),
                    isDark: isDark,
                    currentValue: rasterTimeHistory.last.value.toStringAsFixed(1),
                    unit: 'ms',
                    statusColor: frameTimeColor(rasterTimeHistory.last.value),
                    chart: ProfilerLineChart(
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
                ProfilerChartRow(
                  title: 'CPU',
                  icon: LucideIcons.cpu,
                  color: ColorTokens.chartAmber,
                  isDark: isDark,
                  currentValue: cpu != null ? cpu.toStringAsFixed(1) : '--',
                  unit: '%',
                  statusColor: cpuStatusColor(cpu),
                  chart: ProfilerLineChart(
                    entries: cpuHistory,
                    color: ColorTokens.chartAmber,
                    isDark: isDark,
                    maxY: 100,
                    unit: '%',
                  ),
                ),
                _chartDivider(isDark),
                // Memory chart row
                ProfilerChartRow(
                  title: 'Memory',
                  icon: LucideIcons.memoryStick,
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  currentValue: memory != null
                      ? formatMemoryValue(memory)
                      : '--',
                  unit: memory != null ? formatMemoryUnit(memory) : 'MB',
                  statusColor: const Color(0xFF8B5CF6),
                  chart: ProfilerLineChart(
                    entries: memoryHistory,
                    color: const Color(0xFF8B5CF6),
                    isDark: isDark,
                    fillColor: const Color(0xFF8B5CF6),
                    showArea: true,
                    unit: memory != null ? formatMemoryUnit(memory) : 'MB',
                  ),
                  badge: memAllocRate != null
                      ? AllocRateBadge(rate: memAllocRate, isDark: isDark)
                      : null,
                ),
                _chartDivider(isDark),
                // Network chart row
                ProfilerNetworkRow(
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
                  ProfilerChartRow(
                    title: 'Threads',
                    icon: LucideIcons.gitBranch,
                    color: const Color(0xFF14B8A6),
                    isDark: isDark,
                    currentValue: threadCount?.toString() ?? '--',
                    unit: '',
                    statusColor: const Color(0xFF14B8A6),
                    chart: ProfilerLineChart(
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
                  SystemStatusRow(
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
}