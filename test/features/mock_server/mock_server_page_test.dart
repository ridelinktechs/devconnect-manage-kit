import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/features/mock_server/presentation/editor/body_field.dart';
import 'package:devconnect_manage_tool/features/mock_server/presentation/editor/hold_to_delete.dart';
import 'package:devconnect_manage_tool/features/mock_server/presentation/list/rule_card.dart';
import 'package:devconnect_manage_tool/features/mock_server/presentation/mock_server_page.dart';
import 'package:devconnect_manage_tool/features/round/provider/round_providers.dart';
import 'package:devconnect_manage_tool/features/settings/presentation/controls/stretch_switch.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/models/round/mock_entry.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';
import 'package:devconnect_manage_tool/server/ws_message_handler.dart';

import '../../helpers/fake_ws_server.dart';

const _pixel = DeviceInfo(
  deviceId: 'dev',
  deviceName: 'Pixel 8',
  platform: 'android',
  osVersion: '15',
  appName: 'okicom',
  appVersion: '1.0.0',
);

MockRule _rule(
  String id,
  String name, {
  int status = 200,
  String body = '{"ok":true}',
  Map<String, dynamic>? md,
}) => MockRule(
  id: id,
  name: name,
  method: 'GET',
  urlPattern: '/api/$id',
  statusCode: status,
  headers: const {'Content-Type': 'application/json'},
  body: body,
  enabled: true,
  hitCount: 0,
  updatedAt: 0,
  metadata: md,
);

class _Page {
  final FakeWsServer server;
  final ProviderContainer container;

  _Page(this.server, this.container);

  List<MockRule> get rules => container.read(mockRulesProvider);
  MockRule rule(String id) => rules.firstWhere((r) => r.id == id);
  String? get selected => container.read(selectedMockRuleIdProvider);

  /// The rule list the device got last, as the SDKs read it.
  List<Map<String, dynamic>> get pushed => [
    for (final r in server.sent.last.payload['rules'] as List)
      r as Map<String, dynamic>,
  ];

  void connectDevice([DeviceInfo device = _pixel]) {
    server.connect(device);
    container.read(selectedDeviceProvider.notifier).select(device.deviceId);
  }
}

