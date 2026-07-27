import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/settings/presentation/mcp/mcp_panel.dart';

/// Compact "MCP" pill anchored to the title bar.
///
/// Same visual language as [AppUpdatePill] and [LibUpdateTips] — amber
/// accent for "advisory", 1px inner border for liquid-glass refraction,
/// 220ms easeOutCubic for state transitions, AnimatedScale 0.96 on press.
///
/// Interaction is **click-to-open** (not hover-to-expand) because the
/// panel is a full MCP install card with snippets + Run buttons — too
/// much to fit in a hover-only flyout. Tapping the pill springs open
/// the [McpPanel] as a Dynamic Island-style modal anchored top-right.
class McpPill extends ConsumerStatefulWidget {
  const McpPill({super.key});

  @override
  ConsumerState<McpPill> createState() => _McpPillState();
}

class _McpPillState extends ConsumerState<McpPill> {
  bool _pressed = false;

  static const _accent = Color(0xFFFBBF24);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        McpPanel.show(context);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Tooltip(
          message: 'Install DevConnect MCP into your AI client',
          waitDuration: const Duration(milliseconds: 600),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1F242B).withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.zap, size: 12, color: _accent),
                const SizedBox(width: 6),
                Text(
                  'MCP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: isDark ? Colors.white : Colors.black87,
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