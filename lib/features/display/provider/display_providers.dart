import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/retention_provider.dart';
import '../../../core/utils/list_retention.dart';
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

class DisplayEntriesNotifier extends StateNotifier<List<DisplayEntry>> {
  late final StreamSubscription<DisplayEntry> _sub;
  final Ref _ref;

  DisplayEntriesNotifier(WsMessageHandler handler, this._ref) : super([]) {
    _sub = handler.onDisplay.listen(add);
  }

  void add(DisplayEntry entry) {
    final limit = _ref.read(retentionLimitProvider).limit;
    state = truncateList([...state, entry], limit);
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

/// Async ops have a "drop resolved/rejected first" rule — the user cares
/// more about pending `start` rows (they're waiting on them) than
/// historical `resolve`/`reject` rows. The drop happens before the
/// straight FIFO trim so cap pressure never kills an in-flight op.
class AsyncOpEntriesNotifier extends StateNotifier<List<AsyncOperationEntry>> {
  late final StreamSubscription<AsyncOperationEntry> _sub;
  final Ref _ref;

  AsyncOpEntriesNotifier(WsMessageHandler handler, this._ref) : super([]) {
    _sub = handler.onAsyncOperation.listen(add);
  }

  void add(AsyncOperationEntry entry) {
    final limit = _ref.read(retentionLimitProvider).limit;
    state = truncateList(
      [...state, entry],
      limit,
      // `start` is the "pending" state — keep these in preference to
      // completed (resolve) or failed (reject) entries when trimming.
      shouldDrop: (e) => e.status != AsyncOperationStatus.start,
    );
  }

  void cancelSubscription() => _sub.cancel();
  void clear() => state = [];
}