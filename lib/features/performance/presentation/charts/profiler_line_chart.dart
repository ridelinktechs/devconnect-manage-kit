import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/performance/performance_entry.dart';
import 'profiler_line_painter.dart';

/// StateWidget wrapper around [ProfilerLinePainter]. Tracks the
/// current hover offset so the painter can render a crosshair +
/// tooltip pinned to the nearest data point.
///
/// Shows a centered "waiting for data" placeholder when fewer than
/// 2 entries are available.
class ProfilerLineChart extends StatefulWidget {
  final List<PerformanceEntry> entries;
  final Color color;
  final bool isDark;
  final double? maxY;
  final double? targetLine;
  final String? targetLabel;
  final Color? fillColor;
  final bool showArea;
  final String unit;

  const ProfilerLineChart({
    super.key,
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
  State<ProfilerLineChart> createState() => _ProfilerLineChartState();
}

class _ProfilerLineChartState extends State<ProfilerLineChart> {
  Offset? _hoverPos;

  @override
  Widget build(BuildContext context) {
    if (widget.entries.length < 2) {
      return Center(
        child: Text(
          S.of(context).waitingForData,
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
        painter: ProfilerLinePainter(
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