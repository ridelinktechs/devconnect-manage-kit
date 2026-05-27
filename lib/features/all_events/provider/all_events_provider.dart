import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/tab_visibility_provider.dart';
import '../../../core/utils/duration_format.dart';
import '../../../models/display/display_entry.dart';
import '../../../models/log/error_event.dart';
import '../../../server/providers/server_providers.dart';
import '../../console/provider/console_providers.dart';
import '../../display/provider/display_providers.dart';
import '../../error_inspector/provider/error_providers.dart';
import '../../network_inspector/provider/network_providers.dart';
import '../../state_inspector/provider/state_providers.dart';
import '../../storage_viewer/provider/storage_providers.dart';

enum EventType { log, network, state, storage, display, asyncOp, error }

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

/// Cache to reuse UnifiedEvent objects when source data hasn't changed.
final _eventCache = <String, UnifiedEvent>{};

UnifiedEvent _cached(String id, dynamic rawData, UnifiedEvent Function() create) {
  final cached = _eventCache[id];
  if (cached != null && identical(cached.rawData, rawData)) return cached;
  final ev = create();
  _eventCache[id] = ev;
  return ev;
}

final allEventsProvider = Provider<List<UnifiedEvent>>((ref) {
  final enabledTabs = ref.watch(tabVisibilityProvider);
  final logs = ref.watch(consoleEntriesProvider);
  final network = ref.watch(networkEntriesProvider);
  final stateChanges = ref.watch(stateChangesProvider);
  final storage = ref.watch(storageEntriesProvider);
  final display = ref.watch(displayEntriesProvider);
  final asyncOps = ref.watch(asyncOperationEntriesProvider);

  final events = <UnifiedEvent>[];
  final usedIds = <String>{};

  if (enabledTabs.contains(TabKey.console)) {
    for (final log in logs) {
      events.add(_cached(log.id, log, () => UnifiedEvent(
        type: EventType.log,
        id: log.id,
        deviceId: log.deviceId,
        timestamp: log.timestamp,
        title: log.message,
        subtitle: log.tag ?? 'log',
        level: log.level.name,
        rawData: log,
      )));
      usedIds.add(log.id);
    }
  }

  if (enabledTabs.contains(TabKey.network)) {
    for (final req in network) {
      if (_isSystemUrl(req.url)) continue;
      events.add(_cached(req.id, req, () => UnifiedEvent(
        type: EventType.network,
        id: req.id,
        deviceId: req.deviceId,
        timestamp: req.startTime,
        title: '${req.method} ${_shortenUrl(req.url)}',
        subtitle: req.isComplete
            ? '${req.statusCode} - ${formatDuration(req.duration ?? 0)}'
            : 'in progress',
        level: req.isComplete
            ? (req.statusCode <= 0 || req.statusCode >= 400 ? 'error' : 'info')
            : 'debug',
        rawData: req,
      )));
      usedIds.add(req.id);
    }
  }

  if (enabledTabs.contains(TabKey.state)) {
    for (final sc in stateChanges) {
      events.add(_cached(sc.id, sc, () => UnifiedEvent(
        type: EventType.state,
        id: sc.id,
        deviceId: sc.deviceId,
        timestamp: sc.timestamp,
        title: sc.actionName,
        subtitle: '${sc.stateManagerType} - ${sc.diff.length} changes',
        level: 'info',
        rawData: sc,
      )));
      usedIds.add(sc.id);
    }
  }

  if (enabledTabs.contains(TabKey.storage)) {
    for (final st in storage) {
      events.add(_cached(st.id, st, () => UnifiedEvent(
        type: EventType.storage,
        id: st.id,
        deviceId: st.deviceId,
        timestamp: st.timestamp,
        title: '${st.operation.toUpperCase()} ${st.key}',
        subtitle: st.storageType.name,
        level: st.operation == 'delete' ? 'warn' : 'info',
        rawData: st,
      )));
      usedIds.add(st.id);
    }
  }

  for (final d in display) {
    events.add(_cached(d.id, d, () => UnifiedEvent(
      type: EventType.display,
      id: d.id,
      deviceId: d.deviceId,
      timestamp: d.timestamp,
      title: d.name,
      subtitle: d.preview ?? 'custom display',
      level: 'info',
      rawData: d,
    )));
    usedIds.add(d.id);
  }

  for (final op in asyncOps) {
    events.add(_cached(op.id, op, () => UnifiedEvent(
      type: EventType.asyncOp,
      id: op.id,
      deviceId: op.deviceId,
      timestamp: op.timestamp,
      title: op.description,
      subtitle:
          '${op.operationType.name} - ${op.status.name}${op.duration != null ? ' (${formatDuration(op.duration!)})' : ''}',
      level: op.status == AsyncOperationStatus.reject ? 'error' : 'info',
      rawData: op,
    )));
    usedIds.add(op.id);
  }

  // Error events
  if (enabledTabs.contains(TabKey.error)) {
    final errors = ref.watch(errorEntriesProvider);
    for (final err in errors) {
      final level = switch (err.severity) {
        ErrorSeverity.fatal => 'error',
        ErrorSeverity.crash => 'error',
        ErrorSeverity.error => 'error',
        ErrorSeverity.warning => 'warn',
        ErrorSeverity.info => 'info',
      };
      events.add(_cached(err.id, err, () => UnifiedEvent(
        type: EventType.error,
        id: err.id,
        deviceId: err.deviceId,
        platform: err.platform.name,
        timestamp: err.timestamp,
        title: err.message,
        subtitle: '${err.source ?? err.platform.name} - ${err.deviceInfo ?? ''}',
        level: level,
        rawData: err,
      )));
      usedIds.add(err.id);
    }
  }

  // Clean stale cache entries
  if (usedIds.isEmpty) {
    _eventCache.clear();
  } else if (_eventCache.length > usedIds.length + 100) {
    _eventCache.removeWhere((id, _) => !usedIds.contains(id));
  }

  events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return events;
});

final allEventsSearchProvider = StateProvider<String>((ref) => '');
final allEventsFilterProvider = StateProvider<Set<EventType>>(
  (ref) => EventType.values.toSet(),
);

enum SortOrder { newestFirst, oldestFirst }

final allEventsSortOrderProvider = StateProvider<SortOrder>(
  (ref) => SortOrder.oldestFirst,
);

/// Whether to show system/connectivity check URLs
final showSystemUrlsProvider = StateProvider<bool>((ref) => false);

final filteredAllEventsProvider = Provider<List<UnifiedEvent>>((ref) {
  final events = ref.watch(allEventsProvider);
  final search = ref.watch(allEventsSearchProvider).toLowerCase();
  final filters = ref.watch(allEventsFilterProvider);
  final selectedDevice = ref.watch(selectedDeviceProvider);

  return events.where((e) {
    if (selectedDevice == null) return false;
    if (selectedDevice != allDevicesValue && e.deviceId != selectedDevice) return false;
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
