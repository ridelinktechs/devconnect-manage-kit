import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';

/// A card of related editor fields under a glyph and an uppercase title.
class FormSection extends StatelessWidget {
  final IconData icon;
  final String title;

  /// A quiet word after the title, e.g. "optional".
  final String? note;
  final List<Widget> children;

  const FormSection({
    super.key,
    required this.icon,
    required this.title,
    this.note,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final eyebrow = DefaultTextStyle.of(context).style.copyWith(
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      color: p.textMuted,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: p.textMuted),
              const SizedBox(width: 6),
              Text(title.toUpperCase(), style: eyebrow),
              if (note case final note?) ...[
                const SizedBox(width: 6),
                Text(
                  note,
                  style: eyebrow.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                    color: p.textMuted.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ],
          ),
          for (final child in children) ...[const SizedBox(height: 14), child],
        ],
      ),
    );
  }
}
