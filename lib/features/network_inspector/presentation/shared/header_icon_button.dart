import 'package:flutter/material.dart';

/// Compact 28×28 icon button with a static neutral background, used in
/// the Network Inspector's detail header for screenshot / close actions.
///
/// Local copy of `HeaderIconButton` in `all_events/presentation/buttons/`.
/// Kept separate per the "no cross-feature imports" refactor convention.
/// Note: this version uses a static grey background (no hover state)
/// because the detail header is dense — every cell needs to stay
/// visually quiet to avoid competing with the screenshot itself.
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey.withValues(alpha: 0.1),
            ),
            child: Icon(icon, size: 14, color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }
}