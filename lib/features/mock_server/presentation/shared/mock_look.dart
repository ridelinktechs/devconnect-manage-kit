import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';

/// The methods a rule can match, in the order the editor offers them.
const mockMethods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'];

/// The app's purple, lighter in dark mode: focus, selection and live states.
Color mockAccent(bool isDark) =>
    isDark ? ColorTokens.primaryLight : ColorTokens.primary;

/// Red for errors and deletes, 4.5:1 as text in both themes.
Color mockDanger(bool isDark) =>
    isDark ? ColorTokens.logError : const Color(0xFFCF222E);

/// [status]'s color, the same one the Network tab paints it with.
Color statusTint(int status) => ColorTokens.statusCodeColor(status);

/// [status]'s color for text: the tint in dark mode, Primer's deeper shade
/// of it in light mode.
Color statusInk(int status, {required bool isDark}) {
  final tint = statusTint(status);
  if (isDark) return tint;
  return switch (tint) {
    ColorTokens.success => const Color(0xFF1A7F37),
    ColorTokens.warning => const Color(0xFF9A6700),
    ColorTokens.info => const Color(0xFF0969DA),
    _ => const Color(0xFFCF222E),
  };
}

/// [method]'s color for text, 4.5:1 on the app's surfaces.
Color methodInk(String method, {required bool isDark}) {
  if (isDark) {
    return method.toUpperCase() == 'POST'
        ? ColorTokens.primaryLight
        : ColorTokens.httpMethodColor(method);
  }
  return switch (method.toUpperCase()) {
    'GET' => const Color(0xFF1A7F37),
    'POST' => ColorTokens.primaryDark,
    'PUT' => const Color(0xFF9A6700),
    'PATCH' => const Color(0xFF0B7A7A),
    'DELETE' => const Color(0xFFCF222E),
    _ => const Color(0xFF0969DA),
  };
}

/// The reason phrase of [status], e.g. "Not Found"; empty when unknown.
String statusReason(int status) => switch (status) {
  100 => 'Continue',
  101 => 'Switching Protocols',
  200 => 'OK',
  201 => 'Created',
  202 => 'Accepted',
  204 => 'No Content',
  301 => 'Moved Permanently',
  302 => 'Found',
  304 => 'Not Modified',
  307 => 'Temporary Redirect',
  308 => 'Permanent Redirect',
  400 => 'Bad Request',
  401 => 'Unauthorized',
  403 => 'Forbidden',
  404 => 'Not Found',
  405 => 'Method Not Allowed',
  408 => 'Request Timeout',
  409 => 'Conflict',
  410 => 'Gone',
  422 => 'Unprocessable Content',
  429 => 'Too Many Requests',
  500 => 'Internal Server Error',
  501 => 'Not Implemented',
  502 => 'Bad Gateway',
  503 => 'Service Unavailable',
  504 => 'Gateway Timeout',
  _ => '',
};

/// "300 ms" below a second, "1.5 s" from there on.
String formatDelay(int ms) {
  if (ms < 1000) return '$ms ms';
  final s = ms / 1000;
  return '${s == s.roundToDouble() ? s.round() : s.toStringAsFixed(1)} s';
}
