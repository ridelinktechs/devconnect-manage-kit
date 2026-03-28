import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/log/benchmark_entry.dart';
import '../../../server/providers/server_providers.dart';
import '../../../server/ws_message_handler.dart';

final benchmarkEntriesProvider =
    StateNotifierProvider<BenchmarkNotifier, List<BenchmarkEntry>>((ref) {
  final handler = ref.watch(wsMessageHandlerProvider);
  final notifier = BenchmarkNotifier(handler);
  ref.onDispose(() => notifier.cancelSubscription());
  return notifier;
});

final filteredBenchmarkEntriesProvider =
    Provider<List<BenchmarkEntry>>((ref) {
  final entries = ref.watch(benchmarkEntriesProvider);
  final selectedDevice = ref.watch(selectedDeviceProvider);
  final search = ref.watch(benchmarkSearchProvider).toLowerCase();

  return entries.where((e) {
    if (selectedDevice == null) return false;
    if (selectedDevice != allDevicesValue && e.deviceId != selectedDevice) return false;
    if (search.isNotEmpty && !e.title.toLowerCase().contains(search)) {
      return false;
    }
    return true;
  }).toList();
});

final benchmarkSearchProvider = StateProvider<String>((ref) => '');

/// Stats
final benchmarkStatsProvider = Provider<BenchmarkStats>((ref) {
  final entries = ref.watch(filteredBenchmarkEntriesProvider);
  if (entries.isEmpty) return const BenchmarkStats();

  final durations = entries
      .where((e) => e.duration != null)
      .map((e) => e.duration!)
      .toList();

  if (durations.isEmpty) return BenchmarkStats(total: entries.length);

  durations.sort();
  final avg = durations.reduce((a, b) => a + b) / durations.length;

  return BenchmarkStats(
    total: entries.length,
    avgDuration: avg,
    minDuration: durations.first.toDouble(),
    maxDuration: durations.last.toDouble(),
    p50Duration: durations[durations.length ~/ 2].toDouble(),
  );
});

class BenchmarkStats {
  final int total;
  final double avgDuration;
  final double minDuration;
  final double maxDuration;
  final double p50Duration;

  const BenchmarkStats({
    this.total = 0,
    this.avgDuration = 0,
    this.minDuration = 0,
    this.maxDuration = 0,
    this.p50Duration = 0,
  });
}

class BenchmarkNotifier extends StateNotifier<List<BenchmarkEntry>> {
  late final StreamSubscription<Map<String, dynamic>> _sub;

  BenchmarkNotifier(WsMessageHandler handler) : super([]) {
    _sub = handler.onBenchmark.listen((data) {
      final steps = (data['steps'] as List<dynamic>?)
              ?.map((s) => BenchmarkStep(
                    title: s['title'] as String? ?? '',
                    timestamp: s['timestamp'] as int? ?? 0,
                    delta: s['delta'] as int?,
                  ))
              .toList() ??
          [];

      final entry = BenchmarkEntry(
        id: data['id'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: data['deviceId'] as String? ?? '',
        title: data['title'] as String? ?? 'Benchmark',
        startTime: data['startTime'] as int? ?? 0,
        endTime: data['endTime'] as int?,
        duration: data['duration'] as int?,
        steps: steps,
      );

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
