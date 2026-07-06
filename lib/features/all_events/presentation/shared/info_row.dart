import 'package:flutter/material.dart';

import '../../../../components/text/text_component.dart';
import '../../../../core/constants/app_constants.dart';

/// Two-column "label : value" row with the label in a fixed 100px gutter.
/// Used for displaying key/value metadata when the value fits on a single
/// line (status code, content type, timestamp, …).
class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: TextComponent(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextComponent(
            value,
            style: const TextStyle(
              fontFamily: AppConstants.monoFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
