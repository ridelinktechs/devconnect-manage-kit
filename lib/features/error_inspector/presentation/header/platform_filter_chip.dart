import 'package:flutter/material.dart';

/// Tinted tap-to-compress chip for the Error Inspector's per-platform
/// filter row.
///
/// Visual treatment:
/// - Active → filled tint at 14–18%, colored border at 35%, saturated
///   text, leading dot at 100%
/// - Hover (inactive) → faint tint at 5–8%, neutral border, leading
///   dot at 85%
/// - Default → transparent + neutral border, dot at 50%
///
/// On tap the chip briefly compresses from scale 1.0 → 0.92 over
/// 110ms (the GSAP `power3.out` equivalent) and springs back — a
/// tactile "I clicked it" confirmation without the heavyweight
/// `PressableButton` chain.
class PlatformFilterChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const PlatformFilterChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  State<PlatformFilterChip> createState() => _PlatformFilterChipState();
}

class _PlatformFilterChipState extends State<PlatformFilterChip>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  // Short pop on tap — gsap.to(scale: 0.92, duration: 0.11) → scale: 1
  // (drives ScaleTransition below).
  late final AnimationController _tapCtrl;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    // We drive `_tapCtrl` from 0 (no compression) to 1 (fully compressed)
    // and map to scale 1.0 → 0.92 with easeOut.
    _tapScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    // 0 → 1: scale shrinks to 0.92; on completion, reverse back to 1.
    _tapCtrl.forward(from: 0);
    widget.onTap();
    await Future.delayed(const Duration(milliseconds: 110));
    if (!mounted) return;
    _tapCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = widget.color;

    // Background: active → filled tint, hover → faint tint, default → transparent
    final bg = widget.isActive
        ? c.withValues(alpha: isDark ? 0.18 : 0.14)
        : _hovered
            ? c.withValues(alpha: isDark ? 0.08 : 0.05)
            : Colors.transparent;

    // Text color: active → saturated, hover → 85%, default → 55% muted
    final textColor = widget.isActive
        ? c
        : _hovered
            ? c.withValues(alpha: 0.85)
            : c.withValues(alpha: 0.55);

    return Tooltip(
      message: '${widget.isActive ? "Hide" : "Show"} ${widget.label} errors',
      child: GestureDetector(
        onTap: _onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: widget.isActive
                  ? Border.all(color: c.withValues(alpha: 0.35), width: 1)
                  : Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                      width: 1,
                    ),
            ),
            child: ScaleTransition(
              scale: _tapScale,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color dot — pulses when active (perpetual motion)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isActive
                          ? c
                          : c.withValues(alpha: _hovered ? 0.85 : 0.5),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          widget.isActive ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}