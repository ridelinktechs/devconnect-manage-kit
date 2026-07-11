import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/retention_provider.dart';

/// Pill-style dropdown for picking a [RetentionPreset]. Shared between
/// `data_retention_section` (destructive cap) and
/// `all_events_display_section` (view-only filter).
///
/// Mirrors the visual language of `language_dropdown.dart` — chevron
/// trigger row + popup menu with a check mark next to the active item.
class PresetDropdown extends StatelessWidget {
  final RetentionPreset selected;
  final ValueChanged<RetentionPreset> onSelected;

  const PresetDropdown({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: PopupMenuButton<RetentionPreset>(
        onSelected: onSelected,
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        itemBuilder: (context) => RetentionPreset.values.map((preset) {
          final isActive = preset == selected;
          return PopupMenuItem<RetentionPreset>(
            value: preset,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                if (isActive)
                  const Icon(LucideIcons.check,
                      size: 14, color: Color(0xFF0D9488))
                else
                  const SizedBox(width: 14),
                const SizedBox(width: 10),
                Text(
                  preset.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? const Color(0xFF0D9488)
                        : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(LucideIcons.layers, size: 15, color: Color(0xFF6B7280)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[200] : Colors.grey[800],
                  ),
                ),
              ),
              const Icon(LucideIcons.chevronDown,
                  size: 14, color: Color(0xFF6B7280)),
            ],
          ),
        ),
      ),
    );
  }
}