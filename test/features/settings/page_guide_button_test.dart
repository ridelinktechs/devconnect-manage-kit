import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/components/layout/sidebar.dart';
import 'package:devconnect_manage_tool/core/providers/app_version_provider.dart';
import 'package:devconnect_manage_tool/features/settings/presentation/tips/page_guide_button.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';

void main() {
  test('every sidebar page but All and Settings has a guide', () {
    final s = lookupS(const Locale('en'));
    for (final item in sidebarItems) {
      if (item.routePath == '/all' || item.routePath == '/settings') continue;
      expect(
        guidesForPage(s, item.routePath),
        isNotEmpty,
        reason: item.routePath,
      );
    }
  });

  testWidgets('the i button opens the guides of its page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appVersionProvider.overrideWith((_) async => '9.9.9')],
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: Center(child: PageGuideButton(route: '/network')),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('How to use this page'));
    await tester.pumpAndSettle();
    expect(find.text('Inspect network traffic'), findsOneWidget);
    expect(find.text('Guides · 1/6'), findsOneWidget);
  });
}
