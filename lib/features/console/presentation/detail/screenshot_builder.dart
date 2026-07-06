import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/misc/status_badge.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/screenshot_filename.dart';
import '../../../../core/utils/screenshot_utils.dart';
import '../../../../models/log/log_entry.dart';
import '../shared/level_color.dart';

/// Builds the full-detail capture widget used by the detail panel's
/// "Capture as image" button. Renders the level + timestamp header,
/// tag chip, message block, metadata JsonViewer, and a level-tinted
/// stack trace block — all in one PNG-sized Column.
Widget buildLogDetailScreenshot({
  required BuildContext context,
  required LogEntry entry,
  required bool isDark,
}) {
  final color = levelColor(entry.level);
  final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
    DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
  );

  // Build a descriptive filename: log_<tag>_<ts>_full.png
  final fileName = buildRichScreenshotName(
    type: 'log',
    subject: entry.tag ?? entry.level.name,
    suffix: '_full',
  );

  captureWidgetAsImage(
    context,
    Container(
      color: isDark ? ColorTokens.darkSurface : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? ColorTokens.darkBackground : ColorTokens.lightSurface,
            child: Row(
              children: [
                Icon(LucideIcons.terminal, size: 16, color: ColorTokens.primary),
                const SizedBox(width: 8),
                LogLevelBadge(level: entry.level.name),
                const SizedBox(width: 10),
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tag
          if (entry.tag != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TAG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(entry.tag!, style: TextStyle(fontFamily: AppConstants.monoFontFamily, fontSize: 10, color: Colors.grey[500])),
                  ),
                ],
              ),
            ),
          // Message
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MESSAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? ColorTokens.darkBackground : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Text(
                    entry.message,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 12,
                      height: 1.6,
                      color: isDark ? ColorTokens.lightBackground : ColorTokens.darkNeutral,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Metadata
          if (entry.metadata != null && entry.metadata!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('METADATA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? ColorTokens.darkBackground : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: JsonViewer(data: entry.metadata, initiallyExpanded: true),
                  ),
                ],
              ),
            ),
          // Stack trace
          if (entry.stackTrace != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STACK TRACE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      entry.stackTrace!,
                      style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 11,
                        color: color.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
    width: 600,
    fileName: fileName,
  );
  // The side-effect already ran; return a placeholder so callers can
  // compose if needed.
  return const SizedBox.shrink();
}