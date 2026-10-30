import '../../devconnect_client.dart';

/// Convenience class for logging to DevConnect.
///
/// Usage:
/// ```dart
/// final logger = DevConnectLogger(tag: 'AuthService');
/// logger.info('User logged in');
/// logger.error('Login failed', stackTrace: StackTrace.current.toString());
/// ```
class DevConnectLogger {
  final String? tag;

  const DevConnectLogger({this.tag});

  void debug(String message, {Map<String, dynamic>? metadata}) {
    DevConnectClient.safeSendLog(level: 'debug', message: message, tag: tag, metadata: metadata);
  }

  void info(String message, {Map<String, dynamic>? metadata}) {
    DevConnectClient.safeLog(message, tag: tag, metadata: metadata);
  }

  void warn(String message, {Map<String, dynamic>? metadata}) {
    DevConnectClient.safeSendLog(level: 'warn', message: message, tag: tag, metadata: metadata);
  }

  void error(String message,
      {String? stackTrace, Map<String, dynamic>? metadata}) {
    DevConnectClient.safeSendLog(level: 'error', message: message, tag: tag, stackTrace: stackTrace, metadata: metadata);
  }
}
