import 'package:flutter/material.dart';

/// 24×24 neutral square icon button. Used inside dense detail-panel
/// sections where the 28×28 [IconBtn] would feel too large.
class MiniIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const MiniIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.withValues(alpha: 0.06),
            ),
            child: Icon(icon, size: 11, color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }
}
