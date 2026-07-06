import 'package:flutter/material.dart';

import '../../../../models/log/error_event.dart';
import 'error_tokens.dart' show severityColor;

/// Tinted uppercase pill that labels an [ErrorSeverity]. Local copy of
/// `error_inspector/.../shared/severity_badge.dart` — no cross-feature
/// import, by design.
class SeverityBadge extends StatelessWidget {
  final ErrorSeverity severity;

  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        severity.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}