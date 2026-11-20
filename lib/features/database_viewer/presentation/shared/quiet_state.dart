import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';

/// What an empty area says: one quiet line and an optional second, centred,
/// without an illustration.
class QuietState extends StatelessWidget {
  final String title;
  final String? subtitle;

  const QuietState({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p.text,
                ),
              ),
              if (subtitle case final subtitle?) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: p.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
