import 'package:flutter/material.dart';

/// Live "breathing" indicator: a solid dot at the center with an
/// expanding ring that fades out and restarts every [period] ms.
///
/// Performance note: the ring's alpha rides the controller's progress
/// directly via `widget.color.withValues(alpha: ...)` instead of wrapping
/// in an `Opacity` widget — that avoids intermediate offscreen render
/// passes on every animation tick (the inner Container is a simple
/// solid-color circle, so the Opacity layer is pure overhead).
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  final Duration period;

  const PulsingDot({
    super.key,
    required this.color,
    this.size = 8,
    this.period = const Duration(milliseconds: 1800),
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period)..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 3,
      height: widget.size * 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer expanding ring (perpetual "breathing" pulse).
          // Animate the color's alpha directly instead of wrapping in an
          // `Opacity` widget — that avoids intermediate offscreen render
          // passes on every animation tick.
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Transform.scale(
                scale: 0.6 + 0.8 * _ctrl.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Color alpha rides the same progress: starts at 0.6,
                    // fades to 0 as the ring expands.
                    color: widget.color.withValues(
                      alpha: 0.6 * (1 - _ctrl.value),
                    ),
                  ),
                ),
              );
            },
          ),
          // Solid dot (anchor)
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}