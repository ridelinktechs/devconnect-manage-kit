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

  for (final direction in [1.0, -1.0]) {
    testWidgets(
      'reversing ${direction > 0 ? 'down to up' : 'up to down'} cancels '
      'queued wheel movement and accumulates the new direction',
      (tester) async {
        final controller = SmoothScrollController(initialScrollOffset: 1000);
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

        // Leave several wheel ticks pending when the user reverses direction.
        for (var i = 0; i < 6; i++) {
          await tester.sendEventToBinding(
            pointer.scroll(Offset(0, 40 * direction)),
          );
          await tester.pump(const Duration(milliseconds: 16));
        }
        final reversalOffset = controller.offset;
        final reversedDelta = -12 * direction;
        final queuedTarget = 1000 + 6 * 40 * direction * 2.2;
        expect((queuedTarget - reversalOffset) * direction, greaterThan(100));
        await tester.sendEventToBinding(
          pointer.scroll(Offset(0, reversedDelta)),
        );

        var previous = reversalOffset;
        for (var frame = 0; frame < 50; frame++) {
          // A second tick in the new direction should extend its target.
          if (frame == 6) {
            await tester.sendEventToBinding(
              pointer.scroll(Offset(0, reversedDelta)),
            );
          }
          await tester.pump(const Duration(milliseconds: 16));
          expect(
            (controller.offset - previous) * direction,
            lessThanOrEqualTo(0),
            reason:
                'The viewport must follow the reversed wheel at frame $frame',
          );
          previous = controller.offset;
        }
        expect(
          controller.offset,
          closeTo(reversalOffset + 2 * reversedDelta * 2.2, 0.01),
        );
      },
    );
  }

  testWidgets('with smooth scrolling off a flick moves exactly the wheel '
      'distance on every frame and stops with the wheel', (tester) async {
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
    // A flick recorded on macOS: (ms, px), sped up by the system.
    const flick = [(0, 4.0), (4, 43.3), (27, 161.7), (50, 223.1), (66, 255.0)];
    final steps = <(int, double)>[];
    var clock = 0;
    Future<void> frame() async {
      final before = controller.offset;
      await tester.pump(const Duration(milliseconds: 8));
      clock += 8;
      steps.add((clock, controller.offset - before));
    }

    for (final (ms, dy) in flick) {
      while (clock + 8 <= ms) {
        await frame();
      }
      await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
    }
    while (clock < 1000) {
      await frame();
    }

    final total = flick.fold(0.0, (sum, tick) => sum + tick.$2);
    expect(controller.offset, closeTo(total, 0.01));
    final moving = steps.where((s) => s.$2 > 0.5).toList();
    expect(moving.last.$1 - flick.last.$1, lessThanOrEqualTo(120));
    final whileTurning = steps.where((s) => s.$1 > 8 && s.$1 <= flick.last.$1);
    expect(whileTurning.every((s) => s.$2 > 0.5), isTrue, reason: '$steps');
    expect(moving.map((s) => s.$2).reduce(math.max), lessThan(150));
  });
}
