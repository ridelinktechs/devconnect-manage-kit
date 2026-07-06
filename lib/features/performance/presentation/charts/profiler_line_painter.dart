import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../models/performance/performance_entry.dart';

/// CustomPainter that draws the profiler line chart:
///
///   1. 3 horizontal grid lines
///   2. (optional) dashed target line + label
///   3. line + area fill (gradient)
///   4. latest-value dot with glow
///   5. min/max edge labels
///   6. (optional) hover crosshair + tooltip pinned to nearest point
///
/// Caps rendered data at the last 120 entries to keep paint cheap.
class ProfilerLinePainter extends CustomPainter {
  final List<PerformanceEntry> entries;
  final Color color;
  final bool isDark;
  final double? maxY;
  final double? targetLine;
  final Color fillColor;
  final bool showArea;
  final Offset? hoverPos;
  final String unit;

  ProfilerLinePainter({
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
  bool shouldRepaint(covariant ProfilerLinePainter old) =>
      entries != old.entries ||
      hoverPos != old.hoverPos;
}