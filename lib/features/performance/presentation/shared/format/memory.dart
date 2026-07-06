/// Format a MB value with an auto-picked unit (GB / MB / KB).
String formatMemory(double mb) {
  if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
  if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
  return '${(mb * 1024).toStringAsFixed(0)} KB';
}

/// Numeric-only portion (for metric cards / pills where the unit is
/// rendered in a separate styled label).
String formatMemoryValue(double mb) {
  if (mb >= 1024) return (mb / 1024).toStringAsFixed(1);
  if (mb >= 1) return mb.toStringAsFixed(1);
  return (mb * 1024).toStringAsFixed(0);
}

/// Unit-only portion (matches `formatMemoryValue`'s threshold).
String formatMemoryUnit(double mb) {
  if (mb >= 1024) return 'GB';
  if (mb >= 1) return 'MB';
  return 'KB';
}