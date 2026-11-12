import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../settings/presentation/shared/focus_ring.dart';

/// One quick value: what it fills in, its label and its tooltip.
typedef Preset = ({String value, String label, String? tooltip});

/// Quick values for a field. Picking one fills the field in; the one equal
/// to [current] is lit in its [tintOf] color.
class PresetChips extends StatelessWidget {
  final List<Preset> presets;
  final String current;
  final ValueChanged<String> onPick;

  /// Fill and edge of a lit chip.
  final Color Function(String value) tintOf;

  /// Text of a lit chip.
  final Color Function(String value) inkOf;
  final bool mono;

  const PresetChips({
    super.key,
    required this.presets,
    required this.current,
    required this.onPick,
    required this.tintOf,
    required this.inkOf,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final preset in presets)
          _Chip(
            preset: preset,
            on: current.trim() == preset.value,
            tint: tintOf(preset.value),
            ink: inkOf(preset.value),
            mono: mono,
            onTap: () => onPick(preset.value),
          ),
      ],
    );
  }
}

class _Chip extends StatefulWidget {
  final Preset preset;
  final bool on;
  final Color tint;
  final Color ink;
  final bool mono;
  final VoidCallback onTap;

  const _Chip({
    required this.preset,
    required this.on,
    required this.tint,
    required this.ink,
    required this.mono,
    required this.onTap,
  });

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> {
  static const _ease = Cubic(0.2, 0.8, 0.2, 1);
  static const _spring = Cubic(0.34, 1.45, 0.64, 1);

  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final on = widget.on;
    final color = on ? widget.ink : (_hover ? p.text : p.textMuted);
    final style = widget.mono
        ? chromeMono(context, size: 12, color: color, weight: FontWeight.w700)
        : DefaultTextStyle.of(context).style.copyWith(
            fontSize: 12,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: color,
          );
    final chip = Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 300),
        curve: _spring,
        child: FocusRing(
          onTap: widget.onTap,
          radius: 9,
          selected: on,
          label: widget.preset.label,
          onHover: (v) => setState(() => _hover = v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: _ease,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: on
                  ? widget.tint.withValues(alpha: p.isDark ? 0.18 : 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: on
                    ? widget.tint.withValues(alpha: 0.45)
                    : (_hover ? p.textMuted : p.border),
              ),
            ),
            child: Center(
              widthFactor: 1,
              child: Text(widget.preset.label, style: style),
            ),
          ),
        ),
      ),
    );
    final tooltip = widget.preset.tooltip;
    return tooltip == null || tooltip.isEmpty
        ? chip
        : Tooltip(message: tooltip, child: chip);
  }
}
