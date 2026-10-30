import 'dart:convert';

import 'package:devconnect_manage_kit/src/layout_inspector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Iterable<Map<String, dynamic>> _nodes(Map<String, dynamic> node) sync* {
  yield node;
  for (final child in (node['children'] as List).cast<Map<String, dynamic>>()) {
    yield* _nodes(child);
  }
}

/// A page that stays alive offscreen, as tabs often do.
class _KeptAlivePage extends StatefulWidget {
  const _KeptAlivePage();

  @override
  State<_KeptAlivePage> createState() => _KeptAlivePageState();
}

class _KeptAlivePageState extends State<_KeptAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const SizedBox(key: Key('kept'));
  }
}

/// Records whether the inspector walked into it.
class _Probe extends StatelessWidget {
  const _Probe();

  static var walked = false;

  @override
  StatelessElement createElement() => _ProbeElement(this);

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _ProbeElement extends StatelessElement {
  _ProbeElement(super.widget);

  @override
  void visitChildElements(ElementVisitor visitor) {
    _Probe.walked = true;
    super.visitChildElements(visitor);
  }
}

/// Public: the inspector reads no props from private widgets.
class BrokenDiagnostics extends StatelessWidget {
  const BrokenDiagnostics({super.key});

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    throw StateError('broken');
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 10, height: 10);
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
            Text('shown'),
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

    // Widgets written in this package are the app's own; the RichText
    // inside Text is the framework's.
    expect(box['local'], isTrue);
    expect(nodes.singleWhere((n) => n['name'] == 'RichText')['local'], isFalse);

    // Hidden Offstage subtrees and private widgets are left out.
    expect(nodes.where((n) => n['name'] == 'Text'), hasLength(1));
    expect(nodes.where((n) => (n['name'] as String).startsWith('_')), isEmpty);
  });

  testWidgets('photographs the whole screen, routes above included',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: Text('page')),
        builder: (context, child) => child!,
      ),
    );
    showDialog<void>(
      context: tester.element(find.text('page')),
      builder: (_) => const AlertDialog(content: Text('dialog')),
    );
    await tester.pumpAndSettle();

    final layout =
        await tester.runAsync(() => captureLayout()) as Map<String, dynamic>;
    final png = base64Decode(layout['screenshot'] as String);
    // PNG header: 800 × 600 logical pixels.
    final header = ByteData.sublistView(png);
    expect([header.getUint32(16), header.getUint32(20)], [800, 600]);
    expect(layout.containsKey('truncated'), isFalse);
  });

  testWidgets('leaves out pages kept alive offscreen', (tester) async {
    final pages = PageController();
    addTearDown(pages.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PageView(
          controller: pages,
          children: const [_KeptAlivePage(), SizedBox(key: Key('shown'))],
        ),
      ),
    );
    pages.jumpToPage(1);
    await tester.pump();

    final layout = await captureLayout(screenshot: false);
    // An offscreen page has no position (NaN), which JSON can't carry.
    final json = jsonDecode(jsonEncode(layout)) as Map<String, dynamic>;
    final keys = [
      for (final n in _nodes(json['root'] as Map<String, dynamic>))
        n['props']['key'],
    ];
    expect(keys, contains("[<'shown'>]"));
    expect(keys, isNot(contains("[<'kept'>]")));
  });

  testWidgets('stops walking the tree at the node cap', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [...List.filled(3001, const SizedBox()), const _Probe()],
        ),
      ),
    );
    _Probe.walked = false;

    final layout = await captureLayout(screenshot: false);
    expect(layout['truncated'], isTrue);
    expect(_Probe.walked, isFalse);
  });

  testWidgets('a widget whose diagnostics throw keeps its node',
      (tester) async {
    await tester.pumpWidget(const BrokenDiagnostics(key: Key('broken')));

    final layout = await captureLayout(screenshot: false);
    final node = _nodes(layout['root'] as Map<String, dynamic>)
        .singleWhere((n) => n['name'] == 'BrokenDiagnostics');
    expect(node['props'], {'key': "[<'broken'>]"});
  });
}
