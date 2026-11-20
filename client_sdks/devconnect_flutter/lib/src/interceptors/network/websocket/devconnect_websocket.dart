import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../../../devconnect_client.dart';

/// Wraps a [WebSocket] from `dart:io` so its traffic shows up in the
/// DevConnect WebSocket inspector: `client:ws_open`, a `client:ws_frame`
/// per frame sent or received, and exactly one `client:ws_close`.
///
/// ```dart
/// final socket = await DevConnectWebSocket.connect('wss://api.example.com/ws');
/// socket.listen((message) => print(message));
/// socket.add('subscribe');
/// await socket.close(1000, 'bye');
/// ```
///
/// Read incoming messages through the wrapper (`listen`, `await for`,
/// [frames]); listening to [inner] directly bypasses the capture.
class DevConnectWebSocket extends Stream<dynamic> {
  final WebSocket _inner;
  final String url;

  /// Groups this connection's events on the desktop.
  final String connectionId = const Uuid().v4();
  bool _closeReported = false;

  DevConnectWebSocket._(this._inner, this.url) {
    DevConnectClient.safeSend(
        'client:ws_open', {'connectionId': connectionId, 'url': url});
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

  /// Received messages, each reported as a `receive` frame. The stream
  /// ending (or failing) reports the close.
  @override
  StreamSubscription<dynamic> listen(void Function(dynamic)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _inner
          .transform(StreamTransformer<dynamic, dynamic>.fromHandlers(
            handleData: (data, sink) {
              _reportFrame('receive', data);
              sink.add(data);
            },
            handleError: (error, stackTrace, sink) {
              _reportClose(error: '$error');
              sink.addError(error, stackTrace);
            },
            handleDone: (sink) {
              _reportClose(code: _inner.closeCode, reason: _inner.closeReason);
              sink.close();
            },
          ))
          .listen(onData,
              onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  /// Received frames as `{connectionId, url, direction, opcode, payload, sizeBytes}`.
  Stream<Map<String, dynamic>> get frames => map((data) => _frame('receive', data));

  /// Send a text frame or binary frame.
  void add(dynamic data) {
    _inner.add(data);
    _reportFrame('send', data);
  }

  /// Close the socket.
  Future<void> close([int? code, String? reason]) {
    _reportClose(code: code, reason: reason);
    return _inner.close(code, reason);
  }

  // ---- Pass-through getters ----
  String? get protocol => _inner.protocol;
  int? get closeCode => _inner.closeCode;
  String? get closeReason => _inner.closeReason;

  void _reportFrame(String direction, dynamic data) =>
      DevConnectClient.safeSend('client:ws_frame', _frame(direction, data));

  Map<String, dynamic> _frame(String direction, dynamic data) {
    final text = data is String;
    final sizeBytes =
        text ? utf8.encode(data).length : (data is List ? data.length : 0);
    return {
      'connectionId': connectionId,
      'url': url,
      'direction': direction,
      'opcode': text ? 'text' : 'binary',
      'payload': text ? data : '<binary $sizeBytes bytes>',
      'sizeBytes': sizeBytes,
    };
  }

  /// Sends the connection's one and only `client:ws_close`.
  void _reportClose({int? code, String? reason, String? error}) {
    if (_closeReported) return;
    _closeReported = true;
    DevConnectClient.safeSend('client:ws_close', {
      'connectionId': connectionId,
      'url': url,
      if (code != null) 'code': code,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (error != null) 'error': error,
    });
  }
}

/// Static helpers for consumers who want to push WebSocket events from
/// their own code (e.g. when not using the wrapped class).
/// [connectionId] groups one connection's events; it defaults to the url.
class DevConnectWebSocketHelper {
  DevConnectWebSocketHelper._();

  static void reportOpen(String url, {String? connectionId}) {
    try {
      DevConnectClient.safeSend('client:ws_open', {
        'connectionId': connectionId ?? url,
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
    String? connectionId,
  }) {
    try {
      DevConnectClient.safeSend('client:ws_frame', {
        'connectionId': connectionId ?? url,
        'url': url,
        'direction': direction,
        'opcode': opcode,
        if (payload != null) 'payload': payload,
        if (sizeBytes != null) 'sizeBytes': sizeBytes,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  static void reportClose(String url,
      {int? code, String? reason, String? connectionId}) {
    try {
      DevConnectClient.safeSend('client:ws_close', {
        'connectionId': connectionId ?? url,
        'url': url,
        if (code != null) 'code': code,
        if (reason != null) 'reason': reason,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }
}
