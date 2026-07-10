import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/retention_provider.dart';
import '../../../core/utils/list_retention.dart';
import '../../../core/utils/retention_capped.dart';
import '../../../models/storage/storage_entry.dart';
import '../../../server/providers/server_providers.dart';
import '../../../server/ws_message_handler.dart';

final storageEntriesProvider =
    StateNotifierProvider<StorageNotifier, List<StorageEntry>>((ref) {
  final handler = ref.watch(wsMessageHandlerProvider);
  final notifier = StorageNotifier(handler, ref);
  ref.onDispose(() => notifier.cancelSubscription());
  return notifier;
});

/// Total storage entries ever received by [StorageNotifier],
/// including ones dropped by the retention cap.
///
/// Watches [storageEntriesProvider] (not just the notifier) so this
/// rebuilds every time a new entry is appended — the notifier's
/// [StorageNotifier.totalSeen] getter is otherwise non-reactive.
final storageTotalSeenProvider = Provider<int>((ref) {
  ref.watch(storageEntriesProvider); // subscribe to state changes
  return ref.read(storageEntriesProvider.notifier).totalSeen;
});

/// Source-cached list (capped to the user's retention limit) plus the
/// lifetime total (including dropped entries).
final storageDisplayProvider =
    Provider<RetentionCapped<StorageEntry>>((ref) {
  final all = ref.watch(storageEntriesProvider);
  final limit = ref.watch(retentionLimitProvider.select((p) => p.limit));
  final totalSeen = ref.watch(storageTotalSeenProvider);
  return applyRetentionCap(all, limit, totalSeen: totalSeen);
});

final storageSearchProvider = StateProvider<String>((ref) => '');

/// Single-select operation filter (null = show all).
final storageOperationFilterProvider = StateProvider<String?>((ref) => null);

/// Multi-select storage type filter (all enabled by default).
final storageTypeFilterProvider = StateProvider<Set<StorageType>>(
  (ref) => StorageType.values.toSet(),
);

final filteredStorageEntriesProvider = Provider<List<StorageEntry>>((ref) {
  final entries = ref.watch(storageDisplayProvider).items;
  final search = ref.watch(storageSearchProvider).toLowerCase();
  final selectedDevice = ref.watch(selectedDeviceProvider);
  final opFilter = ref.watch(storageOperationFilterProvider);
  final typeFilter = ref.watch(storageTypeFilterProvider);

  return entries.where((e) {
    if (selectedDevice == null) return false;
    if (selectedDevice != allDevicesValue && e.deviceId != selectedDevice) {
      return false;
    }
    if (opFilter != null && e.operation.toLowerCase() != opFilter) {
      return false;
    }
    if (!typeFilter.contains(e.storageType)) return false;
    if (search.isNotEmpty) {
      return e.key.toLowerCase().contains(search) ||
          (e.value?.toString().toLowerCase().contains(search) ?? false);
    }
    return true;
  }).toList();
});

final selectedStorageIdProvider = StateProvider<String?>((ref) => null);

final selectedStorageEntryProvider = Provider<StorageEntry?>((ref) {
  final id = ref.watch(selectedStorageIdProvider);
  if (id == null) return null;
  final entries = ref.watch(storageEntriesProvider);
  return entries.where((e) => e.id == id).firstOrNull;
});

class StorageNotifier extends StateNotifier<List<StorageEntry>> {
  late final StreamSubscription<StorageEntry> _sub;
  final Ref _ref;

  /// Total storage entries ever received, including ones dropped by the cap.
  int _totalSeen = 0;
  int get totalSeen => _totalSeen;

  StorageNotifier(WsMessageHandler wsMessageHandler, this._ref) : super([]) {
    _sub = wsMessageHandler.onStorage.listen((entry) {
      // Update existing key or add new
      final index = state.indexWhere(
          (e) => e.key == entry.key && e.storageType == entry.storageType);
      if (index >= 0) {
        final updated = List<StorageEntry>.from(state);
        updated[index] = entry;
        state = updated;
      } else {
        final limit = _ref.read(retentionLimitProvider).limit;
        state = truncateList([...state, entry], limit);
        _totalSeen++;
      }
    });
  }

  void cancelSubscription() => _sub.cancel();

  void clear() => state = [];
}
