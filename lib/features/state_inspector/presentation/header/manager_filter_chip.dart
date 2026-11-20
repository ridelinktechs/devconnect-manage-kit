// Lucian UX/UI Prompt #019 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#019
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../settings/presentation/shared/focus_ring.dart';
import '../shared/manager_look.dart';

/// A state library toggle in the State Inspector header, the multi-select
/// chip of Lucian #019 like the Console's level chips: switched on, a check
/// slides out from the left as the chip fills with the library's color. It
/// shows how many changes of the library match, so turning one off never
/// hides changes silently.
class ManagerFilterChip extends StatefulWidget {
  final ManagerLook look;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const ManagerFilterChip({
    super.key,
    required this.look,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<ManagerFilterChip> createState() => _ManagerFilterChipState();
}

class _ManagerFilterChipState extends State<ManagerFilterChip> {
  static const _ease = Cubic(0.2, 0.8, 0.2, 1);
  static const _spring = Cubic(0.34, 1.45, 0.64, 1);

  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final on = widget.isActive;
    final look = widget.look;
    final label = look.label.toUpperCase();
    final ink = look.ink(p.isDark);
    final fg = on ? ink : (_hover ? p.text : p.textMuted);
    final base = DefaultTextStyle.of(context).style;
    return Tooltip(
      message: '${on ? 'Hide' : 'Show'} ${look.label} changes',
      child: Listener(
        onPointerDown: (_) => setState(() => _down = true),
        onPointerUp: (_) => setState(() => _down = false),
        onPointerCancel: (_) => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down ? 0.94 : 1,
          duration: const Duration(milliseconds: 400),
          curve: _spring,
          child: FocusRing(
            onTap: widget.onTap,
            radius: 13,
            selected: on,
            label: '${look.label} ${widget.count}',
            onHover: (v) => setState(() => _hover = v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: _ease,
              height: 26,
              decoration: BoxDecoration(
                color: on
                    ? look.color.withValues(alpha: p.isDark ? 0.18 : 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: on
                      ? look.color.withValues(alpha: 0.45)
                      : (_hover ? p.textMuted : p.border),
                ),
              ),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 450),
                curve: _spring,
                padding: EdgeInsets.only(left: on ? 7 : 10, right: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: on ? 1 : 0),
                      duration: const Duration(milliseconds: 450),
                      curve: _spring,
                      builder: (context, t, child) => SizedBox(
                        width: 16 * math.max(0, t),
                        child: ClipRect(child: child),
                      ),
                      child: AnimatedOpacity(
                        opacity: on ? 1 : 0,
                        duration: const Duration(milliseconds: 250),
                        curve: _ease,
                        child: OverflowBox(
                          alignment: Alignment.centerLeft,
                          maxWidth: 16,
                          child: Icon(LucideIcons.check, size: 12, color: ink),
                        ),
                      ),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: _ease,
                      style: base.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: fg,
                      ),
                      child: Text(label),
                    ),
                    const SizedBox(width: 6),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: _ease,
                      style: base.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: fg.withValues(alpha: 0.75),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      child: Text('${widget.count}'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
