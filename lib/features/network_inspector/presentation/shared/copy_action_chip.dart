import 'package:flutter/material.dart';

import '../../../../components/text/text_component.dart';

/// Compact chip-shaped button with icon + label, used in the network
/// detail panel for copy-style actions (Copy URL, Copy as cURL, …).
///
/// Visually distinct from the icon-only [CopyButton] used in storage /
/// log details — this one carries a label so users see the action name
/// even when no tooltip is rendered (the action row is dense).
class CopyActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const CopyActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF21262D)
                : const Color(0xFFEEF0F2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF30363D)
                  : const Color(0xFFD0D7DE),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 4),
              TextComponent(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}