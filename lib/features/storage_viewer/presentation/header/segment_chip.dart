import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// Pill-shaped chip used inside [SegmentGroup]. Active state tints
/// the background at 15% with the supplied [color] plus a soft
/// 6-blur drop shadow at 20% — gives the active state a slight
/// "lift" without being noisy.
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