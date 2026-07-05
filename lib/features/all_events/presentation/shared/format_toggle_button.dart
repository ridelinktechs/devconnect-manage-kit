import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/text/text_component.dart';
import '../../../../core/theme/color_tokens.dart';
import '../buttons/pressable_button.dart';

/// Toggle that flips between "Format JSON" and "Show raw". When formatted,
/// the button tints to [ColorTokens.primary]; when raw, it falls back to
/// neutral grey so the active state is unmistakable.
class FormatToggleButton extends StatelessWidget {
  final bool isFormatted;
  final VoidCallback onToggle;

  const FormatToggleButton({
    super.key,
    required this.isFormatted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return PressableButton(
      onTap: onToggle,
      child: Tooltip(
        message: isFormatted ? 'Show raw' : 'Format JSON',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isFormatted
                  ? ColorTokens.primary.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.08),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.braces,
                  size: 12,
                  color: isFormatted ? ColorTokens.primary : Colors.grey[500],
                ),
                const SizedBox(width: 4),
                TextComponent(
                  isFormatted ? 'Raw' : 'Format',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color:
                        isFormatted ? ColorTokens.primary : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
