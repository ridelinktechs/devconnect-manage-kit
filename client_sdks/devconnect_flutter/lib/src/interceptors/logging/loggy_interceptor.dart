import '../../devconnect_client.dart';

/// Loggy logger integration that sends logs to DevConnect.
///
/// This provides a LoggyPrinter-compatible class that forwards all
/// Loggy log calls to DevConnect without depending on the loggy package.
///
/// Usage:
/// ```dart
/// import 'package:loggy/loggy.dart';
///
/// // Set as the global printer:
/// Loggy.initLoggy(
///   logPrinter: DevConnect.loggyPrinter(),
/// );
/// ```
///
/// Or use alongside another printer:
/// ```dart
/// Loggy.initLoggy(
///   logPrinter: DevConnectLoggyPrinter(
///     innerPrinter: const PrettyPrinter(),
///   ),
/// );
/// ```
class DevConnectLoggyPrinter {
  /// Optional inner printer to chain. If provided, logs are forwarded
  /// to both DevConnect and the inner printer.
  final dynamic innerPrinter;

  const DevConnectLoggyPrinter({this.innerPrinter});

  /// Called by Loggy for each log record. Compatible with LoggyPrinter.onLog().
  ///
  /// The [record] parameter is a LogRecord from the loggy package, accessed
  /// via duck-typing to avoid a direct dependency.
  void onLog(dynamic record) {
    try {
      // Extract fields from LogRecord via duck-typing
      final String message = _tryGet<String?>(() => record.message?.toString()) ?? '';
      final String loggerName =
          _tryGet<String?>(() => record.loggerName?.toString()) ?? 'loggy';
      final dynamic level = _tryGet<dynamic>(() => record.level);
      final String levelName =
          _tryGet<String?>(() => level?.name?.toString().toLowerCase()) ?? 'debug';
      final dynamic error = _tryGet(() => record.error);
      final dynamic stackTrace = _tryGet(() => record.stackTrace);

      // Map loggy levels to DevConnect levels
      final String dcLevel = _mapLevel(levelName);

      // Build metadata
      final Map<String, dynamic> metadata = {};
      if (error != null) {
        metadata['error'] = error.toString();
      }

      // Send to DevConnect
      DevConnectClient.safeSendLog(
        level: dcLevel,
        message: message,
        tag: loggerName,
        stackTrace: stackTrace?.toString(),
        metadata: metadata.isNotEmpty ? metadata : null,
      );
    } catch (_) {}

    // Forward to inner printer if present
    try {
      if (innerPrinter != null) {
        innerPrinter.onLog(record);
      }
    } catch (_) {}
  }

  static String _mapLevel(String level) {
    switch (level) {
      case 'debug':
      case 'trace':
        return 'debug';
      case 'info':
        return 'info';
      case 'warning':
        return 'warn';
      case 'error':
      case 'critical':
      case 'fatal':
        return 'error';
      default:
        return 'debug';
    }
  }

  static T? _tryGet<T>(T Function() getter) {
    try {
      return getter();
    } catch (_) {
      return null;
    }
  }
}
