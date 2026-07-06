import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../components/misc/status_badge.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/log_message_summary.dart';
import '../../../../models/log/log_entry.dart';
import '../shared/level_color.dart';
import '../shared/tag_badge.dart';

/// One log row inside the streaming list — 3px colored left edge
/// (level accent) + mono timestamp + optional platform badge +
/// `LogLevelBadge` + optional tag + a single-line summarized message.
///
/// The outer 8px-rounded container decoration is supplied by the
/// page via [StableListView]'s `decorationBuilder`; this widget just
/// renders the inner content with the same rounded corners via the
/// top-left radius on the colored edge bar.
class LogEntryContent extends StatelessWidget {
  final LogEntry entry;
  final String? platform;

  const LogEntryContent({
    super.key,
    required this.entry,
    this.platform,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = levelColor(entry.level);
    final time = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (platform != null) ...[
                        PlatformBadge(platform: platform!),
                        const SizedBox(width: 6),
                      ],
                      LogLevelBadge(level: entry.level.name),
                      if (entry.tag != null) ...[
                        const SizedBox(width: 6),
                        TagBadge(tag: entry.tag!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summarizeLogMessage(entry.message),
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 12,
                      height: 1.4,
                      color: isDark
                          ? ColorTokens.lightBackground
                          : ColorTokens.darkNeutral,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}