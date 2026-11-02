import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/preferences/app_preferences.dart';
import 'package:devconnect_manage_tool/core/utils/scroll/smooth_scroll_controller.dart';

void main() {
  setUp(() => AppPreferences().set('smoothScrollEnabled', true));
  tearDown(() => AppPreferences().set('smoothScrollEnabled', false));

  testWidgets('wheel ticks glide without a jump in speed and land on target', (
    tester,
  ) async {
    final controller = SmoothScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ListView.builder(
          controller: controller,
          itemExtent: 50,
          itemCount: 200,
          itemBuilder: (_, i) => Text('$i'),
        ),
      ),
    );
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.hover(tester.getCenter(find.byType(ListView))),
    );

    final offsets = <double>[0];
    Future<void> frames(int n) async {
      for (var i = 0; i < n; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        offsets.add(controller.offset);
      }
    }

    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 40)));
    await frames(6);
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 40)));
    await frames(40);

    expect(controller.offset, closeTo(2 * 40 * 2.2, 0.01));
    final steps = [
      for (var i = 1; i < offsets.length; i++) offsets[i] - offsets[i - 1],
    ];
    expect(steps.every((s) => s >= 0), isTrue, reason: '$steps');
    var biggestChange = 0.0;
    for (var i = 1; i < steps.length; i++) {
      biggestChange = math.max(biggestChange, (steps[i] - steps[i - 1]).abs());
    }
    expect(biggestChange, lessThan(6), reason: '$steps');
  });

  testWidgets('with smooth scrolling off a wheel tick jumps at once', (
    tester,
  ) async {
    await AppPreferences().set('smoothScrollEnabled', false);
    final controller = SmoothScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ListView.builder(
          controller: controller,
          itemExtent: 50,
          itemCount: 200,
          itemBuilder: (_, i) => Text('$i'),
        ),
      ),
    );
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.hover(tester.getCenter(find.byType(ListView))),
    );
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 40)));
    await tester.pump();
    expect(controller.offset, 40);
  });
}
