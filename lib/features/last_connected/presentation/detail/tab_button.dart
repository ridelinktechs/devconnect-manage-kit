import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';

class TabButton extends StatelessWidget {
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int count;

  const TabButton(
    this.label,
    this.index,
    this.selectedIndex,
    this.onTap,
    this.count, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == selectedIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? ColorTokens.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? ColorTokens.primary : Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? ColorTokens.primary.withValues(alpha: 0.7)
                        : Colors.grey[600],
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
