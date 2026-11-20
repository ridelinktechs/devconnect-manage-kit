import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/features/network_inspector/provider/network_control.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/models/network/network_entry.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';
import 'package:devconnect_manage_tool/server/ws_message_handler.dart';

import '../../helpers/fake_ws_server.dart';

DeviceInfo _device(String id) => DeviceInfo(
  deviceId: id,
  deviceName: 'Pixel 8',
  platform: 'react_native',
  osVersion: 'Android 15',
  appName: 'app',
  appVersion: '1.0.0',
);

void main() {
  late FakeWsServer server;
  late WsMessageHandler handler;
  late ProviderContainer container;

  setUp(() {
    server = FakeWsServer();
    handler = WsMessageHandler(server: server);
    container = ProviderContainer(
      overrides: [
        wsMessageHandlerProvider.overrideWithValue(handler),
        connectedDevicesProvider.overrideWithBuild((_, _) => [_device('a')]),
      ],
    );
  });
  tearDown(() {
    handler.dispose();
    container.dispose();
  });

  test('a preset reaches every app, and one that reconnects', () async {
    final presets = container.read(networkPresetProvider.notifier);
    presets.set(NetworkPreset.offline);
    expect(server.sentTo, ['a']);
    expect(server.sent.single.type, WsMessageTypes.serverNetworkThrottle);
    expect(server.sent.single.payload, {'latencyMs': 0, 'offline': true});

    // A reloaded app starts back at normal: re-apply on (re)connect.
    server.connect(_device('b'));
    await Future<void>.delayed(Duration.zero);
    expect(server.sentTo, ['a', 'b']);
    expect(server.sent.last.payload, {'latencyMs': 0, 'offline': true});

    presets.set(NetworkPreset.normal);
    server.connect(_device('c'));
    await Future<void>.delayed(Duration.zero);
    expect(server.sentTo, ['a', 'b', 'a']);
    expect(server.sent.last.payload, {'latencyMs': 0, 'offline': false});
  });

  test('a replay carries what the app needs to send the request again', () {
    handler.replayRequest(
      const NetworkEntry(
        id: 'req-1',
        deviceId: 'a',
        method: 'POST',
        url: 'https://api.x.dev/login',
        requestHeaders: {'Content-Type': 'application/json'},
        requestBody: {'user': 'an'},
        startTime: 0,
      ),
    );
    expect(server.sentTo.single, 'a');
    expect(server.sent.single.type, WsMessageTypes.serverNetworkReplay);
    expect(server.sent.single.payload, {
      'requestId': 'req-1',
      'method': 'POST',
      'url': 'https://api.x.dev/login',
      'headers': {'Content-Type': 'application/json'},
      'body': {'user': 'an'},
    });
  });
}
