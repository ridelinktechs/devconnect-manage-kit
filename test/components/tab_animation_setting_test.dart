import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/components/layout/segmented_tab_bar.dart';
import 'package:devconnect_manage_tool/components/viewers/json/lazy_views.dart';
import 'package:devconnect_manage_tool/components/viewers/json/view_mode_switcher.dart';
import 'package:devconnect_manage_tool/core/preferences/app_preferences.dart';
import 'package:devconnect_manage_tool/core/theme/theme_provider.dart';
import 'package:devconnect_manage_tool/features/state_inspector/presentation/detail/state_json_tab_view.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required bool on,
}) async {
  await AppPreferences().set('tabAnimationEnabled', on);
  addTearDown(() => AppPreferences().set('tabAnimationEnabled', true));
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  testWidgets('with tab animation off, deferred content shows on the first '
      'frame, with no spinner', (tester) async {
    await _pump(
      tester,
      DeferredBuilder(builder: (_) => const Text('ready')),
      on: false,
    );
    expect(find.text('ready'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('with it on, the content waits a frame behind a spinner', (
    tester,
  ) async {
    await _pump(
      tester,
      DeferredBuilder(builder: (_) => const Text('ready')),
      on: true,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump();
    expect(find.text('ready'), findsOneWidget);
  });

  for (final on in [false, true]) {
    testWidgets('the Tree / JSON / Code thumb slides only with tab animation '
        'on (on: $on)', (tester) async {
      await _pump(
        tester,
        ViewModeSwitcher(
          current: BodyViewMode.tree,
          codeLabel: 'Dart',
          onChanged: (_) {},
        ),
        on: on,
      );
      final thumb = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
      expect(
        thumb.duration,
        on ? const Duration(milliseconds: 300) : Duration.zero,
      );
    });
  }

  test('tab animation is on until the user turns it off', () async {
    await AppPreferences().set('tabAnimationEnabled', null);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(tabAnimationEnabledProvider), isTrue);
    expect(
      container.read(tabAnimationProvider),
      const Duration(milliseconds: 300),
    );
  });

  for (final on in [false, true]) {
    testWidgets('a segmented tab bar switches at once when its tabs do not '
        'animate (on: $on)', (tester) async {
      final controller = TabController(
        length: 2,
        vsync: const TestVSync(),
        animationDuration: on
            ? const Duration(milliseconds: 300)
            : Duration.zero,
      );
      addTearDown(controller.dispose);
      await _pump(
        tester,
        SegmentedTabBar(
          controller: controller,
          tabs: const [
            SegmentedTab(icon: Icons.public, label: 'HTTP'),
            SegmentedTab(icon: Icons.code, label: 'Mock'),
          ],
        ),
        on: on,
      );
      final durations = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((c) => c.duration)
          .toSet();
      expect(durations, {
        on ? const Duration(milliseconds: 150) : Duration.zero,
      });
    });

    testWidgets('the State Inspector JSON tabs follow the setting (on: $on)', (
      tester,
    ) async {
      await _pump(tester, const StateJsonTabView(data: {'a': 1}), on: on);
      final tabs = tester.widget<DefaultTabController>(
        find.byType(DefaultTabController),
      );
      expect(
        tabs.animationDuration,
        on ? const Duration(milliseconds: 300) : Duration.zero,
      );
    });
  }
}
