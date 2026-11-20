// Lucian UX/UI Prompt #019 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#019
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../settings/presentation/shared/focus_ring.dart';
import '../shared/storage_tokens.dart';

/// A history filter in the Storage header — an operation or a storage
/// type — as the multi-select chip of Lucian #019, like the Console's level
/// chips: switched on, a check slides out from the left as the chip fills
/// with [color]. It shows how many operations it matches, so switching one
/// off never hides them silently.
class StorageFilterChip extends StatefulWidget {
  final String label;
  final Color color;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const StorageFilterChip({
    super.key,
    required this.label,
    required this.color,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<StorageFilterChip> createState() => _StorageFilterChipState();
}

class _StorageFilterChipState extends State<StorageFilterChip> {
  static const _ease = Cubic(0.2, 0.8, 0.2, 1);
  static const _spring = Cubic(0.34, 1.45, 0.64, 1);

  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final loc = S.of(context);
    final on = widget.isActive;
    final ink = storageInk(widget.color, p.isDark);
    final fg = on ? ink : (_hover ? p.text : p.textMuted);
    final base = DefaultTextStyle.of(context).style;
    return Tooltip(
      message: on
          ? loc.storageFilterHide(widget.label)
          : loc.storageFilterShow(widget.label),
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
            label: '${widget.label} ${widget.count}',
            onHover: (v) => setState(() => _hover = v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: _ease,
              height: 26,
              decoration: BoxDecoration(
                color: on
                    ? widget.color.withValues(alpha: p.isDark ? 0.18 : 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: on
                      ? widget.color.withValues(alpha: 0.45)
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
                      child: Text(widget.label),
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
