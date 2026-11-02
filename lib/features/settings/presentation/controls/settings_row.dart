import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';

/// One setting inside a card: its name and an optional description on the
/// left, the control on the right. A hairline separates it from the row
/// above unless it is [first]. In narrow cards the control drops below.
class SettingsRow extends StatelessWidget {
  final String title;
  final String? description;
  final Widget control;
  final bool first;
  final double controlWidth;

  const SettingsRow({
    super.key,
    required this.title,
    required this.control,
    this.description,
    this.first = false,
    this.controlWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final description = this.description;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: p.text,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 3),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, ?current],
            ),
            child: Text(
              description,
              key: ValueKey(description),
              style: TextStyle(fontSize: 12, height: 1.45, color: p.textMuted),
            ),
          ),
        ],
      ],
    );

    return Container(
      padding: EdgeInsets.only(top: first ? 2 : 14, bottom: 14),
      decoration: BoxDecoration(
        border: first
            ? null
            : Border(top: BorderSide(color: p.border.withValues(alpha: 0.7))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < controlWidth + 220) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [text, const SizedBox(height: 12), control],
            );
          }
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 24),
              SizedBox(width: controlWidth, child: control),
            ],
          );
        },
      ),
    );
  }
}
