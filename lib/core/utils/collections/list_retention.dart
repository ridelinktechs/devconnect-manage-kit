/// Cap a list at [limit] entries, dropping the oldest (head) when the
/// cap is exceeded. Returns the input list unchanged when [limit] is
/// null (unlimited) or the list is already within bounds.
///
/// Drops in chunks (`max(limit * 0.1, 50)`) so we don't reallocate the
/// list on every single insert — same pattern the providers used before
/// the retention setting existed.
///
/// When [shouldDrop] is provided, candidates for removal are first
/// scored: items where `shouldDrop(item) == true` are removed before
/// ones where it is `false`. Used by the async-op notifier to clear
/// resolved/rejected entries before touching the still-pending ones.
List<T> truncateList<T>(
  List<T> list,
  int? limit, {
  bool Function(T item)? shouldDrop,
}) {
  if (limit == null || list.length <= limit) return list;
  final toDrop = list.length - limit;

  // When a "drop first" predicate is supplied, sort indices so that
  // droppable items come first; otherwise drop the oldest (head) entries.
  if (shouldDrop != null) {
    final droppableIndices = <int>[];
    final keepIndices = <int>[];
    for (var i = 0; i < list.length; i++) {
      (shouldDrop(list[i]) ? droppableIndices : keepIndices).add(i);
    }
    final victims = droppableIndices.take(toDrop).toList();
    if (victims.length < toDrop) {
      // Topped up from the head of the keep list.
      final need = toDrop - victims.length;
      victims.addAll(keepIndices.take(need));
    }
    final victimSet = victims.toSet();
    return [
      for (var i = 0; i < list.length; i++)
        if (!victimSet.contains(i)) list[i],
    ];
  }

  return list.sublist(toDrop);
}