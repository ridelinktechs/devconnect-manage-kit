import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';

/// Green/amber/red classification for an FPS reading.
Color fpsStatusColor(double? fps) {
  if (fps == null) return Colors.grey;
  if (fps >= 55) return ColorTokens.chartGreen;
  if (fps >= 30) return ColorTokens.chartAmber;
  return ColorTokens.chartRed;
}

/// Green/amber/red classification for a CPU usage percentage.
Color cpuStatusColor(double? cpu) {
  if (cpu == null) return Colors.grey;
  if (cpu <= 30) return ColorTokens.chartGreen;
  if (cpu <= 60) return ColorTokens.chartAmber;
  return ColorTokens.chartRed;
}

/// Green/amber/red classification for a single-frame time in ms.
/// `≤8` is great (120Hz target), `≤16` is OK (60Hz target).
Color frameTimeColor(double? ms) {
  if (ms == null) return Colors.grey;
  if (ms <= 8) return ColorTokens.chartGreen;
  if (ms <= 16) return ColorTokens.chartAmber;
  return ColorTokens.chartRed;
}