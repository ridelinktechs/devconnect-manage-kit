import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/retention_provider.dart';
import '../../../core/utils/list_retention.dart';
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

final storageSearchProvider = StateProvider<String>((ref) => '');

/// Single-select operation filter (null = show all).
final storageOperationFilterProvider = StateProvider<String?>((ref) => null);

/// Multi-select storage type filter (all enabled by default).
final storageTypeFilterProvider = StateProvider<Set<StorageType>>(
  (ref) => StorageType.values.toSet(),
);

final filteredStorageEntriesProvider = Provider<List<StorageEntry>>((ref) {
  final entries = ref.watch(storageEntriesProvider);
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
      }
    });
  }

  void cancelSubscription() => _sub.cancel();

  void clear() => state = [];
}
