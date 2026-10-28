import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../../models/device_info.dart';
import '../../server/providers/server_providers.dart';
import 'toast_utils.dart';

/// One reload flavour, labelled for the devices it targets. [hotRestart]
/// picks the wire message: `server:hot_restart` instead of `server:reload`.
typedef ReloadAction = ({IconData icon, String label, bool hotRestart});

/// Reload buttons for [devices]: Flutter gets hot reload + hot restart,
/// React Native a Metro reload, Android a restart (`Activity.recreate()`
/// resets state, it doesn't rebuild the APK); a mix of platforms a single
/// universal reload.
List<ReloadAction> reloadActionsFor(List<DeviceInfo> devices, S loc) {
  if (devices.isEmpty) return const [];
  final platforms = {
    for (final d in devices)
      switch (d.platform.toLowerCase()) {
        'react_native' || 'reactnative' || 'rn' => 'react_native',
        final p => p,
      },
  };
  return switch (platforms.length == 1 ? platforms.single : null) {
    'flutter' => [
      (icon: LucideIcons.zap, label: loc.reloadAppHotReload, hotRestart: false),
      (
        icon: LucideIcons.refreshCcw,
        label: loc.reloadAppHotRestart,
        hotRestart: true,
      ),
    ],
    'react_native' => [
      (icon: LucideIcons.rocket, label: loc.reloadAppMetro, hotRestart: false),
    ],
    'android' => [
      (
        icon: LucideIcons.refreshCcw,
        label: loc.reloadAppHotRestart,
        hotRestart: false,
      ),
    ],
    _ => [(icon: LucideIcons.zap, label: loc.reloadApp, hotRestart: false)],
  };
}

/// Devices a reload applies to: the selected one, else every connected one.
List<DeviceInfo> reloadTargets(WidgetRef ref) {
  final devices = ref.read(connectedDevicesProvider);
  final selectedId = ref.read(selectedDeviceProvider);
  final selected = devices.where((d) => d.deviceId == selectedId).toList();
  return selected.isNotEmpty ? selected : devices;
}

/// Asks [reloadTargets] to reload (or hot restart) and toasts the outcome.
void reloadApps(
  BuildContext context,
  WidgetRef ref, {
  bool hotRestart = false,
}) {
  final loc = S.of(context);
  final targets = reloadTargets(ref);
  if (targets.isEmpty) {
    showInfoToast(
      context,
      message: hotRestart ? loc.reloadAppHotRestart : loc.reloadApp,
      subtitle: loc.reloadAppNoDevices,
    );
    return;
  }
  final handler = ref.read(wsMessageHandlerProvider);
  for (final d in targets) {
    hotRestart
        ? handler.triggerHotRestart(d.deviceId)
        : handler.triggerReload(d.deviceId);
  }
  showSuccessToast(
    context,
    message: loc.reloadSent,
    subtitle: loc.sentReloadTo(targets.length),
  );
}

/// ⌘R / Ctrl+R reloads, adding ⇧ hot restarts.
bool isReloadShortcut(KeyEvent event, {required bool hotRestart}) {
  final keyboard = HardwareKeyboard.instance;
  return event is KeyDownEvent &&
      event.logicalKey == LogicalKeyboardKey.keyR &&
      (Platform.isMacOS ? keyboard.isMetaPressed : keyboard.isControlPressed) &&
      keyboard.isShiftPressed == hotRestart &&
      !keyboard.isAltPressed;
}

/// "⌘R" / "Ctrl+R" (with ⇧ / Shift+ for hot restart), for tooltips.
String reloadShortcutLabel({required bool hotRestart}) => Platform.isMacOS
    ? (hotRestart ? '⇧⌘R' : '⌘R')
    : (hotRestart ? 'Ctrl+Shift+R' : 'Ctrl+R');
