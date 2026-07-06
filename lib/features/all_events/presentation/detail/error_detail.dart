import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../models/log/error_event.dart';
import '../shared/copy_button.dart';
import '../shared/error_block.dart';
import 'platform_badge.dart';
import 'severity_badge.dart';

/// Right-pane detail for error events. Mirrors `ErrorDetailPanel` from
/// the error_inspector feature but in a single-scroll layout suitable
/// for the All Events side panel (no tabs). Local copy of the badge
/// widgets avoids a cross-feature import.
class ErrorDetail extends StatefulWidget {
  final ErrorEvent entry;

  const ErrorDetail({super.key, required this.entry});

  @override
  State<ErrorDetail> createState() => _ErrorDetailState();
}

class _ErrorDetailState extends State<ErrorDetail> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _copyText(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    showCopiedToast(context, label: '$label copied');
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: severity + platform badges
          Row(
            children: [
              SeverityBadge(severity: entry.severity),
              const SizedBox(width: 6),
              PlatformBadge(platform: entry.platform),
            ],
          ),
          // Message
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Message',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
              const Spacer(),
              CopyButton(
                tooltip: 'Copy message',
                onTap: () => _copyText(context, entry.message, 'Message'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.message,
            style: TextStyle(
              fontFamily: AppConstants.monoFontFamily,
              fontSize: 12,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          // Stack trace
          if (entry.stackTrace != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Stack Trace',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),
                CopyButton(
                  tooltip: 'Copy stack trace',
                  onTap: () => _copyText(
                    context,
                    entry.stackTrace!,
                    'Stack trace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ErrorBlock(text: entry.stackTrace!, isDark: isDark),
          ],
          // Details
          const SizedBox(height: 16),
          Text(
            'Details',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6),
          _DetailRow('Platform', entry.platform.name),
          _DetailRow('Severity', entry.severity.name),
          _DetailRow('Source', entry.source ?? 'unknown'),
          _DetailRow('Device ID', entry.deviceId),
          if (entry.deviceInfo != null)
            _DetailRow('Device Info', entry.deviceInfo!),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AppConstants.monoFontFamily,
                fontSize: 11,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}