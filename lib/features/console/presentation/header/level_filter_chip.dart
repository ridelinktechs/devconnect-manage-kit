import 'package:flutter/material.dart';

/// Rounded "DEBUG / INFO / WARN / ERROR" pill used in the console
/// toolbar. Active state tints the chip's bg + border with the
/// level's accent color; hover state tints the chip subtly without
/// the user committing to it.
class LevelFilterChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const LevelFilterChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  State<LevelFilterChip> createState() => _LevelFilterChipState();
}

class _LevelFilterChipState extends State<LevelFilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isActive
        ? widget.color.withValues(alpha: 0.15)
        : _hovered
            ? widget.color.withValues(alpha: 0.07)
            : Colors.transparent;

    final borderColor = widget.isActive
        ? widget.color.withValues(alpha: 0.4)
        : _hovered
            ? widget.color.withValues(alpha: 0.25)
            : Colors.grey.withValues(alpha: 0.2);

    return Tooltip(
      message: '${widget.isActive ? "Hide" : "Show"} ${widget.label} logs',
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: widget.isActive ? widget.color : Colors.grey[500],
              ),
            ),
          ),
        ),
      ),
    );
  }
}