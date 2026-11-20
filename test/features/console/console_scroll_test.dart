import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/preferences/app_preferences.dart';
import 'package:devconnect_manage_tool/core/theme/theme_provider.dart';
import 'package:devconnect_manage_tool/features/console/presentation/pages/console_page.dart';
import 'package:devconnect_manage_tool/features/console/provider/console_providers.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';
import 'package:devconnect_manage_tool/models/log/log_entry.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';

var _next = 0;

LogEntry _log() => LogEntry(
  id: 'e${_next++}',
  deviceId: 'd',
  level: LogLevel.info,
  message: 'line $_next',
  timestamp: 1000 + _next,
);

class _Entries extends ConsoleNotifier {
  @override
  List<LogEntry> build() => [for (var i = 0; i < 60; i++) _log()];

  void add() => state = [...state, _log()];
}

class _Selected extends SelectedDeviceNotifier {
  @override
  String? build() => 'd';
}

/// Mounts the Console with 60 logs, turns the wheel up four ticks just after
/// a log arrives, and keeps logs coming every 96 ms; returns how far the list
/// moved on each 8 ms frame.
Future<List<double>> _wheelWhileStreaming(
  WidgetTester tester, {
  required bool newestOnTop,
}) async {
  await AppPreferences().set('smoothScrollEnabled', true);
  await AppPreferences().set('smoothScrollDuration', 300);
  addTearDown(() => AppPreferences().set('smoothScrollEnabled', false));
  tester.view.physicalSize = const Size(1180, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      consoleEntriesProvider.overrideWith(_Entries.new),
      selectedDeviceProvider.overrideWith(_Selected.new),
    ],
  );
  addTearDown(container.dispose);
  if (newestOnTop) {
    container.read(scrollDirectionProvider.notifier).set(ScrollDirection.top);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: ConsolePage()),
      ),
    ),
  );
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  final position = tester
      .stateList<ScrollableState>(find.byType(Scrollable))
      .firstWhere((s) => s.position.maxScrollExtent > 1000)
      .position;
  final pointer = TestPointer(1, PointerDeviceKind.mouse);
  await tester.sendEventToBinding(
    pointer.hover(tester.getCenter(find.byType(ConsolePage))),
  );
  final entries = container.read(consoleEntriesProvider.notifier) as _Entries;
  entries.add();
  await tester.pump(const Duration(milliseconds: 16));

  final offsets = <double>[position.pixels];
  for (var t = 0; t < 1200; t += 8) {
    if (t % 24 == 0 && t <= 72) {
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -120)));
    }
    if (t % 96 == 0) entries.add();
    await tester.pump(const Duration(milliseconds: 8));
    offsets.add(position.pixels);
  }
  return [for (final o in offsets) o - offsets.first];
}

void main() {
  testWidgets('turning the wheel while logs stream scrolls the list instead '
      'of being pulled back to the newest log', (tester) async {
    final moved = await _wheelWhileStreaming(tester, newestOnTop: false);

    expect(moved.last, closeTo(-4 * 120 * 2.2, 1));
    for (var i = 1; i < moved.length; i++) {
      expect(moved[i], lessThanOrEqualTo(moved[i - 1]), reason: '$moved');
    }
  });

  testWidgets('with the newest log on top, a glide keeps moving the same way '
      'while new logs push the rows down', (tester) async {
    final moved = await _wheelWhileStreaming(tester, newestOnTop: true);

    for (var i = 1; i < moved.length; i++) {
      expect(moved[i], greaterThanOrEqualTo(moved[i - 1]), reason: '$moved');
    }
    expect(moved.last % 70, closeTo(4 * 120 * 2.2 % 70, 1));
  });
}
