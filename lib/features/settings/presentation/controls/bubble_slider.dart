// Lucian UX/UI Prompt #017 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#017
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';

/// Slider with its value in a bubble above the handle. While dragging, the
/// bubble leans away from the way the handle moves, as far as its speed,
/// and springs upright when it stops. Arrow keys, Page Up/Down, Home and
/// End work too. A null [onChanged] disables it.
class BubbleSlider extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final List<int> ticks;
  final String Function(int value) format;
  final ValueChanged<int>? onChanged;
  final String label;

  const BubbleSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.ticks,
    required this.format,
    required this.onChanged,
    required this.label,
  });

  @override
  State<BubbleSlider> createState() => _BubbleSliderState();
}

class _BubbleSliderState extends State<BubbleSlider> {
  static const _spring = Cubic(0.34, 1.45, 0.64, 1);
  static const _thumb = 22.0;
  static const _trackTop = 38.0;
  static const _track = 8.0;

  final _focus = FocusNode();
  bool _drag = false;
  bool _hover = false;
  bool _focused = false;
  double _tilt = 0;
  Duration? _lastTime;
  Timer? _still;

  @override
  void dispose() {
    _still?.cancel();
    _focus.dispose();
    super.dispose();
  }

  double get _fraction =>
      ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  void _set(int v) {
    final snapped =
        (((v - widget.min) / widget.step).round() * widget.step + widget.min)
            .clamp(widget.min, widget.max);
    if (snapped != widget.value) widget.onChanged?.call(snapped);
  }

  void _setFromX(double x, double width) => _set(
    widget.min +
        ((x / width).clamp(0.0, 1.0) * (widget.max - widget.min)).round(),
  );

  void _lean(double degrees) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    setState(() => _tilt = degrees.clamp(-22.0, 22.0));
    _still?.cancel();
    _still = Timer(const Duration(milliseconds: 90), () {
      if (mounted) setState(() => _tilt = 0);
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final page = ((widget.max - widget.min) / 10).round();
    final key = event.logicalKey;
    final delta = switch (key) {
      LogicalKeyboardKey.arrowRight ||
      LogicalKeyboardKey.arrowUp => widget.step,
      LogicalKeyboardKey.arrowLeft ||
      LogicalKeyboardKey.arrowDown => -widget.step,
      LogicalKeyboardKey.pageUp => page,
      LogicalKeyboardKey.pageDown => -page,
      LogicalKeyboardKey.home => widget.min - widget.value,
      LogicalKeyboardKey.end => widget.max - widget.value,
      _ => 0,
    };
    if (delta == 0) return KeyEventResult.ignored;
    _lean(delta > 0 ? -9 : 9);
    _set(widget.value + delta);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final enabled = widget.onChanged != null;
    final ring = p.isDark ? const Color(0xFF6E8BFF) : const Color(0xFF4F8DFF);
    final ink = p.text;
    final page = p.isDark ? ColorTokens.darkSurface : Colors.white;
    final reduce = MediaQuery.disableAnimationsOf(context);

    final slider = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final x = _fraction * width;
        return SizedBox(
          height: 78,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              _focus.requestFocus();
              _setFromX(d.localPosition.dx, width);
            },
            onHorizontalDragStart: (d) {
              _focus.requestFocus();
              setState(() => _drag = true);
              _lastTime = d.sourceTimeStamp;
              _setFromX(d.localPosition.dx, width);
            },
            onHorizontalDragUpdate: (d) {
              final now = d.sourceTimeStamp;
              final last = _lastTime;
              final ms = now != null && last != null
                  ? (now - last).inMicroseconds / 1000
                  : 16.0;
              _lastTime = now;
              _lean(-d.delta.dx / (ms < 8 ? 8 : ms) * 14);
              _setFromX(d.localPosition.dx, width);
            },
            onHorizontalDragEnd: (_) => setState(() {
              _drag = false;
              _tilt = 0;
            }),
            onHorizontalDragCancel: () => setState(() {
              _drag = false;
              _tilt = 0;
            }),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: _trackTop,
                  height: _track,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: p.isDark
                          ? const Color(0xFF30363D)
                          : const Color(0xFFE4E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  width: x,
                  top: _trackTop,
                  height: _track,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B6CFF), Color(0xFF4F8DFF)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: x,
                  bottom: 78 - _trackTop + 12,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, 0),
                    child: AnimatedRotation(
                      turns: _tilt / 360,
                      alignment: Alignment.bottomCenter,
                      duration: reduce
                          ? Duration.zero
                          : Duration(milliseconds: _drag ? 120 : 550),
                      curve: _drag ? Curves.linear : _spring,
                      child: AnimatedScale(
                        scale: _drag ? 1.1 : 1,
                        alignment: Alignment.bottomCenter,
                        duration: const Duration(milliseconds: 300),
                        curve: _spring,
                        child: _Bubble(
                          text: widget.format(widget.value),
                          color: ink,
                          textColor: page,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: x - _thumb / 2,
                  top: _trackTop + _track / 2 - _thumb / 2,
                  child: MouseRegion(
                    cursor: _drag
                        ? SystemMouseCursors.grabbing
                        : SystemMouseCursors.grab,
                    onEnter: (_) => setState(() => _hover = true),
                    onExit: (_) => setState(() => _hover = false),
                    child: AnimatedScale(
                      scale: _drag ? 1.15 : (_hover ? 1.08 : 1),
                      duration: const Duration(milliseconds: 350),
                      curve: _spring,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _thumb,
                        height: _thumb,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: ring, spreadRadius: 2.5),
                            if (_drag || _focused)
                              BoxShadow(
                                color: ring.withValues(alpha: 0.2),
                                spreadRadius: 8,
                              ),
                            BoxShadow(
                              color: const Color(
                                0xFF283CA0,
                              ).withValues(alpha: 0.45),
                              offset: const Offset(0, 6),
                              blurRadius: 14,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                for (final t in widget.ticks)
                  _Tick(
                    label: widget.format(t),
                    at: (t - widget.min) / (widget.max - widget.min) * width,
                    width: width,
                    top: _trackTop + _track + 10,
                    on: t <= widget.value,
                  ),
              ],
            ),
          ),
        );
      },
    );

