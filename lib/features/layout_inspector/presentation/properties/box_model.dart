import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../shared/layout_style.dart';

/// Margin around padding around content, with every side's value — the
/// diagram browser devtools show.
class BoxModel extends StatelessWidget {
  final Rect rect;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const BoxModel({
    super.key,
    required this.rect,
    required this.padding,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final number = chromeMono(context, size: 11, color: palette.text);
    final faint = number.copyWith(color: palette.textMuted);
    final caption = TextStyle(fontSize: 9.5, color: palette.textMuted);
    Text side(double v) =>
        Text(v == 0 ? '–' : formatDp(v), style: v == 0 ? faint : number);
    Widget layer(String label, Color tint, EdgeInsets? edges, Widget child) {
      final e = edges ?? EdgeInsets.zero;
      return Container(
        padding: const EdgeInsets.fromLTRB(3, 1, 3, 3),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: palette.isDark ? 0.10 : 0.14),
          border: Border.all(color: tint.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 15,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(label, style: caption),
                    ),
                  ),
                  Center(child: side(e.top)),
                ],
              ),
            ),
            Row(
              children: [
                SizedBox(width: 26, child: Center(child: side(e.left))),
                Expanded(child: child),
                SizedBox(width: 26, child: Center(child: side(e.right))),
              ],
            ),
            const SizedBox(height: 1),
            side(e.bottom),
          ],
        ),
      );
    }

    return layer(
      'margin',
      LayoutColors.margin,
      margin,
      layer(
        'padding',
        LayoutColors.padding,
        padding,
        Container(
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: LayoutColors.content.withValues(
              alpha: palette.isDark ? 0.16 : 0.2,
            ),
            border: Border.all(
              color: LayoutColors.content.withValues(alpha: 0.6),
            ),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            formatSize(rect),
            style: chromeMono(
              context,
              size: 11.5,
              color: palette.text,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
