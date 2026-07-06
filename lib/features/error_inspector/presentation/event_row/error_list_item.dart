import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../models/log/error_event.dart';
import '../shared/error_tokens.dart' show severityColor;
import '../shared/platform_badge.dart';
import '../shared/severity_badge.dart';

/// One row in the Error Inspector's streaming error list.
///
/// Visual structure (left → right):
///   1. **Severity column** — [SeverityBadge] (top) + [PlatformBadge]
///      (bottom), each tinted with the platform's accent color
///   2. **Message column** — mono-font message (max 2 lines, ellipsis)
///      + the first line of the stack trace (if any) in muted grey
///   3. **Time + copy** — timestamp + copy-icon button at the end
///
/// Left border carries the severity's accent color (3px) — the same
/// visual cue as `EventRow` in `all_events` so users familiar with
/// that page recognize the pattern immediately.
class ErrorListItem extends StatelessWidget {
  final ErrorEvent entry;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const ErrorListItem({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final severityClr = severityColor(entry.severity);
    final time = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorTokens.selectedBg(isDark)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white10 : Colors.black12,
            ),
            // Left border mirrors the storage_viewer / all_events pattern:
            // tinted with the row's severity color, but flips to the
            // shared teal selection accent (3px vs the default 2px)
            // when the user picks the row.
            left: BorderSide(
              color: isSelected ? ColorTokens.selectedAccent : severityClr,
              width: isSelected ? 3 : 2,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity & Platform
            Column(
              children: [
                SeverityBadge(severity: entry.severity),
                const SizedBox(height: 4),
                PlatformBadge(platform: entry.platform),
              ],
            ),
            const SizedBox(width: 12),
            // Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.message,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: AppConstants.monoFontFamily,
                      color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.stackTrace != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.stackTrace!.split('\n').first,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: AppConstants.monoFontFamily,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Time & Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: AppConstants.monoFontFamily,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.copy, size: 14),
                      onPressed: onCopy,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Copy',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}