import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';

/// "Icon + bold title" header rendered at the top of every Settings
/// section. Local copy — different signature than the section titles
/// used in other features (no label-color param, no right-side slot).
class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const SectionTitle({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}