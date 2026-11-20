import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/retention_provider.dart';
import '../../../core/utils/collections/list_retention.dart';
import '../../../core/utils/collections/retention_capped.dart';
import '../../../models/state/state_change.dart';
import '../../../server/providers/server_providers.dart';

final stateChangesProvider =
    NotifierProvider<StateChangesNotifier, List<StateChange>>(
        StateChangesNotifier.new);

/// Total state changes ever received by [StateChangesNotifier],
/// including ones dropped by the retention cap.
///
/// Watches [stateChangesProvider] (not just the notifier) so this
/// rebuilds every time a new entry is appended — the notifier's
/// [StateChangesNotifier.totalSeen] getter is otherwise non-reactive.
final stateChangesTotalSeenProvider = Provider<int>((ref) {
  ref.watch(stateChangesProvider); // subscribe to state changes
  return ref.read(stateChangesProvider.notifier).totalSeen;
});

/// Source-cached list (capped to the user's retention limit) plus the
/// lifetime total (including dropped entries).
final stateChangesDisplayProvider =
    Provider<RetentionCapped<StateChange>>((ref) {
  final all = ref.watch(stateChangesProvider);
  final limit = ref.watch(retentionLimitProvider.select((p) => p.limit));
  final totalSeen = ref.watch(stateChangesTotalSeenProvider);
  return applyRetentionCap(all, limit, totalSeen: totalSeen);
});

final selectedStateChangeIdProvider =
    NotifierProvider<_SelectedStateChangeIdNotifier, String?>(
  _SelectedStateChangeIdNotifier.new,
);

class _SelectedStateChangeIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? v) => state = v;
}

final selectedStateChangeProvider = Provider<StateChange?>((ref) {
  final id = ref.watch(selectedStateChangeIdProvider);
  if (id == null) return null;
  final entries = ref.watch(stateChangesProvider);
  return entries.where((e) => e.id == id).firstOrNull;
});

final stateSearchProvider =
    NotifierProvider<_StateSearchNotifier, String>(
  _StateSearchNotifier.new,
);

class _StateSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String v) => state = v;
}

/// The family of a reported `stateManager` as a filter key: `zustand:cart`
/// gives `zustand`, `ReactQuery::todos` gives `reactquery`.
String stateManagerKey(String type) {
  final cut = type.indexOf(':');
  final family = cut < 0 ? type : type.substring(0, cut);
  final key = family.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-.]'), '');
  return key.isEmpty ? 'unknown' : key;
}

/// State library families hidden from the timeline, by [stateManagerKey].
final stateHiddenManagersProvider =
    NotifierProvider<_StateHiddenManagersNotifier, Set<String>>(
  _StateHiddenManagersNotifier.new,
);

class _StateHiddenManagersNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String key) => state =
      state.contains(key) ? ({...state}..remove(key)) : {...state, key};
}

/// The families in [stateSearchedChangesProvider], in the order they first
/// appear: a `stateManager` that names it and how many changes it has.
final stateManagerCountsProvider =
    Provider<List<({String key, String type, int count})>>((ref) {
  final counts = <String, ({String key, String type, int count})>{};
  for (final e in ref.watch(stateSearchedChangesProvider)) {
    final key = stateManagerKey(e.stateManagerType);
    final seen = counts[key];
    counts[key] = (
      key: key,
      type: seen?.type ?? e.stateManagerType,
      count: (seen?.count ?? 0) + 1,
    );
  }
  return counts.values.toList();
});

final filteredStateChangesProvider = Provider<List<StateChange>>((ref) {
  final hidden = ref.watch(stateHiddenManagersProvider);
  final entries = ref.watch(stateSearchedChangesProvider);
  if (hidden.isEmpty) return entries;
  return entries
      .where((e) => !hidden.contains(stateManagerKey(e.stateManagerType)))
      .toList();
});

/// The picked device's changes that match the search, before the family
/// filter.
final stateSearchedChangesProvider = Provider<List<StateChange>>((ref) {
  final entries = ref.watch(stateChangesDisplayProvider).items;
  final search = ref.watch(stateSearchProvider).toLowerCase();
  final selectedDevice = ref.watch(selectedDeviceProvider);

  return entries.where((e) {
    if (selectedDevice == null) return false;
    if (selectedDevice != allDevicesValue && e.deviceId != selectedDevice) return false;
    if (search.isNotEmpty) {
      return e.actionName.toLowerCase().contains(search) ||
          e.stateManagerType.toLowerCase().contains(search);
    }
    return true;
  }).toList();
});

class StateChangesNotifier extends Notifier<List<StateChange>> {
  /// Total state changes ever received, including ones dropped by the cap.
  int _totalSeen = 0;
  int get totalSeen => _totalSeen;

  @override
  List<StateChange> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onState.listen((entry) {
      final limit = ref.read(retentionLimitProvider).limit ?? kRetentionSafetyCap;
      state = truncateList([...state, entry], limit);
      _totalSeen++;
    });
    ref.onDispose(() => sub.cancel());
    return [];
  }

  void clear() => state = [];
}