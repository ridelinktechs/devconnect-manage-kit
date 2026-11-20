import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/features/layout_inspector/provider/layout_providers.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';
import 'package:devconnect_manage_tool/server/ws_message_handler.dart';

import '../../helpers/fake_ws_server.dart';

Map<String, dynamic> node(
  String id,
  num x,
  num y,
  num w,
  num h, [
  List<Map<String, dynamic>> children = const [],
]) => {
  'id': id,
  'name': 'N$id',
  'x': x,
  'y': y,
  'w': w,
  'h': h,
  'props': {'flex': 1, 'gone': null},
  'children': children,
};

void main() {
  // A screen, a header and a body; the body holds a button wrapped by a
  // component of the same size, plus a card the button overlaps.
  final root = LayoutNode.fromJson(
    node('screen', 0, 0, 400, 800, [
      node('header', 0, 0, 400, 60),
      node('body', 0, 60, 400, 740, [
        node('card', 0, 100, 400, 300),
        node('button', 20, 120, 100, 40, [node('view', 20, 120, 100, 40)]),
      ]),
    ]),
  )!;

  test('parses nodes, dropping null props and non-map children', () {
    final parsed = LayoutNode.fromJson({
      ...node('a', 1, 2, 3.5, 4),
      'padding': [8, 4, 8, 4.5],
      'margin': [1, 2],
      'children': [node('b', 0, 0, 1, 1), 'junk', null],
    })!;
    expect(parsed.rect, const Rect.fromLTWH(1, 2, 3.5, 4));
    expect(parsed.props, {'flex': '1'});
    expect(parsed.padding, const EdgeInsets.fromLTRB(8, 4, 8, 4.5));
    expect(parsed.margin, isNull); // malformed
    expect(parsed.children.map((c) => c.id), ['b']);
    expect(LayoutNode.fromJson('nope'), isNull);
  });

  test('finds the innermost element under a point', () {
    List<String> ids(Offset p) =>
        layoutPathAt(root, p).map((n) => n.id).toList();
    expect(ids(const Offset(10, 10)), ['screen', 'header']);
    expect(ids(const Offset(200, 200)), ['screen', 'body', 'card']);
    // The smaller box wins over the card it sits on.
    expect(ids(const Offset(50, 130)), ['screen', 'body', 'button', 'view']);
    expect(ids(const Offset(500, 10)), isEmpty);
  });

  test('names a box by the outermost element drawing it', () {
    expect(layoutElementAt(root, const Offset(50, 130))?.id, 'button');
    expect(layoutElementAt(root, const Offset(200, 600))?.id, 'body');
    expect(layoutElementAt(root, const Offset(-1, 0)), isNull);
  });

  test('a box drawn by nested elements is one chain', () {
    final button = layoutPathTo(root, 'button').last;
    expect(layoutChainOf(button).map((n) => n.id), ['button', 'view']);
    expect(layoutChainOf(root).map((n) => n.id), ['screen']);
  });

  test('lists rows by chain, children only under open rows', () {
    final rows = layoutTreeRows(root, {'screen', 'body'});
    expect(rows.map((r) => (r.$1.first.id, r.$2)), [
      ('screen', 0),
      ('header', 1),
      ('body', 1),
      ('card', 2),
      ('button', 2),
    ]);
    expect(rows.last.$1.map((n) => n.id), ['button', 'view']);
    expect(layoutTreeRows(root, const {}), hasLength(1));
    expect(layoutNodeCount(root), 6);
  });

  // A PNG header: signature, IHDR length and type, then 810 × 1920.
  final pngHeader = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, //
    0x49, 0x48, 0x44, 0x52, 0, 0, 3, 0x2A, 0, 0, 7, 0x80,
  ]);

  test('reads a PNG\'s size from its header', () {
    expect(pngSize(pngHeader), const Size(810, 1920));
    expect(pngSize(Uint8List(30)), isNull);
  });

  test('reads host, local and state, and writes it all back', () {
    final parsed = LayoutNode.fromJson({
      ...node('a', 0, 0, 1, 1),
      'host': true,
      'local': false,
      'state': {'#1': 'loaded', 'gone': null},
    })!;
    expect((parsed.host, parsed.local), (true, false));
    expect(parsed.state, {'#1': 'loaded'});
    expect(LayoutNode.fromJson(parsed.toJson())!.toJson(), parsed.toJson());
  });

  test('the app-only view drops native views, keeping their children', () {
    final tree = LayoutNode.fromJson(
      node('app', 0, 0, 10, 10, [
        {
          ...node('rct', 0, 0, 10, 10, [node('card', 0, 0, 5, 5)]),
          'host': true,
        },
      ]),
    )!;
    expect(layoutFiltered(tree, isAppElement).children.map((c) => c.id), [
      'card',
    ]);
    // Flutter marks its own widgets; with no marks everything stays.
    final framework = {...node('x', 0, 0, 1, 1), 'local': false};
    expect(isAppElement(LayoutNode.fromJson(framework)!), isFalse);
    expect(isAppElement(LayoutNode.fromJson(node('y', 0, 0, 1, 1))!), isTrue);
  });

  test('search finds the rows holding a match, in tree order', () {
    expect(layoutSearch(root, 'nb'), ['body', 'button']);
    // `view` draws the same box as its parent: its row is `button`'s.
    expect(layoutSearch(root, 'NVIEW'), ['button']);
    expect(layoutSearch(root, '  '), isEmpty);
  });

  test('finds an element again in a new capture', () {
    Map<String, dynamic> reId(Map<String, dynamic> json) => {
      ...json,
      'id': '${json['id']}-2',
      'children': [
        for (final c in json['children'] as List)
          reId(c as Map<String, dynamic>),
      ],
    };
    final recaptured = LayoutNode.fromJson(reId(root.toJson()))!;
    final signature = layoutSignature(root, 'view')!;
    expect(layoutFindSignature(recaptured, signature), 'view-2');
    expect(layoutFindSignature(recaptured, [('Nope', 0)]), isNull);
  });

  test('measures between boxes', () {
    List<double> lengths(Rect a, Rect b) => [
      for (final (from, to) in layoutMeasure(a, b)) (to - from).distance,
    ];
    const outer = Rect.fromLTWH(0, 0, 100, 100);
    // Inside: top, bottom, left, right.
    expect(lengths(const Rect.fromLTWH(10, 20, 30, 40), outer), [
      20,
      40,
      10,
      60,
    ]);
    expect(lengths(outer, const Rect.fromLTWH(10, 20, 30, 40)), hasLength(4));
    // Side by side: one line across the gap, at the shared band's middle.
    final beside = layoutMeasure(outer, const Rect.fromLTWH(130, 50, 20, 100));
    expect(beside, [(const Offset(100, 75), const Offset(130, 75))]);
    // Below and to the left: both gaps.
    expect(lengths(outer, const Rect.fromLTWH(-50, 110, 20, 20)), [30, 10]);
    expect(
      layoutMeasure(outer, const Rect.fromLTWH(50, 50, 100, 100)),
      isEmpty,
    );
  });

  test('finds the path to an element', () {
    expect(layoutPathTo(root, 'view').map((n) => n.id), [
      'screen',
      'body',
      'button',
      'view',
    ]);
    expect(layoutPathTo(root, 'missing'), isEmpty);
  });

  group('snapshots', () {
    late FakeWsServer server;
    late WsMessageHandler handler;
    late ProviderContainer container;

    setUp(() {
      server = FakeWsServer();
      handler = WsMessageHandler(server: server);
      container = ProviderContainer(
        overrides: [wsMessageHandlerProvider.overrideWithValue(handler)],
      );
    });
    tearDown(() {
      handler.dispose();
      container.dispose();
    });

    test('a capture asks the device and keeps its answer', () async {
      container.read(layoutSnapshotsProvider.notifier).capture('dev');
      expect(server.sent.single.type, WsMessageTypes.serverLayoutCapture);
      expect(server.sentTo.single, 'dev');
      expect(container.read(layoutSnapshotsProvider.notifier).pending, {'dev'});

      server.emit(
        deviceMessage(WsMessageTypes.clientLayoutSnapshot, {
          'width': 400,
          'height': 800,
          'screenshot': base64Encode([1, 2, 3]),
          'root': node('screen', 0, 0, 400, 800),
          'truncated': true,
        }),
      );
      await Future<void>.delayed(Duration.zero);

      final snap = container.read(layoutSnapshotsProvider)['dev']!;
      expect(snap.size, const Size(400, 800));
      expect(snap.screenshot, [1, 2, 3]);
      expect(snap.root?.id, 'screen');
      expect(snap.truncated, isTrue);
      expect(container.read(layoutSnapshotsProvider.notifier).pending, isEmpty);
    });

    test('a closed capture is gone', () async {
      final notifier = container.read(layoutSnapshotsProvider.notifier);
      server.emit(
        deviceMessage(WsMessageTypes.clientLayoutSnapshot, {
          'width': 400,
          'height': 800,
          'root': node('screen', 0, 0, 400, 800),
        }),
      );
      await Future<void>.delayed(Duration.zero);
      notifier.clear('dev');
      expect(container.read(layoutSnapshotsProvider), isEmpty);
    });

    test('a bad screenshot still keeps the tree', () async {
      container.read(layoutSnapshotsProvider);
      server.emit(
        deviceMessage(WsMessageTypes.clientLayoutSnapshot, {
          'width': 400,
          'height': 800,
          'screenshot': '%%%',
          'root': node('screen', 0, 0, 400, 800),
        }),
      );
      await Future<void>.delayed(Duration.zero);
      final snap = container.read(layoutSnapshotsProvider)['dev']!;
      expect(snap.screenshot, isNull);
      expect(snap.root?.id, 'screen');
    });

    test('keeps the SDK\'s reason when it couldn\'t read the tree', () async {
      container.read(layoutSnapshotsProvider);
      server.emit(
        deviceMessage(WsMessageTypes.clientLayoutSnapshot, {
          'width': 400,
          'height': 800,
          'root': node('root', 0, 0, 400, 800),
          'error': 'React DevTools hook not found (dev builds only)',
        }),
      );
      await Future<void>.delayed(Duration.zero);
      final snap = container.read(layoutSnapshotsProvider)['dev']!;
      expect(snap.error, contains('dev builds only'));
    });

    test('the screenshot sets the canvas shape', () async {
      container.read(layoutSnapshotsProvider);
      server.emit(
        deviceMessage(WsMessageTypes.clientLayoutSnapshot, {
          'width': 411,
          'height': 870, // a window smaller than what was captured
          'screenshot': base64Encode(pngHeader),
          'root': node('root', 0, 0, 411, 870),
        }),
      );
      await Future<void>.delayed(Duration.zero);
      final size = container.read(layoutSnapshotsProvider)['dev']!.size;
      expect(size.width, 411);
      expect(size.height, closeTo(411 * 1920 / 810, 0.01));
    });

    // testWidgets for its fake clock; made in the test's zone so the
    // answer runs on that clock too.
    testWidgets('an earlier capture\'s timeout leaves a newer one waiting', (
      tester,
    ) async {
      final server = FakeWsServer();
      final handler = WsMessageHandler(server: server);
      final container = ProviderContainer(
        overrides: [wsMessageHandlerProvider.overrideWithValue(handler)],
      );
      addTearDown(container.dispose);
      addTearDown(handler.dispose);
      final notifier = container.read(layoutSnapshotsProvider.notifier)
        ..capture('dev');
      await tester.pump(const Duration(seconds: 10));
      server.emit(
        deviceMessage(WsMessageTypes.clientLayoutSnapshot, {
          'width': 400,
          'height': 800,
          'root': node('screen', 0, 0, 400, 800),
        }),
      );
      await tester.pump();
      // Closed, then captured again: the first capture's 15 s run out
      // while the second waits.
      notifier
        ..clear('dev')
        ..capture('dev');
      await tester.pump(const Duration(seconds: 6));
      expect(notifier.pending, {'dev'});
      expect(notifier.unanswered, isEmpty);
      await tester.pump(LayoutSnapshotsNotifier.timeout);
      expect(notifier.unanswered, {'dev'}); // its own timeout still counts
    });

    // testWidgets for its fake clock.
    testWidgets('a capture nobody answers stops waiting', (tester) async {
      final notifier = container.read(layoutSnapshotsProvider.notifier)
        ..capture('dev');
      await tester.pump(LayoutSnapshotsNotifier.timeout);
      expect(notifier.pending, isEmpty);
      expect(notifier.unanswered, {'dev'}); // the page says so
    });
  });
}
