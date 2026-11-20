/// Result of applying a retention cap to a source list.
///
/// - [items] — the most recent [limit] entries (or the full list when
///   no cap is set / list fits under the cap).
/// - [total] — lifetime count of entries received, including ones
///   dropped by the cap. Used by the page header to surface a
///   "Showing N of M" hint when entries have been dropped.
class RetentionCapped<T> {
  final List<T> items;
  final int total;

  const RetentionCapped({required this.items, required this.total});

  /// True when the source was longer than [limit] and some entries were
  /// dropped from the head of the list.
  bool get isTrimmed => total > items.length;
}

/// Apply a retention cap to [source], keeping the most recent [limit]
/// entries. [limit] is the user-configured retention cap; null = no cap.
///
/// Cheap O(n) operation. Used by per-feature display providers so that
/// the page header can surface a "Showing N of M" note when older entries
/// are being hidden by the cap.
RetentionCapped<T> applyRetentionCap<T>(
  List<T> source,
  int? limit, {
  int? totalSeen,
}) {
  if (limit == null || source.length <= limit) {
    return RetentionCapped(
      items: source,
      total: totalSeen ?? source.length,
    );
  }
  return RetentionCapped(
    items: source.sublist(source.length - limit),
    total: totalSeen ?? source.length,
  );
}