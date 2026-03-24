import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../server/providers/server_providers.dart';
import '../../console/provider/console_providers.dart';
import '../../network_inspector/provider/network_providers.dart';
import '../../state_inspector/provider/state_providers.dart';
import '../../storage_viewer/provider/storage_providers.dart';

enum EventType { log, network, state, storage }

class UnifiedEvent {
  final EventType type;
  final String id;
  final String deviceId;
  final String platform;
  final int timestamp;
  final String title;
  final String subtitle;
  final String level;
  final dynamic rawData;

  UnifiedEvent({
    required this.type,
    required this.id,
    required this.deviceId,
    this.platform = '',
    required this.timestamp,
    required this.title,
    required this.subtitle,
    this.level = 'info',
    this.rawData,
  });
}

/// System URLs that should be filtered out (connectivity checks, etc.)
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

final allEventsProvider = Provider<List<UnifiedEvent>>((ref) {
  final logs = ref.watch(consoleEntriesProvider);
  final network = ref.watch(networkEntriesProvider);
  final stateChanges = ref.watch(stateChangesProvider);
  final storage = ref.watch(storageEntriesProvider);

  final events = <UnifiedEvent>[];

  for (final log in logs) {
    events.add(UnifiedEvent(
      type: EventType.log,
      id: log.id,
      deviceId: log.deviceId,
      timestamp: log.timestamp,
      title: log.message,
      subtitle: log.tag ?? 'log',
      level: log.level.name,
      rawData: log,
    ));
  }

  for (final req in network) {
    // Filter out system/connectivity check URLs
    if (_isSystemUrl(req.url)) continue;

    events.add(UnifiedEvent(
      type: EventType.network,
      id: req.id,
      deviceId: req.deviceId,
      timestamp: req.startTime,
      title: '${req.method} ${_shortenUrl(req.url)}',
      subtitle: req.isComplete
          ? '${req.statusCode} - ${req.duration ?? 0}ms'
          : 'pending...',
      level: req.isComplete
          ? (req.statusCode >= 400 ? 'error' : 'info')
          : 'debug',
      rawData: req,
    ));
  }

  for (final sc in stateChanges) {
    events.add(UnifiedEvent(
      type: EventType.state,
      id: sc.id,
      deviceId: sc.deviceId,
      timestamp: sc.timestamp,
      title: sc.actionName,
      subtitle: '${sc.stateManagerType} - ${sc.diff.length} changes',
      level: 'info',
      rawData: sc,
    ));
  }

  for (final st in storage) {
    events.add(UnifiedEvent(
      type: EventType.storage,
      id: st.id,
      deviceId: st.deviceId,
      timestamp: st.timestamp,
      title: '${st.operation.toUpperCase()} ${st.key}',
      subtitle: st.storageType.name,
      level: st.operation == 'delete' ? 'warn' : 'info',
      rawData: st,
    ));
  }

  events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return events;
});

final allEventsSearchProvider = StateProvider<String>((ref) => '');
final allEventsFilterProvider = StateProvider<Set<EventType>>(
  (ref) => EventType.values.toSet(),
);

/// Whether to show system/connectivity check URLs
final showSystemUrlsProvider = StateProvider<bool>((ref) => false);

final filteredAllEventsProvider = Provider<List<UnifiedEvent>>((ref) {
  final events = ref.watch(allEventsProvider);
  final search = ref.watch(allEventsSearchProvider).toLowerCase();
  final filters = ref.watch(allEventsFilterProvider);
  final selectedDevice = ref.watch(selectedDeviceProvider);

  return events.where((e) {
    if (selectedDevice != null && e.deviceId != selectedDevice) return false;
    if (!filters.contains(e.type)) return false;
    if (search.isNotEmpty) {
      return e.title.toLowerCase().contains(search) ||
          e.subtitle.toLowerCase().contains(search);
    }
    return true;
  }).toList();
});

String _shortenUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.path;
  } catch (_) {
    return url;
  }
}
