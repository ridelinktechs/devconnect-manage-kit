import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/retention_provider.dart';
import '../../../core/utils/list_retention.dart';
import '../../../core/utils/retention_capped.dart';
import '../../../models/round/mock_entry.dart';
import '../../../models/round/protocol_entry.dart';
import '../../../models/round/state_round_entry.dart';
import '../../../server/providers/server_providers.dart';

// =============================================================
// Round 2 — extended state managers (BLoC, Provider, ReactQuery,
// Apollo). Same shape, filtered by [manager] at view time.
// =============================================================

final stateRoundEntriesProvider =
    NotifierProvider<StateRoundEntriesNotifier, List<StateRoundEntry>>(
        StateRoundEntriesNotifier.new);

final stateRoundTotalSeenProvider = Provider<int>((ref) {
  ref.watch(stateRoundEntriesProvider);
  return ref.read(stateRoundEntriesProvider.notifier).totalSeen;
});

final stateRoundDisplayProvider =
    Provider<RetentionCapped<StateRoundEntry>>((ref) {
  final all = ref.watch(stateRoundEntriesProvider);
  final limit = ref.watch(retentionLimitProvider.select((p) => p.limit));
  final totalSeen = ref.watch(stateRoundTotalSeenProvider);
  return applyRetentionCap(all, limit, totalSeen: totalSeen);
});

/// Filter chip on the State Inspector: `all` or one of `bloc`,
/// `provider`, `react_query`, `apollo`.
final stateRoundManagerFilterProvider =
    NotifierProvider<_StateRoundManagerFilterNotifier, String>(
  _StateRoundManagerFilterNotifier.new,
);

class _StateRoundManagerFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void set(String v) => state = v;
}

final filteredStateRoundProvider = Provider<List<StateRoundEntry>>((ref) {
  final entries = ref.watch(stateRoundDisplayProvider).items;
  final filter = ref.watch(stateRoundManagerFilterProvider);
  final search = ref.watch(roundSearchProvider).toLowerCase();
  final selectedDevice = ref.watch(selectedDeviceProvider);
  return entries.where((e) {
    if (selectedDevice == null) return false;
    if (selectedDevice != allDevicesValue && e.deviceId != selectedDevice) {
      return false;
    }
    if (filter != 'all' && e.manager != filter) return false;
    if (search.isNotEmpty &&
        !e.action.toLowerCase().contains(search) &&
        !e.manager.toLowerCase().contains(search)) {
      return false;
    }
    return true;
  }).toList();
});

class StateRoundEntriesNotifier extends Notifier<List<StateRoundEntry>> {
  int _totalSeen = 0;
  int get totalSeen => _totalSeen;

  @override
  List<StateRoundEntry> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onStateRound.listen((entry) {
      final limit = ref.read(retentionLimitProvider).limit ?? kRetentionSafetyCap;
      state = truncateList([...state, entry], limit);
      _totalSeen++;
    });
    ref.onDispose(() => sub.cancel());
    return [];
  }

  void clear() => state = [];
}

// =============================================================
// Round 3 — protocol inspectors (GraphQL, WebSocket, gRPC)
// =============================================================

final graphqlEntriesProvider =
    NotifierProvider<GraphqlEntriesNotifier, List<GraphqlEntry>>(
        GraphqlEntriesNotifier.new);

final graphqlDisplayProvider = Provider<RetentionCapped<GraphqlEntry>>((ref) {
  final all = ref.watch(graphqlEntriesProvider);
  final limit = ref.watch(retentionLimitProvider.select((p) => p.limit));
  return applyRetentionCap(all, limit);
});

final selectedGraphqlIdProvider =
    NotifierProvider<_SelectedGraphqlIdNotifier, String?>(
  _SelectedGraphqlIdNotifier.new,
);

class _SelectedGraphqlIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? v) => state = v;
}

final selectedGraphqlProvider = Provider<GraphqlEntry?>((ref) {
  final id = ref.watch(selectedGraphqlIdProvider);
  if (id == null) return null;
  final entries = ref.watch(graphqlEntriesProvider);
  return entries.where((e) => e.id == id).firstOrNull;
});

class GraphqlEntriesNotifier extends Notifier<List<GraphqlEntry>> {
  @override
  List<GraphqlEntry> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onGraphql.listen((entry) {
      // The response half lands on its operation's row.
      final i = state.lastIndexWhere((e) => e.id == entry.id);
      if (i >= 0) {
        state = [...state]..[i] = mergeGraphql(state[i], entry);
        return;
      }
      final limit = ref.read(retentionLimitProvider).limit ?? kRetentionSafetyCap;
      state = truncateList([...state, entry], limit);
    });
    ref.onDispose(() => sub.cancel());
    return [];
  }

  void clear() => state = [];
}

final websocketEntriesProvider = NotifierProvider<
    WebsocketEntriesNotifier, List<WebsocketFrameEntry>>(
        WebsocketEntriesNotifier.new);

