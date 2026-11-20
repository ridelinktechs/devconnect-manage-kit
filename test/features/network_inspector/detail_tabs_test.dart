import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/theme/theme_provider.dart';
import 'package:devconnect_manage_tool/features/all_events/presentation/detail/network_detail.dart';
import 'package:devconnect_manage_tool/features/all_events/presentation/detail/state_detail.dart';
import 'package:devconnect_manage_tool/features/error_inspector/presentation/detail/error_detail_panel.dart';
import 'package:devconnect_manage_tool/features/network_inspector/presentation/request/request_detail_panel.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';
import 'package:devconnect_manage_tool/models/log/error_event.dart';
import 'package:devconnect_manage_tool/models/network/network_entry.dart';
import 'package:devconnect_manage_tool/models/state/state_change.dart';

NetworkEntry _request(String url) => NetworkEntry(
  id: url,
  deviceId: 'ios',
  method: 'GET',
  url: url,
  statusCode: 200,
  requestHeaders: const {'accept': 'application/json'},
  responseHeaders: const {'content-type': 'application/json'},
  responseBody: '{"items": []}',
  startTime: 0,
  endTime: 120,
  duration: 120,
  isComplete: true,
);

const _plain = 'https://api.example.com/v1/cart';
const _withParams = 'https://api.example.com/v1/products?q=lamp';

/// [panel] alone on screen, and the container behind it.
Future<ProviderContainer> _show(WidgetTester tester, Widget panel) async {
  tester.view.physicalSize = const Size(900, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: panel),
      ),
    ),
  );
  await tester.pump();
  return container;
}

/// Turns tab animations off and back on: each change rebuilds the tabs of
/// every open detail panel.
Future<void> _toggleTabAnimation(
  WidgetTester tester,
  ProviderContainer c,
) async {
  final tabs = c.read(tabAnimationEnabledProvider.notifier);
  final enabled = c.read(tabAnimationEnabledProvider);
  tabs.set(!enabled);
  await tester.pumpAndSettle();
  tabs.set(enabled);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a request with query params opens, with its Params tab', (
    tester,
  ) async {
    await _show(
      tester,
      RequestDetailPanel(entry: _request(_withParams), onClose: () {}),
    );
    expect(find.text('Params'), findsOneWidget);
    expect(find.text('Timing'), findsOneWidget);
  });

  testWidgets('a detail panel open on any tab keeps working when the tab '
      'animation setting changes', (tester) async {
    final panels = <(String, Widget, String)>[
      (
        'request',
        RequestDetailPanel(entry: _request(_plain), onClose: () {}),
        'Timing',
      ),
      (
        'request with params, on its fifth tab',
        RequestDetailPanel(entry: _request(_withParams), onClose: () {}),
        'Timing',
      ),
      (
        'All\'s network detail',
        NetworkDetail(entry: _request(_withParams)),
        'Timing',
      ),
      (
        'state detail',
        const StateDetail(
          entry: StateChange(
            id: 's',
            deviceId: 'ios',
            stateManagerType: 'redux',
            actionName: 'cart/ADD_ITEM',
            timestamp: 0,
          ),
        ),
        'Next',
      ),
      (
        'error detail',
        ErrorDetailPanel(
          entry: const ErrorEvent(
            id: 'e',
            deviceId: 'ios',
            platform: ErrorPlatform.js,
            severity: ErrorSeverity.error,
            message: 'boom',
            timestamp: 0,
          ),
          onClose: () {},
        ),
        'Stack Trace',
      ),
    ];
    for (final (name, panel, tab) in panels) {
      final c = await _show(tester, panel);
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      await _toggleTabAnimation(tester, c);
      expect(tester.takeException(), isNull, reason: name);
      expect(find.text(tab), findsOneWidget, reason: name);
    }
  });
}