/// The Mock Server page in a [size] window, with [rules], [selected] open,
/// and the Pixel connected and picked unless [device] is false.
Future<_Page> _open(
  WidgetTester tester, {
  List<MockRule> rules = const [],
  String? selected,
  bool device = true,
  bool animations = false,
  Size size = const Size(1440, 1000),
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
  final page = _Page(server, container);
  container.read(connectedDevicesProvider);
  container.read(mockAuditEntriesProvider);
  if (device) page.connectDevice();
  for (final r in rules) {
    container.read(mockRulesProvider.notifier).add(r);
  }
  container.read(selectedMockRuleIdProvider.notifier).set(selected);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: !animations),
            child: const Scaffold(body: MockServerPage()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return page;
}

Finder _box(String label) => find.widgetWithText(TextField, label);

final _body = find.descendant(
  of: find.byType(BodyField),
  matching: find.byType(TextField),
);

/// Scrolls [finder] into view and taps it.
Future<void> _tapShown(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

String _text(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(field).controller!.text;

Future<void> _type(WidgetTester tester, String label, String text) async {
  await tester.enterText(_box(label), text);
  await tester.pump();
}

/// Two frames: device messages reach providers on a microtask, after the
/// first one.
Future<void> _deliver(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// Lets toasts and the unsaved bar's timers run out.
Future<void> _settleTimers(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 3));

Future<void> _hold(WidgetTester tester, Duration howLong) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(HoldToDelete)),
    kind: PointerDeviceKind.mouse,
  );
  for (var t = 0; t < howLong.inMilliseconds; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  testWidgets('a template on the empty page flies into the folder, then the '
      'rule is made and opened', (tester) async {
    final page = await _open(tester, animations: true);
    expect(find.text('No mock rules yet'), findsOneWidget);

    await tester.tap(find.text('Server error'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(page.rules, isEmpty, reason: 'still flying');
    for (var t = 0; t < 700; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final rule = page.rules.single;
    expect(
      (rule.name, rule.urlPattern, rule.statusCode),
      ('Server error', '/api/', 500),
    );
    expect(page.selected, rule.id);
    expect(_text(tester, _box('Rule name')), 'Server error');
    expect(find.textContaining('Unsaved changes'), findsNothing);
  });

  testWidgets('Add rule makes a rule that opens with nothing unsaved, even '
      'though its JSON is shown indented', (tester) async {
    final page = await _open(
      tester,
      rules: [_rule('a', 'Compact')],
      selected: 'a',
    );
    expect(_text(tester, _body), '{\n  "ok": true\n}');
    expect(find.textContaining('Unsaved changes'), findsNothing);

    await tester.tap(find.text('Add rule'));
    await tester.pump();
    expect(page.rules, hasLength(2));
    expect(page.selected, page.rules.last.id);
    expect(find.textContaining('Unsaved changes'), findsNothing);
  });

  testWidgets('the bar counts changed boxes; Discard restores them and Save '
      'stores them', (tester) async {
    final page = await _open(
      tester,
      rules: [_rule('a', 'Users')],
      selected: 'a',
    );

    await _type(tester, 'Rule name', 'Renamed');
    await _type(tester, 'Status', '404');
    expect(find.text('Unsaved changes: 2'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pump();
    expect(_text(tester, _box('Rule name')), 'Users');
    expect(_text(tester, _box('Status')), '200');
    expect(page.rule('a').name, 'Users');

    await _type(tester, 'Rule name', 'Renamed');
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(page.rule('a').name, 'Renamed');
    expect(find.text('Saved'), findsOneWidget);
    await _settleTimers(tester);
  });

  testWidgets('⌘S saves from inside the editor', (tester) async {
    final page = await _open(
      tester,
      rules: [_rule('a', 'Users')],
      selected: 'a',
    );
    await _type(tester, 'Status', '201');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    expect(page.rule('a').statusCode, 201);
    await _settleTimers(tester);
  });

  testWidgets('a bad regex, status, delay, header line or expiry keeps the '
      'rule unsaved and says why under each box', (tester) async {
    final page = await _open(
      tester,
      rules: [_rule('a', 'Users')],
      selected: 'a',
    );
    await _type(tester, 'URL pattern', '/users/(\\d+');
    await _type(tester, 'Status', '99');
    await _type(tester, 'Delay (ms)', '-5');
    await _type(tester, 'Response headers', 'oops');
    await _type(tester, 'Expires at', 'tomorrow');

    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(find.text('Fix 5 fields first'), findsOneWidget);
    expect(find.textContaining('Not a valid regex'), findsOneWidget);
    expect(find.text('Use a status code from 100 to 599'), findsOneWidget);
    expect(find.text('Use whole milliseconds, 0 or more'), findsOneWidget);
    expect(find.text('Line 1 needs key: value'), findsOneWidget);
    expect(
      find.text('Use ISO-8601, e.g. 2026-12-31T23:59:59Z'),
      findsOneWidget,
    );
    expect(page.rule('a').urlPattern, '/api/a');
    expect(page.rule('a').statusCode, 200);

    await _type(tester, 'Status', '418');
    expect(find.text('Use a status code from 100 to 599'), findsNothing);
    await _settleTimers(tester);
  });

  testWidgets('presets fill the status and delay boxes', (tester) async {
    await _open(tester, rules: [_rule('a', 'Users')], selected: 'a');

    await _tapShown(tester, find.text('404'));
    expect(_text(tester, _box('Status')), '404');
    expect(find.text('Not Found'), findsOneWidget);

    await _tapShown(tester, find.text('3 s'));
    expect(_text(tester, _box('Delay (ms)')), '3000');
    expect(find.text('Answers after 3 s'), findsOneWidget);

    await _tapShown(tester, find.text('None'));
    expect(_text(tester, _box('Delay (ms)')), '');
    expect(find.text('Answers at once'), findsOneWidget);

    await _tapShown(tester, find.text('+ Pixel 8'));
    expect(_text(tester, _box('Only on device IDs')), 'dev');
    expect(find.text('+ Pixel 8'), findsNothing);
  });

  testWidgets('Format indents a JSON body, and other text is flagged as not '
      'JSON', (tester) async {
    await _open(tester, rules: [_rule('a', 'Users')], selected: 'a');

    await tester.enterText(_body, '{"a":[1,2]}');
    await tester.pump();
    await _tapShown(tester, find.text('Format'));
    expect(_text(tester, _body), '{\n  "a": [\n    1,\n    2\n  ]\n}');

    await tester.enterText(_body, 'hello');
    await tester.pump();
    expect(find.text('Not JSON, sent as text'), findsOneWidget);
  });

  testWidgets('with unsaved changes, picking another rule or adding one is '
      'refused until they are saved or discarded', (tester) async {
    final page = await _open(
      tester,
      rules: [_rule('a', 'Users'), _rule('b', 'Orders')],
      selected: 'a',
    );
    await _type(tester, 'Rule name', 'Users v2');

    await tester.tap(find.widgetWithText(RuleCard, 'Orders'));
    await tester.pump();
    expect(page.selected, 'a');
    expect(find.text('Save or discard first'), findsOneWidget);

    await tester.tap(find.text('Add rule'));
    await tester.pump();
    expect(page.rules, hasLength(2));

    await tester.tap(find.text('Discard'));
    await tester.pump();
    await tester.tap(find.widgetWithText(RuleCard, 'Orders'));
    await tester.pump();
    expect(page.selected, 'b');
    await _settleTimers(tester);
  });

  testWidgets('Push all needs one device, sends every rule, then keeps the '
      'device in step', (tester) async {
    final page = await _open(
      tester,
      rules: [_rule('a', 'Users'), _rule('b', 'Orders')],
      selected: 'a',
      device: false,
    );
    expect(find.text('No device selected'), findsOneWidget);
    await tester.tap(find.text('Push all'));
    await tester.pump();
    expect(page.server.sent, isEmpty);

    page.connectDevice();
    await tester.pump();
    expect(find.text('Pixel 8 · not pushed'), findsOneWidget);
    await tester.tap(find.text('Push all'));
    await tester.pump();
    expect(page.server.sent.last.type, WsMessageTypes.serverMockRulesInstall);
    expect(page.server.sentTo.last, 'dev');
    expect(page.pushed.map((r) => r['id']), ['a', 'b']);
    expect(find.text('Pixel 8 · live'), findsOneWidget);
    expect(find.text('Pushed 2 rules'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(RuleCard, 'Orders'),
        matching: find.byType(StretchSwitch),
      ),
    );
    await tester.pump();
    expect(page.pushed.last['enabled'], isFalse);

    await _type(tester, 'Rule name', 'Users v2');
    expect(page.pushed.first['name'], 'Users', reason: 'not saved yet');
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(page.pushed.first['name'], 'Users v2');
    await _settleTimers(tester);
  });

  testWidgets('Clear device empties the device\'s rules and stops keeping it '
      'in step', (tester) async {
    final page = await _open(
      tester,
      rules: [_rule('a', 'Users')],
      selected: 'a',
    );
    await tester.tap(find.text('Push all'));
    await tester.pump();
    await tester.tap(find.text('Clear device'));
    await tester.pump();
    expect(page.pushed, isEmpty);
    expect(find.text('Pixel 8 · not pushed'), findsOneWidget);

    final sent = page.server.sent.length;
    await _type(tester, 'Rule name', 'Users v2');
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(page.server.sent, hasLength(sent));
    await _settleTimers(tester);
  });

  testWidgets('a short press of Hold to delete does nothing; holding it '
      'deletes the rule everywhere, and Undo puts it back in place', (
    tester,
  ) async {
    final page = await _open(
      tester,
      rules: [_rule('a', 'Users'), _rule('b', 'Orders'), _rule('c', 'Me')],
      selected: 'b',
    );
    await tester.tap(find.text('Push all'));
    await tester.pump();

    await _hold(tester, const Duration(milliseconds: 400));
    expect(page.rules, hasLength(3));

    await _hold(tester, const Duration(milliseconds: 1300));
    expect(page.rules.map((r) => r.id), ['a', 'c']);
    expect(page.pushed.map((r) => r['id']), ['a', 'c']);
    expect(find.text('Rule deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(page.rules.map((r) => r.id), ['a', 'b', 'c']);
    expect(page.pushed.map((r) => r['id']), ['a', 'b', 'c']);
    expect(page.selected, 'b');
    expect(_text(tester, _box('Rule name')), 'Orders');
    await _settleTimers(tester);
  });

  testWidgets('deleting the last rule brings back the empty page, with Undo', (
    tester,
  ) async {
    final page = await _open(
      tester,
      rules: [_rule('a', 'Users')],
      selected: 'a',
    );
    await _hold(tester, const Duration(milliseconds: 1300));
    expect(page.rules, isEmpty);
    expect(find.text('No mock rules yet'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(page.rules.single.id, 'a');
    expect(page.selected, 'a');
  });

  testWidgets('a card counts the requests the device answered with its rule', (
    tester,
  ) async {
    final page = await _open(
      tester,
      rules: [_rule('a', 'Users'), _rule('b', 'Orders')],
    );
    for (var i = 0; i < 2; i++) {
      page.server.emit(
        deviceMessage(WsMessageTypes.clientMockedRequest, {
          'ruleId': 'a',
          'url': 'https://api.example.com/api/a',
          'method': 'GET',
          'status': 200,
        }),
      );
    }
    await _deliver(tester);
    expect(
      find.descendant(
        of: find.widgetWithText(RuleCard, 'Users'),
        matching: find.text('2 hits'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(RuleCard, 'Orders'),
        matching: find.text('no hits'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the page fits the narrowest window (900 px less the sidebar), '
      'with a long device name and a rule full of labels', (tester) async {
    final page = await _open(
      tester,
      size: const Size(831, 600),
      device: false,
      rules: [
        _rule(
          'a',
          'A rule with a rather long name for its card',
          status: 503,
          md: {
            'delayMs': 12500,
            'scope': {
              'deviceIds': ['x', 'y', 'z'],
            },
            'expiresAt': '2020-01-01T00:00:00Z',
          },
        ),
      ],
      selected: 'a',
    );
    page.connectDevice(
      const DeviceInfo(
        deviceId: 'sim',
        deviceName: 'iPhone 15 Pro Max (Simulator)',
        platform: 'react_native',
        osVersion: 'iOS 18.0',
        appName: 'okicom',
        appVersion: '1.0.0',
      ),
    );
    await tester.pump();
    expect(find.text('iPhone 15 Pro M… · not pushed'), findsOneWidget);
    await _type(tester, 'Rule name', 'Renamed');
    expect(find.text('Unsaved changes: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the device gets delay, devices, expiry and headers the way the '
      'SDKs read them, and metadata the editor hides survives', (tester) async {
    final page = await _open(
      tester,
      rules: [
        _rule(
          'a',
          'Users',
          md: {
            'matchHeaders': {'x-env': 'test'},
          },
        ),
      ],
      selected: 'a',
    );
    await tester.tap(find.text('Push all'));
    await tester.pump();

    await _type(tester, 'Delay (ms)', '300');
    await _type(tester, 'Only on device IDs', 'dev, other');
    await _type(tester, 'Expires at', '2030-01-01T00:00:00Z');
    await _type(
      tester,
      'Response headers',
      'Content-Type: application/json\nX-Mock: yes',
    );
    await _type(tester, 'Status', '503');
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    final wire = page.pushed.single;
    expect(wire['enabled'], isTrue);
    expect(wire['match'], {
      'method': 'GET',
      'url': '/api/a',
      'headers': {'x-env': 'test'},
    });
    expect(wire['response'], {
      'status': 503,
      'body': '{\n  "ok": true\n}',
      'headers': {'Content-Type': 'application/json', 'X-Mock': 'yes'},
      'delayMs': 300,
    });
    expect(wire['scope'], {
      'deviceIds': ['dev', 'other'],
    });
    expect(wire['expiresAt'], '2030-01-01T00:00:00Z');
    await _settleTimers(tester);
  });
}
