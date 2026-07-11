import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../components/misc/status_badge.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../models/log/log_entry.dart';
import '../shared/body_view.dart' show InlineJsonView;
import '../shared/code_block.dart';
import '../shared/copy_button.dart';
import '../shared/error_block.dart';
import '../shared/section_label.dart';
import '../shared/tag_chip.dart';

/// Right-pane detail for log events.
///
/// Renders the level badge + optional tag chip + copy button in the header
/// row, then a [CodeBlock] (for plain text) or an [InlineJsonView] with
/// the Tree/JSON/Code toggle (for embedded JSON), and finally the
/// optional metadata block and stack trace.
class LogDetail extends StatefulWidget {
  final LogEntry entry;

  const LogDetail({super.key, required this.entry});

  @override
  State<LogDetail> createState() => _LogDetailState();
}

class _LogDetailState extends State<LogDetail> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Try to extract JSON from the log message.
  /// Returns (prefix, parsedJson) or null if no JSON found.
  static (String, dynamic)? _extractJson(String message) {
    // Try full message first
    try {
      final parsed = jsonDecode(message.trim());
      if (parsed is Map || parsed is List) return ('', parsed);
    } catch (_) {}

    // Find all { or [ positions and try each
    for (var i = 0; i < message.length; i++) {
      final ch = message[i];
      if (ch != '{' && ch != '[') continue;
      final jsonStr = message.substring(i).trim();
      try {
        final parsed = jsonDecode(jsonStr);
        if (parsed is Map || parsed is List) {
          final prefix = message.substring(0, i).trim();
          return (prefix, parsed);
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jsonResult = _extractJson(entry.message);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LogLevelBadge(level: entry.level.name),
              if (entry.tag != null) ...[
                const SizedBox(width: 8),
                TagChip(entry.tag!),
              ],
              const Spacer(),
              CopyButton(
                tooltip: 'Copy message',
                onTap: () => _copyText(context, entry.message, 'Message'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionLabel('Message'),
          const SizedBox(height: 6),
          if (jsonResult != null) ...[
            if (jsonResult.$1.isNotEmpty) ...[
              CodeBlock(text: jsonResult.$1, isDark: isDark),
              const SizedBox(height: 10),
            ],
            InlineJsonView(data: jsonResult.$2, label: 'Data'),
          ] else
            CodeBlock(text: entry.message, isDark: isDark),
          if (entry.metadata != null && entry.metadata!.isNotEmpty) ...[
            const SizedBox(height: 16),
            InlineJsonView(data: entry.metadata, label: 'Metadata'),
          ],
          if (entry.stackTrace != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const SectionLabel('Stack Trace'),
                const Spacer(),
                CopyButton(
                  tooltip: 'Copy stack trace',
                  onTap: () =>
                      _copyText(context, entry.stackTrace!, 'Stack trace'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ErrorBlock(text: entry.stackTrace!, isDark: isDark),
          ],
        ],
      ),
    );
  }
}

void _copyText(BuildContext context, String text, String label) {
  Clipboard.setData(ClipboardData(text: text));
  showCopiedToast(context, label: '$label copied');
}