import 'package:flutter/material.dart';

/// Tween-animated counter that smoothly ramps from 0 → [value] over
/// [duration] (default 700ms, easeOutCubic — the GSAP `power3.out`
/// equivalent). Used in the Error Inspector's info-bar tiles so total /
/// fatal / per-platform counts animate when the live stream updates.
///
/// [formatter] lets callers prepend suffixes (e.g. "ms") without
/// re-implementing the tween — when omitted the value is rendered as
/// a plain integer.
class CountUp extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String Function(int)? formatter;

  const CountUp({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 700),
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final n = v.toInt();
        return Text(
          formatter != null ? formatter!(n) : '$n',
          style: style,
        );
      },
    );
  }
}