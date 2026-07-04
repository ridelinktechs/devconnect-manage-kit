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