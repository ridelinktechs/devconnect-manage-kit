import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';

/// Reload connection pill — sits next to the status pill and forces every
/// connected SDK into its reconnect path. Tactile feedback on press.
class ReloadPill extends StatefulWidget {
  final bool restarting;
  final String tooltip;
  final VoidCallback onTap;

  const ReloadPill({
    super.key,
    required this.restarting,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<ReloadPill> createState() => _ReloadPillState();
}

class _ReloadPillState extends State<ReloadPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.restarting) _spinCtrl.repeat();
  }

  @override
  void didUpdateWidget(covariant ReloadPill old) {
    super.didUpdateWidget(old);
    if (widget.restarting && !_spinCtrl.isAnimating) {
      _spinCtrl.repeat();
    } else if (!widget.restarting && _spinCtrl.isAnimating) {
      _spinCtrl.reset();
    }
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.restarting ? null : widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: widget.restarting
                ? ColorTokens.primary.withValues(alpha: isDark ? 0.14 : 0.10)
                : isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.restarting
                  ? ColorTokens.primary.withValues(alpha: 0.35)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _spinCtrl,
                child: Icon(
                  LucideIcons.refreshCw,
                  size: 12,
                  color: widget.restarting
                      ? ColorTokens.primary
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                widget.restarting ? S.of(context).restarting : widget.tooltip,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.restarting
                      ? ColorTokens.primary
                      : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}