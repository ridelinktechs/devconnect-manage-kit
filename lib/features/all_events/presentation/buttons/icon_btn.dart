import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';

/// Square 28×28 icon button for the All Events toolbar. Three visual states:
///
/// - **active** (primary tint) — for sort/auto-scroll toggles that are on.
/// - **danger-on-hover** (error tint) — for the clear-all trash icon.
/// - **muted-on-hover** — neutral hover for inactive icons.
class IconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final bool isDanger;
  final VoidCallback onTap;

  const IconBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  State<IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color iconColor;
    Color bgColor;

    if (widget.isActive) {
      iconColor = ColorTokens.primary;
      bgColor = ColorTokens.primary.withValues(alpha: 0.15);
    } else if (widget.isDanger && _hovered) {
      iconColor = ColorTokens.error;
      bgColor = ColorTokens.error.withValues(alpha: 0.12);
    } else if (_hovered) {
      iconColor = isDark ? Colors.grey[300]! : Colors.grey[700]!;
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06);
    } else {
      iconColor = isDark ? Colors.grey[500]! : Colors.grey[500]!;
      bgColor = Colors.transparent;
    }

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Slightly larger icon button used in the header next to the port/device
/// counters (the server restart "Reload" button).
class HeaderActionIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool spinning;
  final VoidCallback onTap;

  const HeaderActionIcon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.spinning,
    required this.onTap,
  });

  @override
  State<HeaderActionIcon> createState() => _HeaderActionIconState();
}

class _HeaderActionIconState extends State<HeaderActionIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.spinning) _spinCtrl.repeat();
  }

  @override
  void didUpdateWidget(covariant HeaderActionIcon old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_spinCtrl.isAnimating) {
      _spinCtrl.repeat();
    } else if (!widget.spinning && _spinCtrl.isAnimating) {
      _spinCtrl.reset();
    }
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = _hovered || widget.spinning
        ? ColorTokens.primary
        : (isDark ? Colors.grey[400]! : Colors.grey[600]!);
    final bgColor = _hovered || widget.spinning
        ? ColorTokens.primary.withValues(alpha: 0.12)
        : Colors.transparent;

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.spinning ? null : widget.onTap,
        child: MouseRegion(
          cursor:
              widget.spinning ? SystemMouseCursors.basic : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: RotationTransition(
              turns: _spinCtrl,
              child: Icon(widget.icon, size: 12, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}
