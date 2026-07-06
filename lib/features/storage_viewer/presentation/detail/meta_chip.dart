import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// Compact icon + label pill used in the detail panel header (op,
/// storage type, captured-at timestamp). When [color] is `Colors.grey`
/// the chip uses a muted 5% fill instead of a tinted fill so system
/// metadata doesn't compete with the colored badges.
class MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool isMono;

  const MetaChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: color == Colors.grey
            ? (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04))
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: color == Colors.grey ? Colors.grey[500] : color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: isMono ? AppConstants.monoFontFamily : null,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color == Colors.grey ? Colors.grey[500] : color,
              letterSpacing: isMono ? -0.1 : 0.2,
            ),
          ),
        ],
      ),
    );
  }
}