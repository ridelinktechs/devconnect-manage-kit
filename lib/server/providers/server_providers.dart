import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/benchmark/provider/benchmark_providers.dart';
import '../../features/console/provider/console_providers.dart';
import '../../features/display/provider/display_providers.dart';
import '../../features/network_inspector/provider/network_providers.dart';
import '../../features/performance/provider/performance_providers.dart';
import '../../features/state_inspector/provider/state_providers.dart';
import '../../features/storage_viewer/provider/storage_providers.dart';
import '../../models/device_info.dart';
import '../ws_message_handler.dart';
import '../ws_server.dart';

final wsServerProvider = Provider<WsServer>((ref) {
  final server = WsServer();
  ref.onDispose(() { server.dispose(); });
  return server;
});

final wsMessageHandlerProvider = Provider<WsMessageHandler>((ref) {
  final server = ref.watch(wsServerProvider);
  final handler = WsMessageHandler(server: server);
  ref.onDispose(() => handler.dispose());
  return handler;
});

final connectedDevicesProvider =
    StateNotifierProvider<ConnectedDevicesNotifier, List<DeviceInfo>>((ref) {
  final handler = ref.watch(wsMessageHandlerProvider);
  final notifier = ConnectedDevicesNotifier(handler, ref);
  ref.onDispose(() => notifier.cancelSubscriptions());
  return notifier;
});

/// null = no selection (show nothing), 'all' = show all, deviceId = filter
const allDevicesValue = '__all__';

final selectedDeviceProvider =
    StateNotifierProvider<SelectedDeviceNotifier, String?>((ref) {
  return SelectedDeviceNotifier();
});

/// Auto-select first device when it connects.
/// Clear selection when selected device disconnects.
final autoSelectDeviceProvider = Provider<void>((ref) {
  final devices = ref.watch(connectedDevicesProvider);
  final selected = ref.watch(selectedDeviceProvider);
  final notifier = ref.read(selectedDeviceProvider.notifier);

  // Auto-select when a device connects and nothing is selected
  // (unless user manually unselected — tracked by _manuallyUnselected)
  if (devices.isNotEmpty && selected == null && !notifier.manuallyUnselected) {
    Future.microtask(() {
      notifier.select(devices.first.deviceId);
    });
  }

  // Clear selection if selected device disconnected (not 'all')
  if (selected != null &&
      selected != allDevicesValue &&
      !devices.any((d) => d.deviceId == selected)) {
    Future.microtask(() {
      notifier.clearDisconnected();
    });
  }
});

class ConnectedDevicesNotifier extends StateNotifier<List<DeviceInfo>> {
  late final StreamSubscription<DeviceInfo> _connectSub;
  late final StreamSubscription<String> _disconnectSub;
  final Ref _ref;
  final _recentlyDisconnected = <String>{};

  ConnectedDevicesNotifier(WsMessageHandler handler, this._ref) : super([]) {
    _connectSub = handler.onDeviceConnected.listen((device) {
      final isReconnect = _recentlyDisconnected.remove(device.deviceId);
      final filtered = state.where((d) => d.deviceId != device.deviceId).toList();
      state = [...filtered, device];

      // Clear all data on reconnect (app reload / metro restart)
      if (isReconnect) {
        _clearAllData();
      }
    });
    _disconnectSub = handler.onDeviceDisconnected.listen((deviceId) {
      _recentlyDisconnected.add(deviceId);
      state = state.where((d) => d.deviceId != deviceId).toList();
    });
  }

  void _clearAllData() {
    _ref.read(consoleEntriesProvider.notifier).clear();
    _ref.read(networkEntriesProvider.notifier).clear();
    _ref.read(stateChangesProvider.notifier).clear();
    _ref.read(storageEntriesProvider.notifier).clear();
    _ref.read(displayEntriesProvider.notifier).clear();
    _ref.read(asyncOperationEntriesProvider.notifier).clear();
    _ref.read(performanceEntriesProvider.notifier).clear();
    _ref.read(memoryLeakEntriesProvider.notifier).clear();
    _ref.read(benchmarkEntriesProvider.notifier).clear();
    // Clear selections
    _ref.read(selectedNetworkIdProvider.notifier).state = null;
    _ref.read(selectedStorageIdProvider.notifier).state = null;
    _ref.read(selectedStateChangeIdProvider.notifier).state = null;
  }

  void cancelSubscriptions() {
    _connectSub.cancel();
    _disconnectSub.cancel();
  }
}

class SelectedDeviceNotifier extends StateNotifier<String?> {
  SelectedDeviceNotifier() : super(null);

  /// True when user explicitly clicked to unselect (set null).
  /// Reset when user selects a device or a new device auto-selects.
  bool manuallyUnselected = false;

  void select(String? deviceId) {
    if (deviceId == null) {
      manuallyUnselected = true;
    } else {
      manuallyUnselected = false;
    }
    state = deviceId;
  }

  /// Called when selected device disconnects — not a manual unselect.
  void clearDisconnected() {
    manuallyUnselected = false;
    state = null;
  }
}
