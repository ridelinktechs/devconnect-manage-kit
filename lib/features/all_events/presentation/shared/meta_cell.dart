import 'package:flutter/material.dart';

import 'label.dart';

/// One cell of a metadata grid: small uppercase label ([Label]) over a
/// selectable single-line value. Adopts the caller's [valueStyle] for the
/// value; the label is the same color as [Label].
class MetaCell extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle valueStyle;
  final bool isDark;
  final bool monospace;

  const MetaCell({
    super.key,
    required this.label,
    required this.value,
    required this.valueStyle,
    required this.isDark,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Label(text: label, isDark: isDark),
        const SizedBox(height: 6),
        SelectableText(
          value,
          style: valueStyle,
          maxLines: 1,
        ),
      ],
    );
  }
}
