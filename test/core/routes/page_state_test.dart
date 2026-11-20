import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/app.dart';
import 'package:devconnect_manage_tool/components/layout/sidebar.dart';
import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/core/providers/tab_visibility_provider.dart';
import 'package:devconnect_manage_tool/core/routes/app_router.dart';
import 'package:devconnect_manage_tool/core/routes/listen_while_shown.dart';
import 'package:devconnect_manage_tool/features/all_events/presentation/detail/event_detail_panel.dart';
import 'package:devconnect_manage_tool/features/all_events/presentation/event_row/event_row.dart';
import 'package:devconnect_manage_tool/features/console/provider/console_providers.dart';
import 'package:devconnect_manage_tool/features/network_inspector/presentation/pages/network_inspector_page.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/models/log/log_entry.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';

import '../../helpers/fake_ws_server.dart';

/// A server already running, so the app doesn't start a real one.
class _Server extends FakeWsServer {
  @override
  bool get isRunning => true;

  @override
  int get port => 9090;
}

/// Three logs from `dev`, "line 1" to "line 3"; [add] logs the next.
class _Logs extends ConsoleNotifier {
  var _n = 0;

  LogEntry _log() {
    _n++;
    return LogEntry(
      id: 'e$_n',
      deviceId: 'dev',
      level: LogLevel.info,
      message: 'line $_n',
      timestamp: 1000 + _n,
    );
  }

  @override
  List<LogEntry> build() => [_log(), _log(), _log()];

  void add() => state = [...state, _log()];
}

/// The whole app, on All, with `dev` connected.
Future<(ProviderContainer, _Server)> _launch(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final server = _Server();
  appRouter.go('/all');
  // A scope the tree owns, so its timers end with the tree.
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        wsServerProvider.overrideWithValue(server),
        consoleEntriesProvider.overrideWith(_Logs.new),
      ],
      child: const DevConnectApp(),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(DevConnectApp)),
  );
  server.connect(
    const DeviceInfo(
      deviceId: 'dev',
      deviceName: 'iPhone 15',
      platform: 'react_native',
      osVersion: 'iOS 18.0',
      appName: 'okicom',
      appVersion: '1.0.0',
    ),
  );
  await tester.pump();
  await tester.pump();
  return (container, server);
}

/// Clicks [label] in the sidebar.
Future<void> _go(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(Sidebar), matching: find.text(label)),
  );
  await tester.pump();
  await tester.pump();
}

/// Opens "line 2" on All.
Future<void> _openLine2(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(EventRow, 'line 2'));
  await tester.pump();
  expect(find.byType(EventDetailPanel), findsOneWidget);
}

void _expectLine2StillOpen(WidgetTester tester) {
  final panel = tester.widget<EventDetailPanel>(find.byType(EventDetailPanel));
  expect(panel.event.id, 'e2');
  expect(
    tester.widget<EventRow>(find.widgetWithText(EventRow, 'line 2')).isSelected,
    isTrue,
  );
}

final _count = NotifierProvider<_Count, int>(_Count.new);

class _Count extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

class _Probe extends ConsumerStatefulWidget {
  final List<(int?, int)> heard;
  final VoidCallback onShownAgain;

  const _Probe(this.heard, this.onShownAgain);

  @override
  ConsumerState<_Probe> createState() => _ProbeState();
}

class _ProbeState extends ConsumerState<_Probe> with ListenWhileShown {
  @override
  void initState() {
    super.initState();
    listenWhileShown(_count, (previous, next) {
      widget.heard.add((previous, next));
    });
  }

  @override
  void onShownAgain() => widget.onShownAgain();

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  testWidgets('an event open on All is still open and selected after a '
      'visit to Network, and what came in meanwhile is listed', (tester) async {
    final (container, _) = await _launch(tester);
    await _openLine2(tester);

    await _go(tester, 'Network');
    expect(find.byType(NetworkInspectorPage), findsOneWidget);
    expect(find.byType(EventDetailPanel), findsNothing);
    (container.read(consoleEntriesProvider.notifier) as _Logs).add();
    await tester.pump();

    await _go(tester, 'All');
    _expectLine2StillOpen(tester);
    expect(find.widgetWithText(EventRow, 'line 4'), findsOneWidget);
  });

  testWidgets('a visit to a disabled tab keeps the other pages as they '
      'were', (tester) async {
    final (container, _) = await _launch(tester);
    final tabs = container.read(tabVisibilityProvider.notifier);
    tabs.toggle(TabKey.network);
    await tester.pump();
    await _openLine2(tester);

    await _go(tester, 'Network');
    expect(find.text('Tab Disabled'), findsOneWidget);

    await _go(tester, 'All');
    _expectLine2StillOpen(tester);
    tabs.toggle(TabKey.network);
  });

  testWidgets('Database and the Key-Value stores ask the app again each time '
      'they are shown again', (tester) async {
    final (_, server) = await _launch(tester);
    int asked(String type) => server.sent.where((m) => m.type == type).length;

    await _go(tester, 'Database');
    expect(asked(WsMessageTypes.serverDatabaseRequestSchema), 1);
    await _go(tester, 'All');
    await _go(tester, 'Database');
    expect(asked(WsMessageTypes.serverDatabaseRequestSchema), 2);

    await _go(tester, 'Storage');
    await tester.tap(find.text('Key-Value'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(asked(WsMessageTypes.serverStorageRequestAll), 1);
    await _go(tester, 'All');
    await _go(tester, 'Storage');
    expect(asked(WsMessageTypes.serverStorageRequestAll), 2);
  });

  testWidgets('a hidden page hears nothing and, shown again, gets the '
      'current value', (tester) async {
    final heard = <(int?, int)>[];
    var shownAgain = 0;
    final shown = ValueNotifier(true);
    addTearDown(shown.dispose);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ValueListenableBuilder<bool>(
          valueListenable: shown,
          builder: (_, on, _) =>
              TickerMode(enabled: on, child: _Probe(heard, () => shownAgain++)),
        ),
      ),
    );
    container.read(_count.notifier).bump();
    await tester.pump();
    expect(heard, [(null, 0), (0, 1)]);

    shown.value = false;
    await tester.pump();
    container.read(_count.notifier).bump();
    container.read(_count.notifier).bump();
    await tester.pump();
    expect(heard, hasLength(2));

    shown.value = true;
    await tester.pump();
    expect(heard.last, (null, 3));
    expect(shownAgain, 1);
  });
}