    return Semantics(
      slider: true,
      label: widget.label,
      value: widget.format(widget.value),
      increasedValue: widget.format(
        (widget.value + widget.step).clamp(widget.min, widget.max),
      ),
      decreasedValue: widget.format(
        (widget.value - widget.step).clamp(widget.min, widget.max),
      ),
      enabled: enabled,
      onIncrease: enabled ? () => _set(widget.value + widget.step) : null,
      onDecrease: enabled ? () => _set(widget.value - widget.step) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Focus(
            focusNode: _focus,
            canRequestFocus: enabled,
            onKeyEvent: _onKey,
            onFocusChange: (v) => setState(() => _focused = v),
            child: slider,
          ),
        ),
      ),
    );
  }
}

/// The value bubble, its point at the bottom centre.
class _Bubble extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const _Bubble({
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -4),
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A tick label under the track with its mark; the end labels stay inside.
class _Tick extends StatelessWidget {
  final String label;
  final double at;
  final double width;
  final double top;
  final bool on;

  const _Tick({
    required this.label,
    required this.at,
    required this.width,
    required this.top,
    required this.on,
  });

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final color = on ? p.text : p.textMuted;
    final align = at <= 1
        ? CrossAxisAlignment.start
        : (at >= width - 1
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.center);
    final shift = switch (align) {
      CrossAxisAlignment.start => 0.0,
      CrossAxisAlignment.end => -1.0,
      _ => -0.5,
    };
    return Positioned(
      left: at,
      top: top,
      child: FractionalTranslation(
        translation: Offset(shift, 0),
        child: Column(
          crossAxisAlignment: align,
          children: [
            Container(
              width: 2,
              height: 5,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: DefaultTextStyle.of(context).style.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
