import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';

/// Small "dot or icon + label" pill used in the page header to surface
/// server status + device count. Tinted with the supplied [color]
/// (10% fill, 25% border) so the same widget fits a success/info/muted
/// palette without needing a state enum. With [pulse] the dot sends out a
/// slow ring to show the thing is live.
class StatusChip extends StatefulWidget {
  final Color color;
  final String label;
  final IconData? icon;
  final bool pulse;

  const StatusChip({
    super.key,
    required this.color,
    required this.label,
    this.icon,
    this.pulse = false,
  });

  @override
  State<StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<StatusChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(StatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.pulse && !MediaQuery.disableAnimationsOf(context);
    if (run && !_ring.isAnimating) _ring.repeat();
    if (!run && _ring.isAnimating) _ring.reset();
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null)
            Icon(widget.icon, size: 13, color: color)
          else
            SizedBox.square(
              dimension: 12,
              child: AnimatedBuilder(
                animation: _ring,
                builder: (context, _) {
                  final t = _ring.value;
                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      if (_ring.isAnimating)
                        Container(
                          width: 7 + 10 * t,
                          height: 7 + 10 * t,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: 0.45 * (1 - t)),
                          ),
                        ),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(width: 7),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ChromePalette.of(context).text,
            ),
          ),
        ],
      ),
    );
  }
}
