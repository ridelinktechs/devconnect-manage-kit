import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/components/viewers/json_viewer.dart';
import 'package:devconnect_manage_tool/core/preferences/app_preferences.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('JSON lines stay aligned and reverse direction after prolonged '
      'wheel scrolling and parent rebuilds', (tester) async {
    tester.view.physicalSize = const Size(700, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final preferences = AppPreferences();
    final previous = preferences.get<bool>('smoothScrollEnabled', false);
    await preferences.set('smoothScrollEnabled', true);
    addTearDown(() => preferences.set('smoothScrollEnabled', previous));

    final rebuild = ValueNotifier(0);
    addTearDown(rebuild.dispose);
    final data = [for (var i = 0; i < 400; i++) 'value-$i'];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: ValueListenableBuilder<int>(
            valueListenable: rebuild,
            builder: (_, _, _) => JsonPrettyViewer(data: data),
          ),
        ),
      ),
    );
    await _waitForLines(tester);
    final viewport = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    final position = tester.state<ScrollableState>(viewport).position;
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(tester.getCenter(viewport)));
    final viewportTop = tester.getTopLeft(viewport).dy;

    void expectLinesAtOffsets() {
      final first = math.max(0, ((position.pixels - 8) / 18).ceil());
      final count = (position.viewportDimension / 18).floor() - 1;
      for (var row = first; row < first + count; row++) {
        final line = find.text('${row + 1}');
        expect(line, findsOneWidget, reason: 'offset ${position.pixels}');
        final paragraph = tester.renderObject<RenderParagraph>(line);
        final digitBoxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: '${row + 1}'.length),
        );
        expect(
          digitBoxes.map((box) => box.top).toSet(),
          hasLength(1),
          reason: 'Line ${row + 1} must fit within one gutter row',
        );
        expect(
          digitBoxes.every(
            (box) =>
                box.left >= -0.5 && box.right <= paragraph.size.width + 0.5,
          ),
          isTrue,
          reason:
              'Every digit of line ${row + 1} must fit inside the gutter: '
              '$digitBoxes in ${paragraph.size}',
        );
        expect(
          tester.getTopLeft(line).dy,
          closeTo(viewportTop + 8 + row * 18 - position.pixels, 0.1),
          reason: 'line ${row + 1}, offset ${position.pixels}',
        );
      }
    }

    for (var i = 0; i < 180; i++) {
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 12)));
      if (i % 3 == 0) rebuild.value++;
      await tester.pump(const Duration(milliseconds: 16));
      expectLinesAtOffsets();
    }
    expect(position.pixels, greaterThan(100 * 18));
    final beforeReverse = position.pixels;
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -12)));
    await tester.pumpAndSettle();
    expect(
      position.pixels,
      lessThan(beforeReverse),
      reason: 'Scrolling back up must cancel the pending downward target',
    );
    expectLinesAtOffsets();
    final restingOffset = position.pixels;
    rebuild.value++;
    await tester.pumpAndSettle();
    expect(position.pixels, restingOffset);
    expectLinesAtOffsets();
  });

  testWidgets('scaled JSON text fits inside each virtualized row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: JsonPrettyViewer(
              data: [for (var i = 0; i < 400; i++) 'value-$i'],
            ),
          ),
        ),
      ),
    );
    await _waitForLines(tester);

    final content = find.byWidgetPredicate(
      (widget) =>
          widget is RichText && widget.text.toPlainText() == '  "value-0",',
    );
    expect(content, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(content);
    final boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 12),
    );
    expect(boxes, isNotEmpty);
    expect(
      boxes.every((box) => box.top >= 0 && box.bottom <= paragraph.size.height),
      isTrue,
      reason: 'Scaled glyphs must not overflow into neighboring JSON rows',
    );
  });
}

Future<void> _waitForLines(WidgetTester tester) => tester.runAsync(() async {
  for (var i = 0; i < 100 && find.text('402 lines').evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await tester.pump();
  }
});
