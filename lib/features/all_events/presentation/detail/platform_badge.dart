import 'package:flutter/material.dart';

import '../../../../models/log/error_event.dart';
import 'error_tokens.dart' show platformColor, platformLabel;

/// Tinted pill that labels the source [ErrorPlatform]. Local copy of
/// `error_inspector/.../shared/platform_badge.dart` — no cross-feature
/// import, by design.
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