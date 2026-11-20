import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';
import 'layout_style.dart';

/// A small icon (or [text]) button, for panel headers and the zoom bar.
class MiniButton extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;

  const MiniButton({
    super.key,
    this.icon,
    this.text,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final accent = LayoutColors.accent(palette.isDark);
    final color = active ? accent : palette.textMuted;
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: text == null
          ? Icon(icon, size: 14)
          : Text(
              text!,
              style: chromeMono(
                context,
                size: 11,
                color: color,
                weight: FontWeight.w600,
              ),
            ),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(26),
        minimumSize: const Size.square(26),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: color,
        backgroundColor: active ? accent.withValues(alpha: 0.14) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
