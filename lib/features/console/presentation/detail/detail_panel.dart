import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/misc/status_badge.dart';
import '../../../../components/text/text_component.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/log/log_entry.dart';
import '../shared/level_color.dart';
import '../shared/section_label.dart';
import '../shared/tag_badge.dart';
import 'log_message_block.dart';
import 'metadata_block.dart';
import 'screenshot_builder.dart';

/// Right-pane detail panel for a selected log entry. Owns:
///   • the level + timestamp header with copy/screenshot/close
///   • the tag, message, metadata, and stack-trace sections
///   • the level-tinted stack trace styling
class LogDetailPanel extends StatefulWidget {
  final LogEntry entry;
  final VoidCallback onClose;

  const LogDetailPanel({
    super.key,
    required this.entry,
    required this.onClose,
  });

  @override
  State<LogDetailPanel> createState() => _LogDetailPanelState();
}

class _LogDetailPanelState extends State<LogDetailPanel> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = levelColor(entry.level);
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        children: [
          // Header bar
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? ColorTokens.darkBackground : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                LogLevelBadge(level: entry.level.name),
                const SizedBox(width: 10),
                Expanded(
                  child: TextComponent(
                    time,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                // Copy button
                Tooltip(
                  message: S.of(context).copyMessage,
                  child: GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: entry.message));
                      showCopiedToast(context, label: S.of(context).logCopied);
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          LucideIcons.copy,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Screenshot button
                Tooltip(
                  message: 'Capture detail as image',
                  child: GestureDetector(
                    onTap: () => buildLogDetailScreenshot(
                      context: context,
                      entry: entry,
                      isDark: isDark,
                    ),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          LucideIcons.camera,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Close button
                Tooltip(
                  message: S.of(context).closePanel,
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag
                  if (entry.tag != null) ...[
                    SectionLabel(label: S.of(context).tag),
                    const SizedBox(height: 6),
                    TagBadge(tag: entry.tag!),
                    const SizedBox(height: 16),
                  ],

                  // Message — with 3 view modes (Tree / JSON / Code), same
                  // pattern as the All Events detail panel.
                  SectionLabel(label: S.of(context).message),
                  const SizedBox(height: 6),
                  LogMessageBlock(
                    message: entry.message,
                    deviceId: entry.deviceId,
                  ),

                  // Metadata
                  if (entry.metadata != null &&
                      entry.metadata!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    SectionLabel(label: S.of(context).metadata),
                    const SizedBox(height: 6),
                    MetadataBlock(
                      data: entry.metadata!,
                      deviceId: entry.deviceId,
                    ),
                  ],

                  // Stack trace
                  if (entry.stackTrace != null) ...[
                    const SizedBox(height: 20),
                    SectionLabel(label: S.of(context).stackTrace),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: color.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: TextComponent(
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}