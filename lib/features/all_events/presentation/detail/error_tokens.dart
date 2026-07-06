import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../models/log/error_event.dart';

/// Maps an [ErrorSeverity] to its accent color. Local copy of
/// `error_inspector/.../shared/error_tokens.dart` — the two pages
/// must not cross-import.
Color severityColor(ErrorSeverity severity) {
  switch (severity) {
    case ErrorSeverity.fatal:
      return Colors.red.shade900;
    case ErrorSeverity.crash:
      return Colors.red;
    case ErrorSeverity.error:
      return ColorTokens.logError;
    case ErrorSeverity.warning:
      return ColorTokens.logWarn;
    case ErrorSeverity.info:
      return ColorTokens.logInfo;
  }
}

String platformLabel(ErrorPlatform platform) {
  switch (platform) {
    case ErrorPlatform.js:
      return 'JS';
    case ErrorPlatform.native:
      return 'Native';
    case ErrorPlatform.android:
      return 'Android';
    case ErrorPlatform.ios:
      return 'iOS';
  }
}

Color platformColor(ErrorPlatform platform) {
  switch (platform) {
    case ErrorPlatform.js:
      return Colors.blue;
    case ErrorPlatform.native:
      return Colors.purple;
    case ErrorPlatform.android:
      return Colors.green;
    case ErrorPlatform.ios:
      return Colors.orange;
  }
}