// Lucian UX/UI Prompt #228 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#228
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../shared/focus_ring.dart';
import 'guides.dart';

/// Guide card whose border and inside are lit by the lamp of [TipGrid]:
/// [lamp] is the pointer in this card's own coordinates, [glow] its
/// strength from 0 to 1.
class TipCard extends StatelessWidget {
  final Guide guide;
  final Offset lamp;
  final double glow;
  final VoidCallback onTap;

  const TipCard({
    super.key,
    required this.guide,
    required this.lamp,
    required this.glow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final dark = p.isDark;
    return FocusRing(
      onTap: onTap,
      radius: 18,
      label: guide.title,
      child: CustomPaint(
        painter: _GlowPainter(
          lamp: lamp,
          glow: glow,
          base: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.09),
          inside: dark ? p.surface : Colors.white,
          lit: dark ? ColorTokens.primaryLight : ColorTokens.primary,
          spill: ColorTokens.info,
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.07),
                  ),
                ),
                child: Icon(
                  guide.icon,
                  size: 16,
                  color: guideTone(guide.color, dark),
                ),
              ),
              const SizedBox(height: 6),
              const Spacer(),
              Text(
                guide.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                guide.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: p.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The 1.5px gradient border and the faint inner light of a card.
class _GlowPainter extends CustomPainter {
  final Offset lamp;
  final double glow;
  final Color base;
  final Color inside;
  final Color lit;
  final Color spill;

  const _GlowPainter({
    required this.lamp,
    required this.glow,
    required this.base,
    required this.inside,
    required this.lit,
    required this.spill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    final inner = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1.5),
      const Radius.circular(16.5),
    );
    canvas.drawRRect(outer, Paint()..color = base);
    if (glow > 0.001) {
      canvas.drawRRect(
        outer,
        Paint()
          ..shader = ui.Gradient.radial(
            lamp,
            160,
            [
              lit.withValues(alpha: glow),
              spill.withValues(alpha: glow * 0.5),
              spill.withValues(alpha: 0),
            ],
            const [0, 0.4, 0.7],
          ),
      );
    }
    canvas.drawRRect(inner, Paint()..color = inside);
    if (glow > 0.001) {
      canvas.drawRRect(
        inner,
        Paint()
          ..shader = ui.Gradient.radial(
            lamp,
            220,
            [lit.withValues(alpha: glow * 0.14), lit.withValues(alpha: 0)],
            const [0, 0.6],
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.lamp != lamp ||
      old.glow != glow ||
      old.base != base ||
      old.inside != inside ||
      old.lit != lit;
}
