import 'package:flutter/material.dart';

/// Local card wrapper used by every Settings section. 20px padding +
/// 12px radius + 1px hairline border (in [border], themed by the page)
/// — kept local to settings because the prop signature (raw `Color`
/// surface + border) is more flexible than `lib/components/cards/`
/// variants which are themed.
class SettingsCard extends StatelessWidget {
  final Color surface;
  final Color border;
  final Widget child;

  const SettingsCard({
    super.key,
    required this.surface,
    required this.border,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}