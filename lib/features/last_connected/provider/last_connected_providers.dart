import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/device_info.dart';
import '../../../models/disconnected_session.dart';
import '../../../server/providers/server_providers.dart';
import '../../console/provider/console_providers.dart';
import '../../network_inspector/provider/network_providers.dart';
import '../../state_inspector/provider/state_providers.dart';
import '../../storage_viewer/provider/storage_providers.dart';

/// Timeout before considering a device permanently disconnected.
/// If device reconnects within this window, it's treated as a reload.
const _disconnectTimeout = Duration(seconds: 15);

final lastConnectedProvider =
    NotifierProvider<LastConnectedNotifier, List<DisconnectedSession>>(
        LastConnectedNotifier.new);

class LastConnectedNotifier extends Notifier<List<DisconnectedSession>> {
  final Map<String, Timer> _pendingTimers = {};
  final Map<String, DeviceInfo> _pendingDevices = {};

  @override
  List<DisconnectedSession> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final connectSub = handler.onDeviceConnected.listen(_onDeviceConnected);
    final disconnectSub =
        handler.onDeviceDisconnected.listen(_onDeviceDisconnected);
    ref.onDispose(() {
      connectSub.cancel();
      disconnectSub.cancel();
      for (final timer in _pendingTimers.values) {
        timer.cancel();
      }
      _pendingTimers.clear();
    });
    return [];
  }

  void _onDeviceConnected(DeviceInfo device) {
    // Device reconnected within timeout window → cancel pending save (it's a reload)
    final timer = _pendingTimers.remove(device.deviceId);
    if (timer != null) {
      timer.cancel();
      _pendingDevices.remove(device.deviceId);
    }

    // Remove from saved sessions if same deviceId reconnects
    // OR same clientIp reconnects (cross-platform: exit Flutter → back to RN)
    state = state.where((s) {
      if (s.deviceInfo.deviceId == device.deviceId) {
        return false;
      }
      if (device.clientIp != null &&
          s.clientIp != null &&
          s.clientIp == device.clientIp) {
        return false;
      }
      return true;
    }).toList();
  }

  void _onDeviceDisconnected(String deviceId) {
    // Snapshot device info before it's removed from connected list
    final devices = ref.read(connectedDevicesProvider);
    final device = devices.where((d) => d.deviceId == deviceId).firstOrNull;
    if (device == null) return;

    _pendingDevices[deviceId] = device;

    // Start timer — if device doesn't reconnect within timeout, save session
    _pendingTimers[deviceId]?.cancel();
    _pendingTimers[deviceId] = Timer(_disconnectTimeout, () {
      _saveSession(deviceId);
      _pendingTimers.remove(deviceId);
      _pendingDevices.remove(deviceId);
    });
  }

  void _saveSession(String deviceId) {
    final device = _pendingDevices[deviceId];
    if (device == null) return;

    // Snapshot all events for this device
    final logs = ref.read(consoleEntriesProvider);
    final network = ref.read(networkEntriesProvider);
    final stateChanges = ref.read(stateChangesProvider);
    final storage = ref.read(storageEntriesProvider);

    final session = DisconnectedSession(
      deviceInfo: device,
      disconnectedAt: DateTime.now(),
      logs: logs.where((e) => e.deviceId == deviceId).toList(),
      networkEntries: network.where((e) => e.deviceId == deviceId).toList(),
      stateChanges:
          stateChanges.where((e) => e.deviceId == deviceId).toList(),
      storageEntries:
          storage.where((e) => e.deviceId == deviceId).toList(),
      clientIp: device.clientIp,
    );

    // Only save if there was actual data
    if (session.totalEvents > 0) {
      state = [...state, session];
    }
  }

  void clearAll() {
    for (final timer in _pendingTimers.values) {
      timer.cancel();
    }
    _pendingTimers.clear();
    _pendingDevices.clear();
    state = [];
  }

  void removeSession(String deviceId) {
    state = state
        .where((s) => s.deviceInfo.deviceId != deviceId)
        .toList();
  }
}