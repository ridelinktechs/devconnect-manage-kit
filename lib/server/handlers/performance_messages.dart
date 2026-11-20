part of '../ws_message_handler.dart';

extension _PerformanceMessages on WsMessageHandler {
  void _handlePerformance(DCMessage message) {
    final p = message.payload;
    final entry = PerformanceEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      metricType: _parseMetricType(p['metricType'] as String? ?? 'fps'),
      value: (p['value'] as num?)?.toDouble() ?? 0.0,
      timestamp: message.timestamp,
      metadata: p['metadata'] as Map<String, dynamic>?,
    );
    _performanceController.add(entry);
  }

  void _handleMemoryLeak(DCMessage message) {
    final p = message.payload;
    final entry = MemoryLeakEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      leakType: _parseLeakType(p['leakType'] as String? ?? 'custom'),
      objectName: p['objectName'] as String? ?? '',
      detail: p['detail'] as String? ?? '',
      severity: _parseLeakSeverity(p['severity'] as String? ?? 'warning'),
      timestamp: message.timestamp,
      stackTrace: p['stackTrace'] as String?,
      retainedSizeBytes: p['retainedSizeBytes'] as int?,
      metadata: p['metadata'] as Map<String, dynamic>?,
    );
    _memoryLeakController.add(entry);
  }

  PerformanceMetricType _parseMetricType(String type) {
    switch (type) {
      case 'fps':
        return PerformanceMetricType.fps;
      case 'frameBuildTime':
      case 'frame_build_time':
        return PerformanceMetricType.frameBuildTime;
      case 'frameRasterTime':
      case 'frame_raster_time':
        return PerformanceMetricType.frameRasterTime;
      case 'memoryUsage':
      case 'memory_usage':
        return PerformanceMetricType.memoryUsage;
      case 'memoryPeak':
      case 'memory_peak':
        return PerformanceMetricType.memoryPeak;
      case 'memoryAllocationRate':
      case 'memory_allocation_rate':
        return PerformanceMetricType.memoryAllocationRate;
      case 'cpuUsage':
      case 'cpu_usage':
        return PerformanceMetricType.cpuUsage;
      case 'jankFrame':
      case 'jank_frame':
        return PerformanceMetricType.jankFrame;
      case 'networkActivity':
      case 'network_activity':
        return PerformanceMetricType.networkActivity;
      case 'startupTime':
      case 'startup_time':
        return PerformanceMetricType.startupTime;
      case 'batteryLevel':
      case 'battery_level':
        return PerformanceMetricType.batteryLevel;
      case 'thermalState':
      case 'thermal_state':
        return PerformanceMetricType.thermalState;
      case 'threadCount':
      case 'thread_count':
        return PerformanceMetricType.threadCount;
      case 'diskRead':
      case 'disk_read':
        return PerformanceMetricType.diskRead;
      case 'diskWrite':
      case 'disk_write':
        return PerformanceMetricType.diskWrite;
      case 'anr':
        return PerformanceMetricType.anr;
      default:
        return PerformanceMetricType.fps;
    }
  }

  MemoryLeakType _parseLeakType(String type) {
    switch (type) {
      case 'undisposedController':
        return MemoryLeakType.undisposedController;
      case 'undisposedStream':
        return MemoryLeakType.undisposedStream;
      case 'undisposedTimer':
        return MemoryLeakType.undisposedTimer;
      case 'undisposedAnimationController':
        return MemoryLeakType.undisposedAnimationController;
      case 'widgetLeak':
        return MemoryLeakType.widgetLeak;
      case 'growingCollection':
        return MemoryLeakType.growingCollection;
      default:
        return MemoryLeakType.custom;
    }
  }

  /// Per-step benchmark events. The Flutter SDK emits these between
  /// the `client:benchmark` summary start and end to mark individual
  /// checkpoints (frame samples, screen transitions). Forward each as
  /// a standalone event on the benchmark stream so the panel can
  /// render a chip timeline even before the parent summary arrives.
  void _handleBenchmarkStep(DCMessage message) {
    final p = message.payload;
    final payload = {
      'deviceId': message.deviceId,
      'benchmarkId': p['benchmarkId'] as String? ?? '',
      'title': p['title'] as String? ?? '',
      'timestamp': p['timestamp'] as int? ?? message.timestamp,
      'delta': p['delta'] as int?,
    };
    _benchmarkStepController.add(payload);
  }

  MemoryLeakSeverity _parseLeakSeverity(String severity) {
    switch (severity) {
      case 'info':
        return MemoryLeakSeverity.info;
      case 'critical':
        return MemoryLeakSeverity.critical;
      default:
        return MemoryLeakSeverity.warning;
    }
  }
}
