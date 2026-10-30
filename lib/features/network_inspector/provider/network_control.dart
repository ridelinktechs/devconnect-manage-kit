import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/ui/toast_utils.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/network/network_entry.dart';
import '../../../server/providers/server_providers.dart';

/// Network conditions the desktop can impose on the apps' HTTP traffic.
enum NetworkPreset {
  normal(0),
  slow(500),
  slow3g(2000),
  offline(0, isOffline: true);

  final int latencyMs;
  final bool isOffline;
  const NetworkPreset(this.latencyMs, {this.isOffline = false});
}

String networkPresetLabel(S loc, NetworkPreset p) => switch (p) {
  NetworkPreset.normal => loc.networkPresetNormal,
  NetworkPreset.slow => loc.networkPresetSlow,
  NetworkPreset.slow3g => loc.networkPresetSlow3g,
  NetworkPreset.offline => loc.networkPresetOffline,
};

/// The conditions applied to every connected app. Re-sent to a device when
/// it (re)connects, since a reloaded app starts back at normal.
final networkPresetProvider =
    NotifierProvider<NetworkPresetNotifier, NetworkPreset>(
      NetworkPresetNotifier.new,
    );

class NetworkPresetNotifier extends Notifier<NetworkPreset> {
  @override
  NetworkPreset build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onDeviceConnected.listen((device) {
      if (state != NetworkPreset.normal) _apply(device.deviceId, state);
    });
    ref.onDispose(sub.cancel);
    return NetworkPreset.normal;
  }

  void set(NetworkPreset preset) {
    state = preset;
    for (final d in ref.read(connectedDevicesProvider)) {
      _apply(d.deviceId, preset);
    }
  }

  void _apply(String deviceId, NetworkPreset p) => ref
      .read(wsMessageHandlerProvider)
      .setNetworkConditions(
        deviceId,
        latencyMs: p.latencyMs,
        offline: p.isOffline,
      );
}

/// Has the app send [entry]'s request again; it shows up as a new request.
void replayNetworkRequest(
  BuildContext context,
  WidgetRef ref,
  NetworkEntry entry,
) {
  ref.read(wsMessageHandlerProvider).replayRequest(entry);
  showSuccessToast(
    context,
    message: S.of(context).networkReplaySent,
    subtitle: '${entry.method.toUpperCase()} ${entry.url}',
  );
}
