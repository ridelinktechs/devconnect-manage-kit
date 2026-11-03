import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../../core/utils/ui/toast_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/log/log_entry.dart';
import '../shared/level_color.dart';
import '../shared/section_label.dart';
import 'detail_header.dart';
import 'log_message_block.dart';
import 'metadata_block.dart';
import 'occurrences_block.dart';
import 'screenshot_builder.dart';
import 'stack_trace_block.dart';

/// Right-pane detail panel for a selected log entry. Owns:
///   • the [LogDetailHeader] with copy/screenshot/close
///   • the message, metadata, and stack-trace sections
class LogDetailPanel extends StatefulWidget {
  final LogEntry entry;

  /// Every log [entry]'s row stands for when repeats are folded, oldest
  /// first; empty otherwise.
  final List<LogEntry> occurrences;

  /// "App · device" the log came from, when that device is known.
  final String? source;
  final VoidCallback onClose;

  const LogDetailPanel({
    super.key,
    required this.entry,
    this.occurrences = const [],
    this.source,
    required this.onClose,
  });

  @override
  State<LogDetailPanel> createState() => _LogDetailPanelState();
}

class _LogDetailPanelState extends State<LogDetailPanel> {
  final _scrollController = SmoothScrollController();

  /// The occurrence picked in [OccurrencesBlock]; the row's own log if none.
  String? _occurrenceId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final occurrences = widget.occurrences;
    final entry =
        occurrences.where((e) => e.id == _occurrenceId).firstOrNull ??
            widget.entry;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = levelColor(entry.level);

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        children: [
          LogDetailHeader(
            entry: entry,
            source: widget.source,
            onCopy: () {
              Clipboard.setData(ClipboardData(text: entry.message));
              showCopiedToast(context, label: S.of(context).logCopied);
            },
            onCapture: () => buildLogDetailScreenshot(
              context: context,
              entry: entry,
              isDark: isDark,
            ),
            onClose: widget.onClose,
          ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // When each folded repeat ran; picking one shows its details.
                  if (occurrences.length > 1) ...[
                    OccurrencesBlock(
                      occurrences: occurrences,
                      selectedId: entry.id,
                      color: color,
                      onSelect: (e) => setState(() => _occurrenceId = e.id),
                    ),
                    const SizedBox(height: 20),
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
                    StackTraceBlock(
                      trace: entry.stackTrace!,
                      level: entry.level,
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