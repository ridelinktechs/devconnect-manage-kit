import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/performance/performance_entry.dart';
import '../../../server/providers/server_providers.dart';
import '../../../server/ws_message_handler.dart';

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
