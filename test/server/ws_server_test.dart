import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/server/ws_server.dart';

void main() {
  late WsServer server;
  final sockets = <WebSocket>[];

  setUp(() async {
    server = WsServer();
    await server.start(port: 0);
  });
  tearDown(() async {
    for (final s in sockets) {
      await s.close();
    }
    sockets.clear();
    await server.stop();
  });

  /// Connects from this machine (like a simulator or emulator) and
  /// handshakes as [deviceId].
  Future<WebSocket> connect(
    String deviceId, {
    String deviceName = 'iPhone',
    String osVersion = 'iOS 18.0',
  }) async {
    final ws = await WebSocket.connect('ws://127.0.0.1:${server.port}');
    sockets.add(ws);
    ws.listen((_) {}); // read frames, so a close from the server lands
    ws.add(
      jsonEncode({
        'id': deviceId,
        'type': WsMessageTypes.clientHandshake,
        'deviceId': deviceId,
        'timestamp': 0,
        'payload': {
          'deviceInfo': {
            'deviceId': deviceId,
            'deviceName': deviceName,
            'platform': 'react_native',
            'osVersion': osVersion,
            'appName': 'okicom',
            'appVersion': '1.0.0',
          },
        },
      }),
    );
    return ws;
  }

  Future<List<DeviceInfo>> handshakes(int n) =>
      server.onConnection.take(n).toList().timeout(const Duration(seconds: 5));

  test('two devices of one app on this machine both stay connected', () async {
    final connected = handshakes(2);
    await connect('ios');
    await connect(
      'android',
      deviceName: 'sdk_gphone64_arm64',
      osVersion: 'Android 35',
    );
    await connected;
    // Let any close the server sends reach the sockets.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(server.connections.keys, unorderedEquals(['ios', 'android']));
    expect(sockets.map((s) => s.closeCode), [null, null]);
  });

  test('the same device reconnecting replaces its old socket', () async {
    var connected = handshakes(1);
    final old = await connect('ios');
    await connected;
    connected = handshakes(1);
    await connect('ios'); // app reload: new socket, same deviceId
    await connected;
    await old.done.timeout(const Duration(seconds: 5));

    expect(server.connections.keys, ['ios']);
    expect(old.closeCode, isNotNull);
  });

  test('a reload that comes back with a new id replaces the old one', () async {
    // Old SDKs pick a new deviceId on every launch.
    var connected = handshakes(1);
    final old = await connect('ios-launch-1');
    await connected;
    connected = handshakes(1);
    await connect('ios-launch-2');
    await connected;
    await old.done.timeout(const Duration(seconds: 5));

    expect(server.connections.keys, ['ios-launch-2']);
  });
}
