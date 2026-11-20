// Lucian UX/UI Prompt #228 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#228
// Lucian UX/UI Prompt #039 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#039
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'guides.dart';
import 'tip_card.dart';

/// The cards of one tips tab. One lamp follows the pointer and lights every
/// card near it, fading in fast and out slowly. When [tab] changes the old
/// cards slide away and the new ones slide in from the side the user moved
/// toward, one diagonal of the grid after another.
class TipGrid extends StatefulWidget {
  final int tab;
  final List<Guide> guides;
  final ValueChanged<int> onOpen;

  const TipGrid({
    super.key,
    required this.tab,
    required this.guides,
    required this.onOpen,
  });

  @override
  State<TipGrid> createState() => _TipGridState();
}

class _TipGridState extends State<TipGrid> with TickerProviderStateMixin {
  static const _gap = 10.0;
  static const _stagger = 45.0;
  static const _slide = 550.0;
  static const _fade = 350.0;
  static const _spring = Cubic(0.34, 1.45, 0.64, 1);
  static const _ease = Cubic(0.2, 0.8, 0.2, 1);

  late final Ticker _lampTicker = createTicker(_tickLamp);
  Offset _pointer = const Offset(-500, -500);
  double _glow = 0;
  double _glowTarget = 0;
  Duration _last = Duration.zero;

  late final AnimationController _switch = AnimationController(vsync: this);
  List<Guide>? _leaving;
  int _dir = 1;
  Timer? _drop;

  @override
  void didUpdateWidget(TipGrid old) {
    super.didUpdateWidget(old);
    if (old.tab == widget.tab) return;
    _drop?.cancel();
    if (MediaQuery.disableAnimationsOf(context)) {
      _leaving = null;
      _switch.value = 1;
      return;
    }
    _dir = widget.tab > old.tab ? 1 : -1;
    _leaving = old.guides;
    final span = _maxDelay(math.max(old.guides.length, widget.guides.length));
    _switch.duration = Duration(milliseconds: (span + _slide).round());
    _switch.forward(from: 0);
    _drop = Timer(
      Duration(milliseconds: math.max(700, span + _slide).round()),
      () {
        if (mounted) setState(() => _leaving = null);
      },
    );
  }

  @override
  void dispose() {
    _drop?.cancel();
    _lampTicker.dispose();
    _switch.dispose();
    super.dispose();
  }

  void _tickLamp(Duration now) {
    final dt = math.min(0.05, math.max(0, (now - _last).inMicroseconds / 1e6));
    _last = now;
    final rate = MediaQuery.disableAnimationsOf(context)
        ? 1.0
        : math.min(1.0, dt * (_glowTarget > 0 ? 8 : 2.5));
    setState(() => _glow += (_glowTarget - _glow) * rate);
    if ((_glowTarget - _glow).abs() <= 0.005) {
      _glow = _glowTarget;
      _lampTicker.stop();
    }
  }

  void _aim(double target) {
    _glowTarget = target;
    if (!_lampTicker.isActive) {
      _last = Duration.zero;
      _lampTicker.start();
    }
  }

  int _cols(double width) => width >= 600 ? 3 : (width >= 380 ? 2 : 1);

  /// Largest stagger delay among [count] cards laid out [_cols] wide.
  double _maxDelay(int count) {
    var most = 0;
    for (var i = 0; i < count; i++) {
      most = math.max(most, i ~/ _colsNow + i % _colsNow);
    }
    return most * _stagger;
  }

  int _colsNow = 3;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardHeight = 92 + MediaQuery.textScalerOf(context).scale(40);
        final cols = _colsNow = _cols(width);
        final cardWidth = (width - _gap * (cols - 1)) / cols;
        Rect rectOf(int i) => Rect.fromLTWH(
          (i % cols) * (cardWidth + _gap),
          (i ~/ cols) * (cardHeight + _gap),
          cardWidth,
          cardHeight,
        );
        double heightOf(int n) =>
            n == 0 ? 0 : (n / cols).ceil() * (cardHeight + _gap) - _gap;
        double delayOf(int i) => (i ~/ cols + i % cols) * _stagger;

        final leaving = _leaving;
        final height = math.max(
          heightOf(widget.guides.length),
          leaving == null ? 0.0 : heightOf(leaving.length),
        );

        Widget card(Guide g, int i, {required bool interactive}) {
          final rect = rectOf(i);
          return TipCard(
            guide: g,
            lamp: _pointer - rect.topLeft,
            glow: _glow,
            onTap: interactive ? () => widget.onOpen(i) : () {},
          );
        }

        final grid = SizedBox(
          height: height,
          child: ClipRect(
            clipper: const _Inflated(6),
            child: MouseRegion(
              onHover: (e) {
                _pointer = e.localPosition;
                _aim(1);
                setState(() {});
              },
              onExit: (_) => _aim(0),
              child: AnimatedBuilder(
                animation: _switch,
                builder: (context, _) {
                  final ms =
                      _switch.value * (_switch.duration?.inMilliseconds ?? 0);
                  double run(int i, double length, Curve curve) => curve
                      .transform(((ms - delayOf(i)) / length).clamp(0.0, 1.0));
                  final moving = leaving != null;
                  return Stack(
                    children: [
                      if (leaving != null)
                        for (var i = 0; i < leaving.length; i++)
                          Positioned.fromRect(
                            rect: rectOf(i),
                            child: IgnorePointer(
                              child: ExcludeFocus(
                                child: ExcludeSemantics(
                                  child: FractionalTranslation(
                                    translation: Offset(
                                      -_dir * 0.6 * run(i, _slide, _spring),
                                      0,
                                    ),
                                    child: Opacity(
                                      opacity: 1 - run(i, _fade, _ease),
                                      child: card(
                                        leaving[i],
                                        i,
                                        interactive: false,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      for (var i = 0; i < widget.guides.length; i++)
                        Positioned.fromRect(
                          rect: rectOf(i),
                          child: moving
                              ? FractionalTranslation(
                                  translation: Offset(
                                    _dir * 0.7 * (1 - run(i, _slide, _spring)),
                                    0,
                                  ),
                                  child: Opacity(
                                    opacity: run(i, _fade, _ease),
                                    child: card(
                                      widget.guides[i],
                                      i,
                                      interactive: true,
                                    ),
                                  ),
                                )
                              : card(widget.guides[i], i, interactive: true),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
        return reduce
            ? grid
            : AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: _ease,
                alignment: Alignment.topCenter,
                child: grid,
              );
      },
    );
  }
}

/// Clips to the box grown by [by] on every side, so focus rings show but
/// cards sliding past the edges do not.
class _Inflated extends CustomClipper<Rect> {
  final double by;

  const _Inflated(this.by);

  @override
  Rect getClip(Size size) => (Offset.zero & size).inflate(by);

  @override
  bool shouldReclip(_Inflated old) => old.by != by;
}
