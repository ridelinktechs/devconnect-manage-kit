import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/components/layout/deep_link_dialog.dart';
import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';
import 'package:devconnect_manage_tool/server/ws_message_handler.dart';

import '../helpers/fake_ws_server.dart';

DeviceInfo _device(String id) => DeviceInfo(
  deviceId: id,
  deviceName: 'Pixel 8',
  platform: 'react_native',
  osVersion: 'Android 15',
  appName: 'app',
  appVersion: '1.0.0',
);

void main() {
  testWidgets('a deep link opens in every app and the dialog closes cleanly', (
    tester,
  ) async {
    final server = FakeWsServer();
    final handler = WsMessageHandler(server: server);
    addTearDown(handler.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [wsMessageHandlerProvider.overrideWithValue(handler)],
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () =>
                    openDeepLink(context, ref, [_device('a'), _device('b')]),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    final loc = S.of(tester.element(find.text('open')));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'myapp://orders/42');
    await tester.tap(find.widgetWithText(FilledButton, loc.deepLinkOpen));
    // The dialog's exit transition still builds its TextField.
    await tester.pumpAndSettle();

    expect(server.sentTo, ['a', 'b']);
    expect(
      server.sent.map((m) => m.type),
      everyElement(WsMessageTypes.serverOpenUrl),
    );
    expect(server.sent.first.payload, {'url': 'myapp://orders/42'});
    expect(find.text(loc.deepLinkSent), findsOneWidget);
    await tester.pump(const Duration(seconds: 3)); // the toast times out
    await tester.pumpAndSettle();
  });
}
