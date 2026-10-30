import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';

/// A small outlined name: a native view, a chain member.
class TagChip extends StatelessWidget {
  final String text;
  final bool dense;

  const TagChip(this.text, {super.key, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: dense ? 0 : 1.5),
      decoration: BoxDecoration(
        color: palette.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: chromeMono(
          context,
          size: dense ? 10.5 : 11,
          color: palette.textMuted,
        ),
      ),
    );
  }
}
