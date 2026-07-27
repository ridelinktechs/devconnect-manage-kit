import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../devconnect_client.dart';

bool _running = false;

/// Rolling dedup window. SHA-256 of the trimmed top-of-stack maps to
/// `true` (already-seen) or `false` (new). When the same crash fires
/// 10 times in a row we keep reporting the first one and tag
/// subsequent reports as `{deduped: true}` so the desktop can show
/// "x12" counters without flooding the WebSocket.
final HashSet<String> _recentSignatures = HashSet<String>();
final List<String> _dedupOrder = [];
const int _maxDedupWindow = 50;

/// Tiny breadcrumb buffer. Callers (interceptors, screens, etc.)
/// push recent context events here — crash reports carry the last
/// [breadcrumbLimit] entries so the desktop can replay the trail.
final Queue<String> _breadcrumbs = Queue<String>();
const int _breadcrumbLimit = 30;

class ErrorMonitorOptions {
  final bool captureFlutterErrors;
  final bool captureDartErrors;
  final bool capturePlatformErrors;
  final int maxDedupWindow;
  final int breadcrumbLimit;

  const ErrorMonitorOptions({
    this.captureFlutterErrors = true,
    this.captureDartErrors = true,
    this.capturePlatformErrors = true,
    this.maxDedupWindow = _maxDedupWindow,
    this.breadcrumbLimit = _breadcrumbLimit,
  });
}

/// Result of `runZonedGuarded` that callers should `await` from their
/// app entrypoint. Wraps the rest of the app's main() in a guarded
/// zone so synchronous errors that escape the framework are caught.
Future<void> runAppInGuardedZone(
  Future<void> Function() body,
) async {
  await runZonedGuarded<Future<void>>(
    () async {
      await body();
    },
    (error, stack) {
      _sendError(
        platform: _getPlatform(),
        severity: 'fatal',
        message: error.toString(),
        stackTrace: stack.toString(),
        source: 'zone.async',
      );
    },
  );
}

void startErrorMonitor([ErrorMonitorOptions opts = const ErrorMonitorOptions()]) {
  if (_running) return;
  _running = true;

  // 1. Flutter framework errors (build / paint / layout).
  //    `library != null` errors come from the framework itself; treat
  //    them as `error`. Anything else is `fatal` (uncaught user code).
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
          'breadcrumbs': _breadcrumbsSnapshot(),
        },
      );
      // Still call the framework's default presenter so the red
      // banner shows in debug. In release that's a no-op.
      FlutterError.presentError(details);
    };
  }

  // 2. Async errors that escape the zone (different isolate,
  //    microtask, Future.delayed, etc.). Chained after any pre-
  //    existing handler so we never swallow behavior other libraries
  //    have installed.
  if (opts.captureDartErrors) {
    final prior = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _sendError(
        platform: _getPlatform(),
        severity: 'fatal',
        message: error.toString(),
        stackTrace: stack.toString(),
        source: 'dart.isolate',
        metadata: {'breadcrumbs': _breadcrumbsSnapshot()},
      );
      return prior?.call(error, stack) ?? true;
    };
  }

  // The legacy version called `runZonedGuarded(() {}, ...)` with an
  // empty body — entirely useless. The caller is now responsible for
  // wrapping their main() in `runAppInGuardedZone` (see docs above).
}

/// Record a contextual event to attach to the next crash report.
/// e.g. `addBreadcrumb('navigated: settings/mcp')` or
/// `addBreadcrumb('fetch failed: /users 401')`.
void addBreadcrumb(String event) {
  if (!_running) return;
  if (_breadcrumbs.length >= 30) _breadcrumbs.removeFirst();
  _breadcrumbs.addLast('${DateTime.now().toIso8601String()} $event');
}

/// Expose last [n] breadcrumbs as a list (newest first) for inclusion
/// in `metadata.breadcrumbs`.
List<String> _breadcrumbsSnapshot() {
  if (_breadcrumbs.isEmpty) return const <String>[];
  return _breadcrumbs.toList().reversed.toList();
}

/// Manually report an exception thrown from a catch block. Equivalent
/// to Sentry's `captureException()`.
void reportError(Object error, StackTrace stack, {String? source}) {
  if (!_running) return;
  _sendError(
    platform: _getPlatform(),
    severity: 'error',
    message: error.toString(),
    stackTrace: stack.toString(),
    source: source ?? 'manual',
    metadata: {'breadcrumbs': _breadcrumbsSnapshot()},
  );
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

String _getDeviceInfo() {
  try {
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  } catch (_) {
    return Platform.operatingSystem;
  }
}

/// Stable signature for dedup. We use the first 4 lines of the stack
/// (or the message itself if no stack) so signatures stay stable
/// across compilations but vary for distinct failures.
String _signature(String message, String? stack) {
  if (stack == null || stack.trim().isEmpty) {
    return 'm:${message.split('\n').first}';
  }
  final head = stack
      .split('\n')
      .where((l) => l.trim().isNotEmpty)
      .take(4)
      .join('|');
  return 's:$head';
}

bool _dedupAndTrack(String sig) {
  if (_recentSignatures.contains(sig)) return true;
  if (_dedupOrder.length >= _maxDedupWindow) {
    _recentSignatures.remove(_dedupOrder.removeAt(0));
  }
  _recentSignatures.add(sig);
  _dedupOrder.add(sig);
  return false;
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

  // Skip DevConnect internal errors — they belong in a separate
  // diagnostic pipeline (e.g. the desktop's own crash logger).
  if (message.contains('DevConnect') || message.contains('[DC_')) return;

  // Stack-trace dedup: same signature as a recently-reported crash →
  // still emit, but mark deduped:true so the desktop can roll up.
  final sig = _signature(message, stackTrace);
  final isDup = _dedupAndTrack(sig);

  try {
    DevConnectClient.safeSend('client:error', {
      'platform': platform,
      'severity': severity,
      'message': message,
      if (stackTrace != null) 'stackTrace': stackTrace,
      if (source != null) 'source': source,
      'deviceInfo': _getDeviceInfo(),
      if (metadata != null) 'metadata': metadata,
      'signature': sig,
      'deduped': isDup,
    });
  } catch (_) {
    // Encoder failure is non-fatal — never throw in error handler.
  }
}
