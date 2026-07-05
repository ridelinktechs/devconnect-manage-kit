import 'package:flutter/material.dart';

import '../../../../models/log/error_event.dart';
import 'error_tokens.dart' show platformColor, platformLabel;

/// Tinted pill that labels the source [ErrorPlatform] of an error
/// (JS / Native / Android / iOS). Uses the per-platform accent color
/// at 20% for the fill so it reads as a soft tag.
class PlatformBadge extends StatelessWidget {
  final ErrorPlatform platform;

  const PlatformBadge({super.key, required this.platform});

  @override
  Widget build(BuildContext context) {
    final color = platformColor(platform);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        platformLabel(platform),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}