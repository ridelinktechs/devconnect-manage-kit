import 'dart:async';
import 'dart:io';

import 'package:devconnect_manage_kit/devconnect_manage_kit.dart';
import 'package:flutter_test/flutter_test.dart';

/// A dart:io WebSocket whose incoming side is a StreamController.
class _FakeSocket extends Stream<dynamic> implements WebSocket {
  final incoming = StreamController<dynamic>();
  final sent = <dynamic>[];
  @override
  int? closeCode;
  @override
  String? closeReason;

  @override
  StreamSubscription<dynamic> listen(void Function(dynamic)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      incoming.stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  void add(dynamic data) => sent.add(data);

  /// Also how the peer closing the connection looks.
  @override
  Future<void> close([int? code, String? reason]) async {
    closeCode ??= code;
    closeReason ??= reason;
    if (!incoming.isClosed) unawaited(incoming.close());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _url = 'wss://x.dev/ws';

/// Queued `client:ws_*` messages as `{type, ...payload}`.
List<Map<String, dynamic>> _wsEvents() => [
      for (final m in DevConnectClient.queuedMessages)
        if ('${m['type']}'.startsWith('client:ws_'))
          {'type': m['type'], ...m['payload'] as Map<String, dynamic>},
    ];

void main() {
  setUp(() => DevConnectClient.queuedMessages.clear());

  test('listen(): open, frames both ways, one close from close()', () async {
    final fake = _FakeSocket();
    final socket = DevConnect.websocketWrap(fake, _url);
    final received = <dynamic>[];
    final done = Completer<void>();
    socket.listen(received.add, onDone: done.complete);

    socket.add('héllo');
    fake.incoming
      ..add('hi')
      ..add([1, 2, 3]);
    await Future<void>.delayed(Duration.zero);
    await socket.close(1000, 'bye');
    await done.future; // the stream ending must not report a second close

    expect(received, [
      'hi',
      [1, 2, 3],
    ]);
    expect(fake.sent, ['héllo']);
    final id = socket.connectionId;
    Map<String, dynamic> frame(
            String direction, String opcode, String payload, int sizeBytes) =>
        {
          'type': 'client:ws_frame',
          'connectionId': id,
          'url': _url,
          'direction': direction,
          'opcode': opcode,
          'payload': payload,
          'sizeBytes': sizeBytes,
        };
    expect(_wsEvents(), [
      {'type': 'client:ws_open', 'connectionId': id, 'url': _url},
      frame('send', 'text', 'héllo', 6),
      frame('receive', 'text', 'hi', 2),
      frame('receive', 'binary', '<binary 3 bytes>', 3),
      {
        'type': 'client:ws_close',
        'connectionId': id,
        'url': _url,
        'code': 1000,
        'reason': 'bye',
      },
    ]);
  });

  test('frames: the peer closing reports one close with its code', () async {
    final fake = _FakeSocket();
    final socket = DevConnectWebSocket.wrap(fake, _url);
    final frames = socket.frames.toList();

    fake.incoming.add('ping');
    await fake.close(1001, 'going away');
    expect((await frames).single, {
      'connectionId': socket.connectionId,
      'url': _url,
      'direction': 'receive',
      'opcode': 'text',
      'payload': 'ping',
      'sizeBytes': 4,
    });
    await socket.close(); // already closed: still exactly one ws_close

    expect(_wsEvents().where((e) => e['type'] == 'client:ws_close'), [
      {
        'type': 'client:ws_close',
        'connectionId': socket.connectionId,
        'url': _url,
        'code': 1001,
        'reason': 'going away',
      },
    ]);
  });

  test('a stream error reports the close with the error', () async {
    final fake = _FakeSocket();
    final socket = DevConnectWebSocket.wrap(fake, _url);
    final errors = <Object>[];
    final done = Completer<void>();
    socket.listen(null, onError: errors.add, onDone: done.complete);

    fake.incoming.addError(const SocketException('Connection reset'));
    unawaited(fake.incoming.close());
    await done.future;

    expect(errors, hasLength(1));
    final close =
        _wsEvents().singleWhere((e) => e['type'] == 'client:ws_close');
    expect(close['error'], contains('Connection reset'));
    expect(close.containsKey('code'), isFalse);
  });
}
