import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../devconnect_client.dart';

/// Wraps a [WebSocket] from `dart:io` to emit `client:ws_frame` events
/// on every frame.
///
/// Most callers don't need to construct this directly — use the static
/// [DevConnectWebSocket.connect] helper which returns a wrapped socket:
///
/// ```dart
/// final socket = await DevConnectWebSocket.connect('wss://api.example.com/ws');
/// socket.add('subscribe');
/// await for (final frame in socket.frames) {
///   print(frame);
/// }
/// ```
///
/// Consumers needing an `IOWebSocket` directly can wrap with
/// [DevConnectWebSocket.wrap] after `WebSocket.connect`.
class DevConnectWebSocket {
  final WebSocket _inner;
  final String _url;
  final DateTime _openedAt;

  DevConnectWebSocket._(this._inner, this._url) : _openedAt = DateTime.now() {
    _emitOpen();
  }

  /// Build a wrapper around an existing [WebSocket].
  factory DevConnectWebSocket.wrap(WebSocket socket, String url) =>
      DevConnectWebSocket._(socket, url);

  /// Connect to [url] and return a wrapped [DevConnectWebSocket].
  static Future<DevConnectWebSocket> connect(String url,
      {Iterable<String>? protocols, Map<String, dynamic>? headers}) async {
    final raw = await WebSocket.connect(url, protocols: protocols, headers: headers);
    return DevConnectWebSocket._(raw, url);
  }

  /// The underlying dart:io WebSocket. Use when you need raw access.
  WebSocket get inner => _inner;

  /// Stream of frames (a frame is `{direction, opcode, payload, timestamp}`).
  Stream<Map<String, dynamic>> get frames async* {
    await for (final data in _inner) {
      final frame = _frameFromReceive(data);
      try {
        DevConnectClient.safeSend('client:ws_frame', frame);
      } catch (_) {}
      yield frame;
    }
  }

  /// Listen to the raw stream (delegates to inner).
  StreamSubscription listen(void Function(dynamic)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _inner.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  /// Send a text frame or binary frame.
  void add(dynamic data) {
    final opcode = data is String ? 'text' : 'binary';
    final sizeBytes = data is String
        ? utf8.encode(data).length
        : (data is List<int> ? data.length : data.toString().length);
    try {
      DevConnectClient.safeSend('client:ws_frame', {
        'url': _url,
        'direction': 'send',
        'opcode': opcode,
        'sizeBytes': sizeBytes,
        if (opcode == 'text') 'payload': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
    _inner.add(data);
  }

  /// Close the socket.
  Future<void> close([int? code, String? reason]) => _inner.close(code, reason);

  // ---- Pass-through getters ----
  String? get protocol => _inner.protocol;
  int? get closeCode => _inner.closeCode;
  String? get closeReason => _inner.closeReason;

  void _emitOpen() {
    try {
      DevConnectClient.safeSend('client:ws_open', {
        'url': _url,
        'openedAt': _openedAt.millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  Map<String, dynamic> _frameFromReceive(dynamic data) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (data is String) {
      return {
        'url': _url,
        'direction': 'receive',
        'opcode': 'text',
        'payload': data,
        'sizeBytes': utf8.encode(data).length,
        'timestamp': timestamp,
      };
    } else {
      final bytes = data is List<int> ? data : data.toString().codeUnits;
      return {
        'url': _url,
        'direction': 'receive',
        'opcode': 'binary',
        'sizeBytes': bytes.length,
        'payload': '<binary ${bytes.length} bytes>',
        'timestamp': timestamp,
      };
    }
  }
}

/// Static helpers for consumers who want to push WebSocket events from
/// their own code (e.g. when not using the wrapped class).
class DevConnectWebSocketHelper {
  DevConnectWebSocketHelper._();

  static void reportOpen(String url) {
    try {
      DevConnectClient.safeSend('client:ws_open', {
        'url': url,
        'openedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  static void reportFrame({
    required String url,
    required String direction, // 'send' | 'receive'
    required String opcode, // 'text' | 'binary' | 'ping' | 'pong' | 'close'
    dynamic payload,
    int? sizeBytes,
  }) {
    try {
      DevConnectClient.safeSend('client:ws_frame', {
        'url': url,
        'direction': direction,
        'opcode': opcode,
        if (payload != null) 'payload': payload,
        if (sizeBytes != null) 'sizeBytes': sizeBytes,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  static void reportClose(String url, {int? code, String? reason}) {
    try {
      DevConnectClient.safeSend('client:ws_close', {
        'url': url,
        if (code != null) 'code': code,
        if (reason != null) 'reason': reason,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }
}