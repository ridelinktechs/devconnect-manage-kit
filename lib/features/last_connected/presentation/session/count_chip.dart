import 'package:flutter/material.dart';

class CountChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const CountChip(this.icon, this.count, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: color.withValues(alpha: 0.6)),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
