import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import 'timeline_event.dart';

class EventRow extends StatelessWidget {
  final TimelineEvent event;

  const EventRow({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat(
      'HH:mm:ss.SSS',
    ).format(DateTime.fromMillisecondsSinceEpoch(event.timestamp));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.05),
          ),
          left: BorderSide(color: event.color, width: 2),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              time,
              style: TextStyle(
                fontFamily: AppConstants.monoFontFamily,
                fontSize: 9,
                color: Colors.grey[500],
              ),
            ),
          ),
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(event.icon, size: 9, color: event.color),
                const SizedBox(width: 3),
                Text(
                  event.type,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: event.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.title,
              style: TextStyle(
                fontFamily: AppConstants.monoFontFamily,
                fontSize: 11,
                color: isDark ? ColorTokens.lightBackground : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            event.subtitle,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[500],
              fontFamily: AppConstants.monoFontFamily,
            ),
          ),
        ],
      ),
    );
  }
}
