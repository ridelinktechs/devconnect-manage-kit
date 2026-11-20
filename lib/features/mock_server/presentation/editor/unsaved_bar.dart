// Lucian UX/UI Prompt #250 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#250
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../settings/presentation/shared/focus_ring.dart';

enum _Mode { hidden, dirty, warn, saved }

/// Lucian #250's unsaved-changes bar over [child]: it drops in from the top
/// while [changes] > 0, shakes red when [nudge] fires (an attempt to leave)
/// or saving fails, and turns green with "Saved" before sliding away.
/// ⌘S or Ctrl+S inside [child] saves.
class UnsavedBar extends StatefulWidget {
  final Widget child;
  final int changes;

  /// Saves; returns why it couldn't, or null when it did.
  final String? Function() onSave;
  final VoidCallback onDiscard;
  final ValueListenable<int> nudge;

  const UnsavedBar({
    super.key,
    required this.child,
    required this.changes,
    required this.onSave,
    required this.onDiscard,
    required this.nudge,
  });

  @override
  State<UnsavedBar> createState() => _UnsavedBarState();
}

class _UnsavedBarState extends State<UnsavedBar>
    with SingleTickerProviderStateMixin {
  static const _drop = Cubic(0.3, 1.3, 0.5, 1);

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  final _saveNode = FocusNode(debugLabel: 'Save changes');
  String? _warning;
  bool _saved = false;
  Timer? _timer;

  /// The last look the bar was seen in, kept while it slides away.
  (_Mode, String) _shown = (_Mode.dirty, '');

  bool get _motion => !MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    widget.nudge.addListener(_onNudge);
  }

  @override
  void didUpdateWidget(UnsavedBar old) {
    super.didUpdateWidget(old);
    if (old.nudge != widget.nudge) {
      old.nudge.removeListener(_onNudge);
      widget.nudge.addListener(_onNudge);
    }
  }

  @override
  void dispose() {
    widget.nudge.removeListener(_onNudge);
    _timer?.cancel();
    _shake.dispose();
    _saveNode.dispose();
    super.dispose();
  }

  void _onNudge() {
    if (widget.changes == 0) return;
    _warn('Save or discard first');
    _saveNode.requestFocus();
  }

  void _warn(String text) {
    _timer?.cancel();
    setState(() {
      _warning = text;
      _saved = false;
    });
    if (_motion) _shake.forward(from: 0);
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _warning = null);
    });
  }

  void _save() {
    if (widget.changes == 0) return;
    final why = widget.onSave();
    if (why != null) {
      _warn(why);
      return;
    }
    _timer?.cancel();
    setState(() {
      _warning = null;
      _saved = true;
    });
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  void _discard() {
    _timer?.cancel();
    setState(() => _warning = null);
    widget.onDiscard();
  }

  /// The keyframes of `u250-sh`: ±6 px twice, then rest.
  static double _shakeAt(double t) {
    const stops = [0.0, -6.0, 6.0, -6.0, 6.0, 0.0];
    final x = t * (stops.length - 1);
    final i = x.floor().clamp(0, stops.length - 2);
    return stops[i] + (stops[i + 1] - stops[i]) * (x - i);
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final mode = _warning != null
        ? _Mode.warn
        : widget.changes > 0
        ? _Mode.dirty
        : _saved
        ? _Mode.saved
        : _Mode.hidden;
    if (mode != _Mode.hidden) {
      _shown = (
        mode,
        switch (mode) {
          _Mode.warn => _warning!,
          _Mode.saved => 'Saved',
          _ => 'Unsaved changes: ${widget.changes}',
        },
      );
    }
    final (look, text) = _shown;
    final (bg, fg) = switch (look) {
      _Mode.warn => (const Color(0xFFBE123C), Colors.white),
      _Mode.saved => (const Color(0xFF047857), Colors.white),
      _ => (p.text, p.surface),
    };
    final live = mode == _Mode.dirty || mode == _Mode.warn;
    final base = DefaultTextStyle.of(
      context,
    ).style.copyWith(fontSize: 11.5, height: 1.2, fontWeight: FontWeight.w800);

    final bar = AnimatedContainer(
      duration: _motion ? const Duration(milliseconds: 300) : Duration.zero,
      height: 44,
      padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: base.copyWith(color: fg),
              ),
            ),
          ),
          Visibility(
            visible: mode != _Mode.saved,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: ExcludeFocus(
              excluding: !live,
              child: Row(
                children: [
                  _BarButton(
                    label: 'Discard',
                    fill: fg.withValues(alpha: 0.14),
                    ink: fg,
                    style: base,
                    onTap: _discard,
                  ),
                  const SizedBox(width: 6),
                  _BarButton(
                    label: 'Save changes',
                    fill: p.surface,
                    ink: p.text,
                    style: base,
                    focusNode: _saveNode,
                    onTap: _save,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: widget.child),
          Positioned.fill(
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: 8,
                    right: 8,
                    top: 8,
                    child: IgnorePointer(
                      ignoring: mode == _Mode.hidden,
                      child: AnimatedSlide(
                        offset: mode == _Mode.hidden
                            ? const Offset(0, -1.4)
                            : Offset.zero,
                        duration: _motion
                            ? const Duration(milliseconds: 450)
                            : Duration.zero,
                        curve: _drop,
                        child: AnimatedBuilder(
                          animation: _shake,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(
                              _shake.isAnimating ? _shakeAt(_shake.value) : 0,
                              0,
                            ),
                            child: child,
                          ),
                          child: bar,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A 32px button of the bar.
class _BarButton extends StatelessWidget {
  final String label;
  final Color fill;
  final Color ink;
  final TextStyle style;
  final FocusNode? focusNode;
  final VoidCallback onTap;

  const _BarButton({
    required this.label,
    required this.fill,
    required this.ink,
    required this.style,
    this.focusNode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FocusRing(
      onTap: onTap,
      focusNode: focusNode,
      radius: 9,
      label: label,
      child: Container(
        height: 32,
        constraints: const BoxConstraints(minWidth: 52),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(label, style: style.copyWith(color: ink)),
      ),
    );
  }
}
