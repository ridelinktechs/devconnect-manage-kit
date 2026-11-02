// Lucian UX/UI Prompt #039 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#039
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../shared/focus_ring.dart';

/// Pill tab bar: the selected tab sits on an ink pill that stretches and
/// glides over to it. ← / → move between tabs.
class TipTabs extends StatefulWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  const TipTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  State<TipTabs> createState() => _TipTabsState();
}

class _TipTabsState extends State<TipTabs> {
  static const _spring = Cubic(0.34, 1.45, 0.64, 1);
  static const _ease = Cubic(0.2, 0.8, 0.2, 1);
  static const _padding = 16.0;

  late List<FocusNode> _nodes = _makeNodes();

  List<FocusNode> _makeNodes() => [
    for (var i = 0; i < widget.labels.length; i++)
      FocusNode(skipTraversal: i != widget.index),
  ];

  @override
  void didUpdateWidget(TipTabs old) {
    super.didUpdateWidget(old);
    if (old.labels.length != widget.labels.length) {
      for (final n in _nodes) {
        n.dispose();
      }
      _nodes = _makeNodes();
    }
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal = i != widget.index;
    }
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _move(int d) {
    final n = widget.labels.length;
    final i = (widget.index + d + n) % n;
    widget.onChanged(i);
    _nodes[i].requestFocus();
  }

  /// Tab widths like CSS `flex: 1` with a min-content floor: equal shares,
  /// except tabs whose label needs more keep their own width.
  static List<double> _widths(List<double> natural, double available) {
    final widths = List<double>.filled(natural.length, 0);
    final fixed = List<bool>.filled(natural.length, false);
    var space = available;
    var open = natural.length;
    var changed = true;
    while (changed && open > 0) {
      changed = false;
      final share = space / open;
      for (var i = 0; i < natural.length; i++) {
        if (!fixed[i] && natural[i] > share) {
          fixed[i] = true;
          widths[i] = natural[i];
          space -= natural[i];
          open--;
          changed = true;
        }
      }
    }
    for (var i = 0; i < natural.length; i++) {
      if (!fixed[i]) widths[i] = space / open;
    }
    return widths;
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final base = DefaultTextStyle.of(
      context,
    ).style.copyWith(fontSize: 14, fontWeight: FontWeight.w700);
    final page = p.isDark ? ColorTokens.darkSurface : Colors.white;
    final scale = MediaQuery.textScalerOf(context);

    double measure(String label) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: base),
        textDirection: Directionality.of(context),
        textScaler: scale,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width + 2 * _padding;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final natural = [for (final label in widget.labels) measure(label)];
        final available = constraints.maxWidth - 12;
        final total = natural.fold<double>(0, (a, b) => a + b);
        final scroll = total > available;
        final widths = scroll ? natural : _widths(natural, available);
        var left = 0.0;
        for (var i = 0; i < widget.index; i++) {
          left += widths[i];
        }

        final bar = Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: p.border),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: reduce
                    ? Duration.zero
                    : const Duration(milliseconds: 500),
                curve: _spring,
                left: left,
                width: widths[widget.index],
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.text,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: p.isDark ? 0.72 : 0.3,
                        ),
                        offset: const Offset(0, 8),
                        blurRadius: 16,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                ),
              ),
              CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                      _move(1),
                  const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                      _move(-1),
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < widget.labels.length; i++)
                      SizedBox(
                        width: widths[i],
                        height: 42,
                        child: FocusRing(
                          focusNode: _nodes[i],
                          onTap: () => widget.onChanged(i),
                          radius: 999,
                          selected: i == widget.index,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 350),
                              curve: _ease,
                              style: base.copyWith(
                                color: i == widget.index ? page : p.textMuted,
                              ),
                              child: Text(
                                widget.labels[i],
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

        return scroll
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: bar,
              )
            : bar;
      },
    );
  }
}
