import 'package:flutter/material.dart';

/// Compact icon + label + value + optional detail row used by the
/// System Status wrap (startup, battery, thermal, disk R/W, ANR).
/// Tinted at 8% body fill + 15% border to keep the wrap visually
/// quiet against the white/dark surface.
class SystemChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final Color color;
  final bool isDark;

  const SystemChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      detail!,
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}