import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/network/network_entry.dart';
import '../../../models/performance/performance_entry.dart';
import '../../../server/providers/server_providers.dart';
import '../../../server/ws_message_handler.dart';
import '../../network_inspector/provider/network_providers.dart';

// ---- Performance Metrics ----

final performanceEntriesProvider =
    StateNotifierProvider<PerformanceNotifier, List<PerformanceEntry>>((ref) {
  final handler = ref.watch(wsMessageHandlerProvider);
  final notifier = PerformanceNotifier(handler);
  ref.onDispose(() => notifier.cancelSubscription());
  return notifier;
});

final filteredPerformanceEntriesProvider =
    Provider<List<PerformanceEntry>>((ref) {
  final entries = ref.watch(performanceEntriesProvider);
  final selectedDevice = ref.watch(selectedDeviceProvider);
  final metricFilter = ref.watch(performanceMetricFilterProvider);

  return entries.where((e) {
    if (selectedDevice == null) return false;
    if (selectedDevice != allDevicesValue && e.deviceId != selectedDevice) return false;
    if (metricFilter != null && e.metricType != metricFilter) return false;
    return true;
  }).toList();
});

final performanceMetricFilterProvider =
    StateProvider<PerformanceMetricType?>((ref) => null);

/// Latest FPS value
final latestFpsProvider = Provider<double?>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  final fps = entries.where((e) => e.metricType == PerformanceMetricType.fps);
  return fps.isEmpty ? null : fps.last.value;
});

/// Latest memory usage in MB
final latestMemoryProvider = Provider<double?>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  final mem =
      entries.where((e) => e.metricType == PerformanceMetricType.memoryUsage);
  return mem.isEmpty ? null : mem.last.value;
});

/// Latest CPU usage percentage
final latestCpuProvider = Provider<double?>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  final cpu =
      entries.where((e) => e.metricType == PerformanceMetricType.cpuUsage);
  return cpu.isEmpty ? null : cpu.last.value;
});

/// FPS history for chart
final fpsHistoryProvider = Provider<List<PerformanceEntry>>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  return entries
      .where((e) => e.metricType == PerformanceMetricType.fps)
      .toList();
});

/// Memory history for chart
final memoryHistoryProvider = Provider<List<PerformanceEntry>>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  return entries
      .where((e) => e.metricType == PerformanceMetricType.memoryUsage)
      .toList();
});

/// CPU history for chart
final cpuHistoryProvider = Provider<List<PerformanceEntry>>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  return entries
      .where((e) => e.metricType == PerformanceMetricType.cpuUsage)
      .toList();
});

/// Jank frame count
final jankFrameCountProvider = Provider<int>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  return entries
      .where((e) => e.metricType == PerformanceMetricType.jankFrame)
      .length;
});

// ---- Frame Timing ----

/// Frame build time history
final frameBuildTimeHistoryProvider = Provider<List<PerformanceEntry>>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  return entries
      .where((e) => e.metricType == PerformanceMetricType.frameBuildTime)
      .toList();
});

/// Frame raster time history
final frameRasterTimeHistoryProvider = Provider<List<PerformanceEntry>>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  return entries
      .where((e) => e.metricType == PerformanceMetricType.frameRasterTime)
      .toList();
});

// ---- Startup Time ----

final startupTimeProvider = Provider<double?>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  final startup = entries.where((e) => e.metricType == PerformanceMetricType.startupTime);
  return startup.isEmpty ? null : startup.first.value;
});

// ---- Battery & Thermal ----

final latestBatteryProvider = Provider<double?>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  final bat = entries.where((e) => e.metricType == PerformanceMetricType.batteryLevel);
  return bat.isEmpty ? null : bat.last.value;
});

final latestBatteryEntryProvider = Provider<PerformanceEntry?>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  final bat = entries.where((e) => e.metricType == PerformanceMetricType.batteryLevel);
  return bat.isEmpty ? null : bat.last;
});

/// Battery history for chart
final batteryHistoryProvider = Provider<List<PerformanceEntry>>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  return entries
      .where((e) => e.metricType == PerformanceMetricType.batteryLevel)
      .toList();
});

/// Battery drain rate (%/min) — calculated from battery history
final batteryDrainRateProvider = Provider<double?>((ref) {
  final history = ref.watch(batteryHistoryProvider);
  if (history.length < 2) return null;

  // Compare first and last battery readings
  final first = history.first;
  final last = history.last;
  final durationMin = (last.timestamp - first.timestamp) / 60000.0;
  if (durationMin < 0.5) return null; // Need at least 30s of data

  final drainPct = first.value - last.value; // Positive = draining
  final ratePerMin = drainPct / durationMin;
  return (ratePerMin * 100).roundToDouble() / 100;
});

