import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// 28px-tall rounded pill container that hosts a row of [SegmentChip]s.
/// Used in the toolbar's source / filter groups.
///
/// Visual treatment: low-alpha neutral fill, 2px inner padding so chips
/// sit slightly inset from the rounded outline.
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

/// Individual segment chip inside a [SegmentGroup].
///
/// Active state carries two layered cues:
///   1. Filled tint (caller's [color] @ 15% alpha)
///   2. Soft colored glow shadow (caller's [color] @ 20%)
///
/// Inactive state is transparent with a subtle hover-tint background.
class SegmentChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final Color color;
  final bool isMono;
  final VoidCallback onTap;

  const SegmentChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.color,
    this.isMono = false,
    required this.onTap,
  });

  @override
  State<SegmentChip> createState() => _SegmentChipState();
}

class _SegmentChipState extends State<SegmentChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.color.withValues(alpha: 0.15)
                : _hovered
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 6,
                      spreadRadius: -1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: widget.isMono ? AppConstants.monoFontFamily : null,
                fontSize: 10,
                fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                color: widget.isActive
                    ? widget.color
                    : isDark
                        ? Colors.grey[500]
                        : Colors.grey[600],
                letterSpacing: widget.isMono ? 0.3 : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}