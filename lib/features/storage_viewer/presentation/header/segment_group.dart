import 'package:flutter/material.dart';

/// Rounded "rail" that wraps a row of [SegmentChip]s with a single
/// 2px padding container — the visual unit shared by the op-filter
/// group and the scrollable type-filter group in the toolbar.
class SegmentGroup extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const SegmentGroup({
    super.key,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}