import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/features/state_inspector/presentation/event_row/state_change_tile.dart';
import 'package:devconnect_manage_tool/features/state_inspector/presentation/header/manager_filter_chip.dart';
import 'package:devconnect_manage_tool/features/state_inspector/presentation/pages/state_inspector_page.dart';
import 'package:devconnect_manage_tool/features/state_inspector/presentation/shared/diff_summary.dart';
import 'package:devconnect_manage_tool/features/state_inspector/presentation/shared/manager_look.dart';
import 'package:devconnect_manage_tool/features/state_inspector/provider/state_providers.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/models/state/state_change.dart';
import 'package:devconnect_manage_tool/server/protocol/dc_message.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';
import 'package:devconnect_manage_tool/server/ws_message_handler.dart';

import '../../helpers/fake_ws_server.dart';

var _seq = 0;

Map<String, dynamic> _change(
  String manager,
  String action, {
  List<Map<String, dynamic>> diff = const [],
  Map<String, dynamic> next = const {},
}) => {
  'stateManager': manager,
  'action': action,
  'nextState': next,
  'diff': diff,
};

Map<String, dynamic> _op(String path, String op, [Object? from, Object? to]) =>
    {'path': path, 'operation': op, 'oldValue': from, 'newValue': to};

class _Page {
  final FakeWsServer server;
  final ProviderContainer container;

  _Page(this.server, this.container);

  void send(Map<String, dynamic> payload) => server.emit(
    DCMessage(
      id: 'c${_seq++}',
      type: WsMessageTypes.clientStateChange,
      deviceId: 'dev',
      timestamp: 1700000000000 + _seq,
      payload: payload,
    ),
  );
}

/// The State Inspector in a [size] window with the RN device picked, after
/// [changes] arrived.
Future<_Page> _open(
  WidgetTester tester, {
  List<Map<String, dynamic>> changes = const [],
  Size size = const Size(1440, 900),
  String deviceName = 'Pixel 8',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final server = FakeWsServer();
  final handler = WsMessageHandler(server: server);
  final container = ProviderContainer(
    overrides: [wsMessageHandlerProvider.overrideWithValue(handler)],
  );
  addTearDown(() {
    container.dispose();
    handler.dispose();
  });
  container.read(connectedDevicesProvider);
  container.read(stateChangesProvider);
  server.connect(
    DeviceInfo(
      deviceId: 'dev',
      deviceName: deviceName,
      platform: 'react_native',
      osVersion: 'iOS 18.0',
      appName: 'okicom',
      appVersion: '1.0.0',
    ),
  );
  container.read(selectedDeviceProvider.notifier).select('dev');
  final page = _Page(server, container);
  changes.forEach(page.send);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const Scaffold(body: StateInspectorPage()),
          ),
        ),
      ),
    ),
  );
  await _deliver(tester);
  return page;
}

