import 'package:flutter/material.dart';

import '../../core/theme/chrome_palette.dart';

/// A 20px rounded label: an optional glyph and a short text, cut with an
/// ellipsis when room runs out. An empty [text] leaves just the glyph.
class TagLabel extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color color;
  final Color fill;
  final Color? edge;
  final bool mono;

  const TagLabel({
    super.key,
    this.icon,
    required this.text,
    required this.color,
    required this.fill,
    this.edge,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
        border: edge == null ? null : Border.all(color: edge!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            if (text.isNotEmpty) const SizedBox(width: 4),
          ],
          if (text.isNotEmpty)
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: mono
                    ? chromeMono(
                        context,
                        size: 10.5,
                        color: color,
                        weight: FontWeight.w700,
                      )
                    : DefaultTextStyle.of(context).style.copyWith(
                        fontSize: 10.5,
                        height: 1.4,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: color,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
