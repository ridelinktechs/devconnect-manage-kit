// Lucian UX/UI Prompt #003 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#003
import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../settings/presentation/shared/focus_ring.dart';

const _ease = Cubic(0.2, 0.8, 0.2, 1);
const _spring = Cubic(0.34, 1.45, 0.64, 1);

/// The pill Lucian #003 shows once something is held to deletion: "Rule
/// deleted" with an Undo that brings it right back. It rises in and takes
/// focus, so Enter undoes at once.
class UndoPill extends StatefulWidget {
  final VoidCallback onUndo;

  const UndoPill({super.key, required this.onUndo});

  @override
  State<UndoPill> createState() => _UndoPillState();
}

class _UndoPillState extends State<UndoPill> {
  bool _shown = false;
  bool _hover = false;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final motion = !MediaQuery.disableAnimationsOf(context);
    final ink = p.surface;
    final base = DefaultTextStyle.of(context).style;
    final pill = Container(
      width: 268,
      height: 64,
      padding: const EdgeInsets.fromLTRB(22, 0, 8, 0),
      decoration: BoxDecoration(
        color: p.text,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                'Rule deleted',
                style: base.copyWith(
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
            ),
          ),
          Listener(
            onPointerDown: (_) => setState(() => _down = true),
            onPointerUp: (_) => setState(() => _down = false),
            onPointerCancel: (_) => setState(() => _down = false),
            child: AnimatedScale(
              scale: _down ? 0.94 : 1,
              duration: const Duration(milliseconds: 400),
              curve: _spring,
              child: FocusRing(
                onTap: widget.onUndo,
                autofocus: true,
                radius: 23,
                label: 'Undo',
                onHover: (v) => setState(() => _hover = v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: _ease,
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: _hover ? 0.26 : 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Undo',
                    style: base.copyWith(
                      fontSize: 14.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return AnimatedOpacity(
      opacity: _shown || !motion ? 1 : 0,
      duration: motion ? const Duration(milliseconds: 400) : Duration.zero,
      curve: _ease,
      child: AnimatedSlide(
        offset: _shown || !motion ? Offset.zero : const Offset(0, 10 / 64),
        duration: motion ? const Duration(milliseconds: 600) : Duration.zero,
        curve: _spring,
        child: AnimatedScale(
          scale: _shown || !motion ? 1 : 0.96,
          duration: motion ? const Duration(milliseconds: 600) : Duration.zero,
          curve: _spring,
          child: pill,
        ),
      ),
    );
  }
}
