import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: palette.textMuted,
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}
