import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/components/misc/color_sample.dart';
import 'package:devconnect_manage_tool/components/viewers/json_viewer.dart';
import 'package:devconnect_manage_tool/core/utils/code/code_generator.dart';
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

  testWidgets('a huge document shows whole, and its search reaches the end', (
    tester,
  ) async {
    final data = [for (var i = 0; i < 100000; i++) 'v$i', 'needle'];
    await tester.pumpWidget(_app(JsonPrettyViewer(data: data)));
    await _waitForLines(tester);
    final down = _downScrollable();

    expect(find.text('100003 lines'), findsOneWidget);
    expect(find.textContaining('of 100,003 lines'), findsNothing);

    await tester.enterText(find.byType(TextField), 'needle');
    await tester.pump();
    await tester.pump();
    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('100002'), findsOneWidget);
    expect(
      tester.state<ScrollableState>(down).position.pixels,
      greaterThan(1000000),
    );

    final position = tester.state<ScrollableState>(down).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    expect(find.text('100003'), findsOneWidget);
  });

  testWidgets('without a bounded height it shows a capped start, and says so', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: JsonPrettyViewer(data: List.generate(100000, (i) => i)),
        ),
      ),
    );
    await _waitForLines(tester);

    expect(find.textContaining('of 100,002 lines'), findsOneWidget);
  });

  testWidgets('the JSON view finds text, marks it and scrolls to it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        JsonPrettyViewer(
          data: {
            for (var i = 0; i < 400; i++)
              'k$i': i == 350
                  ? 'needle'
                  : i == 352
                  ? 'Needle'
                  : 'hay',
          },
        ),
      ),
    );
    await tester.runAsync(() async {
      for (
        var i = 0;
        i < 100 && find.textContaining(' lines').evaluate().isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    final down = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    bool marked(Color color) =>
        tester.widgetList<RichText>(find.byType(RichText)).any((r) {
          var found = false;
          r.text.visitChildren((span) {
            found |= span.style?.backgroundColor == color;
            return !found;
          });
          return found;
        });

    await tester.enterText(find.byType(TextField), 'needle');
    await tester.pump();
    await tester.pump();

    expect(find.text('1/2'), findsOneWidget);
    expect(marked(const Color(0xFFFBBF24)), isTrue);
    expect(marked(const Color(0x59FBBF24)), isTrue);
    expect(tester.state<ScrollableState>(down).position.pixels, greaterThan(0));

    await tester.tap(find.byTooltip('Next match (↵)'));
    await tester.pump();
    expect(find.text('2/2'), findsOneWidget);
  });

  testWidgets('typing a search moves nothing in the toolbars', (tester) async {
    Future<void> settle() => tester.runAsync(() async {
      for (var i = 0; i < 40; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        await tester.pump();
      }
    });
    // Decoded, like every body the app shows.
    final data = jsonDecode(
      jsonEncode([
        for (var i = 0; i < 30; i++) {'id': i, 'name': 'item $i'},
      ]),
    );
    final views = <String, (Widget, Finder)>{
      'tree': (JsonViewer(data: data), find.byTooltip('Expand all')),
      'json': (JsonPrettyViewer(data: data), find.byTooltip('Copy JSON')),
      // Its copy buttons scroll with the code; the search bar stays put.
      'code': (
        CodeViewer(
          generated: CodeGenerator.generate(data, CodeLang.typescript),
          lang: CodeLang.typescript,
          languageLabel: 'TypeScript',
        ),
        find.byType(TextField),
      ),
    };
    for (final MapEntry(key: name, value: (view, button)) in views.entries) {
      await tester.pumpWidget(
        _app(Center(child: SizedBox(width: 420, height: 500, child: view))),
      );
      await settle();
      final field = find.byType(TextField);
      final before = (tester.getRect(field), tester.getRect(button));
      expect(before.$1.width, greaterThan(60), reason: name);

      for (final query in ['i', 'item 1', 'item 12', 'zzz']) {
        await tester.enterText(field, query);
        await tester.pump();
        expect(
          (tester.getRect(field), tester.getRect(button)),
          before,
          reason: '$name, "$query"',
        );
      }
    }

    await tester.pumpWidget(
      _app(
        Center(
          child: SizedBox(
            width: 420,
            height: 500,
            child: JsonViewer(data: data),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Table'));
    await tester.pump();
    final field = find.byType(TextField);
    final before = tester.getRect(field);
    for (final query in ['1', 'item 2']) {
      await tester.enterText(field, query);
      await tester.pump();
      expect(tester.getRect(field), before, reason: 'table, "$query"');
    }
  });

  testWidgets('the code view finds text in its types and its code', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: CodeViewer(
            generated: CodeGenerator.generate(
              jsonDecode('{"name": "a", "items": [{"name": "b"}]}'),
              CodeLang.typescript,
            ),
            lang: CodeLang.typescript,
            languageLabel: 'TypeScript',
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'name');
    await tester.pump();
    final count = tester
        .widgetList<Text>(find.textContaining(RegExp(r'^1/\d+$')))
        .single
        .data!;
    final total = int.parse(count.split('/').last);
    expect(total, greaterThanOrEqualTo(4));
    expect(find.byType(TextField), findsOneWidget);

    for (var i = 2; i <= total; i++) {
      await tester.tap(find.byTooltip('Next match (↵)'));
      await tester.pump();
      expect(find.text('$i/$total'), findsOneWidget);
    }
  });

  testWidgets('the tree search still counts its matches', (tester) async {
    await tester.pumpWidget(
      _app(const JsonViewer(data: {'a': 'needle', 'b': 'Needle', 'c': 'x'})),
    );

    await tester.enterText(find.byType(TextField), 'needle');
    await tester.pump();

    expect(find.text('1/2'), findsOneWidget);
  });
}

/// Pumps until the JSON view has laid out its document.
Future<void> _waitForLines(WidgetTester tester) => tester.runAsync(() async {
  for (
    var i = 0;
    i < 200 && find.textContaining(' lines').evaluate().isEmpty;
    i++
  ) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  }
});

Finder _downScrollable() => find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
);

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  home: Scaffold(body: child),
);
