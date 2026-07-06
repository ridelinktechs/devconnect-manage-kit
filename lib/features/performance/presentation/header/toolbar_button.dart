import 'package:flutter/material.dart';

/// Icon button used by the profiler toolbar. Hover fills the icon's
/// theme-aware tint (150ms AnimatedContainer). When [filled] is true
/// the icon is replaced with a 14px filled circle in [color] — used
/// for the recording indicator.
class ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final Color? color;
  final bool filled;
  final VoidCallback onTap;

  const ToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isDark,
    this.color,
    this.filled = false,
    required this.onTap,
  });

  @override
  State<ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<ToolbarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.color ??
        (_hovered
            ? (widget.isDark ? Colors.white70 : Colors.black54)
            : Colors.grey[500]);

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hovered
                  ? (widget.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: widget.filled
                ? Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  )
                : Icon(widget.icon, size: 14, color: iconColor),
          ),
        ),
      ),
    );
  }
}