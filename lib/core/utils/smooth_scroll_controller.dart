import 'package:flutter/widgets.dart';

import '../preferences/app_preferences.dart';

/// A custom [ScrollPositionWithSingleContext] that intercepts pointer scroll events
/// (like mouse wheel scroll) and animates the scroll offset instead of jumping
/// immediately, providing a smooth scrolling experience.
class SmoothScrollPosition extends ScrollPositionWithSingleContext {
  SmoothScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  double? _targetPixels;
  bool _isAnimatingSmoothly = false;

  @override
  void pointerScroll(double delta) {
    if (delta == 0.0) {
      return;
    }

    // Check setting from AppPreferences directly and synchronously
    final isSmoothEnabled = AppPreferences().get<bool>('smoothScrollEnabled', false) ?? false;
    if (!isSmoothEnabled) {
      super.pointerScroll(delta);
      return;
    }

    // Calculate target pixels starting from current target (if animating) or current position
    final double basePixels = _targetPixels ?? pixels;
    final double target = (basePixels + delta * 2.2).clamp(minScrollExtent, maxScrollExtent);

    if (target != pixels) {
      _targetPixels = target;

      _isAnimatingSmoothly = true;
      // `.whenComplete` (instead of `.then`) guarantees `_isAnimatingSmoothly`
      // is reset whether the animation completes normally, completes early via
      // `jumpTo`, or fails synchronously inside `animateTo` (e.g. detached
      // scrollable). With the old `.then` + immediate `= false` reset, the
      // flag flipped off before `beginActivity` ever observed it, so the guard
      // in `beginActivity` always cleared `_targetPixels` mid-animation.
      animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuart,
      ).whenComplete(() {
        if (_targetPixels == target) {
          _targetPixels = null;
        }
        _isAnimatingSmoothly = false;
      });
    }
  }

  @override
  void jumpTo(double value) {
    _targetPixels = null;
    super.jumpTo(value);
  }

  @override
  Future<void> animateTo(
    double to, {
    required Duration duration,
    required Curve curve,
  }) {
    if (_targetPixels != to) {
      _targetPixels = null;
    }
    return super.animateTo(to, duration: duration, curve: curve);
  }

  @override
  void beginActivity(ScrollActivity? newActivity) {
    if (!_isAnimatingSmoothly) {
      _targetPixels = null;
    }
    super.beginActivity(newActivity);
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
