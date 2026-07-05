import 'package:flutter/material.dart';

/// Compact muted "label value" chip used inside the network row header
/// (req/s, avg, err, ↓, ↑). Tinted at 4% so it stays subordinate to
/// the [MetricPill]s in the toolbar.
class NetStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const NetStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}