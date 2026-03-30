import 'package:freezed_annotation/freezed_annotation.dart';

part 'performance_entry.freezed.dart';
part 'performance_entry.g.dart';

/// A single performance metric sample (FPS, CPU, memory, frame time, etc.)
@freezed
abstract class PerformanceEntry with _$PerformanceEntry {
  const factory PerformanceEntry({
    required String id,
    required String deviceId,
    required PerformanceMetricType metricType,
    required double value,
    required int timestamp,
    Map<String, dynamic>? metadata,
  }) = _PerformanceEntry;

  factory PerformanceEntry.fromJson(Map<String, dynamic> json) =>
      _$PerformanceEntryFromJson(json);
}

enum PerformanceMetricType {
  fps,
  frameBuildTime,
  frameRasterTime,
  memoryUsage,
  memoryPeak,
  memoryAllocationRate,
  cpuUsage,
  jankFrame,
  networkActivity,
  startupTime,
  batteryLevel,
  thermalState,
  threadCount,
  diskRead,
  diskWrite,
  anr,
}

/// A memory leak warning detected by the SDK
@freezed
abstract class MemoryLeakEntry with _$MemoryLeakEntry {
  const factory MemoryLeakEntry({
    required String id,
    required String deviceId,
    required MemoryLeakType leakType,
    required String objectName,
    required String detail,
    required MemoryLeakSeverity severity,
    required int timestamp,
    String? stackTrace,
    int? retainedSizeBytes,
    Map<String, dynamic>? metadata,
  }) = _MemoryLeakEntry;

  factory MemoryLeakEntry.fromJson(Map<String, dynamic> json) =>
      _$MemoryLeakEntryFromJson(json);
}

enum MemoryLeakType {
  undisposedController,
  undisposedStream,
  undisposedTimer,
  undisposedAnimationController,
  widgetLeak,
  growingCollection,
  custom,
}

enum MemoryLeakSeverity {
  info,
  warning,
  critical,
}
