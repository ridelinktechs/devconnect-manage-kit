import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';
import 'focus_ring.dart';

/// Compact "icon + label" button used for "Run Adb Reverse" / "Devices" /
/// "Start" / "Stop" / "Restart" throughout the Settings page. [filled]
/// paints it in [color]; otherwise it is a soft tint of [color]. While
/// [busy] the icon spins and presses are ignored; a null [onTap] disables
/// it.
class ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool filled;
  final bool busy;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
    this.busy = false,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  static const _spring = Cubic(0.34, 1.45, 0.64, 1);

  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _hover = false;
  bool _down = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSpin();
  }

  @override
  void didUpdateWidget(ActionButton old) {
    super.didUpdateWidget(old);
    _syncSpin();
  }

  void _syncSpin() {
    final run = widget.busy && !MediaQuery.disableAnimationsOf(context);
    if (run && !_spin.isAnimating) _spin.repeat();
    if (!run && _spin.isAnimating) _spin.reset();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final c = widget.color;
    final enabled = widget.onTap != null && !widget.busy;
    final fg = widget.filled ? Colors.white : c;
    final bg = widget.filled
        ? (_hover && enabled ? Color.lerp(c, Colors.white, 0.12)! : c)
        : c.withValues(
            alpha: _hover && enabled ? 0.18 : (p.isDark ? 0.12 : 0.1),
          );

    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.filled ? Colors.transparent : c.withValues(alpha: 0.28),
        ),
        boxShadow: [
          if (widget.filled)
            BoxShadow(
              color: c.withValues(alpha: 0.45),
              offset: const Offset(0, 6),
              blurRadius: 14,
              spreadRadius: -6,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _spin,
            child: Icon(widget.icon, size: 15, color: fg),
          ),
          const SizedBox(width: 7),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );

    if (!enabled) {
      return Opacity(
        opacity: widget.busy ? 0.8 : 0.45,
        child: ExcludeFocus(child: body),
      );
    }
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 350),
        curve: _spring,
        child: FocusRing(
          onTap: widget.onTap!,
          radius: 10,
          label: widget.label,
          onHover: (v) => setState(() => _hover = v),
          child: body,
        ),
      ),
    );
  }
}
