import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/device_info.dart';
import '../ws_message_handler.dart';
import '../ws_server.dart';

final wsServerProvider = Provider<WsServer>((ref) {
  final server = WsServer();
  ref.onDispose(() => server.dispose());
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
  final notifier = ConnectedDevicesNotifier(handler);
  ref.onDispose(() => notifier.cancelSubscriptions());
  return notifier;
});

/// null = show all devices, non-null = filter by this deviceId
final selectedDeviceProvider =
    StateNotifierProvider<SelectedDeviceNotifier, String?>((ref) {
  // Auto-select first device when it connects
  final devices = ref.watch(connectedDevicesProvider);
  final notifier = SelectedDeviceNotifier();
  if (devices.length == 1) {
    notifier.select(devices.first.deviceId);
  }
  return notifier;
});

class ConnectedDevicesNotifier extends StateNotifier<List<DeviceInfo>> {
  late final StreamSubscription<DeviceInfo> _connectSub;
  late final StreamSubscription<String> _disconnectSub;

  ConnectedDevicesNotifier(WsMessageHandler handler) : super([]) {
    _connectSub = handler.onDeviceConnected.listen((device) {
      state = [...state, device];
    });
    _disconnectSub = handler.onDeviceDisconnected.listen((deviceId) {
      state = state.where((d) => d.deviceId != deviceId).toList();
    });
  }

  void cancelSubscriptions() {
    _connectSub.cancel();
    _disconnectSub.cancel();
  }
}

class SelectedDeviceNotifier extends StateNotifier<String?> {
  SelectedDeviceNotifier() : super(null);

  void select(String? deviceId) => state = deviceId;
}
