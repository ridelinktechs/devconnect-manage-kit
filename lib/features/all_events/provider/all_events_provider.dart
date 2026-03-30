import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/tab_visibility_provider.dart';
import '../../../core/utils/duration_format.dart';
import '../../../models/display/display_entry.dart';
import '../../../server/providers/server_providers.dart';
import '../../console/provider/console_providers.dart';
import '../../display/provider/display_providers.dart';
import '../../network_inspector/provider/network_providers.dart';
import '../../state_inspector/provider/state_providers.dart';
import '../../storage_viewer/provider/storage_providers.dart';

enum EventType { log, network, state, storage, display, asyncOp }

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

class AllEventsNotifier extends StateNotifier<List<UnifiedEvent>> {
  AllEventsNotifier(Ref ref) : super([]) {
    _enabledTabs = ref.read(tabVisibilityProvider);

    // Track previous lengths/versions to detect incremental changes
    _prevLogLen = 0;
    _prevNetLen = 0;
    _prevStateLen = 0;
    _prevStorageLen = 0;
    _prevDisplayLen = 0;
    _prevAsyncLen = 0;

    // Listen to tab visibility — rebuild affected types on toggle
    ref.listen<Set<TabKey>>(tabVisibilityProvider, (prev, next) {
      final old = prev ?? <TabKey>{};
      _enabledTabs = next;
      // Find which tabs changed
      final toggled = old.difference(next).union(next.difference(old));
      for (final tab in toggled) {
        switch (tab) {
          case TabKey.console:
            _rebuildType(EventType.log, ref);
          case TabKey.network:
            _rebuildType(EventType.network, ref);
          case TabKey.state:
            _rebuildType(EventType.state, ref);
          case TabKey.storage:
            _rebuildType(EventType.storage, ref);
          default:
            break;
        }
      }
    });

    // Listen to each source provider incrementally
    ref.listen(consoleEntriesProvider, (_, next) => _onLogsChanged(next));
    ref.listen(networkEntriesProvider, (_, next) => _onNetworkChanged(next));
    ref.listen(stateChangesProvider, (_, next) => _onStateChanged(next));
    ref.listen(storageEntriesProvider, (_, next) => _onStorageChanged(next));
    ref.listen(displayEntriesProvider, (_, next) => _onDisplayChanged(next));
    ref.listen(asyncOperationEntriesProvider,
        (_, next) => _onAsyncOpsChanged(next));
  }

  late Set<TabKey> _enabledTabs;
  int _prevLogLen = 0;
  int _prevNetLen = 0;
  int _prevStateLen = 0;
  int _prevStorageLen = 0;
  int _prevDisplayLen = 0;
  int _prevAsyncLen = 0;

  // ---- Incremental handlers ----

