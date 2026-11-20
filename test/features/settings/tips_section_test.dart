import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/features/settings/presentation/sections/tips_section.dart';
import 'package:devconnect_manage_tool/features/settings/presentation/tips/guide_steps.dart';
import 'package:devconnect_manage_tool/features/settings/presentation/tips/tip_detail_dialog.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';

Future<void> _pumpTips(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: const Locale('en'),
      home: const Scaffold(
        body: SingleChildScrollView(
          child: TipsSection(port: 9123, host: '10.0.0.5'),
        ),
      ),
    ),
  );
}

/// Lets a tab switch finish, including dropping the cards that slid away.
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  test('parseSteps splits the leading keys from the text', () {
    final lines = parseSteps('[⇧ ⌘ R] Hot restart\nPlain step\n\n[Esc] Clear');
    expect(lines.map((l) => '${l.$1.join('+')}|${l.$2}'), [
      '⇧+⌘+R|Hot restart',
      '|Plain step',
      'Esc|Clear',
    ]);
  });

  testWidgets('tabs swap the cards; arrow keys move between tabs', (
    tester,
  ) async {
    await _pumpTips(tester);
    expect(find.text('All Events feed'), findsOneWidget);

    await tester.tap(find.text('Shortcuts'));
    await _settle(tester);
    expect(find.text('Reload the app'), findsOneWidget);
    expect(find.text('All Events feed'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    expect(find.text('Android emulator'), findsOneWidget);
    expect(find.text('Reload the app'), findsNothing);
  });

  testWidgets('modal pages with arrows, fills port and host, copies, closes '
      'on Esc', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await _pumpTips(tester);
    await tester.tap(find.text('Connect a device'));
    await _settle(tester);
    await tester.tap(find.text('Android phone over USB'));
    await tester.pumpAndSettle();

    expect(find.byType(GuideDialog), findsOneWidget);
    expect(find.text('Connect a device · 2/5'), findsOneWidget);
    expect(find.text('adb reverse tcp:9123 tcp:9123'), findsOneWidget);

    await tester.tap(find.byTooltip('Copy'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(copied, ['adb reverse tcp:9123 tcp:9123']);
    expect(find.text('Code copied'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Code copied'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('Connect a device · 3/5'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(
      find.textContaining("host: '10.0.0.5',\n  port: 9123,"),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(GuideDialog), findsNothing);
  });

  testWidgets('Next turns into Done on the last guide, which closes', (
    tester,
  ) async {
    await _pumpTips(tester);
    await tester.tap(find.text('Shortcuts'));
    await _settle(tester);
    await tester.tap(find.text('Reload the app'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Next'), findsNothing);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(GuideDialog), findsNothing);
  });

  testWidgets('reduced motion swaps tabs at once; large text fits the cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: const Locale('en'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: const TextScaler.linear(1.6),
          ),
          child: child!,
        ),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: TipsSection(port: 9123, host: '10.0.0.5'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Shortcuts'));
    await tester.pump();
    expect(find.text('Reload the app'), findsOneWidget);
    expect(find.text('All Events feed'), findsNothing);
  });
}
