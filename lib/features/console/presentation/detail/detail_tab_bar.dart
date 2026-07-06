import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';

/// Compact pill-style tab bar for the message view-mode toggle.
/// Same visual pattern as `_DetailTabBar` in `all_events_page.dart`
/// but with a `currentIndex + onSelect` callback instead of a
/// `TabController` — simpler to wire up in a private widget that
/// already manages its own state.
class DetailTabBar extends StatelessWidget {
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const DetailTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ColorTokens.primary;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < tabs.length; i++)
            _buildSegment(tabs[i], i, isDark, accent),
        ],
      ),
    );
  }

  Widget _buildSegment(String label, int index, bool isDark, Color accent) {
    final selected = index == currentIndex;
    return GestureDetector(
      onTap: () => onSelect(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: selected
              ? Border.all(
                  color: isDark
                      ? accent.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.06),
                )
              : Border.all(color: Colors.transparent),
          boxShadow: selected && !isDark
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.2,
            color: selected
                ? accent
                : (isDark ? Colors.grey[500] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}