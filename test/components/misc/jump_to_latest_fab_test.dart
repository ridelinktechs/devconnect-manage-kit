import 'package:devconnect_manage_tool/components/misc/jump_to_latest_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('waits for scroll metrics and can be placed in a Stack', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: Stack(
              children: [
                ListView.builder(
                  controller: controller,
                  itemExtent: 40,
                  itemCount: 20,
                  itemBuilder: (context, index) => Text('Row $index'),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: JumpToLatestFab(scrollController: controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    controller.jumpTo(40);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Jump to latest'), findsOneWidget);
  });

  testWidgets(
    'positions the jump action at the horizontal center of its Stack',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: Stack(
                key: const ValueKey('fab-stack'),
                children: [
                  ListView.builder(
                    controller: controller,
                    itemExtent: 40,
                    itemCount: 20,
                    itemBuilder: (context, index) => Text('Row $index'),
                  ),
                  PositionedJumpToLatestFab(scrollController: controller),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);

      controller.jumpTo(40);
      await tester.pump();

      final stackCenter = tester.getCenter(
        find.byKey(const ValueKey('fab-stack')),
      );
      final buttonCenter = tester.getCenter(find.byType(GestureDetector));

      expect(tester.takeException(), isNull);
      expect(buttonCenter.dx, closeTo(stackCenter.dx, 0.1));
    },
  );
}
