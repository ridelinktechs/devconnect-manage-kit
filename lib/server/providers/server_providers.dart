import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/benchmark/provider/benchmark_providers.dart';
import '../../features/console/provider/console_providers.dart';
import '../../features/device_history/provider/device_history_providers.dart';
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
    NotifierProvider<ConnectedDevicesNotifier, List<DeviceInfo>>(
        ConnectedDevicesNotifier.new);

/// Mirrors connect/disconnect events into the persistent device history.
/// Kept separate from [connectedDevicesProvider] so the in-memory list and
/// the persisted log can evolve independently.
final deviceHistoryMirrorProvider = Provider<void>((ref) {
  final handler = ref.watch(wsMessageHandlerProvider);
  // Use watch (not read) so the mirror re-subscribes if the history
  // notifier is ever recreated (e.g., in tests with provider overrides).
  final history = ref.watch(deviceHistoryProvider.notifier);

  final connectSub = handler.onDeviceConnected.listen(history.onConnected);
  final disconnectSub =
      handler.onDeviceDisconnected.listen(history.onDisconnected);

  ref.onDispose(() {
    connectSub.cancel();
    disconnectSub.cancel();
  });
});

/// null = no selection (show nothing), 'all' = show all, deviceId = filter
const allDevicesValue = '__all__';

final selectedDeviceProvider =
    NotifierProvider<SelectedDeviceNotifier, String?>(
        SelectedDeviceNotifier.new);

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

class ConnectedDevicesNotifier extends Notifier<List<DeviceInfo>> {
  final _recentlyDisconnected = <String>{};

  @override
  List<DeviceInfo> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final connectSub = handler.onDeviceConnected.listen((device) {
      final isReconnect = _recentlyDisconnected.remove(device.deviceId);
      final filtered = state.where((d) => d.deviceId != device.deviceId).toList();
      state = [...filtered, device];

      // Clear all data on reconnect (app reload / metro restart)
      if (isReconnect) {
        _clearAllData();
      }
    });
    final disconnectSub = handler.onDeviceDisconnected.listen((deviceId) {
      _recentlyDisconnected.add(deviceId);
      state = state.where((d) => d.deviceId != deviceId).toList();
    });
    ref.onDispose(() {
      connectSub.cancel();
      disconnectSub.cancel();
    });
    return [];
  }

  void _clearAllData() {
    ref.read(consoleEntriesProvider.notifier).clear();
    ref.read(networkEntriesProvider.notifier).clear();
    ref.read(stateChangesProvider.notifier).clear();
    ref.read(storageEntriesProvider.notifier).clear();
    ref.read(displayEntriesProvider.notifier).clear();
    ref.read(asyncOperationEntriesProvider.notifier).clear();
    ref.read(performanceEntriesProvider.notifier).clear();
    ref.read(memoryLeakEntriesProvider.notifier).clear();
    ref.read(benchmarkEntriesProvider.notifier).clear();
    // Clear selections
    ref.read(selectedNetworkIdProvider.notifier).set(null);
    ref.read(selectedStorageIdProvider.notifier).set(null);
    ref.read(selectedStateChangeIdProvider.notifier).set(null);
  }

  /// Public reset — exposed so the Settings "Clear All Cache" button can wipe
  /// every in-memory log/state/selection without disconnecting devices itself
  /// (the caller is responsible for stopping the server first if needed).
  void clearAllData() => _clearAllData();
}

class SelectedDeviceNotifier extends Notifier<String?> {
  /// True when user explicitly clicked to unselect (set null).
  /// Reset when user selects a device or a new device auto-selects.
  bool manuallyUnselected = false;

  @override
  String? build() => null;

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