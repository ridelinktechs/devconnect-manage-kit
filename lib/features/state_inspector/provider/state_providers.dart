import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/state/state_change.dart';
import '../../../server/providers/server_providers.dart';
import '../../../server/ws_message_handler.dart';

final stateChangesProvider =
    StateNotifierProvider<StateChangesNotifier, List<StateChange>>((ref) {
  final handler = ref.watch(wsMessageHandlerProvider);
  final notifier = StateChangesNotifier(handler);
  ref.onDispose(() => notifier.cancelSubscription());
  return notifier;
});

final selectedStateChangeProvider =
    StateProvider<StateChange?>((ref) => null);

final stateSearchProvider = StateProvider<String>((ref) => '');

final filteredStateChangesProvider = Provider<List<StateChange>>((ref) {
  final entries = ref.watch(stateChangesProvider);
  final search = ref.watch(stateSearchProvider).toLowerCase();
  final selectedDevice = ref.watch(selectedDeviceProvider);

  return entries.where((e) {
    if (selectedDevice != null && e.deviceId != selectedDevice) return false;
    if (search.isNotEmpty) {
      return e.actionName.toLowerCase().contains(search) ||
          e.stateManagerType.toLowerCase().contains(search);
    }
    return true;
  }).toList();
});

class StateChangesNotifier extends StateNotifier<List<StateChange>> {
  late final StreamSubscription<StateChange> _sub;

  StateChangesNotifier(WsMessageHandler wsMessageHandler) : super([]) {
    _sub = wsMessageHandler.onState.listen((entry) {
      if (state.length > 5000) {
        state = [...state.skip(500), entry];
      } else {
        state = [...state, entry];
      }
    });
  }

  void cancelSubscription() => _sub.cancel();

  void clear() => state = [];
}
