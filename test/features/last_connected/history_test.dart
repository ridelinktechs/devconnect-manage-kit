import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/app.dart';
import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/features/last_connected/provider/last_connected_providers.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/server/protocol/dc_message.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';

import '../../helpers/fake_ws_server.dart';

/// A running server whose devices can also leave.
class _Server extends FakeWsServer {
  final _gone = StreamController<String>.broadcast(sync: true);

  void disconnect(String deviceId) => _gone.add(deviceId);

  @override
  Stream<String> get onDisconnection => _gone.stream;

  @override
  bool get isRunning => true;

  @override
  int get port => 9090;
}

void main() {
  testWidgets('a device that leaves for good is kept in History with what it '
      'sent', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final server = _Server();
    // The whole app, so its providers listen in the order they really do.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [wsServerProvider.overrideWithValue(server)],
        child: const DevConnectApp(),
      ),
    );
    final c = ProviderScope.containerOf(
      tester.element(find.byType(DevConnectApp)),
    );
    server.connect(
      const DeviceInfo(
        deviceId: 'pixel',
        deviceName: 'Pixel 9',
        platform: 'react_native',
        osVersion: 'Android 16',
        appName: 'Demo',
        appVersion: '1.0.0',
      ),
    );
    await tester.pump();
    await tester.pump();
    server.emit(
      DCMessage(
        id: 'log',
        type: WsMessageTypes.clientLog,
        deviceId: 'pixel',
        timestamp: 1763600000000,
        payload: {'level': 'info', 'message': 'App launched'},
      ),
    );
    await tester.pump();
    await tester.pump();

    server.disconnect('pixel');
    await tester.pump();
    await tester.pump(const Duration(seconds: 16));

    final sessions = c.read(lastConnectedProvider);
    expect(sessions, hasLength(1));
    expect(sessions.single.deviceInfo.deviceName, 'Pixel 9');
    expect(sessions.single.logs.single.message, 'App launched');
  });
}
