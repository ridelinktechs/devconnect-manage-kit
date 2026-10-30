import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/components/misc/color_sample.dart';
import 'package:devconnect_manage_tool/components/viewers/json_viewer.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('colors get a sample, look-alikes don\'t', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: JsonViewer(
            data: {
              'color': '#4F46E5',
              'border': '1px solid rgb(0, 128, 0)',
              'tier': 'gold',
              'title': 'Order #123456',
            },
          ),
        ),
      ),
    );
    final samples = tester.widgetList<ColorSample>(find.byType(ColorSample));
    expect(samples.map((s) => s.color.toARGB32()), [0xFF4F46E5, 0xFF008000]);
    expect(find.byTooltip('#4F46E5   rgba(79, 70, 229, 1)'), findsOneWidget);
  });

  testWidgets('a big list shows a page of rows at a time', (tester) async {
    await tester.pumpWidget(
      _app(JsonViewer(data: List.generate(450, (i) => i))),
    );
    final rows = find.textContaining(RegExp(r'^\d+: \d+$'), findRichText: true);
    expect(rows, findsNWidgets(200));

    Future<void> showMore(String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.pump();
      await tester.tap(find.text(label));
      await tester.pump();
    }

    await showMore('Show 200 more (250 left)');
    expect(rows, findsNWidgets(400));

    await showMore('Show 50 more (50 left)');
    expect(rows, findsNWidgets(450));
    expect(find.textContaining('more ('), findsNothing);
  });

  testWidgets('a long string shows its start and its length', (tester) async {
    await tester.pumpWidget(_app(JsonViewer(data: {'s': 'x' * 3000})));

    expect(
      find.textContaining(
        '3,000 characters, copy to get all',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.textContaining('x' * 2001, findRichText: true), findsNothing);
  });

  testWidgets('a huge document shows its first lines, and says so', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(JsonPrettyViewer(data: List.generate(100000, (i) => i))),
    );
    await tester.runAsync(() async {
      for (
        var i = 0;
        i < 100 && find.textContaining('of 100,002 lines').evaluate().isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });

    expect(find.textContaining('of 100,002 lines'), findsOneWidget);
  });
}

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  home: Scaffold(body: child),
);
