// Lucian UX/UI Prompt #088 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#088
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../settings/presentation/shared/focus_ring.dart';
import '../shared/rule_templates.dart';

const _ease = Cubic(0.2, 0.8, 0.2, 1);
const _spring = Cubic(0.34, 1.45, 0.64, 1);
const _flight = Cubic(0.45, 0, 0.25, 1);

/// Lucian #088's empty state for a page with no rules: a folder floats, and
/// hovering it or a template opens it a little as paper peeks out. Picking a
/// template flies a sheet into the folder, which gulps it, and then
/// [onCreate] makes the rule. With [dropIn] (the last rule was just
/// deleted) the folder drops back in first.
class EmptyRulesState extends StatefulWidget {
  final ValueChanged<RuleTemplate> onCreate;
  final bool dropIn;

  /// Shown under the templates, e.g. the deleted rule's Undo.
  final Widget? footer;

  const EmptyRulesState({
    super.key,
    required this.onCreate,
    this.dropIn = false,
    this.footer,
  });

  @override
  State<EmptyRulesState> createState() => _EmptyRulesStateState();
}

class _EmptyRulesStateState extends State<EmptyRulesState>
    with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );
  late final AnimationController _gulp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _drop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
    value: 1,
  );
  final _stack = GlobalKey();
  final _art = GlobalKey();
  final _buttons = {for (final t in RuleTemplate.values) t: GlobalKey()};
  final _timers = <Timer>[];
  int _hovering = 0;
  bool _eat = false;
  bool _started = false;
  RuleTemplate? _flying;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;

  bool get _motion => !MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !_motion) return;
    _started = true;
    _float.repeat();
    if (widget.dropIn) _drop.forward(from: 0);
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _float.dispose();
    _fly.dispose();
    _gulp.dispose();
    _drop.dispose();
    super.dispose();
  }

  void _later(int ms, VoidCallback fn) => _timers.add(
    Timer(Duration(milliseconds: ms), () {
      if (mounted) fn();
    }),
  );

  /// The point [dy] of the way down [key]'s box, centered, in the stack.
  Offset _at(GlobalKey key, {double dy = 0.5}) {
    final stack = _stack.currentContext!.findRenderObject()! as RenderBox;
    final box = key.currentContext!.findRenderObject()! as RenderBox;
    return stack.globalToLocal(
      box.localToGlobal(Offset(box.size.width / 2, box.size.height * dy)),
    );
  }

  void _create(RuleTemplate t) {
    if (_flying != null) return;
    if (!_motion) {
      widget.onCreate(t);
      return;
    }
    setState(() {
      _from = _at(_buttons[t]!);
      _to = _at(_art, dy: 0.3);
      _flying = t;
      _eat = true;
    });
    _fly.forward(from: 0);
    _later(700, () {
      setState(() => _eat = false);
      _gulp.forward(from: 0);
    });
    _later(1180, () {
      setState(() => _flying = null);
      widget.onCreate(t);
    });
  }

  void _hover(bool on) => setState(() => _hovering += on ? 1 : -1);

  /// 0 → 1 → 0 over the 5 s float, eased in and out.
  double get _wave => 0.5 - 0.5 * math.cos(2 * math.pi * _float.value);

  /// The `u088-gulp` squash keyframes.
  (double, double) get _squash {
    if (!_gulp.isAnimating) return (1, 1);
    const stops = [0.0, 0.3, 0.62, 1.0];
    const xs = [1.0, 1.08, 0.97, 1.0];
    const ys = [1.0, 0.88, 1.05, 1.0];
    final t = _gulp.value;
    var i = 0;
    while (i < stops.length - 2 && t > stops[i + 1]) {
      i++;
    }
    final k = _ease.transform(
      ((t - stops[i]) / (stops[i + 1] - stops[i])).clamp(0.0, 1.0),
    );
    return (xs[i] + (xs[i + 1] - xs[i]) * k, ys[i] + (ys[i + 1] - ys[i]) * k);
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final base = DefaultTextStyle.of(context).style;
    final pose = _eat ? 2.0 : (_hovering > 0 ? 1.0 : 0.0);

    final art = MouseRegion(
      onEnter: (_) => _hover(true),
      onExit: (_) => _hover(false),
      child: SizedBox(
        key: _art,
        width: 168,
        height: 138,
        child: Stack(
          children: [
            Positioned(
              left: 34,
              right: 34,
              bottom: 0,
              height: 10,
              child: AnimatedBuilder(
                animation: _float,
                builder: (context, _) => Opacity(
                  opacity: 1 - 0.4 * _wave,
                  child: Transform.scale(
                    scaleX: 1 - 0.2 * _wave,
                    child: CustomPaint(
                      painter: _ShadowPainter(
                        p.isDark
                            ? Colors.black.withValues(alpha: 0.55)
                            : p.text.withValues(alpha: 0.16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              width: 168,
              height: 128,
              child: AnimatedBuilder(
                animation: Listenable.merge([_float, _gulp, _drop]),
                builder: (context, child) {
                  final (sx, sy) = _squash;
                  final d = _spring.transform(_drop.value);
                  final grow = 0.85 + 0.15 * d;
                  return Transform.translate(
                    offset: Offset(0, -7 * _wave - 46 * (1 - d)),
                    child: Opacity(
                      opacity: _drop.value.clamp(0.0, 1.0),
                      child: Transform(
                        alignment: const FractionalOffset(0.5, 0.92),
                        transform: Matrix4.diagonal3Values(
                          sx * grow,
                          sy * grow,
                          1,
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: pose),
                  duration: _motion
                      ? const Duration(milliseconds: 550)
                      : Duration.zero,
                  curve: _spring,
                  builder: (context, t, _) => CustomPaint(
                    size: const Size(168, 128),
                    painter: _FolderPainter(t),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Stack(
      key: _stack,
      children: [
        Positioned.fill(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  art,
                  const SizedBox(height: 12),
                  Text(
                    'No mock rules yet',
                    style: base.copyWith(
                      fontSize: 18.5,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.74,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Text(
                      'Pick a template to answer the app\'s requests '
                      'yourself, without a server.',
                      textAlign: TextAlign.center,
                      style: base.copyWith(
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: p.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final t in RuleTemplate.values)
                        _TemplateButton(
                          key: _buttons[t],
                          template: t,
                          onHover: _hover,
                          onTap: () => _create(t),
                        ),
                    ],
                  ),
                  if (widget.footer case final footer?) ...[
                    const SizedBox(height: 24),
                    footer,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (_flying case final t?)
          AnimatedBuilder(
            animation: _fly,
            builder: (context, child) {
              final q = _flight.transform(_fly.value);
              const at = [0.0, 0.45, 0.82, 1.0];
              final d = _to - _from;
              double frames(List<double> v) {
                var i = 0;
                while (i < at.length - 2 && q > at[i + 1]) {
                  i++;
                }
                final k = ((q - at[i]) / (at[i + 1] - at[i])).clamp(0.0, 1.0);
                return v[i] + (v[i + 1] - v[i]) * k;
              }

              return Positioned(
                left: _from.dx - 13 + frames([0, d.dx * 0.45, d.dx, d.dx]),
                top:
                    _from.dy -
                    16 +
                    frames([0, d.dy * 0.45 - 70, d.dy, d.dy + 26]),
                child: IgnorePointer(
                  child: Opacity(
                    opacity: frames([0, 1, 1, 0]).clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: frames([-10, 12, 0, 0]) * math.pi / 180,
                      child: Transform.scale(
                        scale: frames([0.5, 1.1, 0.8, 0.6]),
                        child: child,
                      ),
                    ),
                  ),
                ),
              );
            },
            child: _Paper(color: t.color),
          ),
      ],
    );
  }
}

/// A template choice: a colored glyph tile and the template's name. It lifts
/// on hover and squeezes when pressed.
class _TemplateButton extends StatefulWidget {
  final RuleTemplate template;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;

  const _TemplateButton({
    super.key,
    required this.template,
    required this.onHover,
    required this.onTap,
  });

  @override
  State<_TemplateButton> createState() => _TemplateButtonState();
}

class _TemplateButtonState extends State<_TemplateButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final t = widget.template;
    final fill = p.isDark
        ? (_hover ? const Color(0xFF30363D) : p.selected)
        : (_hover ? const Color(0xFFDDE3E9) : const Color(0xFFEAEEF2));
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 350),
        curve: _spring,
        child: AnimatedSlide(
          offset: Offset(0, _hover && !_down ? -2 / 38 : 0),
          duration: const Duration(milliseconds: 350),
          curve: _spring,
          child: FocusRing(
            onTap: widget.onTap,
            radius: 13,
            label: 'New ${t.label.toLowerCase()} rule',
            onHover: (v) {
              setState(() => _hover = v);
              widget.onHover(v);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 38,
              padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: t.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(t.icon, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    t.label,
                    style: DefaultTextStyle.of(context).style.copyWith(
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: _hover ? p.text : p.textMuted,
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

/// The soft oval under the folder: `radial-gradient(closest-side, …)` on a
/// wide box, which Flutter's circular RadialGradient can't stretch.
class _ShadowPainter extends CustomPainter {
  final Color color;

  const _ShadowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: size.width * 0.8,
        height: size.height * 0.5,
      ),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(_ShadowPainter old) => old.color != color;
}

/// The sheet that flies into the folder: a band in the template's color
/// over two ruled lines.
class _Paper extends StatelessWidget {
  final Color color;

  const _Paper({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 32,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x730A0C14),
            offset: Offset(0, 6),
            blurRadius: 14,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 7,
            child: ColoredBox(color: color),
          ),
          for (final top in const [12.0, 26.0])
            Positioned(
              left: 5,
              top: top,
              width: 16,
              height: 2,
              child: const ColoredBox(color: Color(0xFFCBD3E1)),
            ),
        ],
      ),
    );
  }
}

/// The folder of Lucian #088 in the app's purple, drawn from its SVG.
/// [pose] runs from 0 (closed) through 1 (open, a template hovered) to 2
/// (swallowing a sheet).
class _FolderPainter extends CustomPainter {
  final double pose;

  const _FolderPainter(this.pose);

  static const _poses = [
    [0.0, 1.0, 0.0, 0.0, 0.0, 0.0],
    [-7.0, 0.86, -10.0, -5.0, -6.0, 4.0],
    [-12.0, 0.74, -14.0, -7.0, -10.0, 6.0],
  ];

  static final _back = Path()
    ..moveTo(16, 26)
    ..relativeArcToPoint(
      const Offset(10, -10),
      radius: const Radius.circular(10),
    )
    ..relativeLineTo(34, 0)
    ..relativeArcToPoint(const Offset(6, 2.6), radius: const Radius.circular(8))
    ..relativeLineTo(8, 8.4)
    ..relativeLineTo(68, 0)
    ..relativeArcToPoint(
      const Offset(10, 10),
      radius: const Radius.circular(10),
    )
    ..relativeLineTo(0, 66)
    ..relativeArcToPoint(
      const Offset(-10, 10),
      radius: const Radius.circular(10),
    )
    ..lineTo(26, 113)
    ..relativeArcToPoint(
      const Offset(-10, -10),
      radius: const Radius.circular(10),
    )
    ..close();

  static final _front = Path()
    ..moveTo(10, 50)
    ..relativeArcToPoint(
      const Offset(10, -10),
      radius: const Radius.circular(10),
    )
    ..relativeLineTo(128, 0)
    ..relativeArcToPoint(
      const Offset(10, 10.8),
      radius: const Radius.circular(10),
    )
    ..relativeLineTo(-5, 52)
    ..relativeArcToPoint(
      const Offset(-10, 9.2),
      radius: const Radius.circular(10),
    )
    ..lineTo(25, 112)
    ..relativeArcToPoint(
      const Offset(-10, -9.2),
      radius: const Radius.circular(10),
    )
    ..close();

  double _value(int i) {
    final t = pose.clamp(-0.5, 2.5);
    final from = t < 1 ? 0 : 1;
    final k = t - from;
    return _poses[from][i] + (_poses[from + 1][i] - _poses[from][i]) * k;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 168, size.height / 128);
    final fill = Paint();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const rad = math.pi / 180;

    canvas.drawPath(_back, fill..color = ColorTokens.primaryDark);

    void paper(
      Offset origin,
      double dy,
      double turn,
      RRect sheet,
      Color color,
      Color ink,
      List<(Offset, Offset)> rules,
    ) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy + dy);
      canvas.rotate(turn * rad);
      canvas.translate(-origin.dx, -origin.dy);
      canvas.drawRRect(sheet, fill..color = color);
      for (final (a, b) in rules) {
        canvas.drawLine(a, b, line..color = ink);
      }
      canvas.restore();
    }

    paper(
      const Offset(76, 98),
      _value(2),
      _value(3),
      RRect.fromLTRBR(30, 26, 122, 98, const Radius.circular(6)),
      const Color(0xFFEEF1F7),
      const Color(0xFFC9D1DF),
      const [
        (Offset(42, 40), Offset(90, 40)),
        (Offset(42, 50), Offset(104, 50)),
        (Offset(42, 60), Offset(78, 60)),
      ],
    );
    paper(
      const Offset(95, 100),
      _value(4),
      _value(5),
      RRect.fromLTRBR(50, 32, 140, 100, const Radius.circular(6)),
      Colors.white,
      const Color(0xFFD3DAE6),
      const [
        (Offset(62, 46), Offset(114, 46)),
        (Offset(62, 56), Offset(126, 56)),
        (Offset(62, 66), Offset(92, 66)),
      ],
    );

    canvas.save();
    canvas.translate(84, 112);
    canvas.skew(math.tan(_value(0) * rad), 0);
    canvas.scale(1, math.max(0.05, _value(1)));
    canvas.translate(-84, -112);
    canvas.drawPath(_front, fill..color = ColorTokens.primary);
    canvas.drawLine(
      const Offset(22, 47),
      const Offset(146, 47),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      RRect.fromLTRBR(66, 72, 102, 80, const Radius.circular(4)),
      Paint()..color = Colors.white.withValues(alpha: 0.38),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FolderPainter old) => old.pose != pose;
}
