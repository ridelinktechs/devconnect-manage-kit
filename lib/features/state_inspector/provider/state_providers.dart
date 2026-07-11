import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/retention_provider.dart';
import '../../../core/utils/list_retention.dart';
import '../../../core/utils/retention_capped.dart';
import '../../../models/state/state_change.dart';
import '../../../server/providers/server_providers.dart';
import '../../../server/ws_message_handler.dart';

final stateChangesProvider =
    StateNotifierProvider<StateChangesNotifier, List<StateChange>>((ref) {
  final handler = ref.watch(wsMessageHandlerProvider);
  final notifier = StateChangesNotifier(handler, ref);
  ref.onDispose(() => notifier.cancelSubscription());
  return notifier;
});

/// Total state changes ever received by [StateChangesNotifier],
/// including ones dropped by the retention cap.
///
/// Watches [stateChangesProvider] (not just the notifier) so this
/// rebuilds every time a new entry is appended — the notifier's
/// [StateChangesNotifier.totalSeen] getter is otherwise non-reactive.
final stateChangesTotalSeenProvider = Provider<int>((ref) {
  ref.watch(stateChangesProvider); // subscribe to state changes
  return ref.read(stateChangesProvider.notifier).totalSeen;
});

/// Source-cached list (capped to the user's retention limit) plus the
/// lifetime total (including dropped entries).
final stateChangesDisplayProvider =
    Provider<RetentionCapped<StateChange>>((ref) {
  final all = ref.watch(stateChangesProvider);
  final limit = ref.watch(retentionLimitProvider.select((p) => p.limit));
  final totalSeen = ref.watch(stateChangesTotalSeenProvider);
  return applyRetentionCap(all, limit, totalSeen: totalSeen);
});

final selectedStateChangeIdProvider = StateProvider<String?>((ref) => null);

final selectedStateChangeProvider = Provider<StateChange?>((ref) {
  final id = ref.watch(selectedStateChangeIdProvider);
  if (id == null) return null;
  final entries = ref.watch(stateChangesProvider);
  return entries.where((e) => e.id == id).firstOrNull;
});

final stateSearchProvider = StateProvider<String>((ref) => '');

final filteredStateChangesProvider = Provider<List<StateChange>>((ref) {
  final entries = ref.watch(stateChangesDisplayProvider).items;
  final search = ref.watch(stateSearchProvider).toLowerCase();
  final selectedDevice = ref.watch(selectedDeviceProvider);

  return entries.where((e) {
    if (selectedDevice == null) return false;
    if (selectedDevice != allDevicesValue && e.deviceId != selectedDevice) return false;
    if (search.isNotEmpty) {
      return e.actionName.toLowerCase().contains(search) ||
          e.stateManagerType.toLowerCase().contains(search);
    }
    return true;
  }).toList();
});

class StateChangesNotifier extends StateNotifier<List<StateChange>> {
  late final StreamSubscription<StateChange> _sub;
  final Ref _ref;

  /// Total state changes ever received, including ones dropped by the cap.
  int _totalSeen = 0;
  int get totalSeen => _totalSeen;

  StateChangesNotifier(WsMessageHandler wsMessageHandler, this._ref) : super([]) {
    _sub = wsMessageHandler.onState.listen((entry) {
      final limit = _ref.read(retentionLimitProvider).limit ?? kRetentionSafetyCap;
      state = truncateList([...state, entry], limit);
      _totalSeen++;
    });
  }

  void cancelSubscription() => _sub.cancel();

  void clear() => state = [];
}