/// Two frames: device messages reach providers on a microtask, after the
/// first one.
Future<void> _deliver(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Finder _chip(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(ManagerFilterChip),
);

Finder _card(String action) => find.ancestor(
  of: find.text(action),
  matching: find.byType(StateChangeTile),
);

void main() {
  group('a reported state manager reads as', () {
    for (final (type, label, store) in [
      ('redux', 'Redux', null),
      ('zustand:cart', 'Zustand', 'cart'),
      ('ReactQuery::todos', 'React Query', 'todos'),
      ('valtio:settings', 'Valtio', 'settings'),
      ('xstate:checkout', 'XState', 'checkout'),
      ('Apollo', 'Apollo', null),
      ('cubit', 'BLoC', null),
      ('myStore', 'MyStore', null),
      ('', 'Unknown', null),
    ]) {
      test('"$type" → $label${store == null ? '' : ' · $store'}', () {
        final look = ManagerLook.of(type);
        expect((look.label, look.store), (label, store));
        expect(look.key, stateManagerKey(type));
      });
    }
  });

  test('a diff is counted by what it did, its paths kept in order', () {
    final diff = [
      for (final m in [
        _op('user.token', 'add', null, 'abc'),
        _op('user.name', 'replace', 'Ann', 'Bob'),
        _op('user.name', 'replace', 'Bob', 'Cy'),
        _op('cart', 'remove', {'a': 1}),
      ])
        StateDiffEntry.fromJson(m),
    ];
    final s = DiffSummary.of(diff);
    expect((s.added, s.changed, s.removed), (1, 2, 1));
    expect(s.paths, ['user.token', 'user.name', 'cart']);
    expect(s.onlyLine, isNull);
    expect(DiffSummary.of(const []).isEmpty, isTrue);
  });

  test('a single change reads as one line, values kept short', () {
    String line(Map<String, dynamic> op) =>
        DiffSummary.of([StateDiffEntry.fromJson(op)]).onlyLine!;
    expect(
      line(_op('theme', 'replace', 'light', 'dark')),
      'theme  "light" → "dark"',
    );
    expect(
      line(_op('items.2', 'add', null, {'id': 7, 'qty': 1})),
      'items.2  + {2}',
    );
    expect(line(_op('tags', 'remove', [1, 2, 3])), 'tags  − [3]');
    expect(briefValue('x' * 30), '"${'x' * 23}…"');
    expect(briefValue(null), 'null');
    expect(briefValue(4.5), '4.5');
  });

  testWidgets('a card shows the library, its store, the device, the action, '
      'what the diff did and where', (tester) async {
    await _open(
      tester,
      changes: [
        _change(
          'zustand:cart',
          'addItem',
          diff: [_op('items.2', 'add', null, 1), _op('total', 'replace', 2, 3)],
        ),
        _change(
          'mobx',
          'setTheme',
          diff: [_op('theme', 'replace', 'light', 'dark')],
        ),
        _change('jotai', 'countAtom', next: {'count': 3, 'step': 1}),
        _change(
          'redux',
          'cart/checkout',
          diff: [
            for (var i = 0; i < 9; i++) _op('cart.lines.$i', 'replace', 0, 1),
          ],
        ),
      ],
    );
    final cart = _card('addItem');
    for (final text in [
      'ZUSTAND',
      'cart',
      'RN',
      'okicom · Pixel 8',
      '+1',
      '~1',
      'items.2 · total',
    ]) {
      expect(
        find.descendant(of: cart, matching: find.text(text)),
        findsOneWidget,
        reason: text,
      );
    }
    expect(
      find.descendant(
        of: _card('setTheme'),
        matching: find.text('theme  "light" → "dark"'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _card('countAtom'),
        matching: find.text('state: count, step'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _card('cart/checkout'), matching: find.text('  +3')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _card('cart/checkout'), matching: find.text('~9')),
      findsOneWidget,
    );
  });

  testWidgets('the header has a chip per library with its count, and a chip '
      'hides and shows its changes', (tester) async {
    final page = await _open(
      tester,
      changes: [
        _change('redux', 'user/login'),
        _change('zustand:cart', 'addItem'),
        _change('zustand:user', 'setName'),
        _change('redux', 'user/logout'),
      ],
    );
    expect(
      find.descendant(of: _chip('REDUX'), matching: find.text('2')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _chip('ZUSTAND'), matching: find.text('2')),
      findsOneWidget,
    );
    expect(find.byType(StateChangeTile), findsNWidgets(4));

    await tester.tap(_chip('ZUSTAND'));
    await tester.pump();
    expect(find.byType(StateChangeTile), findsNWidgets(2));
    expect(find.text('addItem'), findsNothing);
    expect(page.container.read(filteredStateChangesProvider), hasLength(2));
    expect(
      find.descendant(of: _chip('ZUSTAND'), matching: find.text('2')),
      findsOneWidget,
      reason: 'the count still says what turning it back on brings',
    );

    await tester.tap(_chip('REDUX'));
    await tester.pump();
    expect(find.text('No changes match'), findsOneWidget);

    await tester.tap(_chip('REDUX'));
    await tester.tap(_chip('ZUSTAND'));
    await tester.pump();
    expect(find.byType(StateChangeTile), findsNWidgets(4));
  });

  testWidgets('the filter keeps its text across tabs, and the timeline\'s '
      'controls show only on its tab', (tester) async {
    await _open(
      tester,
      changes: [_change('redux', 'cart/add'), _change('redux', 'user/login')],
    );
    await tester.enterText(find.byType(TextField), 'cart');
    await tester.pump();
    expect(find.byType(StateChangeTile), findsOneWidget);

    await tester.tap(find.text('State Managers'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ManagerFilterChip), findsNothing);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Timeline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'cart');
    expect(find.byType(StateChangeTile), findsOneWidget);
  });

  testWidgets('the Timeline tab counts what the filters leave', (tester) async {
    await _open(
      tester,
      changes: [
        _change('redux', 'a'),
        _change('mobx', 'b'),
        _change('mobx', 'c'),
      ],
    );
    Finder tabCount(String n) => find.descendant(
      of: find.ancestor(
        of: find.text('Timeline'),
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_TabButton',
        ),
      ),
      matching: find.text(n),
    );
    expect(tabCount('3'), findsOneWidget);
    await tester.tap(_chip('MOBX'));
    await tester.pump();
    expect(tabCount('1'), findsOneWidget);
  });

  testWidgets('with nothing reported yet, the empty state says so', (
    tester,
  ) async {
    final page = await _open(tester);
    expect(
      find.text(
        S.of(tester.element(find.byType(StateInspectorPage))).noStateChanges,
      ),
      findsOneWidget,
    );
    page.send(_change('redux', 'first'));
    await _deliver(tester);
    expect(find.text('first'), findsOneWidget);
  });

  testWidgets('the page fits the narrowest window with many libraries and a '
      'long device name', (tester) async {
    await _open(
      tester,
      size: const Size(831, 600),
      deviceName: 'iPhone 15 Pro Max (Simulator)',
      changes: [
        for (final m in [
          'redux',
          'zustand:a-really-long-store-name',
          'mobx',
          'xstate:checkout',
          'jotai',
          'valtio:x',
          'ReactQuery::todos',
        ])
          _change(
            m,
            'an/action/with/a/rather/long/name/for/the/card',
            diff: [
              _op('a.b.c', 'add', null, 1),
              _op('d', 'replace', 1, 2),
              _op('e', 'remove', 3),
            ],
          ),
      ],
    );
    expect(find.byType(ManagerFilterChip), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
