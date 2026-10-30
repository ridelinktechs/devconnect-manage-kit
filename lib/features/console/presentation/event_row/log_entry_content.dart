import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/misc/status_badge.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/format/log_message_summary.dart';
import '../../../../l10n/generated/app_localizations.dart';
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

  /// The identical logs in a row this one stands for, oldest first; empty
  /// when it stands for itself only.
  final List<LogEntry> run;

  const LogEntryContent({
    super.key,
    required this.entry,
    this.platform,
    this.run = const [],
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
                      if (run.length > 1) ...[
                        const Spacer(),
                        _RepeatPill(run: run, color: color),
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

/// How many times a folded log ran, on its level color; the tooltip says
/// from when to when.
class _RepeatPill extends StatelessWidget {
  final List<LogEntry> run;
  final Color color;

  const _RepeatPill({required this.run, required this.color});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm:ss.SSS');
    String at(LogEntry e) =>
        time.format(DateTime.fromMillisecondsSinceEpoch(e.timestamp));
    // White or near-black, whichever reads better on the level color.
    final l = color.computeLuminance();
    final onColor = 1.05 / (l + 0.05) >= (l + 0.05) / 0.067
        ? Colors.white
        : const Color(0xFF1F2328);
    return Tooltip(
      message:
          '${S.of(context).consoleOccurrences}: ${run.length} · '
          '${at(run.first)} → ${at(run.last)}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 2, 8, 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.repeat2, size: 12, color: onColor),
            const SizedBox(width: 4),
            Text(
              '${run.length}',
              style: chromeMono(
                context,
                size: 11.5,
                color: onColor,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}