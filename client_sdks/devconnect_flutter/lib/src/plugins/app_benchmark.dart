import 'dart:async';

import 'package:flutter/widgets.dart';

import '../devconnect_client.dart';

bool _startupDone = false;
bool _appStateDone = false;

class AppBenchmarkOptions {
  final bool trackStartup;
  final bool trackAppState;

  const AppBenchmarkOptions({
    this.trackStartup = true,
    this.trackAppState = true,
  });
}

void setupAppBenchmark([AppBenchmarkOptions opts = const AppBenchmarkOptions()]) {
  // ---- App Startup Benchmark ----
  if (opts.trackStartup && !_startupDone) {
    _startupDone = true;
    _reportBenchmarkStart('App Startup');
    _reportBenchmarkStep('App Startup', 'Dart VM Initialized');

    // Wait for 3 frames to ensure layout is stable (similar to triple rAF in JS)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportBenchmarkStep('App Startup', 'First Frame Rendered');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _reportBenchmarkStep('App Startup', 'Fully Interactive');
          _reportBenchmarkStop('App Startup');
        });
      });
    });
  }

  // ---- App State Benchmark ----
  if (opts.trackAppState && !_appStateDone) {
    _appStateDone = true;
    WidgetsBinding.instance.addObserver(_AppBenchmarkLifecycleObserver());
  }
}

void benchmarkScreen(String screenName) {
  final title = 'Screen: $screenName';
  _reportBenchmarkStart(title);
  _reportBenchmarkStep(title, 'Component Mount');

  // Wait for 3 frames to ensure layout is stable
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _reportBenchmarkStep(title, 'First Paint');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reportBenchmarkStop(title);
      });
    });
  });
}

Future<T> benchmarkAsync<T>(String title, Future<T> Function() fn) async {
  _reportBenchmarkStart(title);
  _reportBenchmarkStep(title, 'Start');
  try {
    final result = await fn();
    _reportBenchmarkStep(title, 'Complete');
    _reportBenchmarkStop(title);
    return result;
  } catch (error) {
    _reportBenchmarkStep(title, 'Error');
    _reportBenchmarkStop(title);
    rethrow;
  }
}

// ---- Internal helpers ----

final _benchmarkStarts = <String, int>{};

void _reportBenchmarkStart(String title) {
  _benchmarkStarts[title] = DateTime.now().millisecondsSinceEpoch;
}

void _reportBenchmarkStep(String title, String step) {
  DevConnectClient.safeSend('client:benchmark:step', {
    'title': title,
    'step': step,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
}

void _reportBenchmarkStop(String title) {
  final startTime = _benchmarkStarts.remove(title);
  final endTime = DateTime.now().millisecondsSinceEpoch;
  DevConnectClient.safeSend('client:benchmark', {
    'title': title,
    'startTime': startTime ?? endTime,
    'endTime': endTime,
    'duration': startTime != null ? endTime - startTime : 0,
  });
}

class _AppBenchmarkLifecycleObserver extends WidgetsBindingObserver {
  int _backgroundTime = 0;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundTime = DateTime.now().millisecondsSinceEpoch;
      _reportBenchmarkStart('App Background');
      _reportBenchmarkStep('App Background', 'Entered Background');
    } else if (state == AppLifecycleState.resumed && _backgroundTime > 0) {
      _reportBenchmarkStep('App Background', 'Returned to Foreground');
      _reportBenchmarkStop('App Background');
      _backgroundTime = 0;
    }
  }
}
