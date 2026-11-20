// Lucian UX/UI Prompt #008 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#008
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../shared/focus_ring.dart';

/// A labelled block of code with a copy button. Copying redraws the button's
/// icon as a check, sweeps a gleam across the code and pops a "Copied"
/// bubble for 1.8 s.
class CodeSnippet extends StatefulWidget {
  final String label;
  final String code;

  const CodeSnippet({super.key, required this.label, required this.code});

  @override
  State<CodeSnippet> createState() => _CodeSnippetState();
}

class _CodeSnippetState extends State<CodeSnippet>
    with TickerProviderStateMixin {
  static const _ease = Cubic(0.2, 0.8, 0.2, 1);
  static const _spring = Cubic(0.34, 1.45, 0.64, 1);
  static const _mint = ColorTokens.success;

  late final _copied = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  Timer? _reset;
  bool _on = false;
  bool _down = false;
  bool _hover = false;

  @override
  void dispose() {
    _reset?.cancel();
    _copied.dispose();
    _sweep.dispose();
    super.dispose();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.code));
    _reset?.cancel();
    final reduce = MediaQuery.disableAnimationsOf(context);
    setState(() => _on = true);
    if (reduce) {
      _copied.value = 1;
    } else {
      _copied.forward(from: 0);
      _sweep.forward(from: 0);
    }
    _reset = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _on = false);
      if (reduce) {
        _copied.value = 0;
      } else {
        _copied.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final page = p.isDark ? ColorTokens.darkSurface : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: _ease,
      decoration: BoxDecoration(
        color: p.codeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _on ? _mint : p.border),
        boxShadow: [
          BoxShadow(
            color: _mint.withValues(alpha: _on ? 1 : 0),
            spreadRadius: 0.5,
          ),
          BoxShadow(
            color: _mint.withValues(alpha: _on ? 0.16 : 0),
            spreadRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: p.textMuted,
                    ),
                  ),
                ),
                _button(p, page),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                  child: Text(
                    widget.code,
                    style: chromeMono(context, size: 12.5, color: p.text),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _sweep,
                      builder: (context, _) {
                        if (!_sweep.isAnimating) return const SizedBox.shrink();
                        final t = _ease.transform(_sweep.value);
                        return FractionalTranslation(
                          translation: Offset(-1.1 + 2.2 * t, 0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: const Alignment(-1, -0.18),
                                end: const Alignment(1, 0.18),
                                colors: [
                                  _mint.withValues(alpha: 0),
                                  _mint.withValues(alpha: 0.3),
                                  _mint.withValues(alpha: 0),
                                ],
                                stops: const [0.2, 0.5, 0.8],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(ChromePalette p, Color page) {
    final s = S.of(context);
    final surface2 = p.isDark
        ? const Color(0xFF262C36)
        : const Color(0xFFEAEEF2);
    final surface3 = p.isDark
        ? const Color(0xFF30363D)
        : const Color(0xFFDDE2E7);
    final iconColor = _on
        ? ColorTokens.darkSurface
        : (_hover ? p.text : p.textMuted);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Listener(
          onPointerDown: (_) => setState(() => _down = true),
          onPointerUp: (_) => setState(() => _down = false),
          onPointerCancel: (_) => setState(() => _down = false),
          child: AnimatedScale(
            scale: _down ? 0.88 : 1,
            duration: const Duration(milliseconds: 450),
            curve: _spring,
            child: Tooltip(
              message: s.tipsCopyCode,
              child: FocusRing(
                onTap: _copy,
                radius: 9,
                offset: 3,
                label: s.tipsCopyCode,
                onHover: (v) => setState(() => _hover = v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: _ease,
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _on ? _mint : (_hover ? surface3 : surface2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: AnimatedBuilder(
                    animation: _copied,
                    builder: (context, _) {
                      final v = _copied.value;
                      final fade = _ease.transform((v / 0.5).clamp(0.0, 1.0));
                      final pop = _spring.transform(v);
                      final draw = _ease.transform(
                        ((v - 0.2) / 0.8).clamp(0.0, 1.0),
                      );
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: 1 - fade,
                            child: Transform.rotate(
                              angle: pop * math.pi / 6,
                              child: Transform.scale(
                                scale: 1 - 0.6 * pop,
                                child: Icon(
                                  LucideIcons.copy,
                                  size: 15,
                                  color: iconColor,
                                ),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: fade,
                            child: Transform.rotate(
                              angle: (1 - pop) * -math.pi / 6,
                              child: Transform.scale(
                                scale: 0.4 + 0.6 * pop,
                                child: CustomPaint(
                                  size: const Size.square(15),
                                  painter: _CheckPainter(
                                    progress: draw,
                                    color: iconColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -6,
          bottom: 38,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _copied,
              builder: (context, _) {
                final v = _copied.value;
                if (v == 0) return const SizedBox.shrink();
                final fade = _ease.transform((v / 0.5).clamp(0.0, 1.0));
                final pop = _spring.transform(v);
                return Opacity(
                  opacity: fade,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - pop)),
                    child: Transform.scale(
                      scale: 0.8 + 0.2 * pop,
                      alignment: const Alignment(0.6, 1),
                      child: _Bubble(
                        text: s.tipsCodeCopied,
                        color: p.text,
                        textColor: page,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// "Copied" speech bubble with its arrow at the bottom right.
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
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 13),
            child: Transform.translate(
              offset: const Offset(0, -4),
              child: Transform.rotate(
                angle: math.pi / 4,
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
          ),
        ],
      ),
    );
  }
}

/// The check mark of the copy button, drawn up to [progress] of its length.
class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _CheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final k = size.width / 24;
    final path = Path()
      ..moveTo(5.5 * k, 12.5 * k)
      ..lineTo(9.7 * k, 16.7 * k)
      ..lineTo(18.5 * k, 8 * k);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.color != color;
}
