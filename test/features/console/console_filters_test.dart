import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/features/console/presentation/empty/no_match_state.dart';
import 'package:devconnect_manage_tool/features/console/presentation/event_row/log_entry_content.dart';
import 'package:devconnect_manage_tool/features/console/presentation/header/level_filter_chip.dart';
import 'package:devconnect_manage_tool/features/console/presentation/pages/console_page.dart';
import 'package:devconnect_manage_tool/features/console/provider/console_providers.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';
import 'package:devconnect_manage_tool/models/log/log_entry.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';

LogEntry _log(String id, LogLevel level, String message, {String dev = 'd'}) =>
    LogEntry(
      id: id,
      deviceId: dev,
      level: level,
      message: message,
      timestamp: DateTime(
        2026,
        11,
        3,
        9,
        0,
        int.parse(id),
      ).millisecondsSinceEpoch,
    );

class _Entries extends ConsoleNotifier {
  _Entries(this.logs);

  final List<LogEntry> logs;

  @override
  List<LogEntry> build() => logs;
}

class _Selected extends SelectedDeviceNotifier {
  @override
  String? build() => 'd';
}

final _logs = [
  _log('1', LogLevel.debug, 'poll a'),
  _log('2', LogLevel.debug, 'poll b'),
  _log('3', LogLevel.info, 'poll ok'),
  _log('4', LogLevel.warn, 'cache high'),
  _log('5', LogLevel.error, 'poll failed', dev: 'other'),
];

List<Override> get _overrides => [
  consoleEntriesProvider.overrideWith(() => _Entries(_logs)),
  selectedDeviceProvider.overrideWith(_Selected.new),
];

void main() {
  test('level chips count the device and the search; the list also '
      'the levels', () {
    final container = ProviderContainer(overrides: _overrides);
    addTearDown(container.dispose);
    container.read(consoleSearchProvider.notifier).set('POLL');
    container.read(consoleFilterProvider.notifier).toggle(LogLevel.debug);

    expect(container.read(consoleLevelCountsProvider), {
      LogLevel.debug: 2,
      LogLevel.info: 1,
      LogLevel.warn: 0,
      LogLevel.error: 0,
    });
    expect(container.read(filteredConsoleEntriesProvider).map((e) => e.id), [
      '3',
    ]);
  });

  Future<void> pumpConsole(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides,
        child: const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(body: ConsolePage()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('hiding every level offers to show them all, with how many '
      'logs come back', (tester) async {
    await pumpConsole(tester);
    expect(find.byType(LogEntryContent), findsNWidgets(4));

    for (final chip in tester.widgetList(find.byType(LevelFilterChip))) {
      await tester.tap(find.byWidget(chip));
    }
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(NoMatchState), findsOneWidget);
    expect(find.text('Show all levels'), findsOneWidget);
    expect(find.text('+4'), findsOneWidget);

    await tester.tap(find.text('Show all levels'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(NoMatchState), findsNothing);
    expect(find.byType(LogEntryContent), findsNWidgets(4));
  });

  testWidgets('a search with no match offers to clear it, box included', (
    tester,
  ) async {
    await pumpConsole(tester);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Clear search'), findsOneWidget);

    await tester.tap(find.text('Clear search'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '',
    );
    expect(find.byType(LogEntryContent), findsNWidgets(4));
  });
}
