import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';

/// Makes [child] a keyboard-reachable button: Enter or Space presses it, and
/// while it has keyboard focus a 2px accent outline sits [offset] px outside
/// it, like the `:focus-visible` ring of the Lucian elements.
class FocusRing extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double radius;
  final double offset;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool selected;
  final String? label;
  final ValueChanged<bool>? onHover;

  const FocusRing({
    super.key,
    required this.onTap,
    required this.child,
    this.radius = 8,
    this.offset = 2,
    this.focusNode,
    this.autofocus = false,
    this.selected = false,
    this.label,
    this.onHover,
  });

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ring = widget.offset + 2;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: widget.onHover,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            children: [
              widget.child,
              if (_focused)
                Positioned(
                  left: -ring,
                  top: -ring,
                  right: -ring,
                  bottom: -ring,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          widget.radius + ring,
                        ),
                        border: Border.all(
                          color: isDark
                              ? ColorTokens.primaryLight
                              : ColorTokens.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
