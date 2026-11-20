import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';

class Notice extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;

  const Notice({
    super.key,
    required this.text,
    this.icon = LucideIcons.info,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final tint = color ?? palette.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color == null
            ? palette.surface
            : tint.withValues(alpha: palette.isDark ? 0.12 : 0.08),
        border: Border.all(
          color: color == null ? palette.border : tint.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 14, color: tint),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: SelectableText(
              text,
              style: TextStyle(fontSize: 12, height: 1.4, color: palette.text),
            ),
          ),
        ],
      ),
    );
  }
}
