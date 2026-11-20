import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/core/preferences/app_preferences.dart';
import 'package:devconnect_manage_tool/features/state_inspector/presentation/event_row/state_change_tile.dart';
import 'package:devconnect_manage_tool/features/settings/presentation/tips/page_guide_button.dart';
import 'package:devconnect_manage_tool/features/state_inspector/presentation/pages/state_inspector_page.dart';
import 'package:devconnect_manage_tool/features/state_inspector/presentation/shared/state_setup_code.dart';
import 'package:devconnect_manage_tool/features/state_inspector/provider/state_providers.dart';
import 'package:devconnect_manage_tool/features/state_inspector/provider/state_tools_providers.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/server/protocol/dc_message.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';
import 'package:devconnect_manage_tool/server/ws_message_handler.dart';

import '../../helpers/fake_ws_server.dart';

var _seq = 0;

const _state = {
  'auth': {
    'user': {'name': 'Ada', 'nick': null},
  },
  'cart': {
    'items': [
      {'price': 1},
      {'price': 9.5},
    ],
  },
};

class _Page {
  final FakeWsServer server;
  final ProviderContainer container;

  _Page(this.server, this.container);

  /// The app reports a Redux change that leaves [next] as its state.
  void report(String action, Map<String, dynamic> next) => server.emit(
    DCMessage(
      id: 'c${_seq++}',
      type: WsMessageTypes.clientStateChange,
      deviceId: 'dev',
      timestamp: 1700000000000 + _seq,
      payload: {'stateManager': 'redux', 'action': action, 'nextState': next},
    ),
  );

  /// What the desktop sent the device last, of [type].
  DCMessage? last(String type) =>
      server.sent.where((m) => m.type == type).lastOrNull;
}

