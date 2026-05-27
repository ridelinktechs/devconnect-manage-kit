import 'package:flutter/material.dart';

class JumpToLatestFab extends StatefulWidget {
  final ScrollController scrollController;
  final bool reversed;

  const JumpToLatestFab({
    super.key,
    required this.scrollController,
    this.reversed = false,
  });

  @override
  State<JumpToLatestFab> createState() => _JumpToLatestFabState();
}

class PositionedJumpToLatestFab extends StatelessWidget {
  final ScrollController scrollController;
  final bool reversed;
  final double bottom;

  const PositionedJumpToLatestFab({
    super.key,
    required this.scrollController,
    this.reversed = false,
    this.bottom = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      left: 0,
      right: 0,
      child: Center(
        child: JumpToLatestFab(
          scrollController: scrollController,
          reversed: reversed,
        ),
      ),
    );
  }
}

class _JumpToLatestFabState extends State<JumpToLatestFab> {
  bool _scheduledMetricsCheck = false;

  void _scheduleMetricsCheck() {
    if (_scheduledMetricsCheck) return;
    _scheduledMetricsCheck = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduledMetricsCheck = false;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.scrollController,
      builder: (context, _) {
        if (!widget.scrollController.hasClients) return const SizedBox.shrink();
        final pos = widget.scrollController.position;
        if (!pos.hasContentDimensions) {
          _scheduleMetricsCheck();
          return const SizedBox.shrink();
        }
        final atEdge = widget.reversed
            ? pos.pixels <= pos.minScrollExtent + 2.0
            : pos.pixels >= pos.maxScrollExtent - 2.0;
        if (atEdge) return const SizedBox.shrink();

        return _JumpButton(
          reversed: widget.reversed,
          onTap: () {
            if (!widget.scrollController.hasClients ||
                !widget.scrollController.position.hasContentDimensions) {
              return;
            }
            final currentPos = widget.scrollController.position;
            final target = widget.reversed
                ? currentPos.minScrollExtent
                : currentPos.maxScrollExtent;
            widget.scrollController.animateTo(
              target,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          },
        );
      },
    );
  }
}

class _JumpButton extends StatefulWidget {
  final bool reversed;
  final VoidCallback onTap;

  const _JumpButton({required this.reversed, required this.onTap});

  @override
  State<_JumpButton> createState() => _JumpButtonState();
}

class _JumpButtonState extends State<_JumpButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: 'Jump to latest',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _hovered
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.10))
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.reversed
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 6),
                Text(
                  'Jump to latest',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
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
