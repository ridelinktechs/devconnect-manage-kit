import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/retention_provider.dart';
import '../../../core/utils/list_retention.dart';
import '../../../core/utils/retention_capped.dart';
import '../../../models/display/display_entry.dart';
import '../../../server/providers/server_providers.dart';
import '../../../server/ws_message_handler.dart';

// ---- Display Entries ----

final displayEntriesProvider =
    StateNotifierProvider<DisplayEntriesNotifier, List<DisplayEntry>>((ref) {
  final handler = ref.watch(wsMessageHandlerProvider);
  final notifier = DisplayEntriesNotifier(handler, ref);
  ref.onDispose(() => notifier.cancelSubscription());
  return notifier;
});

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

class DisplayEntriesNotifier extends StateNotifier<List<DisplayEntry>> {
  late final StreamSubscription<DisplayEntry> _sub;
  final Ref _ref;

  /// Total display entries ever received, including ones dropped by the cap.
  int _totalSeen = 0;
  int get totalSeen => _totalSeen;

  DisplayEntriesNotifier(WsMessageHandler handler, this._ref) : super([]) {
    _sub = handler.onDisplay.listen(add);
  }

  void add(DisplayEntry entry) {
    final limit = _ref.read(retentionLimitProvider).limit ?? kRetentionSafetyCap;
    state = truncateList([...state, entry], limit);
    _totalSeen++;
  }

  void cancelSubscription() => _sub.cancel();
  void clear() => state = [];
}

// ---- Async Operation Entries ----

final asyncOperationEntriesProvider =
    StateNotifierProvider<AsyncOpEntriesNotifier, List<AsyncOperationEntry>>(
        (ref) {
  final handler = ref.watch(wsMessageHandlerProvider);
  final notifier = AsyncOpEntriesNotifier(handler, ref);
  ref.onDispose(() => notifier.cancelSubscription());
  return notifier;
});

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
class AsyncOpEntriesNotifier extends StateNotifier<List<AsyncOperationEntry>> {
  late final StreamSubscription<AsyncOperationEntry> _sub;
  final Ref _ref;

  /// Total async-op entries ever received, including ones dropped by the cap.
  int _totalSeen = 0;
  int get totalSeen => _totalSeen;

  AsyncOpEntriesNotifier(WsMessageHandler handler, this._ref) : super([]) {
    _sub = handler.onAsyncOperation.listen(add);
  }

  void add(AsyncOperationEntry entry) {
    final limit = _ref.read(retentionLimitProvider).limit ?? kRetentionSafetyCap;
    state = truncateList(
      [...state, entry],
      limit,
      // `start` is the "pending" state — keep these in preference to
      // completed (resolve) or failed (reject) entries when trimming.
      shouldDrop: (e) => e.status != AsyncOperationStatus.start,
    );
    _totalSeen++;
  }

  void cancelSubscription() => _sub.cancel();
  void clear() => state = [];
}