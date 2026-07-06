import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../models/network/network_entry.dart';

/// Waterfall-style horizontal bar chart of recent network requests.
/// Up to 60 bars: x-position encodes start time, bar width encodes
/// duration, color encodes status (error/red, ≥400/red, ≥300/amber,
/// in-flight/blue @40%, default/blue).
class NetworkWaterfallPainter extends CustomPainter {
  final List<NetworkEntry> entries;
  final bool isDark;

  NetworkWaterfallPainter({required this.entries, required this.isDark});

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
  bool shouldRepaint(covariant NetworkWaterfallPainter old) =>
      entries.length != old.entries.length;
}