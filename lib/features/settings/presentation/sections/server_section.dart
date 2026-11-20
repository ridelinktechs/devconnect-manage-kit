import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../header/section_title.dart';
import '../shared/action_button.dart';
import '../shared/status_chip.dart';

/// Server & Connection card — status, the address apps connect to, port
/// input, Start / Stop / Restart buttons and the start error banner. Owns
/// no state of its own; the parent passes the controller + server snapshot
/// and reacts to [onStartStop] and [onRestart].
class ServerSection extends ConsumerWidget {
  final TextEditingController portController;
  final dynamic server;
  final String address;
  final bool restarting;
  final VoidCallback onStartStop;
  final VoidCallback onRestart;
  final void Function(String, [String?]) onCopy;

  const ServerSection({
    super.key,
    required this.portController,
    required this.server,
    required this.address,
    required this.restarting,
    required this.onStartStop,
    required this.onRestart,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startError = ref.watch(serverStartErrorProvider);
    final s = S.of(context);
    final p = ChromePalette.of(context);
    final running = server.isRunning == true;
    final accent = p.isDark ? ColorTokens.primaryLight : ColorTokens.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SectionTitle(icon: LucideIcons.server, title: s.server),
            ),
            StatusChip(
              color: running ? ColorTokens.success : ColorTokens.error,
              label: running ? s.serverRunning : s.serverStopped,
              pulse: running,
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: p.codeBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: running
                  ? ColorTokens.success.withValues(alpha: 0.35)
                  : p.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                running ? LucideIcons.radioTower : LucideIcons.radio,
                size: 16,
                color: running ? ColorTokens.success : p.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: running && address.isNotEmpty
                    ? Text(
                        address,
                        style: chromeMono(
                          context,
                          size: 13.5,
                          color: p.text,
                          weight: FontWeight.w600,
                        ),
                      )
                    : Text(
                        s.serverStoppedHint,
                        style: TextStyle(fontSize: 12.5, color: p.textMuted),
                      ),
              ),
              if (running && address.isNotEmpty)
                Tooltip(
                  message: s.copy,
                  child: IconButton(
                    onPressed: () => onCopy(address),
                    icon: Icon(LucideIcons.copy, size: 15, color: p.textMuted),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
        if (running) ...[
          const SizedBox(height: 6),
          Text(
            s.serverAddressHint,
            style: TextStyle(fontSize: 12, color: p.textMuted),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Text(s.port, style: TextStyle(fontSize: 13, color: p.textMuted)),
            const SizedBox(width: 10),
            SizedBox(
              width: 96,
              height: 36,
              child: TextField(
                controller: portController,
                enabled: !running,
                textAlign: TextAlign.center,
                style: chromeMono(
                  context,
                  size: 13.5,
                  color: running ? p.textMuted : p.text,
                  weight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: p.codeBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: p.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: p.border),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: p.border.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const Spacer(),
            if (running) ...[
              ActionButton(
                label: restarting ? s.restarting : s.restart,
                icon: LucideIcons.rotateCw,
                color: accent,
                busy: restarting,
                onTap: onRestart,
              ),
              const SizedBox(width: 8),
              ActionButton(
                label: s.stop,
                icon: LucideIcons.square,
                color: ColorTokens.error,
                onTap: restarting ? null : onStartStop,
              ),
            ] else
              ActionButton(
                label: s.start,
                icon: LucideIcons.play,
                color: ColorTokens.success,
                filled: true,
                onTap: restarting ? null : onStartStop,
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
                      .set(null),
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