import 'dart:math' as math;
import 'dart:ui' show clampDouble;

import 'package:flutter/material.dart';

import '../../provider/layout_providers.dart';
import '../shared/layout_style.dart';

class OverlayPainter extends CustomPainter {
  final LayoutNode root;
  final LayoutNode? hovered;
  final LayoutNode? selected;
  final double scale;
  final TransformationController zoom;
  final bool measuring;
  final bool outlineAll;
  final bool isDark;
  final String? fontFamily;

  OverlayPainter({
    required this.root,
    required this.hovered,
    required this.selected,
    required this.scale,
    required this.zoom,
    required this.measuring,
    required this.outlineAll,
    required this.isDark,
    required this.fontFamily,
  }) : super(repaint: zoom);

  Rect _scaled(Rect r) => Rect.fromLTRB(
    r.left * scale,
    r.top * scale,
    r.right * scale,
    r.bottom * scale,
  );

  void _ring(Canvas canvas, Rect outer, Rect inner, Color color) =>
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(outer)
          ..addRect(inner),
        Paint()..color = color,
      );

  Paint _stroke(Color color, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    // Lines and tags keep their on-screen size at any zoom.
    final z = zoom.value.getMaxScaleOnAxis();
    final h = hovered;
    final s = selected;
    final measure = measuring && h != null && s != null && h.id != s.id;
    if (outlineAll) {
      final outline = _stroke(
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.18),
        1 / z,
      );
      final stack = [root];
      while (stack.isNotEmpty) {
        final node = stack.removeLast();
        canvas.drawRect(_scaled(node.rect), outline);
        stack.addAll(node.children);
      }
    }
    if (h != null && !measure) {
      final box = _scaled(h.rect);
      if (h.margin case final m?) {
        _ring(
          canvas,
          _scaled(m.inflateRect(h.rect)),
          box,
          LayoutColors.margin.withValues(alpha: 0.45),
        );
      }
      final content = switch (h.padding) {
        final p? => _scaled(p.deflateRect(h.rect)),
        null => box,
      };
      if (content != box) {
        _ring(
          canvas,
          box,
          content,
          LayoutColors.padding.withValues(alpha: 0.45),
        );
      }
      canvas.drawRect(
        content,
        Paint()..color = LayoutColors.content.withValues(alpha: 0.4),
      );
      canvas.drawRect(box, _stroke(LayoutColors.content, 1 / z));
    }
    if (s != null) {
      canvas.drawRect(
        _scaled(s.rect),
        _stroke(LayoutColors.accent(isDark), 2 / z),
      );
    }
    if (measure) {
      final line = _stroke(LayoutColors.measure, 1 / z);
      canvas.drawRect(_scaled(h.rect), line);
      for (final (from, to) in layoutMeasure(s.rect, h.rect)) {
        canvas.drawLine(from * scale, to * scale, line);
        _pill(
          canvas,
          (from + to) * scale / 2,
          formatDp((to - from).distance),
          z,
        );
      }
    } else if (h ?? s case final labelled?) {
      _label(canvas, size, labelled, _scaled(labelled.rect), z);
    }
  }

  /// Name and size in a dark tag above the box — below it, or inside it,
  /// when there's no room — kept inside the screen.
  void _label(Canvas canvas, Size size, LayoutNode node, Rect box, double z) {
    final text = TextPainter(
      text: TextSpan(
        style: TextStyle(fontFamily: fontFamily, fontSize: 11),
        children: [
          TextSpan(
            text: node.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: '  ${formatSize(node.rect)}',
            style: const TextStyle(color: Color(0xFFB0B8C4)),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(0, size.width * z - 16));
    // Laid out on screen, placed on the (zoomed) canvas.
    final tag = Size(text.width + 12, text.height + 6);
    final w = tag.width / z;
    final hgt = tag.height / z;
    final gap = 4 / z;
    final above = box.top - hgt - gap;
    final below = box.bottom + gap;
    final top = above >= 0
        ? above
        : below + hgt <= size.height
        ? below
        : box.top + gap;
    final left = clampDouble(box.left, 0, math.max(0, size.width - w));
    canvas
      ..save()
      ..translate(left, top)
      ..scale(1 / z)
      ..drawRRect(
        RRect.fromRectAndRadius(Offset.zero & tag, const Radius.circular(4)),
        Paint()..color = const Color(0xEB111827),
      );
    text.paint(canvas, const Offset(6, 3));
    canvas.restore();
  }

  /// A distance in a red pill centered on [at].
  void _pill(Canvas canvas, Offset at, String label, double z) {
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pill = Rect.fromCenter(
      center: Offset.zero,
      width: text.width + 10,
      height: text.height + 4,
    );
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..scale(1 / z)
      ..drawRRect(
        RRect.fromRectAndRadius(pill, const Radius.circular(3)),
        Paint()..color = LayoutColors.measure,
      );
    text.paint(canvas, pill.topLeft + const Offset(5, 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(OverlayPainter old) =>
      old.hovered != hovered ||
      old.selected != selected ||
      old.scale != scale ||
      old.root != root ||
      old.measuring != measuring ||
      old.outlineAll != outlineAll ||
      old.isDark != isDark;
}
