import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mcp_clients.dart';
import '../../../../core/providers/mcp_pairing_provider.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../l10n/app_localizations.dart';

/// Status of a Run action — drives header icon + colour.
enum _Status { success, failed, timeout, notFound }

_Status _statusFromResult(McpResult r) => switch (r) {
      McpResult.success => _Status.success,
      McpResult.failed => _Status.failed,
      McpResult.timeout => _Status.timeout,
      McpResult.notFound => _Status.notFound,
    };

Future<void> showMcpInstallResultDialog(
  BuildContext context, {
  required TokenCommandTemplate client,
  required String command,
  required String stdout,
  required String stderr,
  required int exitCode,
  required McpResult status,
  required String downloadUrl,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.50),
    builder: (_) => _McpInstallResultDialog(
      client: client,
      command: command,
      stdout: stdout,
      stderr: stderr,
      exitCode: exitCode,
      status: _statusFromResult(status),
      downloadUrl: downloadUrl,
    ),
  );
}

class _McpInstallResultDialog extends StatefulWidget {
  final TokenCommandTemplate client;
  final String command;
  final String stdout;
  final String stderr;
  final int exitCode;
  final _Status status;
  final String downloadUrl;

  const _McpInstallResultDialog({
    required this.client,
    required this.command,
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.status,
    required this.downloadUrl,
  });

  @override
  State<_McpInstallResultDialog> createState() => _McpInstallResultDialogState();
}

class _McpInstallResultDialogState extends State<_McpInstallResultDialog> {
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    if (widget.status == _Status.success) {
      _autoClose = Timer(const Duration(seconds: 10), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    super.dispose();
  }

  IconData get _icon => switch (widget.status) {
        _Status.success => LucideIcons.checkCircle,
        _Status.failed => LucideIcons.xCircle,
        _Status.timeout => LucideIcons.clockAlert,
        _Status.notFound => LucideIcons.circleAlert,
      };

  Color get _iconColor => switch (widget.status) {
        _Status.success => ColorTokens.success,
        _Status.failed => ColorTokens.error,
        _Status.timeout => ColorTokens.warning,
        _Status.notFound => ColorTokens.warning,
      };

  String _titleFor(BuildContext context) {
    final loc = S.of(context);
    return switch (widget.status) {
      _Status.success => loc.mcpInstallSuccess,
      _Status.failed => loc.mcpInstallFailed,
      _Status.timeout => loc.mcpInstallTimeout,
      _Status.notFound => loc.mcpInstallBinaryMissing(
            widget.client.displayName,
            widget.downloadUrl,
          ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? ColorTokens.darkBackground : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          Icon(_icon, size: 18, color: _iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _titleFor(context),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 480),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _label(loc.mcpInstallResult, isDark),
              const SizedBox(height: 4),
              _mono(widget.command, isDark),
              const SizedBox(height: 12),
              _label('stdout', isDark),
              const SizedBox(height: 4),
              _mono(widget.stdout.isEmpty ? '(empty)' : widget.stdout, isDark,
                  maxLines: 8),
              const SizedBox(height: 12),
              _label('stderr', isDark),
              const SizedBox(height: 4),
              _mono(
                widget.stderr.isEmpty ? '(empty)' : widget.stderr,
                isDark,
                maxLines: 8,
                redBg: widget.stderr.isNotEmpty,
              ),
              const SizedBox(height: 8),
              Text(
                'exit=${widget.exitCode}',
                style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
                  fontSize: 10,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.status == _Status.notFound)
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.downloadUrl));
              showCopiedToast(context, label: loc.copied);
            },
            icon: const Icon(LucideIcons.copy, size: 12),
            label: Text(loc.copy, style: const TextStyle(fontSize: 12)),
          ),
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.command));
            showCopiedToast(context, label: loc.mcpCommandCopied);
          },
          icon: const Icon(LucideIcons.clipboardCopy, size: 12),
          label: Text(loc.copy, style: const TextStyle(fontSize: 12)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.close, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _label(String text, bool isDark) => Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      );

  Widget _mono(String text, bool isDark, {int maxLines = 4, bool redBg = false}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: redBg
              ? ColorTokens.error.withValues(alpha: isDark ? 0.10 : 0.06)
              : (isDark
                  ? const Color(0xFF0D1117).withValues(alpha: 0.85)
                  : const Color(0xFFF0F0F0)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: redBg
                ? ColorTokens.error.withValues(alpha: 0.30)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04)),
          ),
        ),
        child: SelectableText(
          text,
          maxLines: maxLines,
          style: const TextStyle(
            fontFamily: AppConstants.monoFontFamily,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      );
}