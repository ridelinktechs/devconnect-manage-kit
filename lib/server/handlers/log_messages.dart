part of '../ws_message_handler.dart';

extension _LogMessages on WsMessageHandler {
  void _handleLog(DCMessage message) {
    final entry = LogEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      level: _parseLogLevel(message.payload['level'] as String? ?? 'info'),
      message: message.payload['message'] as String? ?? '',
      timestamp: message.timestamp,
      metadata: message.payload['metadata'] as Map<String, dynamic>?,
      stackTrace: message.payload['stackTrace'] as String?,
      tag: message.payload['tag'] as String?,
    );
    _logController.add(entry);
  }

  LogLevel _parseLogLevel(String level) {
    switch (level.toLowerCase()) {
      case 'debug':
        return LogLevel.debug;
      case 'warn':
      case 'warning':
        return LogLevel.warn;
      case 'error':
        return LogLevel.error;
      default:
        return LogLevel.info;
    }
  }

  void _handleError(DCMessage message) {
    final p = message.payload;
    final entry = ErrorEvent(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      platform: _parseErrorPlatform(p['platform'] as String? ?? 'js'),
      severity: _parseErrorSeverity(p['severity'] as String? ?? 'error'),
      message: p['message'] as String? ?? '',
      timestamp: message.timestamp,
      stackTrace: p['stackTrace'] as String?,
      source: p['source'] as String?,
      deviceInfo: p['deviceInfo'] as String?,
      metadata: p['metadata'] as Map<String, dynamic>?,
    );
    _errorController.add(entry);
  }

  /// Decode and cache a source map. RN bundlers ship `.map` files at
  /// production build time; the SDK uploads them once per bundle/build
  /// and the desktop uses the cached JSON to symbolicate minified
  /// stack frames in the Errors tab.
  void _handleSourceMap(DCMessage message) {
    final p = message.payload;
    final mapId = p['mapId'] as String?;
    final raw = p['map'];
    if (mapId == null || mapId.isEmpty || raw == null) return;
    if (_sourceMaps.containsKey(mapId)) return;
    final decoded = raw is Map
        ? raw.cast<String, dynamic>()
        : _tryDecodeMapString(raw);
    if (decoded == null) return;
    _sourceMaps[mapId] = decoded;
    _trimSourceMaps();
  }

  /// A few SDKs stringify the map before sending; recover it lazily
  /// so the wire format stays flexible.
  Map<String, dynamic>? _tryDecodeMapString(dynamic raw) {
    if (raw is! String) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
    return null;
  }

  void _trimSourceMaps() {
    if (_sourceMaps.length <= 32) return;
    final drop = _sourceMaps.length - 16;
    final keys = _sourceMaps.keys.toList(growable: false);
    for (var i = 0; i < drop; i++) {
      _sourceMaps.remove(keys[i]);
    }
  }

  ErrorPlatform _parseErrorPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return ErrorPlatform.android;
      case 'ios':
        return ErrorPlatform.ios;
      case 'native':
        return ErrorPlatform.native;
      default:
        return ErrorPlatform.js;
    }
  }

  ErrorSeverity _parseErrorSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'fatal':
        return ErrorSeverity.fatal;
      case 'crash':
        return ErrorSeverity.crash;
      case 'warning':
        return ErrorSeverity.warning;
      case 'info':
        return ErrorSeverity.info;
      default:
        return ErrorSeverity.error;
    }
  }
}
