import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';

/// Compact status indicator for the All Events header.
///
/// Single rounded pill that conveys server state + port + device count.
/// Dot gently pulses when the server is running (perpetual micro-motion),
/// turns warning amber if the port is occupied, error red if stopped.
class ServerStatusPill extends StatefulWidget {
  final bool serverRunning;
  final bool portOccupied;
  final int port;
  final int deviceCount;
  final String? startError;

  const ServerStatusPill({
    super.key,
    required this.serverRunning,
    required this.portOccupied,
    required this.port,
    required this.deviceCount,
    required this.startError,
  });

  @override
  State<ServerStatusPill> createState() => _ServerStatusPillState();
}

class _ServerStatusPillState extends State<ServerStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.serverRunning) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ServerStatusPill old) {
    super.didUpdateWidget(old);
    if (widget.serverRunning && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.serverRunning && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color _accent() {
    if (widget.portOccupied) return ColorTokens.warning;
    if (!widget.serverRunning) return ColorTokens.error;
    return ColorTokens.success;
  }

  String _label() {
    if (widget.portOccupied) return S.of(context).portOccupied(widget.port);
    if (!widget.serverRunning) return S.of(context).stopped;
    return 'Port ${widget.port}';
  }

  IconData _icon() {
    if (widget.portOccupied) return LucideIcons.triangleAlert;
    if (!widget.serverRunning) return LucideIcons.circlePause;
    return LucideIcons.radio;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent();
    final label = _label();
    final icon = _icon();

    return Tooltip(
      message: widget.portOccupied && widget.startError != null
          ? widget.startError!
          : label,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark
              ? accent.withValues(alpha: 0.08)
              : accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accent.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing dot
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                final scale = widget.serverRunning
                    ? 1.0 + 0.4 * _pulseCtrl.value
                    : 1.0;
                final alpha = widget.serverRunning
                    ? 1.0 - 0.5 * _pulseCtrl.value
                    : 1.0;
                return Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: alpha),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.45 * alpha),
                        blurRadius: 6 * scale,
                        spreadRadius: 1 * scale,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 11, color: accent.withValues(alpha: 0.85)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontFamily: AppConstants.monoFontFamily,
                color: accent.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
            if (widget.deviceCount > 0) ...[
              Container(
                width: 1,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: accent.withValues(alpha: 0.25),
              ),
              Text(
                '${widget.deviceCount}',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: AppConstants.monoFontFamily,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                widget.deviceCount == 1 ? 'device' : 'devices',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}