import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../header/section_title.dart';

/// Server & Connection card. Two visually-distinct port sub-blocks
/// (Device / MCP) sit side-by-side inside a liquid-glass surface, each
/// with a role chip + label, a mono input, and a status pill. The
/// "Apply Changes" affordance only surfaces when at least one port has
/// been edited — and reads as the primary action, not a footnote.
///
/// ponytail: this is a presentational card — it owns no state, the
/// parent passes controllers + server snapshots and reacts to callbacks.
class ServerSection extends ConsumerWidget {
  final TextEditingController portController;
  final TextEditingController mcpPortController;
  final dynamic server;
  final dynamic mcpServer;
  final VoidCallback onStartStop;
  final VoidCallback onMcpStartStop;
  final VoidCallback? onApply;
  final bool showApply;

  const ServerSection({
    super.key,
    required this.portController,
    required this.mcpPortController,
    required this.server,
    required this.mcpServer,
    required this.onStartStop,
    required this.onMcpStartStop,
    this.onApply,
    this.showApply = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startError = ref.watch(serverStartErrorProvider);
    final mcpStartError = ref.watch(mcpStartErrorProvider);
    final hasError = startError != null || mcpStartError != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final deviceSubtle =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final mcpSubtle =
        isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(icon: LucideIcons.server, title: S.of(context).server),

        // Two port sub-blocks sit side by side. On narrow widths they
        // collapse to a single column via Wrap.
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 308,
              child: _PortBlock(
                accent: deviceSubtle,
                icon: LucideIcons.smartphone,
                label: S.of(context).mcpDevicePort,
                status: server.isRunning
                    ? _PortStatus.online
                    : _PortStatus.offline,
                controller: portController,
                startStopLabel:
                    server.isRunning ? S.of(context).stop : S.of(context).start,
                startStopIcon: server.isRunning
                    ? LucideIcons.square
                    : LucideIcons.play,
                startStopColor: server.isRunning
                    ? ColorTokens.error
                    : ColorTokens.success,
                dimmed: server.isRunning && !showApply,
                onStartStop: onStartStop,
              ),
            ),
            SizedBox(
              width: 308,
              child: _PortBlock(
                accent: mcpSubtle,
                icon: LucideIcons.zap,
                label: S.of(context).mcpServerPort,
                status: mcpServer.isRunning
                    ? _PortStatus.online
                    : _PortStatus.offline,
                controller: mcpPortController,
                startStopLabel: mcpServer.isRunning
                    ? S.of(context).stop
                    : S.of(context).start,
                startStopIcon: mcpServer.isRunning
                    ? LucideIcons.square
                    : LucideIcons.play,
                startStopColor: mcpServer.isRunning
                    ? ColorTokens.error
                    : ColorTokens.success,
                dimmed: mcpServer.isRunning && !showApply,
                onStartStop: onMcpStartStop,
              ),
            ),
          ],
        ),

        if (showApply) ...[
          const SizedBox(height: 14),
          _ApplyChangesBar(
            onApply: onApply ?? () {},
            onDiscard: () {
              portController.text =
                  (server.isRunning ? server.port : AppConstants.defaultPort)
                      .toString();
              mcpPortController.text = (mcpServer.isRunning
                      ? mcpServer.port
                      : 5564)
                  .toString();
            },
          ),
        ],

        if (hasError) ...[
          const SizedBox(height: 12),
          _ErrorBanner(
            message: startError ?? mcpStartError ?? '',
            onDismiss: () {
              ref.read(serverStartErrorProvider.notifier).state = null;
              ref.read(mcpStartErrorProvider.notifier).state = null;
            },
          ),
        ],
      ],
    );
  }
}

enum _PortStatus { online, offline }

