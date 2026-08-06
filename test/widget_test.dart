import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:devconnect_manage_tool/app.dart';

void main() {
  testWidgets('DevConnect app launches', (WidgetTester tester) async {
    // Realistic desktop viewport. Any layout overflow that surfaces in this
    // test is a real bug — we deliberately DON'T silence it here, because
    // catching it in CI is the only reliable way to fix it at the source.
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(child: DevConnectApp()),
    );
    // Drain the auto-start timers (most expensive is the 2s
    // Process.run timeout in LocalMcpServerManager._resolveNodeBinary,
    // plus the 3.2s toast dismiss timer that fires whenever a toast
    // shows up during the first frame).
    await tester.pump(const Duration(seconds: 5));
  });
}
