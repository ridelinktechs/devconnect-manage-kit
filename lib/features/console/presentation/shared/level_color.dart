import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../models/log/log_entry.dart';

/// Accent color for each log level. Centralized here so the toolbar
/// filter chip + the entry row's left border + the detail panel's
/// stack trace tint all stay in sync.
Color levelColor(LogLevel level) {
  switch (level) {
    case LogLevel.debug:
      return ColorTokens.logDebug;
    case LogLevel.info:
      return ColorTokens.logInfo;
    case LogLevel.warn:
      return ColorTokens.logWarn;
    case LogLevel.error:
      return ColorTokens.logError;
  }
}