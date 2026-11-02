import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:devconnect_manage_tool/core/preferences/app_preferences.dart';
import 'package:devconnect_manage_tool/core/providers/app_version_provider.dart';
import 'package:devconnect_manage_tool/core/providers/tab_visibility_provider.dart';
import 'package:devconnect_manage_tool/features/settings/presentation/controls/bubble_slider.dart';
import 'package:devconnect_manage_tool/features/settings/presentation/controls/segmented_picker.dart';
import 'package:devconnect_manage_tool/features/settings/presentation/controls/stretch_switch.dart';
import 'package:devconnect_manage_tool/features/settings/presentation/pages/settings_page.dart';
import 'package:devconnect_manage_tool/features/settings/presentation/sections/quick_start_section.dart';
import 'package:devconnect_manage_tool/features/settings/presentation/sections/server_section.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';

Widget _app(Widget child) => ProviderScope(
  overrides: [appVersionProvider.overrideWith((_) async => '9.9.9')],
  child: MaterialApp(
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  ),
);

class _FakeServer {
  _FakeServer(this.isRunning);
  final bool isRunning;
  int get port => 9090;
}

void main() {
  setUp(() => AppPreferences().set('tab_hidden', null));
  tearDown(() => AppPreferences().set('tab_hidden', null));

  testWidgets('the menu switches groups; every hideable tab has a switch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const SettingsPage()));
    await tester.pumpAndSettle();
    expect(find.text('v9.9.9'), findsOneWidget);
    expect(find.text('Server'), findsOneWidget);
    expect(find.text('Tab Visibility'), findsNothing);

    await tester.tap(find.text('Appearance').first);
    await tester.pumpAndSettle();
    expect(find.text('Server'), findsNothing);
    expect(find.text('Tab Visibility'), findsOneWidget);
    expect(find.byType(StretchSwitch), findsNWidgets(1 + TabKey.values.length));
    expect(find.text('Mock server'), findsOneWidget);

    await tester.tap(find.text('Mock server'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsPage)),
    );
    expect(
      container.read(tabVisibilityProvider).contains(TabKey.mockServer),
      isFalse,
    );
    expect(
      find.text('${TabKey.values.length - 1} / ${TabKey.values.length}'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a running server offers Restart and Stop; restarting locks Stop',
    (tester) async {
      var restarts = 0, stops = 0;
      Widget server({required bool restarting}) => _app(
        ServerSection(
          portController: TextEditingController(text: '9090'),
          server: _FakeServer(true),
          address: 'ws://10.0.0.5:9090',
          restarting: restarting,
          onStartStop: () => stops++,
          onRestart: () => restarts++,
          onCopy: (_, [_]) {},
        ),
      );
      await tester.pumpWidget(server(restarting: false));
      expect(find.text('ws://10.0.0.5:9090'), findsOneWidget);
      await tester.tap(find.text('Restart'));
      await tester.tap(find.text('Stop'));
      expect((restarts, stops), (1, 1));

      await tester.pumpWidget(server(restarting: true));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Stop'), warnIfMissed: false);
      expect(stops, 1);
      expect(find.text('Restarting…'), findsOneWidget);
    },
  );

  testWidgets('segments and the slider follow the arrow keys', (tester) async {
    var mode = 'a';
    var ms = 300;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              SegmentedPicker<String>(
                segments: const [
                  (value: 'a', label: 'A', icon: null),
                  (value: 'b', label: 'B', icon: null),
                ],
                value: mode,
                onChanged: (v) => setState(() => mode = v),
              ),
              BubbleSlider(
                value: ms,
                min: 0,
                max: 1000,
                step: 50,
                ticks: const [0, 1000],
                format: (v) => '${v}ms',
                label: 'Duration',
                onChanged: (v) => setState(() => ms = v),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(mode, 'b');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(mode, 'a');

    await tester.tap(find.byType(BubbleSlider));
    await tester.pumpAndSettle();
    expect(ms, 500);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump(const Duration(milliseconds: 600));
    expect(ms, 1000);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump(const Duration(milliseconds: 600));
    expect(ms, 950);
  });

  testWidgets('React Native installs with yarn or npm; the pick is copied '
      'and remembered', (tester) async {
    Future<void> reset() async {
      await AppPreferences().set('quickStartPlatform', null);
      await AppPreferences().set('quickStartManager', null);
    }

    await reset();
    addTearDown(reset);
    String? copied;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      _app(
        const SingleChildScrollView(
          child: QuickStartSection(ip: '10.0.0.5', port: 9090),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('npm'), findsNothing);

    await tester.tap(find.text('React Native'));
    await tester.pumpAndSettle();
    expect(find.text('yarn'), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.copy));
    await tester.pump(const Duration(seconds: 2));
    expect(copied, 'yarn add devconnect-manage-kit');

    await tester.tap(find.text('npm'));
    await tester.pumpAndSettle();
    expect(find.text('npm install '), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.copy));
    await tester.pump(const Duration(seconds: 2));
    expect(copied, 'npm install devconnect-manage-kit');
    expect(AppPreferences().get<String>('quickStartManager'), 'npm');

    await tester.tap(find.text('Flutter'));
    await tester.pumpAndSettle();
    expect(find.text('npm'), findsNothing);
  });
}
