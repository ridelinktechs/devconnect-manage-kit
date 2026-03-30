import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/color_tokens.dart';

class StatusBadge extends StatelessWidget {
  final int statusCode;

  const StatusBadge({super.key, required this.statusCode});

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.statusCodeColor(statusCode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$statusCode',
        style: TextStyle(
          fontFamily: AppConstants.monoFontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class HttpMethodBadge extends StatelessWidget {
  final String method;

  const HttpMethodBadge({super.key, required this.method});

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.httpMethodColor(method);
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          method.toUpperCase(),
          style: TextStyle(
            fontFamily: AppConstants.monoFontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class LogLevelBadge extends StatelessWidget {
  final String level;

  const LogLevelBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (level.toLowerCase()) {
      case 'debug':
        color = ColorTokens.logDebug;
        break;
      case 'info':
        color = ColorTokens.logInfo;
        break;
      case 'warn':
      case 'warning':
        color = ColorTokens.logWarn;
        break;
      case 'error':
        color = ColorTokens.logError;
        break;
      default:
        color = ColorTokens.logInfo;
    }

    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          level.toUpperCase(),
          style: TextStyle(
            fontFamily: AppConstants.monoFontFamily,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class PlatformBadge extends StatelessWidget {
  final String platform;

  const PlatformBadge({super.key, required this.platform});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (platform.toLowerCase()) {
      case 'flutter':
        color = const Color(0xFF02569B);
        label = 'Flutter';
        break;
      case 'react_native':
      case 'reactnative':
        color = const Color(0xFF61DAFB);
        label = 'RN';
        break;
      case 'android':
        color = const Color(0xFF3DDC84);
        label = 'Android';
        break;
      default:
        color = Colors.grey;
        label = platform;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