final websocketDisplayProvider =
    Provider<RetentionCapped<WebsocketFrameEntry>>((ref) {
  final all = ref.watch(websocketEntriesProvider);
  final limit = ref.watch(retentionLimitProvider.select((p) => p.limit));
  return applyRetentionCap(all, limit);
});

final selectedWebsocketIdProvider =
    NotifierProvider<_SelectedWebsocketIdNotifier, String?>(
  _SelectedWebsocketIdNotifier.new,
);

class _SelectedWebsocketIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? v) => state = v;
}

final selectedWebsocketProvider = Provider<WebsocketFrameEntry?>((ref) {
  final id = ref.watch(selectedWebsocketIdProvider);
  if (id == null) return null;
  final entries = ref.watch(websocketEntriesProvider);
  return entries.where((e) => e.id == id).firstOrNull;
});

class WebsocketEntriesNotifier extends Notifier<List<WebsocketFrameEntry>> {
  @override
  List<WebsocketFrameEntry> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onWebsocket.listen((entry) {
      final limit = ref.read(retentionLimitProvider).limit ?? kRetentionSafetyCap;
      state = truncateList([...state, entry], limit);
    });
    ref.onDispose(() => sub.cancel());
    return [];
  }

  void clear() => state = [];
}

final grpcEntriesProvider =
    NotifierProvider<GrpcEntriesNotifier, List<GrpcCallEntry>>(
        GrpcEntriesNotifier.new);

final grpcDisplayProvider = Provider<RetentionCapped<GrpcCallEntry>>((ref) {
  final all = ref.watch(grpcEntriesProvider);
  final limit = ref.watch(retentionLimitProvider.select((p) => p.limit));
  return applyRetentionCap(all, limit);
});

final selectedGrpcIdProvider =
    NotifierProvider<_SelectedGrpcIdNotifier, String?>(
  _SelectedGrpcIdNotifier.new,
);

class _SelectedGrpcIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? v) => state = v;
}

final selectedGrpcProvider = Provider<GrpcCallEntry?>((ref) {
  final id = ref.watch(selectedGrpcIdProvider);
  if (id == null) return null;
  final entries = ref.watch(grpcEntriesProvider);
  return entries.where((e) => e.id == id).firstOrNull;
});

class GrpcEntriesNotifier extends Notifier<List<GrpcCallEntry>> {
  @override
  List<GrpcCallEntry> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onGrpc.listen((entry) {
      // The end half lands on its start's row.
      final i = state.lastIndexWhere((e) => e.id == entry.id);
      if (i >= 0) {
        state = [...state]..[i] = mergeGrpc(state[i], entry);
        return;
      }
      final limit = ref.read(retentionLimitProvider).limit ?? kRetentionSafetyCap;
      state = truncateList([...state, entry], limit);
    });
    ref.onDispose(() => sub.cancel());
    return [];
  }

  void clear() => state = [];
}

// =============================================================
// Round 4 — mock audit (read-only audit log on the desktop)
// =============================================================

final mockAuditEntriesProvider =
    NotifierProvider<MockAuditEntriesNotifier, List<MockedRequestEntry>>(
        MockAuditEntriesNotifier.new);

final mockAuditDisplayProvider =
    Provider<RetentionCapped<MockedRequestEntry>>((ref) {
  final all = ref.watch(mockAuditEntriesProvider);
  final limit = ref.watch(retentionLimitProvider.select((p) => p.limit));
  return applyRetentionCap(all, limit);
});

class MockAuditEntriesNotifier extends Notifier<List<MockedRequestEntry>> {
  @override
  List<MockedRequestEntry> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onMockAudit.listen((entry) {
      final enriched = _enrich(entry);
      final limit = ref.read(retentionLimitProvider).limit ?? kRetentionSafetyCap;
      state = truncateList([...state, enriched], limit);
    });
    ref.onDispose(() => sub.cancel());
    return [];
  }

  void clear() => state = [];

  /// Adds the rule's name, and its method / URL pattern when the SDK
  /// didn't send the request's real ones (older SDKs only ship `ruleId`
  /// and `status`).
  MockedRequestEntry _enrich(MockedRequestEntry entry) {
    if (entry.matchedRuleId.isEmpty) return entry;
    final rule = ref
        .read(mockRulesProvider)
        .where((r) => r.id == entry.matchedRuleId)
        .firstOrNull;
    if (rule == null) return entry;
    return MockedRequestEntry(
      id: entry.id,
      deviceId: entry.deviceId,
      method: entry.url.isNotEmpty ? entry.method : rule.method,
      url: entry.url.isNotEmpty ? entry.url : rule.urlPattern,
      matchedRuleId: entry.matchedRuleId,
      matchedRuleName: rule.name,
      statusCode: entry.statusCode,
      timestamp: entry.timestamp,
      metadata: entry.metadata,
    );
  }
}

// =============================================================
// Round 4 — mock rule store (the rules the desktop edits and pushes
// down to the SDK). Lives in-process; survives reconnects.
// =============================================================

class MockRulesNotifier extends Notifier<List<MockRule>> {
  @override
  List<MockRule> build() => [];

