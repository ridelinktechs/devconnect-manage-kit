// Lucian UX/UI Prompt #092 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#092
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/log/log_entry.dart';
import '../../../settings/presentation/shared/focus_ring.dart';
import '../shared/level_color.dart';

/// One way out of an empty Console: what it drops, what the button says, how
/// many logs it brings back, and what it does.
typedef NoMatchFix = ({
  String drops,
  String label,
  int count,
  VoidCallback apply,
});

const _ease = Cubic(0.2, 0.8, 0.2, 1);
const _spring = Cubic(0.34, 1.45, 0.64, 1);

/// What the Console shows when it has logs but the level filter or the
/// search hides them all, after Lucian #092: a magnifier sweeps the empty
/// shelves, and each [fixes] entry offers to drop a filter, crossed out,
/// with the number of logs that would come back.
class NoMatchState extends StatefulWidget {
  final List<NoMatchFix> fixes;

  const NoMatchState({super.key, required this.fixes});

  @override
  State<NoMatchState> createState() => _NoMatchStateState();
}

class _NoMatchStateState extends State<NoMatchState>
    with TickerProviderStateMixin {
  late final _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );
  late final _enter = AnimationController(vsync: this);
  final _scroll = SmoothScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _scan.stop();
      _enter.value = 1;
    } else {
      if (!_scan.isAnimating) _scan.repeat();
      if (_enter.duration == null) {
        _enter.duration = Duration(
          milliseconds: 100 + widget.fixes.length * 80 + 450,
        );
        _enter.forward();
      }
    }
  }

  @override
  void dispose() {
    _scan.dispose();
    _enter.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final loc = S.of(context);
    final total = math.max(1, _enter.duration?.inMilliseconds ?? 1);
    return Center(
      child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                height: 92,
                child: CustomPaint(
                  painter: _ShelvesPainter(scan: _scan, palette: p),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                loc.consoleNoMatchTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.58,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                loc.consoleNoMatchSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: p.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              for (final (i, fix) in widget.fixes.indexed)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                  child: _Rise(
                    animation: CurvedAnimation(
                      parent: _enter,
                      curve: Interval(
                        math.min(1, (100 + i * 80) / total),
                        math.min(1, (100 + i * 80 + 450) / total),
                        curve: _spring,
                      ),
                    ),
                    child: _FixButton(fix: fix),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lifts [child] in from 14px lower, a little smaller and transparent.
class _Rise extends AnimatedWidget {
  final Widget child;

  const _Rise({required Animation<double> animation, required this.child})
    : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - t)),
        child: Transform.scale(scale: 0.95 + 0.05 * t, child: child),
      ),
    );
  }
}

/// A full-width suggestion: the filter it drops, struck through, then what
/// it does and how many logs it brings back.
class _FixButton extends StatefulWidget {
  final NoMatchFix fix;

  const _FixButton({required this.fix});

  @override
  State<_FixButton> createState() => _FixButtonState();
}

class _FixButtonState extends State<_FixButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final fix = widget.fix;
    final accent = p.isDark ? ColorTokens.primaryLight : ColorTokens.primary;
    final raised = p.isDark ? const Color(0xFF262C36) : const Color(0xFFEAEEF2);
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 300),
        curve: _spring,
        child: FocusRing(
          onTap: fix.apply,
          radius: 14,
          label: '${fix.label}, +${fix.count}',
          onHover: (v) => setState(() => _hover = v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: _ease,
            height: 46,
            padding: const EdgeInsets.only(left: 8, right: 12),
            decoration: BoxDecoration(
              color: _hover ? raised : p.selected,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Flexible(
                  flex: 0,
                  child: Container(
                    height: 28,
                    constraints: const BoxConstraints(maxWidth: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: p.border),
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        fix.drops,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: p.text,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: levelColor(LogLevel.error),
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fix.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _hover ? p.text : p.textMuted,
                    ),
                  ),
                ),
                Text(
                  '+${fix.count}',
                  style: chromeMono(
                    context,
                    size: 13,
                    color: accent,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSlide(
                  offset: Offset(_hover ? 0.2 : 0, 0),
                  duration: const Duration(milliseconds: 300),
                  curve: _spring,
                  child: Icon(
                    LucideIcons.arrowRight,
                    size: 15,
                    color: _hover ? p.text : p.textMuted,
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

/// Three dotted shelves and a magnifier that sweeps along them on Lucian
/// #092's `u092-scan` keyframes; it rests at the start when motion is off.
class _ShelvesPainter extends CustomPainter {
  final Animation<double> scan;
  final ChromePalette palette;

  _ShelvesPainter({required this.scan, required this.palette})
    : super(repaint: scan);

  static const _keys = [
    (0.0, 0.0, 0.0),
    (46.0, 10.0, 8.0),
    (78.0, -4.0, -4.0),
    (30.0, -8.0, -10.0),
    (0.0, 0.0, 0.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 150, size.height / 92);
    final shelf = Paint()
      ..color = palette.border
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final y in [30.0, 56.0, 82.0]) {
      for (var x = 8.0; x < 142; x += 11) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 2, 142), y), shelf);
      }
    }

    final at = scan.value * 4;
    final i = math.min(at.floor(), 3);
    final k = Curves.easeInOut.transform(at - i);
    final (x0, y0, r0) = _keys[i];
    final (x1, y1, r1) = _keys[i + 1];
    canvas
      ..save()
      ..translate(x0 + (x1 - x0) * k, y0 + (y1 - y0) * k)
      ..rotate((r0 + (r1 - r0) * k) * math.pi / 180);
    final ink = Paint()
      ..color = palette.text
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawCircle(
        const Offset(34, 38),
        20,
        Paint()..color = ColorTokens.primary.withValues(alpha: 0.12),
      )
      ..drawCircle(const Offset(34, 38), 20, ink..strokeWidth = 5)
      ..drawPath(
        Path()
          ..moveTo(24, 30)
          ..arcToPoint(const Offset(32, 25), radius: const Radius.circular(12)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      )
      ..drawLine(
        const Offset(48, 52),
        const Offset(62, 66),
        ink..strokeWidth = 7,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_ShelvesPainter old) => old.palette != palette;
}
