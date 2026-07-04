/// Sanitizes a string so it can be safely embedded in a screenshot filename.
///
/// - Replaces any character that is not [A-Za-z0-9_-] with `_`.
/// - Collapses runs of underscores into one.
/// - Trims leading/trailing underscores.
/// - Truncates to [maxLen] characters so the final name + suffix stays
///   under typical filesystem limits.
String safeFileName(String raw, {int maxLen = 40}) {
  if (raw.isEmpty) return 'item';
  final cleaned = raw.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  final trimmed = cleaned.replaceAll(RegExp(r'_+'), '_');
  final stripped =
      trimmed.replaceAll(RegExp(r'^_+|_+$'), '');
  if (stripped.isEmpty) return 'item';
  return stripped.length > maxLen ? stripped.substring(0, maxLen) : stripped;
}

/// Builds a screenshot filename from a [prefix] (e.g. `storage_data`) and a
/// subject identifier (e.g. a storage key or network URL).
///
/// Example:
/// ```dart
/// buildScreenshotName('storage_data', 'user:session-token');
/// // → 'storage_data_user_session-token.png'
/// ```
String buildScreenshotName(String prefix, String subject) {
  final safe = safeFileName(subject);
  return '${prefix}_$safe';
}

/// Builds a unified screenshot filename with the form
/// `<type>_<subject>_<isoTimestamp>_<suffix>.png`.
///
/// The app name is intentionally **not** included — screenshots may be
/// shared with clients and the internal app identifier must not leak.
///
/// - [type] is a short category label (e.g. `log`, `network`, `state`,
///   `storage`, `error`, `display`).
/// - [subject] is a meaningful identifier — a storage key, a network URL
///   path, a log tag, etc. It's sanitized via [safeFileName].
/// - [suffix] disambiguates the capture kind (e.g. `_full`, `_data`,
///   `_detail`).
///
/// Example:
/// ```dart
/// buildRichScreenshotName(
///   type: 'network',
///   subject: 'https://api.example.com/v1/users',
///   suffix: '_full',
/// );
/// // → 'network_api_example_com_v1_users_2026-07-04T19-52-47_full.png'
/// ```
String buildRichScreenshotName({
  required String type,
  required String subject,
  required String suffix,
}) {
  final t = safeFileName(type);
  final s = safeFileName(subject);
  final ts = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .split('.')
      .first;
  return '${t}_${s}_${ts}$suffix';
}