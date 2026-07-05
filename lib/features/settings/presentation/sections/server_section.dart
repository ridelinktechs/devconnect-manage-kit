import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../header/section_title.dart';
import '../shared/action_button.dart';

/// Server & Connection card — port input + start/stop button + error
/// banner. Owns no state of its own; the parent passes the controller
/// + server snapshot and reacts to [onStartStop].
class ServerSection extends ConsumerWidget {
  final TextEditingController portController;
  final dynamic server;
  final VoidCallback onStartStop;

  const ServerSection({
    super.key,
    required this.portController,
    required this.server,
    required this.onStartStop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startError = ref.watch(serverStartErrorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(icon: LucideIcons.server, title: S.of(context).server),
        Row(
          children: [
            Text(S.of(context).port, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              height: 34,
              child: TextField(
                controller: portController,
                enabled: !server.isRunning,
                style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
                  fontSize: 13,
                  color: server.isRunning ? Colors.grey : null,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            ActionButton(
              label: server.isRunning ? S.of(context).stop : S.of(context).start,
              icon: server.isRunning ? LucideIcons.square : LucideIcons.play,
              color: server.isRunning ? ColorTokens.error : ColorTokens.success,
              onTap: onStartStop,
            ),
          ],
        ),
        if (startError != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorTokens.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ColorTokens.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.triangleAlert,
                  size: 14,
                  color: ColorTokens.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    startError,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ColorTokens.error,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => ref
                      .read(serverStartErrorProvider.notifier)
                      .state = null,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Icon(
                      LucideIcons.x,
                      size: 14,
                      color: ColorTokens.error.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Map a raw server start exception to a human-readable message. Kept
/// file-private because the lookup only matters inside the Settings
/// page's start/stop handler.
String describeStartError(Object error, int port) {
  final msg = error.toString();
  if (msg.contains('Address already in use') ||
      msg.contains('errno = 48') ||
      msg.contains('errno = 98')) {
    return 'Port $port is already in use. '
        'Close the other app using this port, or enter a different port above and press Start.';
  }
  return 'Failed to start server on port $port: $msg';
}