import 'package:flutter/material.dart';

import '../../../../components/text/text_component.dart';
import '../../../../core/constants/app_constants.dart';

/// Plain-text rendering of a log message body — used by
/// [LogMessageBlock] when the message is not JSON-parseable. Skips
/// the 3-mode view toggle entirely.
class PlainMessageBlock extends StatelessWidget {
  final String text;
  final bool isDark;

  const PlainMessageBlock({
    super.key,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TextComponent(
      text,
      style: TextStyle(
        fontFamily: AppConstants.monoFontFamily,
        fontSize: 12,
        height: 1.5,
        color: isDark
            ? const Color(0xFFCCCCCC)
            : const Color(0xFF333333),
      ),
    );
  }
}