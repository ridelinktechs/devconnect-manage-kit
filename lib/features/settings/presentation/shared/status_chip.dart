import 'package:flutter/material.dart';

/// Small filled "icon + label" chip used in the page header to surface
/// server status + device count. Tinted with the supplied [color]
/// (10% fill, 25% border) so the same widget fits a success/info/muted
/// palette without needing a state enum.
class StatusChip extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;

  const StatusChip({
    super.key,
    required this.color,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}