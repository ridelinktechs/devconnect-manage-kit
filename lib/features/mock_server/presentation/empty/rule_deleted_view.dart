// Lucian UX/UI Prompt #003 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#003
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../models/round/mock_entry.dart';
import 'undo_pill.dart';

const _ease = Cubic(0.2, 0.8, 0.2, 1);
const _spring = Cubic(0.34, 1.45, 0.64, 1);

/// Where the editor was, right after a rule was held to deletion: the rule
/// crumples away as the file does in Lucian #003, and Undo brings it back.
class RuleDeletedView extends StatefulWidget {
  final MockRule rule;
  final VoidCallback onUndo;

  const RuleDeletedView({super.key, required this.rule, required this.onUndo});

  @override
  State<RuleDeletedView> createState() => _RuleDeletedViewState();
}

class _RuleDeletedViewState extends State<RuleDeletedView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gone = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gone.value > 0 || _gone.isAnimating) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _gone.value = 1;
    } else {
      _gone.forward();
    }
  }

  @override
  void dispose() {
    _gone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final rule = widget.rule;
    final method = rule.method.toUpperCase();
    final color = ColorTokens.httpMethodColor(method);
    final base = DefaultTextStyle.of(context).style;

    final card = Container(
      width: 268,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            offset: const Offset(0, 18),
            blurRadius: 30,
            spreadRadius: -22,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(color, Colors.white, 0.3)!, color],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(9),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 7,
                  child: Text(
                    method.length > 4 ? method.substring(0, 3) : method,
                    textAlign: TextAlign.center,
                    style: base.copyWith(
                      fontSize: 9.5,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.57,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.name.trim().isEmpty ? '(unnamed rule)' : rule.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: base.copyWith(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${rule.urlPattern} → ${rule.statusCode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: chromeMono(context, size: 12, color: p.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _gone,
            builder: (context, child) {
              final t = _gone.value;
              final move = _spring.transform(t);
              final fade = _ease.transform((t / (500 / 700)).clamp(0.0, 1.0));
              return Opacity(
                opacity: 1 - fade,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 6 * fade,
                    sigmaY: 6 * fade,
                  ),
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..translateByDouble(0, 18 * move, 0, 1)
                      ..rotateZ(-0.10472 * move)
                      ..scaleByDouble(1 - 0.45 * move, 1 - 0.45 * move, 1, 1),
                    child: child,
                  ),
                ),
              );
            },
            child: card,
          ),
          const SizedBox(height: 26),
          UndoPill(onUndo: widget.onUndo),
          const SizedBox(height: 14),
          Text(
            'Pick another rule, or press Add rule',
            style: base.copyWith(
              fontSize: 12.5,
              height: 1.4,
              color: p.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
