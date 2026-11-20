// Lucian UX/UI Prompt #003 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#003
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../shared/mock_look.dart';

/// Lucian #003's delete button: a red fill rises only while it is held
/// (pointer, or Space / Enter), drains when let go, and [onDeleted] runs
/// once it is full.
class HoldToDelete extends StatefulWidget {
  /// What screen readers announce, e.g. "Hold to delete Users list".
  final String semanticLabel;
  final VoidCallback onDeleted;

  const HoldToDelete({
    super.key,
    required this.semanticLabel,
    required this.onDeleted,
  });

  @override
  State<HoldToDelete> createState() => _HoldToDeleteState();
}

class _HoldToDeleteState extends State<HoldToDelete>
    with SingleTickerProviderStateMixin {
  static const _hold = 1200.0;
  static const _spring = Cubic(0.34, 1.45, 0.64, 1);

  late final Ticker _ticker = createTicker(_tick);
  final _focus = FocusNode(debugLabel: 'Hold to delete');
  double _p = 0;
  bool _holding = false;
  bool _focused = false;
  Duration _last = Duration.zero;
  Duration _now = Duration.zero;

  @override
  void dispose() {
    _ticker.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1000;
    _last = elapsed;
    _now = elapsed;
    setState(() {
      _p = _holding
          ? (_p + dt / _hold).clamp(0.0, 1.0)
          : (_p - dt / (_hold / 2.4)).clamp(0.0, 1.0);
    });
    if (_holding && _p >= 1) {
      _holding = false;
      _ticker.stop();
      widget.onDeleted();
    } else if (!_holding && _p == 0) {
      _ticker.stop();
    }
  }

  void _start() {
    if (_holding) return;
    setState(() => _holding = true);
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _stop() {
    if (!_holding) return;
    setState(() => _holding = false);
    if (!_ticker.isActive && _p > 0) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.space && key != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) _start();
    if (event is KeyUpEvent) _stop();
    return KeyEventResult.handled;
  }

  /// The `u003-shake` jitter, 120 ms a loop.
  Offset get _jitter {
    final t = (_now.inMilliseconds % 120) / 120;
    if (t < 0.25) return Offset(-0.6 * t / 0.25, 0.3 * t / 0.25);
    if (t < 0.75) {
      final k = (t - 0.25) / 0.5;
      return Offset(-0.6 + 1.2 * k, 0.3 - 0.6 * k);
    }
    final k = (t - 0.75) / 0.25;
    return Offset(0.6 - 0.6 * k, -0.3 + 0.3 * k);
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final danger = mockDanger(p.isDark);
    final motion = !MediaQuery.disableAnimationsOf(context);
    final onFill = p.isDark ? const Color(0xFF0B0C12) : Colors.white;
    final style = DefaultTextStyle.of(context).style.copyWith(
      fontSize: 13,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.26,
    );
    Widget label(Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.trash2, size: 15, color: color),
        const SizedBox(width: 8),
        Text('Hold to delete', style: style.copyWith(color: color)),
      ],
    );

    final body = Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(danger.withValues(alpha: 0.12), p.surface),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: danger.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          label(danger),
          Positioned(
            left: -17.5,
            right: -17.5,
            top: -1.5,
            bottom: -1.5,
            child: ClipPath(
              clipper: _FillClip(_p),
              child: ColoredBox(
                color: danger,
                child: Center(child: label(onFill)),
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: Focus(
        focusNode: _focus,
        onKeyEvent: _onKey,
        onFocusChange: (v) {
          setState(() => _focused = v);
          if (!v) _stop();
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Listener(
            onPointerDown: (e) {
              if (e.buttons == kPrimaryButton) _start();
            },
            onPointerUp: (_) => _stop(),
            onPointerCancel: (_) => _stop(),
            child: AnimatedScale(
              scale: _holding ? 0.97 : 1,
              duration: motion
                  ? const Duration(milliseconds: 500)
                  : Duration.zero,
              curve: _spring,
              child: Transform.translate(
                offset: _holding && _p > 0.55 && motion ? _jitter : Offset.zero,
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: _focused
                        ? Border.all(color: danger, width: 2)
                        : null,
                  ),
                  child: body,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The left [p] of the pill, rounded like it.
class _FillClip extends CustomClipper<Path> {
  final double p;

  const _FillClip(this.p);

  @override
  Path getClip(Size size) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * p, size.height),
        Radius.circular(size.height / 2),
      ),
    );

  @override
  bool shouldReclip(_FillClip old) => old.p != p;
}
