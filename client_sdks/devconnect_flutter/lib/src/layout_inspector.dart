import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Past this many widgets the tree is cut short.
const _maxNodes = 3000;

/// The screen as the desktop's Layout tab shows it: a screenshot plus the
/// widget tree, each widget with its on-screen bounds (logical pixels) and
/// non-default properties. Private widgets (`_Foo`) and hidden `Offstage`
/// subtrees (routes below the current one) are left out; their children
/// hang off the nearest widget kept.
Future<Map<String, dynamic>> captureLayout({bool screenshot = true}) async {
  final binding = WidgetsBinding.instance;
  final view = binding.platformDispatcher.implicitView;
  final screen =
      view == null ? Size.zero : view.physicalSize / view.devicePixelRatio;
  RenderRepaintBoundary? boundary;
  var count = 0;

  List<Map<String, dynamic>> visit(Element element) {
    final widget = element.widget;
    if (widget is Offstage && widget.offstage) return const [];
    final box = element.renderObject;
    // The first full-screen repaint boundary (the current page) is what
    // gets photographed.
    if (boundary == null &&
        box is RenderRepaintBoundary &&
        box.hasSize &&
        box.size.width >= screen.width - 1 &&
        box.size.height >= screen.height - 1) {
      boundary = box;
    }
    final children = <Map<String, dynamic>>[];
    element.visitChildElements((child) => children.addAll(visit(child)));
    final name = widget.runtimeType.toString();
    if (name.startsWith('_') ||
        count >= _maxNodes ||
        box is! RenderBox ||
        !box.hasSize ||
        !box.attached) {
      return children;
    }
    count++;
    final origin = box.localToGlobal(Offset.zero);
    final padding = box is RenderPadding
        ? box.padding.resolve(box.textDirection)
        : EdgeInsets.zero;
    return [
      {
        'id': '${identityHashCode(element)}',
        'name': name,
        'x': origin.dx,
        'y': origin.dy,
        'w': box.size.width,
        'h': box.size.height,
        if (padding != EdgeInsets.zero)
          'padding': [padding.left, padding.top, padding.right, padding.bottom],
        'props': widgetProps(widget),
        'children': children,
      },
    ];
  }

  final roots = switch (binding.rootElement) {
    final root? => visit(root),
    null => const <Map<String, dynamic>>[],
  };

  String? png;
  if (screenshot && boundary != null) {
    try {
      final image = await boundary!.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes != null) png = base64Encode(bytes.buffer.asUint8List());
    } catch (_) {
      // No picture (e.g. not painted yet); the tree is still useful.
    }
  }

  return {
    'width': screen.width,
    'height': screen.height,
    'screenshot': png,
    'root': roots.length == 1
        ? roots.single
        : {
            'id': 'root',
            'name': 'Root',
            'x': 0.0,
            'y': 0.0,
            'w': screen.width,
            'h': screen.height,
            'props': const <String, String>{},
            'children': roots,
          },
  };
}

/// [widget]'s key and its properties that differ from their defaults, as
/// short strings.
@visibleForTesting
Map<String, String> widgetProps(Widget widget) {
  final props = <String, String>{
    if (widget.key case final key?) 'key': '$key',
  };
  for (final p in widget.toDiagnosticsNode().getProperties()) {
    if (props.length >= 16) break;
    final name = p.name;
    if (name == null || p.isFiltered(DiagnosticLevel.info)) continue;
    final value = p.toDescription();
    if (value.isEmpty || value == 'null') continue;
    props[name] = value.length > 200 ? '${value.substring(0, 200)}…' : value;
  }
  return props;
}
