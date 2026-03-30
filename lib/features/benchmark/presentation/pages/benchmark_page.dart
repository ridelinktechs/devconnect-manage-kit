import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/duration_format.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../components/feedback/empty_state.dart';
import '../../../../components/inputs/search_field.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../models/log/benchmark_entry.dart';
import '../../provider/benchmark_providers.dart';

class BenchmarkPage extends ConsumerStatefulWidget {
  const BenchmarkPage({super.key});

  @override
  ConsumerState<BenchmarkPage> createState() => _BenchmarkPageState();
}

class _BenchmarkPageState extends ConsumerState<BenchmarkPage> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(filteredBenchmarkEntriesProvider);
    final stats = ref.watch(benchmarkStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selected = _selectedId != null
        ? entries.where((e) => e.id == _selectedId).firstOrNull
        : null;

    // Clear selection if entry was removed
    if (_selectedId != null && selected == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedId = null);
      });
    }

    return Column(
      children: [
        // Toolbar
        _Toolbar(
          count: entries.length,
          isDark: isDark,
          onClear: () {
            ref.read(benchmarkEntriesProvider.notifier).clear();
            setState(() => _selectedId = null);
          },
        ),
        // Stats row
        if (entries.isNotEmpty)
          _StatsBar(stats: stats, isDark: isDark),
        // Content
        Expanded(
          child: entries.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.timer,
                  title: 'No Benchmarks',
                  subtitle:
                      'Use benchmarkStart/Step/Stop in your SDK to measure performance',
                )
              : Row(
                  children: [
                    // List
                    Expanded(
                      flex: selected != null ? 4 : 1,
                      child: ListView.builder(
                        itemCount: entries.length,
                        itemExtent: 56,
                        itemBuilder: (context, index) {
                          // Show newest first
                          final entry =
                              entries[entries.length - 1 - index];
                          final isSelected = _selectedId == entry.id;
                          return _BenchmarkRow(
                            entry: entry,
                            isSelected: isSelected,
                            isDark: isDark,
                            onTap: () => setState(() =>
                                _selectedId = isSelected ? null : entry.id),
                          );
                        },
                      ),
                    ),
                    // Detail
                    if (selected != null) ...[
                      VerticalDivider(
                        width: 1,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                      Expanded(
                        flex: 5,
                        child: _BenchmarkDetail(
                          key: ValueKey(selected.id),
                          entry: selected,
                          isDark: isDark,
                          onClose: () =>
                              setState(() => _selectedId = null),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// Toolbar
// ═══════════════════════════════════════════════

class _Toolbar extends ConsumerWidget {
  final int count;
  final bool isDark;
  final VoidCallback onClear;

  const _Toolbar({
    required this.count,
    required this.isDark,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.timer, size: 15, color: ColorTokens.secondary),
          const SizedBox(width: 8),
          Text(
            'Benchmarks',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ColorTokens.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ColorTokens.secondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 30,
              child: SearchField(
                hintText: 'Search benchmarks...',
                onChanged: (v) =>
                    ref.read(benchmarkSearchProvider.notifier).state = v,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(LucideIcons.trash2,
                size: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600]),
            onPressed: onClear,
            tooltip: 'Clear all',
            splashRadius: 14,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Stats Bar
// ═══════════════════════════════════════════════

class _StatsBar extends StatelessWidget {
  final BenchmarkStats stats;
  final bool isDark;

  const _StatsBar({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
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
          _StatChip(
              label: 'Total', value: '${stats.total}', color: Colors.grey),
          const SizedBox(width: 16),
          _StatChip(
            label: 'Avg',
            value: formatDuration(stats.avgDuration.toInt()),
            color: ColorTokens.secondary,
          ),
          const SizedBox(width: 16),
          _StatChip(
            label: 'Min',
            value: formatDuration(stats.minDuration.toInt()),
            color: ColorTokens.success,
          ),
          const SizedBox(width: 16),
          _StatChip(
            label: 'Max',
            value: formatDuration(stats.maxDuration.toInt()),
            color: _durationColor(stats.maxDuration),
          ),
          const SizedBox(width: 16),
          _StatChip(
            label: 'P50',
            value: formatDuration(stats.p50Duration.toInt()),
            color: _durationColor(stats.p50Duration),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: AppConstants.monoFontFamily,
            color: isDark ? color.withValues(alpha: 0.9) : color,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// Benchmark Row
// ═══════════════════════════════════════════════

class _BenchmarkRow extends StatelessWidget {
  final BenchmarkEntry entry;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _BenchmarkRow({
    required this.entry,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm:ss.SSS')
        .format(DateTime.fromMillisecondsSinceEpoch(entry.startTime));
    final duration = entry.duration;
    final durationColor = duration != null ? _durationColor(duration.toDouble()) : Colors.grey;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? ColorTokens.secondary.withValues(alpha: 0.1)
                  : ColorTokens.secondary.withValues(alpha: 0.06))
              : null,
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            left: isSelected
                ? BorderSide(color: ColorTokens.secondary, width: 2)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            // Timer icon
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: durationColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(LucideIcons.timer, size: 14, color: durationColor),
            ),
            const SizedBox(width: 10),
            // Title + time
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? ColorTokens.lightBackground : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$time  •  ${entry.steps.length} steps',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: AppConstants.monoFontFamily,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            // Duration badge
            if (duration != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: durationColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  formatDuration(duration),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppConstants.monoFontFamily,
                    color: durationColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Benchmark Detail Panel
// ═══════════════════════════════════════════════

class _BenchmarkDetail extends StatelessWidget {
  final BenchmarkEntry entry;
  final bool isDark;
  final VoidCallback onClose;

  const _BenchmarkDetail({
    super.key,
    required this.entry,
    required this.isDark,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final startTime = DateFormat('yyyy-MM-dd HH:mm:ss.SSS')
        .format(DateTime.fromMillisecondsSinceEpoch(entry.startTime));
    final endTime = entry.endTime != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss.SSS')
            .format(DateTime.fromMillisecondsSinceEpoch(entry.endTime!))
        : null;

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        children: [
          // Header
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? ColorTokens.darkBackground : Colors.white,
            ),
            child: Row(
              children: [
                Icon(LucideIcons.timer,
                    size: 14, color: ColorTokens.secondary),
                const SizedBox(width: 8),
                Text(
                  entry.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ColorTokens.secondary,
                  ),
                ),
                const Spacer(),
                if (entry.duration != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _durationColor(entry.duration!.toDouble())
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      formatDuration(entry.duration!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppConstants.monoFontFamily,
                        color:
                            _durationColor(entry.duration!.toDouble()),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(LucideIcons.x,
                      size: 14,
                      color:
                          isDark ? Colors.grey[500] : Colors.grey[600]),
                  onPressed: onClose,
                  splashRadius: 14,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Info
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timing info
                  _InfoCard(
                    isDark: isDark,
                    children: [
                      _InfoRow(label: 'Start', value: startTime),
                      if (endTime != null)
                        _InfoRow(label: 'End', value: endTime),
                      if (entry.duration != null)
                        _InfoRow(
                          label: 'Duration',
                          value: formatDuration(entry.duration!),
                          valueColor:
                              _durationColor(entry.duration!.toDouble()),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Steps timeline
                  if (entry.steps.isNotEmpty) ...[
                    Text(
                      'Steps (${entry.steps.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? ColorTokens.lightBackground
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Waterfall chart
                    _WaterfallChart(
                      entry: entry,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    // Step list
                    ...entry.steps.asMap().entries.map(
                          (e) => _StepRow(
                            index: e.key,
                            step: e.value,
                            totalDuration: entry.duration ?? 1,
                            isDark: isDark,
                          ),
                        ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'No intermediate steps recorded',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
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

// ═══════════════════════════════════════════════
// Waterfall Chart
// ═══════════════════════════════════════════════

class _WaterfallChart extends StatelessWidget {
  final BenchmarkEntry entry;
  final bool isDark;

  const _WaterfallChart({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final totalDuration = entry.duration ?? 1;
    if (totalDuration == 0 || entry.steps.isEmpty) {
      return const SizedBox.shrink();
    }

    // Build segments: start -> step1 -> step2 -> ... -> end
    final segments = <_Segment>[];
    int prevTime = entry.startTime;

    for (int i = 0; i < entry.steps.length; i++) {
      final step = entry.steps[i];
      final delta = step.delta ?? (step.timestamp - prevTime);
      segments.add(_Segment(
        label: step.title,
        duration: delta,
        fraction: delta / totalDuration,
      ));
      prevTime = step.timestamp;
    }

    // Final segment (last step -> end)
    if (entry.endTime != null) {
      final remaining = entry.endTime! - prevTime;
      if (remaining > 0) {
        segments.add(_Segment(
          label: 'finish',
          duration: remaining,
          fraction: remaining / totalDuration,
        ));
      }
    }

    final colors = [
      ColorTokens.chartBlue,
      ColorTokens.chartGreen,
      ColorTokens.chartAmber,
      ColorTokens.chartRed,
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
      const Color(0xFFFF6B35),
    ];

    return Container(
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: segments.asMap().entries.map((e) {
          final seg = e.value;
          final color = colors[e.key % colors.length];
          return Expanded(
            flex: (seg.fraction * 1000).round().clamp(1, 1000),
            child: Tooltip(
              message: '${seg.label}: ${formatDuration(seg.duration)}',
              child: Container(
                color: color.withValues(alpha: 0.7),
                alignment: Alignment.center,
                child: seg.fraction > 0.08
                    ? Text(
                        formatDuration(seg.duration),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppConstants.monoFontFamily,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.clip,
                        maxLines: 1,
                      )
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Segment {
  final String label;
  final int duration;
  final double fraction;

  const _Segment({
    required this.label,
    required this.duration,
    required this.fraction,
  });
}

// ═══════════════════════════════════════════════
// Step Row
// ═══════════════════════════════════════════════

class _StepRow extends StatelessWidget {
  final int index;
  final BenchmarkStep step;
  final int totalDuration;
  final bool isDark;

  const _StepRow({
    required this.index,
    required this.step,
    required this.totalDuration,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final delta = step.delta ?? 0;
    final pct = totalDuration > 0
        ? (delta / totalDuration * 100).toStringAsFixed(1)
        : '0.0';
    final time = DateFormat('HH:mm:ss.SSS')
        .format(DateTime.fromMillisecondsSinceEpoch(step.timestamp));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
      ),
      child: Row(
        children: [
          // Step number
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorTokens.secondary.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: ColorTokens.secondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? ColorTokens.lightBackground
                        : Colors.black87,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: AppConstants.monoFontFamily,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          // Delta
          Text(
            '+${formatDuration(delta)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: AppConstants.monoFontFamily,
              color: _durationColor(delta.toDouble()),
            ),
          ),
          const SizedBox(width: 8),
          // Percentage
          SizedBox(
            width: 44,
            child: Text(
              '$pct%',
              style: TextStyle(
                fontSize: 10,
                fontFamily: AppConstants.monoFontFamily,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Info Card / Info Row
// ═══════════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _InfoCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 11,
                fontFamily: AppConstants.monoFontFamily,
                fontWeight: FontWeight.w500,
                color: valueColor ??
                    (isDark
                        ? ColorTokens.lightBackground
                        : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════

Color _durationColor(double ms) {
  if (ms < 100) return ColorTokens.success;
  if (ms < 500) return ColorTokens.chartAmber;
  if (ms < 1000) return ColorTokens.chartRed;
  return const Color(0xFFDC2626);
}

// Use formatDuration from core/utils/duration_format.dart
