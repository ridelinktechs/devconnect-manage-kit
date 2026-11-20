// Lucian UX/UI Prompt #141 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#141
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';

/// One key of a shortcut, drawn as a keycap with a deep bottom edge. Mac
/// modifier glyphs read as Ctrl / Alt / Shift on other systems.
class Keycap extends StatelessWidget {
  final String label;

  const Keycap(this.label, {super.key});

  static String _forPlatform(String key) {
    if (Platform.isMacOS) return key;
    return switch (key) {
      '⌘' => 'Ctrl',
      '⌥' => 'Alt',
      '⇧' => 'Shift',
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(1, 1, 1, 3),
      decoration: BoxDecoration(
        color: p.border,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: p.isDark ? 0.35 : 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        constraints: const BoxConstraints(minWidth: 26, minHeight: 25),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Align(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            _forPlatform(label),
            style: chromeMono(
              context,
              size: 12.5,
              color: p.text,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
