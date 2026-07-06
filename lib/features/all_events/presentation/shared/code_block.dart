import 'package:flutter/material.dart';

import '../../../../components/text/text_component.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';

/// Monospaced block of text in a tinted box — used to render raw JSON keys,
/// stack traces, pretty-printed payloads. Width stretches to fill the
/// parent so it sits naturally inside the detail panel column.
class CodeBlock extends StatelessWidget {
  final String text;
  final bool isDark;

  const CodeBlock({super.key, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: TextComponent(
        text,
        style: TextStyle(
          fontFamily: AppConstants.monoFontFamily,
          fontSize: 12,
          color: isDark ? ColorTokens.lightBackground : Colors.black87,
          height: 1.6,
        ),
      ),
    );
  }
}