/// Single port sub-block. Role chip + label + status pill at the top,
/// mono input fills the middle, start/stop button at the right.
class _PortBlock extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String label;
  final _PortStatus status;
  final TextEditingController controller;
  final String startStopLabel;
  final IconData startStopIcon;
  final Color startStopColor;
  final bool dimmed;
  final VoidCallback onStartStop;

  const _PortBlock({
    required this.accent,
    required this.icon,
    required this.label,
    required this.status,
    required this.controller,
    required this.startStopLabel,
    required this.startStopIcon,
    required this.startStopColor,
    required this.dimmed,
    required this.onStartStop,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.025);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final onlineDot = const Color(0xFF22C55E);
    final onlineText = const Color(0xFF22C55E);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Role chip + label + status pill row.
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 10, color: accent),
                    const SizedBox(width: 4),
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _StatusPill(
                online: status == _PortStatus.online,
                color: onlineDot,
                textColor: onlineText,
                label: status == _PortStatus.online ? 'Online' : 'Offline',
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Input row.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0D1117).withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontFamily: AppConstants.monoFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: accent.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          enabled: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(
                            fontFamily: AppConstants.monoFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: dimmed
                                ? (isDark
                                    ? Colors.white38
                                    : Colors.black38)
                                : null,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            hintText: 'port',
                            hintStyle: TextStyle(
                              fontFamily: AppConstants.monoFontFamily,
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white24
                                  : Colors.black26,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _TactileStartStop(
                label: startStopLabel,
                icon: startStopIcon,
                color: startStopColor,
                onTap: onStartStop,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tiny "Online / Offline" pill — green dot + label. Communicates the
/// running state of the underlying server at a glance.
class _StatusPill extends StatelessWidget {
  final bool online;
  final Color color;
  final Color textColor;
  final String label;

  const _StatusPill({
    required this.online,
    required this.color,
    required this.textColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: online ? textColor : (color.withValues(alpha: 0.6)),
          ),
        ),
      ],
    );
  }
}

/// Start / stop button with the project's tactile press feel. Wraps the
/// standard [_TactileButton] used elsewhere — see mcp_cli_cards.dart.
class _TactileStartStop extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TactileStartStop({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_TactileStartStop> createState() => _TactileStartStopState();
}

class _TactileStartStopState extends State<_TactileStartStop> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.color;
    final bg = accent.withValues(alpha: isDark ? 0.16 : 0.14);
    final fg = accent;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: fg.withValues(alpha: 0.30), width: 0.7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 12, color: fg),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Apply Changes" bar that surfaces only when a port has been edited.
/// Reads as the primary CTA — amber filled, with a subtle Discard
/// fallback so the user can revert their edit without retyping.
class _ApplyChangesBar extends StatelessWidget {
  final VoidCallback onApply;
  final VoidCallback onDiscard;
  const _ApplyChangesBar({required this.onApply, required this.onDiscard});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amber = const Color(0xFFFBBF24);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: amber.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, size: 14, color: amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Port values changed — restart the servers to apply.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.black87,
              ),
            ),
          ),
          _GhostButton(
            label: 'Discard',
            onTap: onDiscard,
          ),
          const SizedBox(width: 6),
          _PrimaryApplyButton(label: 'Apply Changes', onTap: onApply),
        ],
      ),
    );
  }
}

class _PrimaryApplyButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryApplyButton({required this.label, required this.onTap});

  @override
  State<_PrimaryApplyButton> createState() => _PrimaryApplyButtonState();
}

class _PrimaryApplyButtonState extends State<_PrimaryApplyButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final amber = const Color(0xFFFBBF24);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: amber,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: amber.withValues(alpha: 0.35),
                blurRadius: 12,
                spreadRadius: -3,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.check, size: 13, color: Colors.black),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostButton({required this.label, required this.onTap});

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white70 : Colors.black54;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tighter error banner than the original. Inline icon + dismiss, no
/// large block of red — reads as a notice rather than a shout.
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: ColorTokens.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorTokens.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(LucideIcons.triangleAlert,
              size: 13, color: ColorTokens.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11.5,
                color: ColorTokens.error,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDismiss,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Icon(
                LucideIcons.x,
                size: 12,
                color: ColorTokens.error.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
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