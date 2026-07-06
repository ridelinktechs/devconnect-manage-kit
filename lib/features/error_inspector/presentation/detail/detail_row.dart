import 'package:flutter/material.dart';

import '../../../../components/text/text_component.dart';
import '../../../../core/constants/app_constants.dart';

/// Two-column "label / value" row used in the Error Inspector's
/// Details tab. Label sits in a fixed 80-px gutter (muted grey, w600,
/// 11pt) so all rows align down the column; value is selectable mono
/// at 11pt so users can copy individual fields without selecting the
/// whole payload.
class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: TextComponent(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: TextComponent(
              value,
              style: TextStyle(
                fontFamily: AppConstants.monoFontFamily,
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}