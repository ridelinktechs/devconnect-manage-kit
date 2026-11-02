import 'package:flutter/material.dart';

/// Local card wrapper used by every Settings section. 20px padding +
/// 14px radius + 1px hairline border (in [border], themed by the page)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
            offset: const Offset(0, 18),
            blurRadius: 36,
            spreadRadius: -24,
          ),
        ],
      ),
      child: child,
    );
  }
}