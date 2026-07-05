import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../models/log/error_event.dart';

/// Maps an [ErrorSeverity] to its accent color. Fatal / crash use the
/// saturated red range so they always read as critical against the
/// neutral page chrome; warning / info borrow the log palette.
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

/// Short, uppercase label for an [ErrorPlatform]. Used in badges, chips,
/// and the per-platform count cells in the info bar.
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

/// Stable per-platform accent color used for badges, filter chips, and
/// the info-bar dots. The four platforms map to four distinct hues so
/// they read unambiguously when several are stacked next to each other.
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