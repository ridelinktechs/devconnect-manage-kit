import 'package:flutter/material.dart';

import '../../../../components/text/text_component.dart';
import '../../../../core/constants/app_constants.dart';

/// Small mono-font tag chip (e.g. log tag, error source). Tinted by the
/// caller-supplied [color]; uses a 10% alpha fill so it never fights the
/// surface chrome.
class TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const TagChip(this.label, {super.key, this.color = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextComponent(
        label,
        style: TextStyle(
          fontFamily: AppConstants.monoFontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
