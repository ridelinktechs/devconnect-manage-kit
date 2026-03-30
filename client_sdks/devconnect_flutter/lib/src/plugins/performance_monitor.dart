import 'dart:async';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../devconnect_client.dart';

bool _running = false;
Timer? _memoryTimer;
Timer? _cpuTimer;
Timer? _systemTimer;
bool _startupReported = false;

class PerformanceMonitorOptions {
  final int fpsInterval;
  final int memoryInterval;
  final int cpuInterval;
  final int systemInterval;
  final double jankThresholdMs;

  const PerformanceMonitorOptions({
    this.fpsInterval = 2000,
    this.memoryInterval = 5000,
    this.cpuInterval = 3000,
    this.systemInterval = 10000,
    this.jankThresholdMs = 32.0,
  });
}

final _initTime = DateTime.now();

void startPerformanceMonitor([PerformanceMonitorOptions opts = const PerformanceMonitorOptions()]) {
  if (_running) return;
  _running = true;

  // Wait for 3 frames to ensure layout is stable before tracking
  WidgetsBinding.instance.addPostFrameCallback((_) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_running) return;

        // ---- Startup Time ----
        if (!_startupReported) {
          final startupMs = DateTime.now().difference(_initTime).inMilliseconds;
          DevConnectClient.safeSend('client:performance:metric', {
            'metricType': 'startup_time',
            'value': startupMs.toDouble(),
            'label': 'App startup: ${startupMs}ms',
          });
          _startupReported = true;
        }

        // ---- Frame timing (FPS + jank + build/raster time) ----
        WidgetsBinding.instance.addTimingsCallback(_onFrameTimings);

        // ---- Memory monitor ----
        _memoryTimer = Timer.periodic(Duration(milliseconds: opts.memoryInterval), (_) {
          if (!_running) return;
          _reportMemory();
        });

        // ---- CPU monitor ----
        _cpuTimer = Timer.periodic(Duration(milliseconds: opts.cpuInterval), (_) {
          if (!_running) return;
          _reportCpu(opts.cpuInterval);
        });

        // ---- System metrics (battery, threads, disk) ----
        _reportSystemMetrics(); // Report immediately once
        _systemTimer = Timer.periodic(Duration(milliseconds: opts.systemInterval), (_) {
          if (!_running) return;
          _reportSystemMetrics();
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
  _cpuTimer?.cancel();
  _cpuTimer = null;
  _systemTimer?.cancel();
  _systemTimer = null;
  _totalBuildMs = 0;
  _totalRasterMs = 0;
  _cpuFrameCount = 0;
}

// ---- CPU estimation state ----
double _totalBuildMs = 0;
double _totalRasterMs = 0;
int _cpuFrameCount = 0;

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

    // Accumulate for CPU estimation
    _totalBuildMs += buildMs;
    _totalRasterMs += rasterMs;
    _cpuFrameCount++;

    // Report frame build time
    DevConnectClient.safeSend('client:performance:metric', {
      'metricType': 'frame_build_time',
      'value': (buildMs * 10).roundToDouble() / 10,
      'label': 'Build: ${buildMs.round()}ms',
      'metadata': {'rasterMs': rasterMs, 'totalMs': totalMs},
    });

    // Report frame raster time
    DevConnectClient.safeSend('client:performance:metric', {
      'metricType': 'frame_raster_time',
      'value': (rasterMs * 10).roundToDouble() / 10,
      'label': 'Raster: ${rasterMs.round()}ms',
    });

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

void _reportCpu(int intervalMs) {
  if (_cpuFrameCount == 0) return;
  final totalWorkMs = _totalBuildMs + _totalRasterMs;
  final usage = (totalWorkMs / intervalMs * 100).clamp(0.0, 100.0);
  DevConnectClient.safeSend('client:performance:metric', {
    'metricType': 'cpu_usage',
    'value': (usage * 10).roundToDouble() / 10,
    'label': 'UI Thread Utilization (%)',
    'metadata': {
      'buildTimeMs': (_totalBuildMs * 10).roundToDouble() / 10,
      'rasterTimeMs': (_totalRasterMs * 10).roundToDouble() / 10,
      'frames': _cpuFrameCount,
    },
  });
  _totalBuildMs = 0;
  _totalRasterMs = 0;
  _cpuFrameCount = 0;
}

// ---- Memory ----
double _lastMemoryMB = 0;

void _reportMemory() {
  try {
    double memoryMB = 0;
    String label = 'Memory (MB)';
    Map<String, dynamic> metadata = {};

    final rss = ProcessInfo.currentRss;
    if (rss > 0) {
      memoryMB = (rss / 1024 / 1024 * 10).roundToDouble() / 10;
      label = 'RSS Memory (MB)';
      metadata = {'maxRss': ProcessInfo.maxRss, 'rssBytes': rss};
    }

    if (memoryMB == 0 && Platform.isAndroid) {
      try {
        final status = File('/proc/self/status').readAsStringSync();
        final vmRss = RegExp(r'VmRSS:\s+(\d+)\s+kB').firstMatch(status);
        if (vmRss != null) {
          final kB = int.parse(vmRss.group(1)!);
          memoryMB = (kB / 1024 * 10).roundToDouble() / 10;
          label = 'VmRSS (MB)';
          final vmSize = RegExp(r'VmSize:\s+(\d+)\s+kB').firstMatch(status);
          metadata = {
            'vmRssKB': kB,
            if (vmSize != null) 'vmSizeKB': int.parse(vmSize.group(1)!),
          };
        }
      } catch (_) {}
    }

    if (memoryMB == 0) {
      final maxRss = ProcessInfo.maxRss;
      if (maxRss > 0) {
        memoryMB = (maxRss / 1024 / 1024 * 10).roundToDouble() / 10;
        label = 'Peak RSS (MB)';
        metadata = {'maxRssBytes': maxRss};
      }
    }

    if (memoryMB > 0) {
      DevConnectClient.safeSend('client:performance:metric', {
        'metricType': 'memory_usage',
        'value': memoryMB,
        'label': label,
        'metadata': metadata,
      });

      // Memory allocation rate
      if (_lastMemoryMB > 0) {
        final deltaMB = memoryMB - _lastMemoryMB;
        final ratePerSec = (deltaMB / 5.0 * 100).roundToDouble() / 100; // 5s interval
        DevConnectClient.safeSend('client:performance:metric', {
          'metricType': 'memory_allocation_rate',
          'value': ratePerSec,
          'label': '${ratePerSec >= 0 ? '+' : ''}$ratePerSec MB/s',
        });
      }
      _lastMemoryMB = memoryMB;
    }
  } catch (_) {}
}

// ---- System metrics ----
void _reportSystemMetrics() {
  // Thread count (Android via /proc/self/status)
  if (Platform.isAndroid) {
    try {
      final status = File('/proc/self/status').readAsStringSync();
      final threads = RegExp(r'Threads:\s+(\d+)').firstMatch(status);
      if (threads != null) {
        DevConnectClient.safeSend('client:performance:metric', {
          'metricType': 'thread_count',
          'value': int.parse(threads.group(1)!).toDouble(),
          'label': '${threads.group(1)} threads',
        });
      }
    } catch (_) {}

    // Disk I/O (Android via /proc/self/io)
    try {
      final io = File('/proc/self/io').readAsStringSync();
      final readBytes = RegExp(r'read_bytes:\s+(\d+)').firstMatch(io);
      final writeBytes = RegExp(r'write_bytes:\s+(\d+)').firstMatch(io);
      if (readBytes != null) {
        final mb = (int.parse(readBytes.group(1)!) / 1024 / 1024 * 10).roundToDouble() / 10;
        DevConnectClient.safeSend('client:performance:metric', {
          'metricType': 'disk_read',
          'value': mb,
          'label': 'Disk Read: $mb MB',
        });
      }
      if (writeBytes != null) {
        final mb = (int.parse(writeBytes.group(1)!) / 1024 / 1024 * 10).roundToDouble() / 10;
        DevConnectClient.safeSend('client:performance:metric', {
          'metricType': 'disk_write',
          'value': mb,
          'label': 'Disk Write: $mb MB',
        });
      }
    } catch (_) {}

    // Battery level (Android via /sys/class/power_supply/battery/)
    try {
      final capacity = File('/sys/class/power_supply/battery/capacity').readAsStringSync().trim();
      final status = File('/sys/class/power_supply/battery/status').readAsStringSync().trim();
      final level = int.tryParse(capacity);
      if (level != null) {
        DevConnectClient.safeSend('client:performance:metric', {
          'metricType': 'battery_level',
          'value': level.toDouble(),
          'label': 'Battery: $level% ($status)',
          'metadata': {'status': status},
        });
      }
    } catch (_) {}

    // Thermal (Android via thermal_zone0)
    try {
      final temp = File('/sys/class/thermal/thermal_zone0/temp').readAsStringSync().trim();
      final tempC = (int.tryParse(temp) ?? 0) / 1000.0;
      if (tempC > 0) {
        // 0=nominal, 1=fair, 2=serious, 3=critical
        final state = tempC < 35 ? 0.0 : tempC < 40 ? 1.0 : tempC < 45 ? 2.0 : 3.0;
        DevConnectClient.safeSend('client:performance:metric', {
          'metricType': 'thermal_state',
          'value': state,
          'label': 'Thermal: ${tempC.toStringAsFixed(1)}°C',
          'metadata': {'temperatureC': tempC},
        });
      }
    } catch (_) {}
  }

  // iOS — limited access from Dart, report what's available
  if (Platform.isIOS) {
    // Thread count via Isolate (main + other)
    DevConnectClient.safeSend('client:performance:metric', {
      'metricType': 'thread_count',
      'value': Platform.numberOfProcessors.toDouble(),
      'label': '${Platform.numberOfProcessors} cores',
      'metadata': {'note': 'CPU cores (thread count not available on iOS from Dart)'},
    });
  }
}