/// Estimated battery time remaining (minutes)
final batteryTimeRemainingProvider = Provider<double?>((ref) {
  final battery = ref.watch(latestBatteryProvider);
  final drainRate = ref.watch(batteryDrainRateProvider);
  if (battery == null || drainRate == null || drainRate <= 0) return null;
  return battery / drainRate; // minutes remaining
});

final latestThermalProvider = Provider<double?>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  final th = entries.where((e) => e.metricType == PerformanceMetricType.thermalState);
  return th.isEmpty ? null : th.last.value;
});

final latestThermalEntryProvider = Provider<PerformanceEntry?>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  final th = entries.where((e) => e.metricType == PerformanceMetricType.thermalState);
  return th.isEmpty ? null : th.last;
});

// ---- Thread Count ----

final latestThreadCountProvider = Provider<int?>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  final tc = entries.where((e) => e.metricType == PerformanceMetricType.threadCount);
  return tc.isEmpty ? null : tc.last.value.toInt();
});

final threadCountHistoryProvider = Provider<List<PerformanceEntry>>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  return entries
      .where((e) => e.metricType == PerformanceMetricType.threadCount)
      .toList();
});

// ---- Disk I/O ----

final latestDiskReadProvider = Provider<double?>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  final dr = entries.where((e) => e.metricType == PerformanceMetricType.diskRead);
  return dr.isEmpty ? null : dr.last.value;
});

final latestDiskWriteProvider = Provider<double?>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  final dw = entries.where((e) => e.metricType == PerformanceMetricType.diskWrite);
  return dw.isEmpty ? null : dw.last.value;
});

// ---- Memory Allocation Rate ----

final latestMemAllocRateProvider = Provider<double?>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  final rate = entries.where((e) => e.metricType == PerformanceMetricType.memoryAllocationRate);
  return rate.isEmpty ? null : rate.last.value;
});

// ---- ANR ----

final anrCountProvider = Provider<int>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  return entries
      .where((e) => e.metricType == PerformanceMetricType.anr)
      .length;
});

final anrEntriesProvider = Provider<List<PerformanceEntry>>((ref) {
  final entries = ref.watch(filteredPerformanceEntriesProvider);
  return entries
      .where((e) => e.metricType == PerformanceMetricType.anr)
      .toList();
});

// ---- Network Activity for Profiler ----

/// Estimate body size in bytes from content-length header or body string
int _estimateBodySize(dynamic body, Map<String, String> headers) {
  // Try Content-Length header first
  final cl = headers['content-length'] ?? headers['Content-Length'];
  if (cl != null) {
    final parsed = int.tryParse(cl);
    if (parsed != null && parsed > 0) return parsed;
  }
  // Fallback: estimate from body
  if (body == null) return 0;
  if (body is String) return body.length;
  return body.toString().length;
}

/// Network download speed (bytes/sec, rolling 10s window)
final networkDownloadSpeedProvider = Provider<double>((ref) {
  final entries = ref.watch(networkEntriesProvider);
  final selectedDevice = ref.watch(selectedDeviceProvider);
  final now = DateTime.now().millisecondsSinceEpoch;
  const windowMs = 10000;

  int totalBytes = 0;
  for (final e in entries) {
    if (selectedDevice == null) continue;
    if (selectedDevice != allDevicesValue && e.deviceId != selectedDevice) continue;
    if (!e.isComplete) continue;
    if (e.endTime == null || (now - e.endTime!) > windowMs) continue;
    totalBytes += _estimateBodySize(e.responseBody, e.responseHeaders);
  }
  return totalBytes / (windowMs / 1000);
});

/// Network upload speed (bytes/sec, rolling 10s window)
final networkUploadSpeedProvider = Provider<double>((ref) {
  final entries = ref.watch(networkEntriesProvider);
  final selectedDevice = ref.watch(selectedDeviceProvider);
  final now = DateTime.now().millisecondsSinceEpoch;
  const windowMs = 10000;

  int totalBytes = 0;
  for (final e in entries) {
    if (selectedDevice == null) continue;
    if (selectedDevice != allDevicesValue && e.deviceId != selectedDevice) continue;
    if (!e.isComplete) continue;
    if (e.endTime == null || (now - e.endTime!) > windowMs) continue;
    totalBytes += _estimateBodySize(e.requestBody, e.requestHeaders);
  }
  return totalBytes / (windowMs / 1000);
});

/// Active (in-flight) requests count
final activeNetworkRequestsProvider = Provider<int>((ref) {
  final entries = ref.watch(networkEntriesProvider);
  final selectedDevice = ref.watch(selectedDeviceProvider);
  return entries.where((e) {
    if (selectedDevice == null) return false;
    if (selectedDevice != allDevicesValue && e.deviceId != selectedDevice) return false;
    return !e.isComplete;
  }).length;
});

