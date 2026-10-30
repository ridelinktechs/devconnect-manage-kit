import 'package:flutter/material.dart';

import '../../core/theme/chrome_palette.dart';
import '../../core/utils/color_values.dart';

/// A color's swatch, over a checkerboard so its transparency shows. Hover
/// for its hex and rgba().
class ColorSample extends StatelessWidget {
  final Color color;

  const ColorSample(this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    return Tooltip(
      message: '${colorHex(color)}   ${colorRgba(color)}',
      child: Container(
        width: 11,
        height: 11,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: palette.isDark ? Colors.white38 : Colors.black26,
          ),
          borderRadius: BorderRadius.circular(2.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(1.5),
          child: CustomPaint(painter: _Checkered(color)),
        ),
      ),
    );
  }
}

class _Checkered extends CustomPainter {
  final Color color;

  _Checkered(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a < 1) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
      final dark = Paint()..color = const Color(0xFFC8C8C8);
      final cell = size.width / 3;
      for (var x = 0; x < 3; x++) {
        for (var y = x.isOdd ? 0 : 1; y < 3; y += 2) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), dark);
        }
      }
    }
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Checkered old) => old.color != color;
}

/// [text] as spans with a [ColorSample] at each of [samples]' offsets
/// (ascending); [piece] builds the text between them.
List<InlineSpan> withColorSamples(
  String text,
  List<(int, Color)> samples,
  InlineSpan Function(String piece) piece,
) {
  final spans = <InlineSpan>[];
  var from = 0;
  for (final (at, color) in samples) {
    if (at > from) spans.add(piece(text.substring(from, at)));
    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        // Left out of selections: what's copied is the text.
        child: SelectionContainer.disabled(child: ColorSample(color)),
      ),
    );
    from = at;
  }
  if (from < text.length) spans.add(piece(text.substring(from)));
  return spans;
}

/// Where [withColorSamples] puts [text]'s colors (see [findColors]).
List<(int, Color)> colorSamplesIn(String text, {String? key}) => [
  for (final c in findColors(text, key: key)) (c.start, c.color),
];