/// The State Inspector on its Controls tab, the device connected unless
/// [device] is false, after the app reported [state] (if any).
Future<_Page> _open(
  WidgetTester tester, {
  bool device = true,
  Map<String, dynamic>? state,
  String platform = 'react_native',
}) async {
  tester.view.physicalSize = const Size(1440, 900);
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
  final page = _Page(server, container);
  container.read(connectedDevicesProvider);
  container.read(stateChangesProvider);
  if (device) {
    server.connect(
      DeviceInfo(
        deviceId: 'dev',
        deviceName: 'Pixel 8',
        platform: platform,
        osVersion: 'iOS 18.0',
        appName: 'okicom',
        appVersion: '1.0.0',
      ),
    );
    container.read(selectedDeviceProvider.notifier).select('dev');
  }
  if (state != null) page.report('app/boot', state);
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
  await tester.pump();
  await tester.pump();
  await tester.tap(find.text('Controls'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return page;
}

Finder get _pathField => find.byType(TextField).at(0);
Finder get _actionField => find.byType(TextField).at(1);

/// Two frames: device messages reach providers on a microtask, after the
/// first one.
Future<void> _deliver(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// Lets the toasts run out.
Future<void> _settle(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 3));

void main() {
  tearDown(() => AppPreferences().set('state_subscriptions', null));

  testWidgets('with no device picked, Controls asks for one', (tester) async {
    await _open(tester, device: false);
    expect(
      find.text(
        'Select a device in the bottom bar to watch, snapshot and drive its '
        'state.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('before the app reports any state, nothing can be snapshot', (
    tester,
  ) async {
    await _open(tester);
    expect(
      find.text('This device hasn\'t reported any state yet.'),
      findsOneWidget,
    );
    final take = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Take snapshot'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(take.onPressed, isNull);
  });

  testWidgets('a pinned path shows its live value and follows the app; a '
      'missing path reads apart from null; pins are kept', (tester) async {
    final page = await _open(tester, state: _state);
    Future<void> pin(String path) async {
      await tester.enterText(_pathField, path);
      await tester.tap(find.byTooltip('Pin path'));
      await tester.pump();
    }

    await pin('auth.user.name');
    expect(find.text('"Ada"'), findsOneWidget);
    await pin('cart.items[1].price');
    expect(find.text('9.5'), findsOneWidget);
    await pin('auth.user.nick');
    expect(find.text('null'), findsOneWidget);
    await pin('auth.user.age');
    expect(find.text('(not in state)'), findsOneWidget);
    await pin('auth.user.name');
    await pin('   ');
    expect(page.container.read(stateSubscriptionsProvider), [
      'auth.user.name',
      'cart.items[1].price',
      'auth.user.nick',
      'auth.user.age',
    ], reason: 'the same path pins once, and a blank one not at all');

    page.report('user/rename', {
      'auth': {
        'user': {'name': 'Bob'},
      },
    });
    await _deliver(tester);
    expect(find.text('"Bob"'), findsOneWidget);
    expect(find.text('"Ada"'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find
            .ancestor(
              of: find.text('auth.user.age'),
              matching: find.byType(Row),
            )
            .first,
        matching: find.byTooltip('Remove'),
      ),
    );
    await tester.pump();
    expect(find.text('auth.user.age'), findsNothing);
    expect(
      AppPreferences().get<String>('state_subscriptions'),
      '["auth.user.name","cart.items[1].price","auth.user.nick"]',
    );
  });

  testWidgets('a snapshot keeps the state, and Restore sends it to the '
      'device', (tester) async {
    final page = await _open(tester, state: _state);
    await tester.tap(find.text('Take snapshot'));
    await tester.pump();
    expect(find.textContaining('Snapshot '), findsOneWidget);
    expect(find.text('okicom · 2 keys'), findsOneWidget);

    page.report('cart/clear', {'cart': {}});
    await _deliver(tester);
    await tester.tap(find.text('Restore'));
    await tester.pump();
    final restore = page.last(WsMessageTypes.serverStateRestore)!;
    expect(page.server.sentTo.last, 'dev');
    expect(restore.payload['state'], _state);
    expect(find.text('State restore sent'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pump();
    expect(find.text('Restore'), findsNothing);
    expect(page.container.read(stateSnapshotsProvider), isEmpty);
    await _settle(tester);
  });

  testWidgets('Dispatch sends a JSON object to the device as a Redux action, '
      'keeps it under Recent, and refuses anything else', (tester) async {
    final page = await _open(tester, state: _state);
    Future<void> dispatch(String text) async {
      await tester.enterText(_actionField, text);
      await tester.tap(find.text('Dispatch'));
      await tester.pump();
    }

    for (final bad in ['LOGOUT', '[1, 2]', '"x"', '{"type": ']) {
      await dispatch(bad);
      expect(
        find.text('The action must be a JSON object.'),
        findsOneWidget,
        reason: bad,
      );
    }
    expect(page.last(WsMessageTypes.serverReduxDispatch), isNull);

    await dispatch('{"type": "LOGOUT"}');
    expect(find.text('The action must be a JSON object.'), findsNothing);
    final sent = page.last(WsMessageTypes.serverReduxDispatch)!;
    expect(page.server.sentTo.last, 'dev');
    expect(sent.payload, {
      'action': {'type': 'LOGOUT'},
    });
    expect(find.text('Action dispatched'), findsOneWidget);

    await dispatch('{"type": "cart/add", "id": 7}');
    await dispatch('{"type": "LOGOUT"}');
    expect(page.container.read(dispatchHistoryProvider), [
      '{"type":"LOGOUT"}',
      '{"type":"cart/add","id":7}',
    ]);

    await tester.tap(find.text('{"type":"cart/add","id":7}'));
    await tester.pump();
    expect(
      tester.widget<TextField>(_actionField).controller!.text,
      '{\n  "type": "cart/add",\n  "id": 7\n}',
    );
    await _settle(tester);
  });

  testWidgets('the Timeline\'s detail panel restores, or snapshots, the state '
      'right after a change', (tester) async {
    final page = await _open(tester, state: _state);
    page.report('cart/clear', {'cart': {}});
    await _deliver(tester);
    await tester.tap(find.text('Timeline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(
      find.ancestor(
        of: find.text('app/boot'),
        matching: find.byType(StateChangeTile),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Restore the app\'s state to this point'));
    await tester.pump();
    expect(
      page.last(WsMessageTypes.serverStateRestore)!.payload['state'],
      _state,
    );

    await tester.tap(find.byTooltip('Save as snapshot'));
    await tester.pump();
    final snapshot = page.container.read(stateSnapshotsProvider).single;
    expect(snapshot.name, startsWith('app/boot · '));
    expect(snapshot.state, _state);
    await _settle(tester);
  });

  for (final (platform, name, restore, dispatch) in [
    (
      'react_native',
      'React Native',
      'DevConnect.onStateRestore((state) =>',
      'DevConnect.connectReduxStore(store);',
    ),
    (
      'flutter',
      'Flutter',
      '(state) => store.restore(state);',
      '(action) => store.dispatch(action);',
    ),
    (
      'android',
      'Android',
      'DevConnect.onStateRestore = { state ->',
      'DevConnect.onReduxDispatch = { action ->',
    ),
  ]) {
    testWidgets('on $name, Restore and Dispatch each show the app code they '
        'need', (tester) async {
      await _open(tester, state: _state, platform: platform);
      final setup = find.text('Set up in your $name app');
      expect(setup, findsNWidgets(2));
      expect(find.textContaining(restore), findsNothing, reason: 'closed');

      await tester.tap(setup.first);
      await tester.pump();
      expect(find.textContaining(restore), findsOneWidget);
      expect(find.textContaining(dispatch), findsNothing);

      await tester.tap(setup.last);
      await tester.pump();
      expect(find.textContaining(dispatch), findsOneWidget);
    });
  }

  testWidgets('a platform with no such code shows no setup', (tester) async {
    await _open(tester, state: _state, platform: 'web');
    expect(find.textContaining('Set up in your'), findsNothing);
  });

  testWidgets('the State page\'s guide explains the controls with code for '
      'every platform', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (context) {
            final guides = guidesForPage(S.of(context), '/state');
            final controls = guides.singleWhere(
              (g) => g.title == 'Control state from the desktop',
            );
            expect(controls.code.map((c) => c.$1), [
              'React Native · App.tsx',
              'Flutter · main.dart',
              'Android · Application.kt',
            ]);
            final [rn, flutter, android] = [
              for (final c in controls.code) c.$2,
            ];
            expect(rn, contains('connectReduxStore(store)'));
            expect(rn, contains('onStateRestore'));
            expect(flutter, contains('DevConnect.onReduxDispatch ='));
            expect(
              '// after await DevConnect.init(...)'.allMatches(flutter),
              hasLength(1),
            );
            expect(android, contains('DevConnect.onStateRestore ='));
            expect(stateControlsSetup('android'), android);
            return const SizedBox();
          },
        ),
      ),
    );
  });
}
