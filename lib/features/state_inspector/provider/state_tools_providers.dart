import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/app_preferences.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/state/state_change.dart';
import '../../../server/providers/server_providers.dart';
import 'state_providers.dart';

/// What [valueAtPath] returns for a path that isn't in the state — `null`
/// is a real value.
const stateMissing = Object();

/// Value at [path] in [root]: `auth.user.name`, `items[0].price` or
/// `items.0.price`. [stateMissing] when a step doesn't exist.
Object? valueAtPath(Object? root, String path) {
  Object? node = root;
  for (final m in RegExp(r'[^.\[\]\s]+').allMatches(path)) {
    final step = m[0]!;
    final index = int.tryParse(step);
    if (node is Map && node.containsKey(step)) {
      node = node[step];
    } else if (node is List &&
        index != null &&
        index >= 0 &&
        index < node.length) {
      node = node[index];
    } else {
      return stateMissing;
    }
  }
  return node;
}

/// The state [deviceId]'s app reported last (`nextState` of its latest
/// change), or null before it reports any.
Map<String, dynamic>? latestStateOf(
  List<StateChange> changes,
  String deviceId,
) {
  for (final c in changes.reversed) {
    if (c.deviceId == deviceId) return c.nextState;
  }
  return null;
}

/// Live state of [deviceId], following [stateChangesProvider].
final latestStateProvider = Provider.family<Map<String, dynamic>?, String>(
  (ref, deviceId) => latestStateOf(ref.watch(stateChangesProvider), deviceId),
);

/// Pinned state paths (Reactotron "state subscriptions"), kept across runs.
final stateSubscriptionsProvider =
    NotifierProvider<StateSubscriptionsNotifier, List<String>>(
      StateSubscriptionsNotifier.new,
    );

class StateSubscriptionsNotifier extends Notifier<List<String>> {
  static const _key = 'state_subscriptions';

  @override
  List<String> build() {
    try {
      final raw = AppPreferences().get<String>(_key);
      return raw == null
          ? const []
          : List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return const []; // corrupt preference: start over
    }
  }

  void add(String path) {
    final p = path.trim();
    if (p.isEmpty || state.contains(p)) return;
    _save([...state, p]);
  }

  void remove(String path) => _save([...state]..remove(path));

  void _save(List<String> paths) {
    state = paths;
    AppPreferences().set(_key, jsonEncode(paths));
  }
}

/// A saved copy of an app's state, to restore later.
class StateSnapshot {
  final String id;
  final String name;
  final String deviceId;
  final Map<String, dynamic> state;
  final DateTime takenAt;

  const StateSnapshot({
    required this.id,
    required this.name,
    required this.deviceId,
    required this.state,
    required this.takenAt,
  });
}

/// Snapshots taken this session, newest first.
final stateSnapshotsProvider =
    NotifierProvider<StateSnapshotsNotifier, List<StateSnapshot>>(
      StateSnapshotsNotifier.new,
    );

class StateSnapshotsNotifier extends Notifier<List<StateSnapshot>> {
  @override
  List<StateSnapshot> build() => const [];

  void add(String name, String deviceId, Map<String, dynamic> snapshot) {
    final now = DateTime.now();
    state = [
      StateSnapshot(
        id: '${now.microsecondsSinceEpoch}',
        name: name,
        deviceId: deviceId,
        state: snapshot,
        takenAt: now,
      ),
      ...state,
    ];
  }

  void remove(String id) => state = [...state]..removeWhere((s) => s.id == id);
}

/// Actions dispatched from the desktop this session, newest first, so one
/// can be sent again.
final dispatchHistoryProvider =
    NotifierProvider<DispatchHistoryNotifier, List<String>>(
      DispatchHistoryNotifier.new,
    );

class DispatchHistoryNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  void add(String action) =>
      state = [action, ...state.where((a) => a != action)].take(10).toList();
}

/// Sends [state] to [deviceId]'s app to replace its own (the app wires it
/// with `onStateRestore`), and toasts.
void restoreAppState(
  BuildContext context,
  WidgetRef ref,
  String deviceId,
  Map<String, dynamic> state,
) {
  ref.read(wsMessageHandlerProvider).restoreState(deviceId, state);
  showSuccessToast(context, message: S.of(context).stateRestoreSent);
}
