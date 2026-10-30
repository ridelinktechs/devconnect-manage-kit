import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../components/misc/status_badge.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/log/log_entry.dart';

class LogList extends StatelessWidget {
  final List<LogEntry> entries;
  final ScrollController? controller;

  const LogList({super.key, required this.entries, this.controller});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return EmptyState(
        icon: LucideIcons.terminal,
        title: S.of(context).noLogsYet,
      );
    }
    return ListView.builder(
      controller: controller,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[entries.length - 1 - index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final time = DateFormat(
          'HH:mm:ss.SSS',
        ).format(DateTime.fromMillisecondsSinceEpoch(e.timestamp));

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.05),
              ),
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
              LogLevelBadge(level: e.level.name),
              const SizedBox(width: 8),
              if (e.tag != null) ...[
                Text(
                  e.tag!,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[500],
                    fontFamily: AppConstants.monoFontFamily,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  e.message,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    color: e.level == LogLevel.error
                        ? ColorTokens.error
                        : isDark
                        ? Colors.white
                        : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