  void add(MockRule rule) {
    state = [...state, rule];
  }

  void update(MockRule rule) {
    state = [
      for (final r in state)
        if (r.id == rule.id) rule else r,
    ];
  }

  void toggle(String ruleId, bool enabled) {
    state = [
      for (final r in state)
        if (r.id == ruleId) r.copyWith(enabled: enabled, updatedAt: DateTime.now().millisecondsSinceEpoch) else r,
    ];
  }

  void remove(String ruleId) {
    state = state.where((r) => r.id != ruleId).toList();
  }

  void clear() => state = [];

  void replaceAll(List<MockRule> rules) {
    state = rules;
  }
}

final mockRulesProvider =
    NotifierProvider<MockRulesNotifier, List<MockRule>>(
        MockRulesNotifier.new);

/// The devices that were sent the mock rules, kept in step with the list:
/// it's re-sent whole whenever it changes (toggle, edit, delete — every
/// SDK replaces its rules with what it gets) and when such a device
/// reconnects (the SDKs keep rules in memory only).
final mockRulesSyncProvider =
    NotifierProvider<MockRulesSyncNotifier, Set<String>>(
        MockRulesSyncNotifier.new);

class MockRulesSyncNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onDeviceConnected.listen((device) {
      if (state.contains(device.deviceId)) {
        handler.installMockRules(device.deviceId, ref.read(mockRulesProvider));
      }
    });
    ref.onDispose(sub.cancel);
    ref.listen(mockRulesProvider, (_, rules) {
      for (final deviceId in state) {
        handler.installMockRules(deviceId, rules);
      }
    });
    return const {};
  }

  /// Sends [deviceId] the whole list and keeps it in step from now on.
  void push(String deviceId) {
    state = {...state, deviceId};
    ref
        .read(wsMessageHandlerProvider)
        .installMockRules(deviceId, ref.read(mockRulesProvider));
  }

  /// Empties [deviceId]'s rules and stops keeping it in step.
  void clear(String deviceId) {
    state = {...state}..remove(deviceId);
    ref.read(wsMessageHandlerProvider).clearMockRules(deviceId);
  }
}

final selectedMockRuleIdProvider =
    NotifierProvider<_SelectedMockRuleIdNotifier, String?>(
  _SelectedMockRuleIdNotifier.new,
);

class _SelectedMockRuleIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? v) => state = v;
}

final selectedMockRuleProvider = Provider<MockRule?>((ref) {
  final id = ref.watch(selectedMockRuleIdProvider);
  if (id == null) return null;
  final rules = ref.watch(mockRulesProvider);
  return rules.where((r) => r.id == id).firstOrNull;
});

// =============================================================
// Shared search box for Round 2-5 tabs that need one.
// Lives here so the State / Network tabs share the same widget.
// =============================================================

final roundSearchProvider =
    NotifierProvider<_RoundSearchNotifier, String>(
  _RoundSearchNotifier.new,
);

class _RoundSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String v) => state = v;
}

/// The desktop's view of the currently-selected device, as an
/// action-target for the round 4 / round 5 Server→Client commands.
final roundActionTargetProvider = Provider<String?>((ref) {
  final selected = ref.watch(selectedDeviceProvider);
  if (selected == null || selected == allDevicesValue) return null;
  return selected;
});


/// One GraphQL operation from its two halves, which may arrive in either
/// order: the request's name, type, variables and start time; the latest
/// response's result.
GraphqlEntry mergeGraphql(GraphqlEntry old, GraphqlEntry next) {
  final request = next.isComplete ? old : next;
  final result = next.isComplete ? next : old;
  return GraphqlEntry(
    id: old.id,
    deviceId: old.deviceId,
    operation: request.operation,
    type: request.type,
    variables:
        request.variables.isNotEmpty ? request.variables : result.variables,
    isComplete: result.isComplete,
    latencyMs: result.latencyMs,
    cacheHit: result.cacheHit,
    data: result.data,
    errors: result.errors,
    error: result.error,
    timestamp: request.timestamp,
    metadata: request.metadata == null && result.metadata == null
        ? null
        : {...?request.metadata, ...?result.metadata},
  );
}

/// One gRPC call from its start and end events, in either order; a
/// finished call never goes back to pending.
GrpcCallEntry mergeGrpc(GrpcCallEntry old, GrpcCallEntry next) {
  final end = next.status != null ? next : old;
  final start = identical(end, next) ? old : next;
  return GrpcCallEntry(
    id: old.id,
    deviceId: old.deviceId,
    service: start.service.isNotEmpty ? start.service : end.service,
    method: start.method.isNotEmpty ? start.method : end.method,
    request: start.request.isNotEmpty ? start.request : end.request,
    response: end.response,
    timestamp: start.timestamp < end.timestamp ? start.timestamp : end.timestamp,
    latencyMs: end.latencyMs,
    status: end.status,
    error: end.error,
    metadata: start.metadata == null && end.metadata == null
        ? null
        : {...?start.metadata, ...?end.metadata},
  );
}
