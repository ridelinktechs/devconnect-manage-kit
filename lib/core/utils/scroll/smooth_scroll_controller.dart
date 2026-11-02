import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../preferences/app_preferences.dart';

/// A custom [ScrollPositionWithSingleContext] that intercepts pointer scroll events
/// (like mouse wheel scroll) and glides to the new offset instead of jumping
/// immediately, providing a smooth scrolling experience.
///
/// Trackpads and Magic Mouse reach Flutter as pan gestures with the system's
/// own momentum, so this only changes mouse wheels.
class SmoothScrollPosition extends ScrollPositionWithSingleContext {
  SmoothScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  @override
  void pointerScroll(double delta) {
    if (delta == 0.0) {
      return;
    }

    final isSmoothEnabled =
        AppPreferences().get<bool>('smoothScrollEnabled', false) ?? false;
    if (!isSmoothEnabled) {
      super.pointerScroll(delta);
      return;
    }

    final current = activity;
    final base = current is _WheelScrollActivity ? current.target : pixels;
    final target = (base + delta * 2.2).clamp(minScrollExtent, maxScrollExtent);
    updateUserScrollDirection(
      -delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse,
    );
    if (current is _WheelScrollActivity) {
      current.target = target;
      return;
    }
    if (target == pixels) return;

    final durationMs =
        AppPreferences().get<int>('smoothScrollDuration', 250) ?? 250;
    beginActivity(
      _WheelScrollActivity(
        this,
        from: pixels,
        target: target,
        settle: Duration(milliseconds: durationMs),
        vsync: context.vsync,
      ),
    );
  }
}

/// Carries the offset to [target] on a critically damped spring. A new wheel
/// tick only moves [target], so the speed changes smoothly instead of
/// restarting from a standstill or a sudden burst, and the list keeps taking
/// clicks and hovers while it moves.
class _WheelScrollActivity extends ScrollActivity {
  _WheelScrollActivity(
    super.delegate, {
    required double from,
    required this.target,
    required Duration settle,
    required TickerProvider vsync,
  }) : _x = from,
       _omega = 5 / math.max(0.05, settle.inMicroseconds / 1e6) {
    _ticker = vsync.createTicker(_tick)..start();
  }

  double target;

  /// Spring stiffness: settles within ~[settle] (95% of the way at 5/ω).
  final double _omega;
  double _x;
  double _v = 0;
  Duration _last = Duration.zero;
  late final Ticker _ticker;

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0) return;

    final metrics = delegate as ScrollMetrics;
    target = target.clamp(metrics.minScrollExtent, metrics.maxScrollExtent);
    final e = _x - target;
    final c = _v + _omega * e;
    final decay = math.exp(-_omega * dt);
    var next = target + (e + c * dt) * decay;
    _v = (_v - _omega * c * dt) * decay;
    final done = (next - target).abs() < 0.5 && _v.abs() < 20;
    if (done) {
      next = target;
      _v = 0;
    }
    _x = next;
    if (delegate.setPixels(next) != 0.0 || done) {
      delegate.goBallistic(0.0);
    }
  }

  @override
  void dispatchOverscrollNotification(
    ScrollMetrics metrics,
    BuildContext context,
    double overscroll,
  ) {
    OverscrollNotification(
      metrics: metrics,
      context: context,
      overscroll: overscroll,
      velocity: velocity,
    ).dispatch(context);
  }

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => true;

  @override
  double get velocity => _v;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

/// A custom [ScrollController] that returns [SmoothScrollPosition] instead of
/// [ScrollPositionWithSingleContext] to enable smooth scrolling.
class SmoothScrollController extends ScrollController {
  SmoothScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return SmoothScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}
