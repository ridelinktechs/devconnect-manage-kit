import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';
import 'keycap.dart';

/// Splits [steps] into lines of (keys, text); `[⇧ ⌘ R] text` names keys.
List<(List<String>, String)> parseSteps(String steps) {
  final keyed = RegExp(r'^\[([^\]]+)\]\s*(.*)$');
  return [
    for (final raw in steps.split('\n'))
      if (raw.trim().isNotEmpty)
        switch (keyed.firstMatch(raw.trim())) {
          final m? => (
            m.group(1)!.split(' ').where((k) => k.isNotEmpty).toList(),
            m.group(2)!,
          ),
          null => (const <String>[], raw.trim()),
        },
  ];
}

/// The steps of a guide: a table of keys when every line names keys,
/// otherwise a numbered list joined by a line.
class GuideSteps extends StatelessWidget {
  final String steps;
  final Color color;

  const GuideSteps({super.key, required this.steps, required this.color});

  @override
  Widget build(BuildContext context) {
    final lines = parseSteps(steps);
    final p = ChromePalette.of(context);
    final text = TextStyle(fontSize: 13, height: 1.5, color: p.text);

    if (lines.every((l) => l.$1.isNotEmpty)) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.border),
        ),
        child: Column(
          children: [
            for (var i = 0; i < lines.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : Border(top: BorderSide(color: p.border)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [for (final k in lines[i].$1) Keycap(k)],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(lines[i].$2, style: text)),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < lines.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: p.isDark ? 0.16 : 0.12),
                        border: Border.all(
                          color: color.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    if (i < lines.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: p.border,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 2,
                      bottom: i < lines.length - 1 ? 14 : 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final k in lines[i].$1)
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Keycap(k),
                          ),
                        if (lines[i].$1.isNotEmpty) const SizedBox(width: 3),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: lines[i].$1.isEmpty ? 0 : 5,
                            ),
                            child: Text(lines[i].$2, style: text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
