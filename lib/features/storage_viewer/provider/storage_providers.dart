import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/retention_provider.dart';
import '../../../core/utils/list_retention.dart';
import '../../../core/utils/retention_capped.dart';
import '../../../models/storage/storage_entry.dart';
import '../../../server/providers/server_providers.dart';

final storageEntriesProvider =
    NotifierProvider<StorageNotifier, List<StorageEntry>>(
        StorageNotifier.new);

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

final storageSearchProvider =
    NotifierProvider<_StorageSearchNotifier, String>(
  _StorageSearchNotifier.new,
);

class _StorageSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String v) => state = v;
}

/// Single-select operation filter (null = show all).
final storageOperationFilterProvider =
    NotifierProvider<_StorageOperationFilterNotifier, String?>(
  _StorageOperationFilterNotifier.new,
);

class _StorageOperationFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? v) => state = v;
}

/// Multi-select storage type filter (all enabled by default).
final storageTypeFilterProvider =
    NotifierProvider<_StorageTypeFilterNotifier, Set<StorageType>>(
  _StorageTypeFilterNotifier.new,
);

class _StorageTypeFilterNotifier extends Notifier<Set<StorageType>> {
  @override
  Set<StorageType> build() => StorageType.values.toSet();

  void set(Set<StorageType> v) => state = v;

  void toggle(StorageType type) {
    state = state.contains(type)
        ? state.difference({type})
        : {...state, type};
  }
}

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

final selectedStorageIdProvider =
    NotifierProvider<_SelectedStorageIdNotifier, String?>(
  _SelectedStorageIdNotifier.new,
);

class _SelectedStorageIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? v) => state = v;
}

final selectedStorageEntryProvider = Provider<StorageEntry?>((ref) {
  final id = ref.watch(selectedStorageIdProvider);
  if (id == null) return null;
  final entries = ref.watch(storageEntriesProvider);
  return entries.where((e) => e.id == id).firstOrNull;
});

class StorageNotifier extends Notifier<List<StorageEntry>> {
  /// Total storage entries ever received, including ones dropped by the cap.
  int _totalSeen = 0;
  int get totalSeen => _totalSeen;

  @override
  List<StorageEntry> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onStorage.listen((entry) {
      // Pure event-log: every reported operation is its own row. The
      // SDK mints a fresh UUID per `_send()` and the handler's
      // `_uniqueOneShotId` disambiguates on retry, so every entry that
      // reaches us has a unique id — no content-based dedup needed.
      final limit = ref.read(retentionLimitProvider).limit;
      state = truncateList([...state, entry], limit);
      _totalSeen++;
    });
    ref.onDispose(() => sub.cancel());
    return [];
  }

  void clear() => state = [];
}