import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';

/// Amber "Clear stale (N)" pill that surfaces pending requests that
/// haven't received a response in over 10 minutes — the client likely
/// crashed or the network dropped mid-flight. Tapping the pill clears
/// those stale rows so the list doesn't fill up with dead entries.
class ClearStaleBtn extends StatefulWidget {
  final int count;
  final VoidCallback onTap;

  const ClearStaleBtn({super.key, required this.count, required this.onTap});

  @override
  State<ClearStaleBtn> createState() => _ClearStaleBtnState();
}

class _ClearStaleBtnState extends State<ClearStaleBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = S.of(context);
    const accent = Color(0xFFFBBF24); // amber 400 — matches Tree mode

    final bg = _hovered
        ? accent.withValues(alpha: isDark ? 0.18 : 0.16)
        : accent.withValues(alpha: isDark ? 0.12 : 0.10);
    final border = accent.withValues(alpha: isDark ? 0.40 : 0.36);

    return Tooltip(
      message: loc.clearStaleTooltip(widget.count),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.timerOff, size: 12, color: accent),
                const SizedBox(width: 5),
                Text(
                  loc.clearStaleButton(widget.count),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}