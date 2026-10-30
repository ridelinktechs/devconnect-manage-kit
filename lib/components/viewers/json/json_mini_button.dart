import 'package:flutter/material.dart';

class JsonMiniButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;
  final bool loading;

  const JsonMiniButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
    this.loading = false,
  });

  @override
  State<JsonMiniButton> createState() => _JsonMiniButtonState();
}

class _JsonMiniButtonState extends State<JsonMiniButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: widget.loading
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _hovered && !widget.loading
                  ? (widget.isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: widget.loading
                ? SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: widget.isDark
                          ? Colors.grey[600]
                          : Colors.grey[400],
                    ),
                  )
                : Icon(
                    widget.icon,
                    size: 13,
                    color: _hovered
                        ? (widget.isDark ? Colors.white70 : Colors.black54)
                        : Colors.grey[500],
                  ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Segmented button used in detail panels for the Tree / JSON / Code
// toggle. Kept here so it can be reused across feature pages.
// ═══════════════════════════════════════════════════════════════════
