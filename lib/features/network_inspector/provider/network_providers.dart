import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/retention_provider.dart';
import '../../../core/utils/list_retention.dart';
import '../../../core/utils/retention_capped.dart';
import '../../../models/network/network_entry.dart';
import '../../../server/providers/server_providers.dart';
import '../../../server/ws_message_handler.dart';

final networkEntriesProvider =
    StateNotifierProvider<NetworkNotifier, List<NetworkEntry>>((ref) {
  final handler = ref.watch(wsMessageHandlerProvider);
  final notifier = NetworkNotifier(handler, ref);
  ref.onDispose(() => notifier.cancelSubscription());
  return notifier;
});

/// Total entries ever received by [NetworkNotifier], including ones
/// dropped by the retention cap. Toolbars consume this so they can
/// surface a "Showing N of M" hint when entries were dropped.
///
/// Watches [networkEntriesProvider] (not just the notifier) so this
/// rebuilds every time a new entry is appended — the notifier's
/// [NetworkNotifier.totalSeen] getter is otherwise non-reactive.
final networkTotalSeenProvider = Provider<int>((ref) {
  ref.watch(networkEntriesProvider); // subscribe to state changes
  return ref.read(networkEntriesProvider.notifier).totalSeen;
});

/// Source-cached list (capped to the user's retention limit) plus the
/// lifetime total (including dropped entries). Toolbars consume this
/// so they can surface a "Showing N of M" hint when entries were
/// dropped by the cap.
final networkDisplayProvider =
    Provider<RetentionCapped<NetworkEntry>>((ref) {
  final all = ref.watch(networkEntriesProvider);
  final limit = ref.watch(retentionLimitProvider.select((p) => p.limit));
  final totalSeen = ref.watch(networkTotalSeenProvider);
  return applyRetentionCap(all, limit, totalSeen: totalSeen);
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
  final entries = ref.watch(networkDisplayProvider).items;
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

/// Check if a response body is a real parsed value (not a blob placeholder).
bool _isBetterBody(dynamic body) {
  if (body == null) return false;
  if (body is Map || body is List) return true;
  if (body is String && !body.startsWith('<blob')) return true;
  return false;
}

/// Merge two duplicate network entries, preferring the one with better data.
NetworkEntry _mergeNetworkEntries(NetworkEntry existing, NetworkEntry incoming) {
  final useExistingBody = _isBetterBody(existing.responseBody);
  final useIncomingBody = _isBetterBody(incoming.responseBody);

  final bestBody = useIncomingBody
      ? incoming.responseBody
      : (useExistingBody ? existing.responseBody : incoming.responseBody);

  final bestRequestBody = _isBetterBody(incoming.requestBody)
      ? incoming.requestBody
      : existing.requestBody;

  final bestStatusCode = incoming.statusCode != 0 ? incoming.statusCode : existing.statusCode;
  final bestError = incoming.error ?? existing.error;
  final bestIsComplete = incoming.isComplete || existing.isComplete;
  final bestEndTime = incoming.endTime ?? existing.endTime;
  final bestDuration = incoming.duration ?? existing.duration;

  final mergedReqHeaders = {...existing.requestHeaders, ...incoming.requestHeaders};
  final mergedResHeaders = {...existing.responseHeaders, ...incoming.responseHeaders};

  return existing.copyWith(
    statusCode: bestStatusCode,
    requestHeaders: mergedReqHeaders,
    responseHeaders: mergedResHeaders,
    requestBody: bestRequestBody,
    responseBody: bestBody,
    endTime: bestEndTime,
    duration: bestDuration,
    error: bestError,
    isComplete: bestIsComplete,
  );
}

/// Requests that have been pending (no response) for longer than this
/// are considered stale — usually the client app crashed, the network
/// dropped, or the server never got a complete message. The toolbar
/// surfaces a "Clear stale (N)" button so users can prune them.
const Duration kStaleRequestThreshold = Duration(minutes: 10);

class NetworkNotifier extends StateNotifier<List<NetworkEntry>> {
  late final StreamSubscription<NetworkEntry> _sub;
  final Ref _ref;

  /// Total entries ever received, including ones dropped by the cap.
  /// Used by the toolbar to surface a "Showing N of M" hint when the
  /// cap has trimmed older entries.
  int _totalSeen = 0;
  int get totalSeen => _totalSeen;

  NetworkNotifier(WsMessageHandler wsMessageHandler, this._ref) : super([]) {
    _sub = wsMessageHandler.onNetwork.listen((entry) {
      if (entry.method.toUpperCase() == 'OPTIONS') return;
      if (entry.method.toUpperCase() == 'HEAD' && !entry.isComplete) return;
      // Server guarantees unique ids, so a row always represents one
      // logical request — update if seen before, otherwise append.
      final index = state.indexWhere((e) => e.id == entry.id);
      if (index >= 0) {
        final updated = List<NetworkEntry>.from(state);
        // Prefer the richer of the two rows — keeps completed data if
        // we already have a partial one (start → complete round-trip).
        updated[index] = _mergeNetworkEntries(state[index], entry);
        state = updated;
      } else {
        final limit = _ref.read(retentionLimitProvider).limit;
        state = truncateList([...state, entry], limit);
        _totalSeen++;
      }
    });
  }

  void cancelSubscription() => _sub.cancel();

  void clear() => state = [];

  /// Count entries still waiting for a response after the stale threshold.
  /// These usually mean the client crashed before sending a complete, or
  /// the network died mid-flight.
  int countStale({DateTime? now}) {
    final cutoff = (now ?? DateTime.now())
        .subtract(kStaleRequestThreshold)
        .millisecondsSinceEpoch;
    return state.where((e) => !e.isComplete && e.startTime < cutoff).length;
  }

  /// Drop every stale entry. Returns how many rows were removed so the
  /// UI can show a confirmation toast.
  int clearStale({DateTime? now}) {
    final cutoff = (now ?? DateTime.now())
        .subtract(kStaleRequestThreshold)
        .millisecondsSinceEpoch;
    final before = state.length;
    state = state
        .where((e) => e.isComplete || e.startTime >= cutoff)
        .toList(growable: false);
    return before - state.length;
  }
}

/// Live count of stale (unanswered > 10min) network entries. Drives the
/// "Clear stale (N)" button visibility on the network toolbar.
final staleNetworkCountProvider = Provider<int>((ref) {
  final entries = ref.watch(networkEntriesProvider);
  final cutoff = DateTime.now()
      .subtract(kStaleRequestThreshold)
      .millisecondsSinceEpoch;
  return entries.where((e) => !e.isComplete && e.startTime < cutoff).length;
});