  void _onLogsChanged(List logs) {
    if (!_enabledTabs.contains(TabKey.console)) {
      _prevLogLen = logs.length;
      return;
    }
    if (logs.length < _prevLogLen) {
      // Cleared — rebuild this type
      _removeType(EventType.log);
      _prevLogLen = 0;
    }
    if (logs.length > _prevLogLen) {
      final newEvents = <UnifiedEvent>[];
      for (var i = _prevLogLen; i < logs.length; i++) {
        final log = logs[i];
        newEvents.add(UnifiedEvent(
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
      _prevLogLen = logs.length;
      _insertSorted(newEvents);
    }
  }

  void _onNetworkChanged(List network) {
    if (!_enabledTabs.contains(TabKey.network)) {
      _prevNetLen = network.length;
      return;
    }
    if (network.length < _prevNetLen) {
      _removeType(EventType.network);
      _prevNetLen = 0;
    }
    if (network.length > _prevNetLen) {
      // New entries appended
      final newEvents = <UnifiedEvent>[];
      for (var i = _prevNetLen; i < network.length; i++) {
        final req = network[i];
        if (_isSystemUrl(req.url)) continue;
        newEvents.add(_networkToEvent(req));
      }
      _prevNetLen = network.length;
      _insertSorted(newEvents);
    } else if (network.length == _prevNetLen && network.isNotEmpty) {
      // Same length — an existing entry was updated (response completed).
      // Update matching unified events in-place.
      _updateNetworkEntries(network);
    }
  }

  void _updateNetworkEntries(List network) {
    // Build id->entry map for quick lookup
    final byId = <String, dynamic>{};
    for (final req in network) {
      byId[req.id] = req;
    }
    var changed = false;
    final updated = List<UnifiedEvent>.from(state);
    for (var i = 0; i < updated.length; i++) {
      final ev = updated[i];
      if (ev.type != EventType.network) continue;
      final req = byId[ev.id];
      if (req == null) continue;
      final newEv = _networkToEvent(req);
      // Only replace if subtitle changed (status/duration update)
      if (newEv.subtitle != ev.subtitle || newEv.level != ev.level) {
        updated[i] = newEv;
        changed = true;
      }
    }
    if (changed) {
      state = updated;
    }
  }

  UnifiedEvent _networkToEvent(dynamic req) {
    return UnifiedEvent(
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
    );
  }

  void _onStateChanged(List stateChanges) {
    if (!_enabledTabs.contains(TabKey.state)) {
      _prevStateLen = stateChanges.length;
      return;
    }
    if (stateChanges.length < _prevStateLen) {
      _removeType(EventType.state);
      _prevStateLen = 0;
    }
    if (stateChanges.length > _prevStateLen) {
      final newEvents = <UnifiedEvent>[];
      for (var i = _prevStateLen; i < stateChanges.length; i++) {
        final sc = stateChanges[i];
        newEvents.add(UnifiedEvent(
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
      _prevStateLen = stateChanges.length;
      _insertSorted(newEvents);
    }
  }

  void _onStorageChanged(List storage) {
    if (!_enabledTabs.contains(TabKey.storage)) {
      _prevStorageLen = storage.length;
      return;
    }
    if (storage.length < _prevStorageLen) {
      _removeType(EventType.storage);
      _prevStorageLen = 0;
    }
    if (storage.length > _prevStorageLen) {
      final newEvents = <UnifiedEvent>[];
      for (var i = _prevStorageLen; i < storage.length; i++) {
        final st = storage[i];
        newEvents.add(UnifiedEvent(
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
      _prevStorageLen = storage.length;
      _insertSorted(newEvents);
    }
  }

  void _onDisplayChanged(List display) {
    // Display entries are always shown (not gated by tabVisibility)
    if (display.length < _prevDisplayLen) {
      _removeType(EventType.display);
      _prevDisplayLen = 0;
    }
    if (display.length > _prevDisplayLen) {
      final newEvents = <UnifiedEvent>[];
      for (var i = _prevDisplayLen; i < display.length; i++) {
        final d = display[i];
        newEvents.add(UnifiedEvent(
          type: EventType.display,
          id: d.id,
          deviceId: d.deviceId,
          timestamp: d.timestamp,
          title: d.name,
          subtitle: d.preview ?? 'custom display',
          level: 'info',
          rawData: d,
        ));
      }
      _prevDisplayLen = display.length;
      _insertSorted(newEvents);
    }
  }

  void _onAsyncOpsChanged(List asyncOps) {
    // Async ops are always shown (not gated by tabVisibility)
    if (asyncOps.length < _prevAsyncLen) {
      _removeType(EventType.asyncOp);
      _prevAsyncLen = 0;
    }
    if (asyncOps.length > _prevAsyncLen) {
      final newEvents = <UnifiedEvent>[];
      for (var i = _prevAsyncLen; i < asyncOps.length; i++) {
        final op = asyncOps[i];
        newEvents.add(UnifiedEvent(
          type: EventType.asyncOp,
          id: op.id,
          deviceId: op.deviceId,
          timestamp: op.timestamp,
          title: op.description,
          subtitle:
              '${op.operationType.name} - ${op.status.name}${op.duration != null ? ' (${formatDuration(op.duration!)})' : ''}',
          level: op.status == AsyncOperationStatus.reject ? 'error' : 'info',
          rawData: op,
        ));
      }
      _prevAsyncLen = asyncOps.length;
      _insertSorted(newEvents);
    }
  }

  // ---- Helpers ----

  /// Remove all events of a given type from state.
  void _removeType(EventType type) {
    state = state.where((e) => e.type != type).toList();
  }

  /// Rebuild all events for a specific type from the current source data.
  void _rebuildType(EventType type, Ref ref) {
    // Remove existing events of this type
    _removeType(type);

    switch (type) {
      case EventType.log:
        _prevLogLen = 0;
        if (_enabledTabs.contains(TabKey.console)) {
          _onLogsChanged(ref.read(consoleEntriesProvider));
        }
      case EventType.network:
        _prevNetLen = 0;
        if (_enabledTabs.contains(TabKey.network)) {
          _onNetworkChanged(ref.read(networkEntriesProvider));
        }
      case EventType.state:
        _prevStateLen = 0;
        if (_enabledTabs.contains(TabKey.state)) {
          _onStateChanged(ref.read(stateChangesProvider));
        }
      case EventType.storage:
        _prevStorageLen = 0;
        if (_enabledTabs.contains(TabKey.storage)) {
          _onStorageChanged(ref.read(storageEntriesProvider));
        }
      case EventType.display:
        _prevDisplayLen = 0;
        _onDisplayChanged(ref.read(displayEntriesProvider));
      case EventType.asyncOp:
        _prevAsyncLen = 0;
        _onAsyncOpsChanged(ref.read(asyncOperationEntriesProvider));
    }
  }

  /// Insert new events into the already-sorted state list.
  void _insertSorted(List<UnifiedEvent> newEvents) {
    if (newEvents.isEmpty) return;
    if (state.isEmpty) {
      newEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      state = newEvents;
      return;
    }
    // Fast path: all new events are newer than the last existing event
    // (common case — events arrive in chronological order)
    final lastTs = state.last.timestamp;
    final allNewer = newEvents.every((e) => e.timestamp >= lastTs);
    if (allNewer) {
      newEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      state = [...state, ...newEvents];
      return;
    }
    // Slow path: merge
    final merged = [...state, ...newEvents];
    merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    state = merged;
  }
}

final allEventsProvider =
    StateNotifierProvider<AllEventsNotifier, List<UnifiedEvent>>((ref) {
  return AllEventsNotifier(ref);
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
