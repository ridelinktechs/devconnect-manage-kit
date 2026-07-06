import 'package:flutter/material.dart';

import '../../../../components/text/text_component.dart';

/// Small uppercase section label rendered via [TextComponent] so it
/// participates in the global text style. Used in the right-hand detail
/// panel of the All Events page to introduce each chunk of metadata.
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return TextComponent(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey[500],
        letterSpacing: 0.5,
      ),
    );
  }
}
