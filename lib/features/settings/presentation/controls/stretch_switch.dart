// Lucian UX/UI Prompt #013 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#013
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../shared/focus_ring.dart';

/// On/off switch whose knob stretches like rubber while it travels, then
/// snaps back; the ✕ inside is redrawn as a ✓ when it turns on.
class StretchSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  /// Fill of the switch when on; the app's purple when null.
  final Color? color;

  const StretchSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.color,
  });

  @override
  State<StretchSwitch> createState() => _StretchSwitchState();
}

class _StretchSwitchState extends State<StretchSwitch>
    with SingleTickerProviderStateMixin {
  static const _ease = Cubic(0.2, 0.8, 0.2, 1);
  static const _spring = Cubic(0.34, 1.45, 0.64, 1);
  static const _width = 44.0;
  static const _height = 24.0;
  static const _inset = 3.0;
  static const _knob = _height - 2 * _inset;
  static const _stretched = _knob * 1.4;

  late final AnimationController _mark = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 530),
    value: widget.value ? 1 : 0,
  );
  bool _stretch = false;
  Timer? _settle;

  @override
  void didUpdateWidget(StretchSwitch old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _mark.value = widget.value ? 1 : 0;
      return;
    }
    widget.value ? _mark.forward() : _mark.reverse();
    setState(() => _stretch = true);
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 170), () {
      if (mounted) setState(() => _stretch = false);
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    _mark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final on = widget.value;
    final onChanged = widget.onChanged;
    final custom = widget.color;
    final accent = custom ?? ColorTokens.primary;
    final left = on
        ? _width - _inset - (_stretch ? _stretched : _knob)
        : _inset;

    final body = SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: _ease,
            decoration: BoxDecoration(
              color: p.isDark
                  ? const Color(0xFF30363D)
                  : const Color(0xFFDDE1E6),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: on ? 0.55 : 0),
                  offset: const Offset(0, 6),
                  blurRadius: 12,
                  spreadRadius: -6,
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: on ? 1 : 0,
              duration: const Duration(milliseconds: 450),
              curve: _ease,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(999)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: custom == null
                        ? const [ColorTokens.primaryLight, ColorTokens.primary]
                        : [Color.lerp(custom, Colors.white, 0.25)!, custom],
                  ),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: _spring,
            left: left,
            top: _inset,
            child: AnimatedContainer(
              duration: Duration(milliseconds: _stretch ? 180 : 320),
              curve: _ease,
              width: _stretch ? _stretched : _knob,
              height: _knob,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    offset: const Offset(0, 2),
                    blurRadius: 5,
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _mark,
                builder: (context, _) => CustomPaint(
                  painter: _MarkPainter(_mark.value * 530, accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      toggled: on,
      label: widget.label,
      child: Opacity(
        opacity: onChanged == null ? 0.45 : 1,
        child: onChanged == null
            ? ExcludeFocus(child: body)
            : FocusRing(
                onTap: () => onChanged(!on),
                radius: 999,
                offset: 3,
                child: body,
              ),
      ),
    );
  }
}

/// The ✕ that fades as the ✓ is drawn, [ms] into the 530 ms switch.
class _MarkPainter extends CustomPainter {
  static const _ease = Cubic(0.2, 0.8, 0.2, 1);

  final double ms;
  final Color color;

  const _MarkPainter(this.ms, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.height / 24;
    final c = Offset(size.width / 2, size.height / 2);
    final cross = 1 - _ease.transform((ms / 300).clamp(0.0, 1.0));
    final check = _ease.transform(((ms - 180) / 350).clamp(0.0, 1.0));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void draw(Path path, double amount, Color color) {
      if (amount <= 0) return;
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(
          metric.extractPath(0, metric.length * amount),
          paint..color = color,
        );
      }
    }

    Offset at(double x, double y) => c + Offset((x - 12) * k, (y - 12) * k);
    draw(
      Path()
        ..moveTo(at(8.5, 8.5).dx, at(8.5, 8.5).dy)
        ..lineTo(at(15.5, 15.5).dx, at(15.5, 15.5).dy)
        ..moveTo(at(15.5, 8.5).dx, at(15.5, 8.5).dy)
        ..lineTo(at(8.5, 15.5).dx, at(8.5, 15.5).dy),
      cross,
      const Color(0xFFA3A0AA),
    );
    draw(
      Path()
        ..moveTo(at(6.5, 12.5).dx, at(6.5, 12.5).dy)
        ..lineTo(at(10.5, 16.5).dx, at(10.5, 16.5).dy)
        ..lineTo(at(17.5, 8.5).dx, at(17.5, 8.5).dy),
      check,
      color,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.ms != ms || old.color != color;
}
