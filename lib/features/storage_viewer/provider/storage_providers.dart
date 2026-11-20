import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/retention_provider.dart';
import '../../../core/utils/collections/list_retention.dart';
import '../../../core/utils/collections/retention_capped.dart';
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

/// Operations hidden from the history (`read`, `write`, …), in lower case.
final storageHiddenOpsProvider =
    NotifierProvider<StorageHiddenOpsNotifier, Set<String>>(
  StorageHiddenOpsNotifier.new,
);

class StorageHiddenOpsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void set(Set<String> v) => state = v;

  void toggle(String op) =>
      state = state.contains(op) ? state.difference({op}) : {...state, op};
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
  final hiddenOps = ref.watch(storageHiddenOpsProvider);
  final typeFilter = ref.watch(storageTypeFilterProvider);

  return entries.where((e) {
    if (!storageOnDevice(e, selectedDevice)) return false;
    if (hiddenOps.contains(e.operation.toLowerCase())) return false;
    if (!typeFilter.contains(e.storageType)) return false;
    return storageMatchesSearch(e, search);
  }).toList();
});

/// Whether [e] came from [selectedDevice], or any device when every device
/// is picked.
bool storageOnDevice(StorageEntry e, String? selectedDevice) =>
    selectedDevice != null &&
    (selectedDevice == allDevicesValue || e.deviceId == selectedDevice);

/// Whether [e]'s key or value holds [search], already in lower case.
bool storageMatchesSearch(StorageEntry e, String search) =>
    search.isEmpty ||
    e.key.toLowerCase().contains(search) ||
    (e.value?.toString().toLowerCase().contains(search) ?? false);

/// How many operations of each kind and of each storage type the history
/// holds for the picked device and search, before the operation and type
/// filters: the counts on their chips.
final storageFacetsProvider =
    Provider<({Map<String, int> ops, Map<StorageType, int> types})>((ref) {
  final entries = ref.watch(storageDisplayProvider).items;
  final search = ref.watch(storageSearchProvider).toLowerCase();
  final device = ref.watch(selectedDeviceProvider);
  final ops = <String, int>{};
  final types = <StorageType, int>{};
  for (final e in entries) {
    if (!storageOnDevice(e, device) || !storageMatchesSearch(e, search)) {
      continue;
    }
    final op = e.operation.toLowerCase();
    ops[op] = (ops[op] ?? 0) + 1;
    types[e.storageType] = (types[e.storageType] ?? 0) + 1;
  }
  return (ops: ops, types: types);
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