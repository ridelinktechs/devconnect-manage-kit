import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../header/section_title.dart';
import '../shared/action_button.dart';
import '../shared/code_block.dart';
import '../usb/adb_resolver.dart';

/// USB Tools card — adb reverse for Android (uses [resolveAdbPath] to
/// locate the binary, falls back to a SnackBar if missing), iProxy
/// hint for iOS, plus copy-able code blocks for the terminal commands.
class UsbToolsSection extends StatelessWidget {
  final int port;
  final void Function(String, [String?]) onCopy;

  const UsbToolsSection({super.key, required this.port, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeBg = isDark ? ColorTokens.darkSurface : const Color(0xFFF0F0F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(icon: LucideIcons.usb, title: S.of(context).usbConnection),

        // Android
        Text(S.of(context).android,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3DDC84),
            )),
        const SizedBox(height: 6),
        CodeBlock(
          code: 'adb reverse tcp:$port tcp:$port',
          bg: codeBg,
          onCopy: onCopy,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ActionButton(
              label: S.of(context).runAdbReverse,
              icon: LucideIcons.refreshCw,
              color: ColorTokens.secondary,
              onTap: () async {
                try {
                  final adbPath = await resolveAdbPath();
                  if (adbPath == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'adb not found.\nHOME=${Platform.environment['HOME'] ?? 'null'}\nChecked: ~/Library/Android/sdk/platform-tools/adb',
                          ),
                          backgroundColor: ColorTokens.error,
                          behavior: SnackBarBehavior.floating,
                          width: 500,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                    return;
                  }
                  final result = await Process.run(
                    adbPath,
                    ['reverse', 'tcp:$port', 'tcp:$port'],
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.exitCode == 0
                              ? 'adb reverse OK ($adbPath)'
                              : 'adb error: ${result.stderr}',
                        ),
                        backgroundColor: result.exitCode == 0
                            ? ColorTokens.success
                            : ColorTokens.error,
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        width: 400,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('adb exception: $e'),
                        backgroundColor: ColorTokens.error,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(width: 6),
            ActionButton(
              label: S.of(context).devices,
              icon: LucideIcons.smartphone,
              color: Colors.grey,
              onTap: () async {
                try {
                  final adbPath = await resolveAdbPath();
                  if (adbPath == null) return;
                  final result = await Process.run(adbPath, ['devices']);
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(S.of(context).adbDevices),
                        content: Text(
                          result.stdout.toString().trim(),
                          style: const TextStyle(
                            fontFamily: AppConstants.monoFontFamily,
                            fontSize: 12,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(S.of(context).ok),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (_) {}
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // iOS
        Text(S.of(context).ios,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            )),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorTokens.success.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
            border:
                Border.all(color: ColorTokens.success.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.wifi, size: 13, color: ColorTokens.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  S.of(context).wifiAutoConnect,
                  style: TextStyle(fontSize: 11, color: ColorTokens.success),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        CodeBlock(
          code: 'brew install libimobiledevice',
          bg: codeBg,
          onCopy: onCopy,
        ),
        const SizedBox(height: 4),
        CodeBlock(
          code: 'iproxy $port $port',
          bg: codeBg,
          onCopy: onCopy,
        ),
      ],
    );
  }
}