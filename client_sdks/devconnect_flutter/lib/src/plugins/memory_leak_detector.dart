import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../devconnect_client.dart';

bool _running = false;
Timer? _checkTimer;
final List<double> _heapSnapshots = [];

class MemoryLeakDetectorOptions {
  final int checkInterval;
  final double heapGrowthThresholdMB;
  final int maxSnapshots;

  const MemoryLeakDetectorOptions({
    this.checkInterval = 10000,
    this.heapGrowthThresholdMB = 20.0,
    this.maxSnapshots = 10,
  });
}

void startMemoryLeakDetector([MemoryLeakDetectorOptions opts = const MemoryLeakDetectorOptions()]) {
  if (_running) return;
  _running = true;

  // ---- Track app lifecycle for background detection ----
  WidgetsBinding.instance.addObserver(_MemoryLeakLifecycleObserver(opts));

  // ---- Periodic heap growth check ----
  _checkTimer = Timer.periodic(Duration(milliseconds: opts.checkInterval), (_) {
    if (!_running) return;
    _checkHeapGrowth(opts.heapGrowthThresholdMB, opts.maxSnapshots);
  });
}

void stopMemoryLeakDetector() {
  _running = false;
  _checkTimer?.cancel();
  _checkTimer = null;
  _heapSnapshots.clear();
}

void _checkHeapGrowth(double thresholdMB, int maxSnapshots) {
  double? heapMB;

  try {
    final rss = ProcessInfo.currentRss;
    if (rss > 0) {
      heapMB = rss / 1024 / 1024;
    }
  } catch (_) {}

  if (heapMB == null) return;

  _heapSnapshots.add(heapMB);
  if (_heapSnapshots.length > maxSnapshots) {
    _heapSnapshots.removeAt(0);
  }

  // Detect consistent growth
  if (_heapSnapshots.length >= 3) {
    final first = _heapSnapshots.first;
    final last = _heapSnapshots.last;
    final growth = last - first;

    bool isGrowing = true;
    for (int i = 1; i < _heapSnapshots.length; i++) {
      if (_heapSnapshots[i] <= _heapSnapshots[i - 1]) {
        isGrowing = false;
        break;
      }
    }

    if (isGrowing && growth > thresholdMB) {
      DevConnectClient.safeSend('client:memory:leak', {
        'leakType': 'growing_collection',
        'severity': growth > thresholdMB * 2 ? 'critical' : 'warning',
        'objectName': 'Dart Heap',
        'detail':
            'Memory grew ${growth.round()}MB over ${_heapSnapshots.length} samples (${first.round()}MB → ${last.round()}MB)',
        'retainedSizeBytes': (growth * 1024 * 1024).round(),
        'metadata': {
          'snapshots': _heapSnapshots.map((s) => (s * 10).roundToDouble() / 10).toList(),
          'growthMB': (growth * 10).roundToDouble() / 10,
        },
      });
    }
  }
}

class _MemoryLeakLifecycleObserver extends WidgetsBindingObserver {
  final MemoryLeakDetectorOptions opts;
  _MemoryLeakLifecycleObserver(this.opts);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _checkHeapGrowth(opts.heapGrowthThresholdMB, opts.maxSnapshots);
    }
  }
}
