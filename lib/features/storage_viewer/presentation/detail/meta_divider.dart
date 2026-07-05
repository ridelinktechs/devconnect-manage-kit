import 'package:flutter/material.dart';

import '../../../../components/text/text_component.dart';

/// "Metadata" header + trailing hairline divider. Used to separate
/// the value block from the footer metadata list.
class MetaDivider extends StatelessWidget {
  const MetaDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        TextComponent(
          'Metadata',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}