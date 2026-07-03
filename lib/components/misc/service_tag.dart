import 'package:flutter/material.dart';

import '../../core/theme/color_tokens.dart';

class ServiceTag extends StatelessWidget {
  final String name;
  const ServiceTag({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final color = colorForService(name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static Color colorForService(String name) {
    switch (name) {
      case 'AWS':
      case 'AWS Cognito':
        return const Color(0xFFFF9900);
      case 'Google Maps':
        return const Color(0xFF4285F4);
      case 'Firebase':
        return const Color(0xFFFFCA28);
      case 'Stripe':
        return const Color(0xFF635BFF);
      case 'GitHub':
        return const Color(0xFF8B949E);
      case 'Sentry':
        return const Color(0xFF6C5FC7);
      default:
        return ColorTokens.primary;
    }
  }
}
