import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/network/network_entry.dart';
import '../../../server/providers/server_providers.dart';
import '../../../server/ws_message_handler.dart';

final networkEntriesProvider =
    StateNotifierProvider<NetworkNotifier, List<NetworkEntry>>((ref) {
  final handler = ref.watch(wsMessageHandlerProvider);
  final notifier = NetworkNotifier(handler);
  ref.onDispose(() => notifier.cancelSubscription());
  return notifier;
});

final networkSearchProvider = StateProvider<String>((ref) => '');
final networkMethodFilterProvider = StateProvider<String?>((ref) => null);
final networkSourceFilterProvider =
    StateProvider<Set<String>>((ref) => {'app', 'library', 'system'});

/// System URLs to hide by default (connectivity checks, captive portal, etc.)
const _systemUrlPatterns = [
  'generate_204',
  'connectivitycheck',
  'captive.apple.com',
  'msftconnecttest',
  'gstatic.com/generate_204',
  'clients3.google.com',
  'detectportal',
  'nmcheck',
];

bool _isSystemUrl(String url) {
  final lower = url.toLowerCase();
  return _systemUrlPatterns.any((p) => lower.contains(p));
}

final filteredNetworkEntriesProvider = Provider<List<NetworkEntry>>((ref) {
  final entries = ref.watch(networkEntriesProvider);
  final search = ref.watch(networkSearchProvider).toLowerCase();
  final methodFilter = ref.watch(networkMethodFilterProvider);
  final selectedDevice = ref.watch(selectedDeviceProvider);
  final sourceFilter = ref.watch(networkSourceFilterProvider);

  return entries.where((e) {
    if (selectedDevice == null) return false;
    if (selectedDevice != allDevicesValue && e.deviceId != selectedDevice) return false;
    if (methodFilter != null && e.method.toUpperCase() != methodFilter) {
      return false;
    }
    if (!sourceFilter.contains(e.source)) return false;
    // Hide system/connectivity check URLs unless searching for them
    if (search.isEmpty && _isSystemUrl(e.url)) return false;
    if (search.isNotEmpty) {
      return e.url.toLowerCase().contains(search);
    }
    return true;
  }).toList();
});

/// Stores the selected entry ID (not the object — object goes stale on update).
final selectedNetworkIdProvider = StateProvider<String?>((ref) => null);

/// Always returns the latest entry object from the list for the selected ID.
final selectedNetworkEntryProvider = Provider<NetworkEntry?>((ref) {
  final id = ref.watch(selectedNetworkIdProvider);
  if (id == null) return null;
  final entries = ref.watch(networkEntriesProvider);
  return entries.where((e) => e.id == id).firstOrNull;
});

class NetworkNotifier extends StateNotifier<List<NetworkEntry>> {
  late final StreamSubscription<NetworkEntry> _sub;

  NetworkNotifier(WsMessageHandler wsMessageHandler) : super([]) {
    _sub = wsMessageHandler.onNetwork.listen((entry) {
      // Update existing or add new
      final index = state.indexWhere((e) => e.id == entry.id);
      if (index >= 0) {
        final updated = List<NetworkEntry>.from(state);
        updated[index] = entry;
        state = updated;
      } else {
        if (state.length > 5000) {
          state = [...state.skip(500), entry];
        } else {
          state = [...state, entry];
        }
      }
    });
  }

  void cancelSubscription() => _sub.cancel();

  void clear() => state = [];
}
