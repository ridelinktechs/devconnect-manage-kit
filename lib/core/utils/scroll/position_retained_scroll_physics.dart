import 'package:flutter/widgets.dart';

/// Custom [ScrollPhysics] that retains the scroll position when new items are
/// added above the current viewport (e.g. a reversed ListView growing at the
/// visual top).
///
/// Without this, [ScrollPosition.pixels] stays unchanged while
/// [maxScrollExtent] grows, causing visible items to drift/jump.
///
/// This is the canonical solution used by Flutter chat apps to prevent scroll
/// drift when new messages arrive while the user is reading older messages.
///
/// See: https://github.com/flutter/flutter/issues/63946
///      https://github.com/flutter/flutter/issues/80250
class PositionRetainedScrollPhysics extends ScrollPhysics {
  /// When true, the physics will adjust scroll position to compensate for
  /// content added above the viewport. Set to false to disable temporarily.
  final bool shouldRetain;

  const PositionRetainedScrollPhysics({
    super.parent,
    this.shouldRetain = true,
  });

  @override
  PositionRetainedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return PositionRetainedScrollPhysics(
      parent: buildParent(ancestor),
      shouldRetain: shouldRetain,
    );
  }

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    final position = super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );

    final diff = newPosition.maxScrollExtent - oldPosition.maxScrollExtent;

    // Only adjust when:
    // 1. shouldRetain is enabled
    // 2. Content grew (diff > 0) -- items were added
    // 3. User has scrolled away from the start (pixels > minScrollExtent),
    //    meaning they are NOT at the bottom/newest position
    if (shouldRetain &&
        diff > 0 &&
        oldPosition.pixels > oldPosition.minScrollExtent) {
      return position + diff;
    }

    return position;
  }
}
