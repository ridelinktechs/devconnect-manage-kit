import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 30×30 round copy icon with hover fill + press feedback. Local copy of
/// `all_events/presentation/shared/copy_button.dart` (which uses an
/// internal `PressableButton`) — kept local to avoid a cross-feature
/// import, mirroring the pattern used by every other sub-folder here.
class CopyButton extends StatefulWidget {
  final String tooltip;
  final VoidCallback onTap;
  final IconData icon;

  const CopyButton({
    super.key,
    required this.tooltip,
    required this.onTap,
    this.icon = LucideIcons.copy,
  });

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: _hovered
                  ? Colors.grey.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }
}