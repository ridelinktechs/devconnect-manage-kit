// Lucian UX/UI Prompt #047 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#047
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../shared/focus_ring.dart';

/// One choice of a [SegmentedPicker].
typedef Segment<T> = ({T value, String label, IconData? icon});

/// Equal-width segmented control. The knob stretches as it moves: the edge
/// in front gets there first on an ease, the trailing edge follows on a
/// spring. ← / → change the value.
class SegmentedPicker<T> extends StatefulWidget {
  final List<Segment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  const SegmentedPicker({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  @override
  State<SegmentedPicker<T>> createState() => _SegmentedPickerState<T>();
}

class _SegmentedPickerState<T> extends State<SegmentedPicker<T>>
    with SingleTickerProviderStateMixin {
  static const _ease = Cubic(0.2, 0.8, 0.2, 1);
  static const _spring = Cubic(0.34, 1.45, 0.64, 1);
  static const _lead = 300.0;
  static const _trail = 500.0;
  static const _delay = 70.0;

  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 570),
    value: 1,
  );

  /// Knob edges in segment units, before and after the current move.
  late (double, double) _from = _target;
  late (double, double) _to = _target;
  late List<FocusNode> _nodes = _makeNodes();

  int get _index => widget.segments
      .indexWhere((s) => s.value == widget.value)
      .clamp(0, widget.segments.length - 1);

  (double, double) get _target => (_index.toDouble(), _index + 1.0);

  List<FocusNode> _makeNodes() => [
    for (var i = 0; i < widget.segments.length; i++)
      FocusNode(skipTraversal: i != _index),
  ];

  (double, double) get _edges {
    final ms = _move.value * 570;
    double run(double start, double length, Curve curve) =>
        curve.transform(((ms - start) / length).clamp(0.0, 1.0));
    final right = _to.$1 > _from.$1;
    final l = right ? run(_delay, _trail, _spring) : run(0, _lead, _ease);
    final r = right ? run(0, _lead, _ease) : run(_delay, _trail, _spring);
    return (
      _from.$1 + (_to.$1 - _from.$1) * l,
      _from.$2 + (_to.$2 - _from.$2) * r,
    );
  }

  @override
  void didUpdateWidget(SegmentedPicker<T> old) {
    super.didUpdateWidget(old);
    if (old.segments.length != widget.segments.length) {
      for (final n in _nodes) {
        n.dispose();
      }
      _nodes = _makeNodes();
    }
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal = i != _index;
    }
    if (_target == _to) return;
    _from = _edges;
    _to = _target;
    if (MediaQuery.disableAnimationsOf(context)) {
      _move.value = 1;
    } else {
      _move.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _move.dispose();
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _step(int d) {
    final n = widget.segments.length;
    final i = (_index + d + n) % n;
    widget.onChanged(widget.segments[i].value);
    _nodes[i].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final track = p.isDark ? const Color(0xFF0D1117) : const Color(0xFFEEF1F4);
    final knob = p.isDark ? const Color(0xFF262C36) : Colors.white;
    final base = DefaultTextStyle.of(
      context,
    ).style.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600);

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border.withValues(alpha: 0.6)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final unit = constraints.maxWidth / widget.segments.length;
          return Stack(
            children: [
              AnimatedBuilder(
                animation: _move,
                builder: (context, _) {
                  final (l, r) = _edges;
                  return Positioned(
                    left: l * unit,
                    width: (r - l) * unit,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: knob,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: p.isDark ? 0.6 : 0.18,
                            ),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                            spreadRadius: -6,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                      _step(1),
                  const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                      _step(-1),
                },
                child: Row(
                  children: [
                    for (var i = 0; i < widget.segments.length; i++)
                      Expanded(
                        child: _Option(
                          segment: widget.segments[i],
                          selected: i == _index,
                          focusNode: _nodes[i],
                          style: base,
                          onTap: () {
                            _nodes[i].requestFocus();
                            widget.onChanged(widget.segments[i].value);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One option: shrinks a little while pressed, brightens on hover.
class _Option<T> extends StatefulWidget {
  final Segment<T> segment;
  final bool selected;
  final FocusNode focusNode;
  final TextStyle style;
  final VoidCallback onTap;

  const _Option({
    required this.segment,
    required this.selected,
    required this.focusNode,
    required this.style,
    required this.onTap,
  });

  @override
  State<_Option<T>> createState() => _OptionState<T>();
}

class _OptionState<T> extends State<_Option<T>> {
  static const _spring = Cubic(0.34, 1.45, 0.64, 1);

  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final color = widget.selected
        ? p.text
        : (_hover ? p.text.withValues(alpha: 0.8) : p.textMuted);
    final icon = widget.segment.icon;
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 300),
        curve: _spring,
        child: FocusRing(
          focusNode: widget.focusNode,
          onTap: widget.onTap,
          radius: 12,
          offset: 1,
          selected: widget.selected,
          onHover: (v) => setState(() => _hover = v),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: widget.style.copyWith(color: color),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: color),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, c, _) =>
                          Icon(icon, size: 15, color: c),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: Text(
                      widget.segment.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
