import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';

/// A divider that resizes what's on either side when dragged: between
/// columns for [Axis.vertical], between rows for [Axis.horizontal].
class Splitter extends StatelessWidget {
  final Axis axis;
  final ValueChanged<double> onDrag;

  const Splitter({super.key, required this.axis, required this.onDrag});

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final vertical = axis == Axis.vertical;
    return MouseRegion(
      cursor: vertical
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: vertical ? (d) => onDrag(d.delta.dx) : null,
        onVerticalDragUpdate: vertical ? null : (d) => onDrag(d.delta.dy),
        child: SizedBox(
          width: vertical ? 5 : null,
          height: vertical ? null : 5,
          child: Center(
            child: vertical
                ? VerticalDivider(width: 1, color: palette.border)
                : Divider(height: 1, color: palette.border),
          ),
        ),
      ),
    );
  }
}
