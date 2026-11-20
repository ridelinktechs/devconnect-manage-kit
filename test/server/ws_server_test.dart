import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/core/providers/app_version_provider.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';
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

  test('server:hello and the HTTP reply carry the app version', () async {
    server.version = '9.9.9';
    final ws = await WebSocket.connect('ws://127.0.0.1:${server.port}');
    sockets.add(ws);
    final hello = jsonDecode(await ws.first as String) as Map<String, dynamic>;
    expect(hello['type'], WsMessageTypes.serverHello);
    expect((hello['payload'] as Map)['version'], '9.9.9');

    final client = HttpClient();
    addTearDown(client.close);
    final res = await (await client.get('127.0.0.1', server.port, '/')).close();
    final info = jsonDecode(await res.transform(utf8.decoder).join()) as Map;
    expect(info['version'], '9.9.9');
  });

  test('the server takes the version of the running app', () async {
    final container = ProviderContainer(
      overrides: [appVersionProvider.overrideWith((_) async => '9.9.9')],
    );
    addTearDown(container.dispose);
    final s = container.read(wsServerProvider);
    await container.read(appVersionProvider.future);
    await Future<void>.delayed(Duration.zero);
    expect(s.version, '9.9.9');
  });

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

  test('a message sent in chunks arrives whole, each chunk acked', () async {
    final ws = await WebSocket.connect('ws://127.0.0.1:${server.port}');
    sockets.add(ws);
    final acks = <Object?>[];
    ws.listen((data) {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      if (message['type'] == WsMessageTypes.serverChunkAck) {
        acks.add((message['payload'] as Map)['id']);
      }
    });
    final text = 'ą' * 2500;
    final json = jsonEncode({
      'id': 'm1',
      'type': 'client:log',
      'deviceId': 'ios',
      'timestamp': 0,
      'payload': {'message': text},
    });
    final received = server.onMessage.first;

    for (var at = 0; at < json.length; at += 1000) {
      final end = at + 1000 < json.length ? at + 1000 : json.length;
      ws.add(
        jsonEncode({
          'type': WsMessageTypes.clientChunk,
          'payload': {
            'id': 'c1',
            'data': json.substring(at, end),
            'last': end == json.length,
          },
        }),
      );
    }

    final message = await received.timeout(const Duration(seconds: 5));
    expect(message.payload['message'], text);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(acks, List.filled((json.length / 1000).ceil(), 'c1'));
  });
}
