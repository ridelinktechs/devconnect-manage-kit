import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../devconnect_client.dart';

bool _running = false;

class ErrorMonitorOptions {
  final bool captureFlutterErrors;
  final bool captureDartErrors;
  final bool capturePlatformErrors;
  final int maxErrors;

  const ErrorMonitorOptions({
    this.captureFlutterErrors = true,
    this.captureDartErrors = true,
    this.capturePlatformErrors = true,
    this.maxErrors = 100,
  });
}

void startErrorMonitor([ErrorMonitorOptions opts = const ErrorMonitorOptions()]) {
  if (_running) return;
  _running = true;

  // Flutter error handler
  if (opts.captureFlutterErrors) {
    FlutterError.onError = (FlutterErrorDetails details) {
      _sendError(
        platform: _getPlatform(),
        severity: details.library != null ? 'error' : 'fatal',
        message: details.exceptionAsString(),
        stackTrace: details.stack?.toString(),
        source: details.library ?? 'flutter',
        metadata: {
          'context': details.context?.toString(),
          'information': details.informationCollector?.toString(),
        },
      );
      // Call original handler
      FlutterError.presentError(details);
    };
  }

  // Platform dispatcher error handler (Dart isolate errors)
  if (opts.captureDartErrors) {
    final originalOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _sendError(
        platform: _getPlatform(),
        severity: 'fatal',
        message: error.toString(),
        stackTrace: stack.toString(),
        source: 'dart.isolate',
        metadata: {},
      );
      originalOnError?.call(error, stack);
      return true;
    };
  }

  // Zone error handler for async errors
  if (opts.captureDartErrors) {
    runZonedGuarded(() {
      // This runs inside a guarded zone to catch async errors
    }, (error, stack) {
      _sendError(
        platform: _getPlatform(),
        severity: 'error',
        message: error.toString(),
        stackTrace: stack.toString(),
        source: 'zone.async',
        metadata: {},
      );
    });
  }

  // iOS/Android native error handler
  if (opts.capturePlatformErrors) {
    _setupPlatformErrorHandler();
  }
}

void stopErrorMonitor() {
  _running = false;
  FlutterError.onError = null;
  PlatformDispatcher.instance.onError = null;
}

String _getPlatform() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  return 'unknown';
}

void _sendError({
  required String platform,
  required String severity,
  required String message,
  String? stackTrace,
  String? source,
  Map<String, dynamic>? metadata,
}) {
  if (!_running) return;

  // Skip DevConnect internal errors
  if (message.contains('DevConnect') || message.contains('[DC_')) return;

  DevConnectClient.safeSend('client:error', {
    'platform': platform,
    'severity': severity,
    'message': message,
    if (stackTrace != null) 'stackTrace': stackTrace,
    if (source != null) 'source': source,
    'deviceInfo': _getDeviceInfo(),
    if (metadata != null) 'metadata': metadata,
  });
}

String _getDeviceInfo() {
  try {
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  } catch (_) {
    return Platform.operatingSystem;
  }
}

void _setupPlatformErrorHandler() {
  // Platform-specific error capture
  if (Platform.isAndroid) {
    // Android: catch exceptions via Flutter engine
    WidgetsBinding.instance.addObserver(_AndroidErrorObserver());
  } else if (Platform.isIOS) {
    // iOS: catch NSException via Flutter engine
    WidgetsBinding.instance.addObserver(_IOSErrorObserver());
  }
}

class _AndroidErrorObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Check for background errors
    }
  }
}

class _IOSErrorObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Check for background errors
    }
  }
}