import 'package:devconnect_manage_kit/src/layout_inspector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Iterable<Map<String, dynamic>> _nodes(Map<String, dynamic> node) sync* {
  yield node;
  for (final child in (node['children'] as List).cast<Map<String, dynamic>>()) {
    yield* _nodes(child);
  }
}

void main() {
  testWidgets('maps the visible widget tree with bounds and props',
      (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(width: 120, height: 40, key: Key('box')),
            ),
            Offstage(child: Text('hidden route')),
          ],
        ),
      ),
    );

    final layout = await captureLayout(screenshot: false);
    expect(layout['width'], 800);
    expect(layout['height'], 600);

    final nodes = _nodes(layout['root'] as Map<String, dynamic>).toList();
    final box = nodes.singleWhere((n) => n['name'] == 'SizedBox');
    expect([box['x'], box['y'], box['w'], box['h']], [8.0, 8.0, 120.0, 40.0]);
    expect(box['props'], containsPair('key', "[<'box'>]"));
    expect(box['props'], containsPair('width', '120.0'));
    expect(box, isNot(contains('padding')));

    final padding = nodes.singleWhere((n) => n['name'] == 'Padding');
    expect(padding['props'], containsPair('padding', 'EdgeInsets.all(8.0)'));
    expect(padding['padding'], [8.0, 8.0, 8.0, 8.0]);
    expect((padding['children'] as List).single, same(box));

    // Hidden Offstage subtrees and private widgets are left out.
    expect(nodes.where((n) => n['name'] == 'Text'), isEmpty);
    expect(nodes.where((n) => (n['name'] as String).startsWith('_')), isEmpty);
  });
}
