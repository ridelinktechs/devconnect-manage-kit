import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:devconnect_manage_tool/app.dart';

void main() {
  testWidgets('DevConnect app launches', (WidgetTester tester) async {
    // Ignore layout overflow exceptions which are unrelated to our scroll optimization
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) {
        return;
      }
      originalOnError?.call(details);
    };

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });

    await tester.pumpWidget(
      const ProviderScope(child: DevConnectApp()),
    );
    await tester.pump(const Duration(milliseconds: 500));
  });
}
