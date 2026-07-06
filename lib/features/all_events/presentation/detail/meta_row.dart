import 'package:flutter/material.dart';

/// Compact key/value row for the storage metadata footer. Label sits in
/// a fixed 84px gutter; value is selectable monospace.
class MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle monoStyle;
  final Color labelColor;

  const MetaRow({
    super.key,
    required this.label,
    required this.value,
    required this.monoStyle,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: labelColor,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SelectableText(
              value,
              style: monoStyle,
            ),
          ),
        ],
      ),
    );
  }
}