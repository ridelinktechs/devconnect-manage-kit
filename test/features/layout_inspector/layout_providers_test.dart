import 'dart:convert';

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
        }),
      );
      await Future<void>.delayed(Duration.zero);

      final snap = container.read(layoutSnapshotsProvider)['dev']!;
      expect(snap.size, const Size(400, 800));
      expect(snap.screenshot, [1, 2, 3]);
      expect(snap.root?.id, 'screen');
      expect(container.read(layoutSnapshotsProvider.notifier).pending, isEmpty);
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

    // testWidgets for its fake clock.
    testWidgets('a capture nobody answers stops waiting', (tester) async {
      final notifier = container.read(layoutSnapshotsProvider.notifier)
        ..capture('dev');
      await tester.pump(LayoutSnapshotsNotifier.timeout);
      expect(notifier.pending, isEmpty);
    });
  });
}
