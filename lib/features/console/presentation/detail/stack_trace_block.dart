// Lucian UX/UI Prompt #072 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#072
import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../../models/log/log_entry.dart';
import '../shared/level_color.dart';

/// A stack trace set like the log block of Lucian #072: mono 11.5/1.6 on the
/// code surface, scrolling sideways rather than wrapping frames, with the
/// first line, the error itself, in the level's color.
class StackTraceBlock extends StatefulWidget {
  final String trace;
  final LogLevel level;

  const StackTraceBlock({super.key, required this.trace, required this.level});

  @override
  State<StackTraceBlock> createState() => _StackTraceBlockState();
}

class _StackTraceBlockState extends State<StackTraceBlock> {
  final _scroll = SmoothScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final lines = widget.trace.trimRight().split('\n');
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.codeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border.withValues(alpha: 0.6)),
      ),
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(10),
        child: SelectableText.rich(
          TextSpan(
            style: chromeMono(
              context,
              size: 11.5,
              color: p.textMuted,
              weight: FontWeight.w600,
            ).copyWith(height: 1.6),
            children: [
              TextSpan(
                text: lines.first,
                style: TextStyle(
                  color: levelInk(widget.level, isDark: p.isDark),
                ),
              ),
              for (final line in lines.skip(1)) TextSpan(text: '\n$line'),
            ],
          ),
        ),
      ),
    );
  }
}
