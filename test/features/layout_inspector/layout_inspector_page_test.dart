import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/components/misc/color_sample.dart';
import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/features/layout_inspector/presentation/layout_inspector_page.dart';
import 'package:devconnect_manage_tool/features/layout_inspector/presentation/shared/splitter.dart';
import 'package:devconnect_manage_tool/l10n/app_localizations.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';
import 'package:devconnect_manage_tool/server/ws_message_handler.dart';

import '../../helpers/fake_ws_server.dart';

void main() {
  late FakeWsServer server;

  /// The app answering a capture.
  Future<void> answer(WidgetTester tester) async {
    server.emit(
      deviceMessage(WsMessageTypes.clientLayoutSnapshot, {
        'width': 390,
        'height': 844,
        'root': {
          'id': '1',
          'name': 'App',
          'x': 0,
          'y': 0,
          'w': 390,
          'h': 844,
          'children': [
            {
              'id': '2',
              'name': 'Button',
              'x': 16,
              'y': 760,
              'w': 358,
              'h': 52,
              'props': {
                'color': '#4F46E5',
                'title': 'Pay',
                'note': List.filled(300, 'word').join(' '),
              },
            },
          ],
        },
      }),
    );
    await tester.pump();
    await tester.pump();
  }

  /// The page showing a 390 × 844 capture with a button at the bottom.
  Future<S> showCapture(WidgetTester tester) async {
    // Made in the test's zone, so its events run on the test's clock.
    server = FakeWsServer();
    final handler = WsMessageHandler(server: server);
    addTearDown(handler.dispose);
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [wsMessageHandlerProvider.overrideWithValue(handler)],
        child: const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(body: LayoutInspectorPage()),
        ),
      ),
    );
    server.connect(
      const DeviceInfo(
        deviceId: 'dev',
        deviceName: 'iPhone',
        platform: 'react_native',
        osVersion: 'iOS 18.0',
        appName: 'okicom',
        appVersion: '1.0.0',
      ),
    );
    await tester.pump();
    await answer(tester);
    return S.of(tester.element(find.byType(LayoutInspectorPage)));
  }

  final screen = find.descendant(
    of: find.byType(InteractiveViewer),
    matching: find.byType(ClipRRect),
  );

  Future<void> shortcut(WidgetTester tester, LogicalKeyboardKey key) async {
    final command = Platform.isMacOS
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    await tester.sendKeyDownEvent(command);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(command);
    await tester.pump();
  }

  testWidgets('zooms to the app\'s size, a preset, the selection, and back '
      'to fit', (tester) async {
    final loc = await showCapture(tester);
    final fitted = tester.getRect(screen);

    await shortcut(tester, LogicalKeyboardKey.digit0);
    expect(tester.getRect(screen).width, closeTo(390, 0.01));

    await tester.tap(find.byTooltip(loc.layoutZoomLevel));
    await tester.pumpAndSettle();
    await tester.tap(find.text('200%'));
    await tester.pumpAndSettle();
    expect(tester.getRect(screen).width, closeTo(780, 0.01));

    // The button fills the view, less the margins, in its middle.
    await tester.tap(find.text('Button'));
    await tester.pump();
    await shortcut(tester, LogicalKeyboardKey.digit2);
    final s = tester.getRect(screen);
    final k = s.width / 390;
    final button = Rect.fromLTWH(
      s.left + 16 * k,
      s.top + 760 * k,
      358 * k,
      52 * k,
    );
    final view = tester.getRect(find.byType(InteractiveViewer));
    expect((button.center - view.center).distance, lessThan(0.5));
    expect(button.width, closeTo(view.width - 96, 0.5));

    await shortcut(tester, LogicalKeyboardKey.digit1);
    expect(tester.getRect(screen), fitted);
  });

  testWidgets('a color prop shows its sample', (tester) async {
    await showCapture(tester);
    await tester.tap(find.text('Button'));
    await tester.pump();
    final sample = tester.widget<ColorSample>(find.byType(ColorSample));
    expect(sample.color.toARGB32(), 0xFF4F46E5);
  });

  testWidgets('a long value folds to three lines, with a toggle', (
    tester,
  ) async {
    final loc = await showCapture(tester);
    await tester.tap(find.text('Button'));
    await tester.pump();
    Text note() => tester.widget<Text>(
      find.byWidgetPredicate(
        (w) =>
            w is Text && (w.textSpan?.toPlainText() ?? '').startsWith('word'),
      ),
    );
    final panel = find
        .descendant(
          of: find.byType(SelectionArea),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text(loc.showMore),
      100,
      scrollable: panel,
    );
    await tester.pump();
    expect(note().maxLines, 3);

    await tester.tap(find.text(loc.showMore));
    await tester.pump();
    expect(note().maxLines, isNull);

    await tester.scrollUntilVisible(
      find.text(loc.collapse),
      100,
      scrollable: panel,
    );
    await tester.pump();
    await tester.tap(find.text(loc.collapse));
    await tester.pump();
    expect(note().maxLines, 3);
  });

  testWidgets('capturing again after closing shows the new capture', (
    tester,
  ) async {
    final loc = await showCapture(tester);
    // Everything one might have done with the first capture.
    await tester.tap(find.text('Button'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Bu');
    await tester.pump();
    await tester.tap(find.byTooltip(loc.layoutAppOnly));
    await tester.pump();
    await shortcut(tester, LogicalKeyboardKey.digit0);
    await tester.tap(find.byTooltip(loc.layoutClose));
    await tester.pump();
    await tester.tap(find.text(loc.layoutCapture));
    await tester.pump();
    expect(server.sent.last.type, WsMessageTypes.serverLayoutCapture);
    await answer(tester);
    expect(screen, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('prop keys widen with the panel', (tester) async {
    await showCapture(tester);
    await tester.tap(find.text('Button'));
    await tester.pump();
    final before = tester.getSize(find.text('title')).width;
    // The divider between the canvas and the panel, dragged left.
    await tester.drag(find.byType(Splitter).first, const Offset(-200, 0));
    await tester.pump();
    expect(tester.getSize(find.text('title')).width, greaterThan(before));
  });

  testWidgets('closing the capture goes back to the hint', (tester) async {
    final loc = await showCapture(tester);
    await tester.tap(find.byTooltip(loc.layoutClose));
    await tester.pump();
    expect(screen, findsNothing);
    expect(find.text(loc.layoutHint), findsOneWidget);
  });
}