/// Network requests per second (rolling window)
final networkRequestsPerSecondProvider = Provider<double>((ref) {
  final entries = ref.watch(networkEntriesProvider);
  final selectedDevice = ref.watch(selectedDeviceProvider);
  final now = DateTime.now().millisecondsSinceEpoch;
  final windowMs = 10000; // 10 second window
  final recent = entries.where((e) {
    if (selectedDevice == null) return false;
    if (selectedDevice != allDevicesValue && e.deviceId != selectedDevice) return false;
    return (now - e.startTime) < windowMs;
  }).length;
  return (recent / (windowMs / 1000) * 10).roundToDouble() / 10;
});

/// Network history: completed requests with duration for chart
final networkHistoryProvider = Provider<List<NetworkEntry>>((ref) {
  final entries = ref.watch(networkEntriesProvider);
  final selectedDevice = ref.watch(selectedDeviceProvider);
  return entries.where((e) {
    if (selectedDevice == null) return false;
    if (selectedDevice != allDevicesValue && e.deviceId != selectedDevice) return false;
    return e.isComplete && e.duration != null;
  }).toList();
});

/// Average response time (last 50 requests)
final avgResponseTimeProvider = Provider<double?>((ref) {
  final history = ref.watch(networkHistoryProvider);
  if (history.isEmpty) return null;
  final recent = history.length > 50 ? history.sublist(history.length - 50) : history;
  final total = recent.fold<double>(0, (sum, e) => sum + (e.duration ?? 0).toDouble());
  return total / recent.length;
});

/// Error rate percentage (last 100 requests)
final networkErrorRateProvider = Provider<double>((ref) {
  final history = ref.watch(networkHistoryProvider);
  if (history.isEmpty) return 0;
  final recent = history.length > 100 ? history.sublist(history.length - 100) : history;
  final errors = recent.where((e) => e.statusCode >= 400 || e.error != null).length;
  return (errors / recent.length * 100 * 10).roundToDouble() / 10;
});

class PerformanceNotifier extends StateNotifier<List<PerformanceEntry>> {
  late final StreamSubscription<PerformanceEntry> _sub;

  PerformanceNotifier(WsMessageHandler handler) : super([]) {
    _sub = handler.onPerformance.listen((entry) {
      if (state.length > 10000) {
        state = [...state.skip(1000), entry];
      } else {
        state = [...state, entry];
      }
    });
  }

  void cancelSubscription() => _sub.cancel();
  void clear() => state = [];
}

// ---- Memory Leak Detection ----

final memoryLeakEntriesProvider =
    StateNotifierProvider<MemoryLeakNotifier, List<MemoryLeakEntry>>((ref) {
  final handler = ref.watch(wsMessageHandlerProvider);
  final notifier = MemoryLeakNotifier(handler);
  ref.onDispose(() => notifier.cancelSubscription());
  return notifier;
});

final memoryLeakFilterProvider =
    StateProvider<MemoryLeakSeverity?>((ref) => null);

final filteredMemoryLeakEntriesProvider =
    Provider<List<MemoryLeakEntry>>((ref) {
  final entries = ref.watch(memoryLeakEntriesProvider);
  final selectedDevice = ref.watch(selectedDeviceProvider);
  final severityFilter = ref.watch(memoryLeakFilterProvider);

  return entries.where((e) {
    if (selectedDevice == null) return false;
    if (selectedDevice != allDevicesValue && e.deviceId != selectedDevice) return false;
    if (severityFilter != null && e.severity != severityFilter) return false;
    return true;
  }).toList();
});

/// Count by severity
final memoryLeakCountsProvider =
    Provider<Map<MemoryLeakSeverity, int>>((ref) {
  final entries = ref.watch(filteredMemoryLeakEntriesProvider);
  return {
    MemoryLeakSeverity.critical:
        entries.where((e) => e.severity == MemoryLeakSeverity.critical).length,
    MemoryLeakSeverity.warning:
        entries.where((e) => e.severity == MemoryLeakSeverity.warning).length,
    MemoryLeakSeverity.info:
        entries.where((e) => e.severity == MemoryLeakSeverity.info).length,
  };
});

class MemoryLeakNotifier extends StateNotifier<List<MemoryLeakEntry>> {
  late final StreamSubscription<MemoryLeakEntry> _sub;

  MemoryLeakNotifier(WsMessageHandler handler) : super([]) {
    _sub = handler.onMemoryLeak.listen((entry) {
      if (state.length > 5000) {
        state = [...state.skip(500), entry];
      } else {
        state = [...state, entry];
      }
    });
  }

  void cancelSubscription() => _sub.cancel();
  void clear() => state = [];
}
