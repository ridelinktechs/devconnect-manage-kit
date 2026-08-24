import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/retention_provider.dart';
import '../../../core/utils/list_retention.dart';
import '../../../core/utils/retention_capped.dart';
import '../../../models/display/display_entry.dart';
import '../../../server/providers/server_providers.dart';

// ---- Display Entries ----

final displayEntriesProvider =
    NotifierProvider<DisplayEntriesNotifier, List<DisplayEntry>>(
        DisplayEntriesNotifier.new);

/// Total display entries ever received by [DisplayEntriesNotifier],
/// including ones dropped by the retention cap.
///
/// Watches [displayEntriesProvider] (not just the notifier) so this
/// rebuilds every time a new entry is appended — the notifier's
/// [DisplayEntriesNotifier.totalSeen] getter is otherwise non-reactive.
final displayTotalSeenProvider = Provider<int>((ref) {
  ref.watch(displayEntriesProvider); // subscribe to state changes
  return ref.read(displayEntriesProvider.notifier).totalSeen;
});

/// Source-cached list (capped to the user's retention limit) plus the
/// lifetime total (including dropped entries).
final displayDisplayProvider =
    Provider<RetentionCapped<DisplayEntry>>((ref) {
  final all = ref.watch(displayEntriesProvider);
  final limit = ref.watch(retentionLimitProvider.select((p) => p.limit));
  final totalSeen = ref.watch(displayTotalSeenProvider);
  return applyRetentionCap(all, limit, totalSeen: totalSeen);
});

class DisplayEntriesNotifier extends Notifier<List<DisplayEntry>> {
  /// Total display entries ever received, including ones dropped by the cap.
  int _totalSeen = 0;
  int get totalSeen => _totalSeen;

  @override
  List<DisplayEntry> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onDisplay.listen(_add);
    ref.onDispose(() => sub.cancel());
    return [];
  }

  void _add(DisplayEntry entry) {
    final limit = ref.read(retentionLimitProvider).limit ?? kRetentionSafetyCap;
    state = truncateList([...state, entry], limit);
    _totalSeen++;
  }

  void clear() => state = [];
}

// ---- Async Operation Entries ----

final asyncOperationEntriesProvider =
    NotifierProvider<AsyncOpEntriesNotifier, List<AsyncOperationEntry>>(
        AsyncOpEntriesNotifier.new);

/// Total async-op entries ever received by [AsyncOpEntriesNotifier],
/// including ones dropped by the retention cap.
///
/// Watches [asyncOperationEntriesProvider] (not just the notifier) so this
/// rebuilds every time a new entry is appended — the notifier's
/// [AsyncOpEntriesNotifier.totalSeen] getter is otherwise non-reactive.
final asyncOpTotalSeenProvider = Provider<int>((ref) {
  ref.watch(asyncOperationEntriesProvider); // subscribe to state changes
  return ref.read(asyncOperationEntriesProvider.notifier).totalSeen;
});

/// Source-cached list (capped to the user's retention limit) plus the
/// lifetime total (including dropped entries).
final asyncOpDisplayProvider =
    Provider<RetentionCapped<AsyncOperationEntry>>((ref) {
  final all = ref.watch(asyncOperationEntriesProvider);
  final limit = ref.watch(retentionLimitProvider.select((p) => p.limit));
  final totalSeen = ref.watch(asyncOpTotalSeenProvider);
  return applyRetentionCap(all, limit, totalSeen: totalSeen);
});

/// Async ops have a "drop resolved/rejected first" rule — the user cares
/// more about pending `start` rows (they're waiting on them) than
/// historical `resolve`/`reject` rows. The drop happens before the
/// straight FIFO trim so cap pressure never kills an in-flight op.
class AsyncOpEntriesNotifier extends Notifier<List<AsyncOperationEntry>> {
  /// Total async-op entries ever received, including ones dropped by the cap.
  int _totalSeen = 0;
  int get totalSeen => _totalSeen;

  @override
  List<AsyncOperationEntry> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onAsyncOperation.listen(_add);
    ref.onDispose(() => sub.cancel());
    return [];
  }

  void _add(AsyncOperationEntry entry) {
    final limit = ref.read(retentionLimitProvider).limit ?? kRetentionSafetyCap;
    state = truncateList(
      [...state, entry],
      limit,
      // `start` is the "pending" state — keep these in preference to
      // completed (resolve) or failed (reject) entries when trimming.
      shouldDrop: (e) => e.status != AsyncOperationStatus.start,
    );
    _totalSeen++;
  }

  void clear() => state = [];
}