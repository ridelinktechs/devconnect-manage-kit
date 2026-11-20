// Lucian UX/UI Prompt #025 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#025
import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../shared/mock_look.dart';

const _ease = Cubic(0.2, 0.8, 0.2, 1);
const _spring = Cubic(0.34, 1.45, 0.64, 1);

/// An outlined field from Lucian #025: the label rises into a notch in the
/// border, a check draws in when [check] is true, and leaving the field
/// while [error] is set shakes it and drops the error below. Discard flashes
/// the fields it reset with an amber ring, as in Lucian #250.
class NotchedField extends StatefulWidget {
  final TextEditingController controller;
  final String label;

  /// Why the value can't be saved; shown once the field is left, or at once
  /// after [reveal] changes.
  final String? error;

  /// A quiet hint under the field while no error shows.
  final String? helper;

  /// Null leaves no room for the check; otherwise whether it shows.
  final bool? check;
  final bool mono;
  final int minLines;
  final int maxLines;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  /// Bumped to show [error] now, with a shake.
  final int reveal;

  /// Bumped to flash the field; it flashes only when [flashing].
  final int flash;
  final bool flashing;

  const NotchedField({
    super.key,
    required this.controller,
    required this.label,
    this.error,
    this.helper,
    this.check,
    this.mono = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.focusNode,
    this.keyboardType,
    this.onChanged,
    this.reveal = 0,
    this.flash = 0,
    this.flashing = false,
  });

  @override
  State<NotchedField> createState() => _NotchedFieldState();
}

class _NotchedFieldState extends State<NotchedField>
    with TickerProviderStateMixin {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  /// Whether the field has been left once, so its error may show.
  bool _strict = false;

  bool get _motion => !MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(NotchedField old) {
    super.didUpdateWidget(old);
    if (widget.reveal != old.reveal) {
      _strict = true;
      if (widget.error != null && _motion) _shake.forward(from: 0);
    }
    if (widget.flash != old.flash && widget.flashing && _motion) {
      _flash.forward(from: 0);
    }
  }

  void _onFocus() {
    if (!_focus.hasFocus) {
      _strict = true;
      if (widget.error != null && _motion) _shake.forward(from: 0);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    _shake.dispose();
    _flash.dispose();
    super.dispose();
  }

  /// [child] growing open over 400 ms; at once with animations off, where a
  /// zero-length AnimatedSize would relayout itself mid-layout.
  Widget _drop(Widget child) => _motion
      ? AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: _ease,
          alignment: Alignment.topLeft,
          child: child,
        )
      : child;

  /// The keyframes of `u025-shake`, ±7 px easing back to rest.
  static double _shakeAt(double t) {
    const stops = [0.0, -7.0, 6.0, -4.0, 2.0, 0.0];
    final x = t * (stops.length - 1);
    final i = x.floor().clamp(0, stops.length - 2);
    return stops[i] + (stops[i + 1] - stops[i]) * _ease.transform(x - i);
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final accent = mockAccent(p.isDark);
    final danger = mockDanger(p.isDark);
    final focused = _focus.hasFocus;
    final error = _strict ? widget.error : null;
    final bad = error != null;
    final edge = bad ? danger : (focused ? accent : p.border);
    OutlineInputBorder outline(double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: edge, width: width),
    );
    final style = widget.mono
        ? chromeMono(context, size: 13.5, color: p.text)
        : DefaultTextStyle.of(context).style.copyWith(
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w500,
            color: p.text,
          );
    final labelBase = DefaultTextStyle.of(
      context,
    ).style.copyWith(fontSize: 14, height: 1.2);
    final check = widget.check;

    final field = TextField(
      controller: widget.controller,
      focusNode: _focus,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      style: style,
      cursorColor: accent,
      decoration: InputDecoration(
        labelText: widget.label,
        alignLabelWithHint: widget.maxLines > 1,
        labelStyle: labelBase.copyWith(
          fontWeight: FontWeight.w500,
          color: bad ? danger : p.textMuted,
        ),
        floatingLabelStyle: labelBase.copyWith(
          fontWeight: FontWeight.w600,
          color: bad ? danger : (focused ? accent : p.textMuted),
        ),
        filled: true,
        fillColor: p.surface,
        hoverColor: Colors.transparent,
        contentPadding: EdgeInsets.fromLTRB(18, 18, check == null ? 18 : 6, 18),
        enabledBorder: outline(1.5),
        focusedBorder: outline(2),
        border: outline(1.5),
        suffixIcon: check == null ? null : _Check(on: check),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 26,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_shake, _flash]),
          builder: (context, child) {
            final t = _flash.value;
            final glow = !_flash.isAnimating
                ? 0.0
                : (t < 0.25 ? t / 0.25 : (1 - t) / 0.75);
            return Transform.translate(
              offset: Offset(
                _shake.isAnimating ? _shakeAt(_shake.value) : 0,
                0,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (glow > 0)
                      BoxShadow(
                        color: const Color(
                          0xFFF59E0B,
                        ).withValues(alpha: 0.6 * _ease.transform(glow)),
                        spreadRadius: 3,
                      ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: field,
        ),
        _drop(
          error != null
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 0, 0),
                  child: Semantics(
                    liveRegion: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(top: 1),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: danger,
                          ),
                          child: Text(
                            '!',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: p.isDark
                                  ? const Color(0xFF0B0C12)
                                  : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            error,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : widget.helper == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 0, 0),
                  child: Text(
                    widget.helper!,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: p.textMuted,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// The mint disc of Lucian #025 that springs in while its check draws.
class _Check extends StatelessWidget {
  final bool on;

  const _Check({required this.on});

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final motion = !MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: AnimatedScale(
        scale: on ? 1 : 0,
        duration: motion ? const Duration(milliseconds: 450) : Duration.zero,
        curve: _spring,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(shape: BoxShape.circle, color: p.success),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: on ? 1 : 0),
            duration: motion
                ? const Duration(milliseconds: 500)
                : Duration.zero,
            curve: const Interval(0.3, 1, curve: _ease),
            builder: (context, t, _) => CustomPaint(
              painter: _CheckPainter(
                t,
                p.isDark ? const Color(0xFF0B0C12) : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double t;
  final Color color;

  const _CheckPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    canvas.translate((size.width - 14) / 2, (size.height - 14) / 2);
    final path = Path()
      ..moveTo(3, 7.3)
      ..lineTo(5.7, 10)
      ..lineTo(11, 4.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * t), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t || old.color != color;
}
