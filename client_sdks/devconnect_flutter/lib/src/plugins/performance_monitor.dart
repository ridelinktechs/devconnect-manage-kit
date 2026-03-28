import 'dart:async';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../devconnect_client.dart';

bool _running = false;
Timer? _memoryTimer;

class PerformanceMonitorOptions {
  final int fpsInterval;
  final int memoryInterval;
  final double jankThresholdMs;

  const PerformanceMonitorOptions({
    this.fpsInterval = 2000,
    this.memoryInterval = 5000,
    this.jankThresholdMs = 32.0,
  });
}

void startPerformanceMonitor([PerformanceMonitorOptions opts = const PerformanceMonitorOptions()]) {
  if (_running) return;
  _running = true;

  // Wait for 3 frames to ensure layout is stable before tracking
  WidgetsBinding.instance.addPostFrameCallback((_) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_running) return;

        // ---- Frame timing (FPS + jank) ----
        WidgetsBinding.instance.addTimingsCallback(_onFrameTimings);

        // ---- Memory monitor ----
        _memoryTimer = Timer.periodic(Duration(milliseconds: opts.memoryInterval), (_) {
          if (!_running) return;
          _reportMemory();
        });
      });
    });
  });
}

void stopPerformanceMonitor() {
  _running = false;
  WidgetsBinding.instance.removeTimingsCallback(_onFrameTimings);
  _memoryTimer?.cancel();
  _memoryTimer = null;
}

// ---- Frame timing callback ----
int _frameCount = 0;
int _lastFpsReport = 0;
const _fpsReportInterval = 2000; // ms

void _onFrameTimings(List<FrameTiming> timings) {
  if (!_running) return;

  final now = DateTime.now().millisecondsSinceEpoch;
  if (_lastFpsReport == 0) _lastFpsReport = now;

  for (final timing in timings) {
    _frameCount++;

    final buildMs = timing.buildDuration.inMicroseconds / 1000.0;
    final rasterMs = timing.rasterDuration.inMicroseconds / 1000.0;
    final totalMs = timing.totalSpan.inMicroseconds / 1000.0;

    // Detect jank
    if (totalMs > 32.0) {
      DevConnectClient.safeSend('client:performance:metric', {
        'metricType': 'jank_frame',
        'value': (totalMs * 10).roundToDouble() / 10,
        'label': 'Slow frame: ${totalMs.round()}ms (build: ${buildMs.round()}ms, raster: ${rasterMs.round()}ms)',
        'metadata': {
          'buildDuration': buildMs,
          'rasterDuration': rasterMs,
        },
      });
    }
  }

  // Report FPS periodically
  final elapsed = now - _lastFpsReport;
  if (elapsed >= _fpsReportInterval) {
    final fps = (_frameCount / elapsed * 1000 * 10).roundToDouble() / 10;
    DevConnectClient.safeSend('client:performance:metric', {
      'metricType': 'fps',
      'value': fps,
      'label': 'UI Thread FPS',
    });
    _frameCount = 0;
    _lastFpsReport = now;
  }
}

void _reportMemory() {
  // Dart VM memory info via ProcessInfo
  try {
    final rss = ProcessInfo.currentRss;
    final maxRss = ProcessInfo.maxRss;
    if (rss > 0) {
      DevConnectClient.safeSend('client:performance:metric', {
        'metricType': 'memory_usage',
        'value': (rss / 1024 / 1024 * 10).roundToDouble() / 10,
        'label': 'RSS Memory (MB)',
        'metadata': {
          'maxRss': maxRss,
          'rssBytes': rss,
        },
      });
    }
  } catch (_) {}
}
