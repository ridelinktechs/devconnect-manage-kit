import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/retention_provider.dart';
import '../../../core/utils/list_retention.dart';
import '../../../core/utils/retention_capped.dart';
import '../../../models/log/error_event.dart';
import '../../../server/providers/server_providers.dart';
import '../../../server/ws_message_handler.dart';

// ---- Error Events ----

final errorEntriesProvider =
    NotifierProvider<ErrorNotifier, List<ErrorEvent>>(
        ErrorNotifier.new);

/// Total errors ever received by [ErrorNotifier], including ones
/// dropped by the retention cap.
///
/// Watches [errorEntriesProvider] (not just the notifier) so this
/// rebuilds every time a new entry is appended — the notifier's
/// [ErrorNotifier.totalSeen] getter is otherwise non-reactive.
final errorTotalSeenProvider = Provider<int>((ref) {
  ref.watch(errorEntriesProvider); // subscribe to state changes
  return ref.read(errorEntriesProvider.notifier).totalSeen;
});

/// Source-cached list (capped to the user's retention limit) plus the
/// lifetime total (including dropped entries).
final errorDisplayProvider =
    Provider<RetentionCapped<ErrorEvent>>((ref) {
  final all = ref.watch(errorEntriesProvider);
  final limit = ref.watch(retentionLimitProvider.select((p) => p.limit));
  final totalSeen = ref.watch(errorTotalSeenProvider);
  return applyRetentionCap(all, limit, totalSeen: totalSeen);
});

final errorSearchProvider =
    NotifierProvider<_ErrorSearchNotifier, String>(
  _ErrorSearchNotifier.new,
);

class _ErrorSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String v) => state = v;
}

final errorFilterProvider =
    NotifierProvider<_ErrorFilterNotifier, Set<ErrorPlatform>>(
  _ErrorFilterNotifier.new,
);

class _ErrorFilterNotifier extends Notifier<Set<ErrorPlatform>> {
  @override
  Set<ErrorPlatform> build() => ErrorPlatform.values.toSet();

  void set(Set<ErrorPlatform> v) => state = v;

  void toggle(ErrorPlatform platform) {
    state = state.contains(platform)
        ? state.difference({platform})
        : {...state, platform};
  }
}

final errorSeverityFilterProvider =
    NotifierProvider<_ErrorSeverityFilterNotifier, Set<ErrorSeverity>>(
  _ErrorSeverityFilterNotifier.new,
);

class _ErrorSeverityFilterNotifier extends Notifier<Set<ErrorSeverity>> {
  @override
  Set<ErrorSeverity> build() => ErrorSeverity.values.toSet();

  void set(Set<ErrorSeverity> v) => state = v;

  void toggle(ErrorSeverity severity) {
    state = state.contains(severity)
        ? state.difference({severity})
        : {...state, severity};
  }
}

final filteredErrorEntriesProvider = Provider<List<ErrorEvent>>((ref) {
  final entries = ref.watch(errorEntriesProvider);
  final search = ref.watch(errorSearchProvider).toLowerCase();
  final platformFilters = ref.watch(errorFilterProvider);
  final severityFilters = ref.watch(errorSeverityFilterProvider);
  final selectedDevice = ref.watch(selectedDeviceProvider);

  return entries.where((e) {
    if (selectedDevice == null) return false;
    if (selectedDevice != allDevicesValue && e.deviceId != selectedDevice) return false;
    if (!platformFilters.contains(e.platform)) return false;
    if (!severityFilters.contains(e.severity)) return false;
    if (search.isNotEmpty) {
      return e.message.toLowerCase().contains(search) ||
          (e.source?.toLowerCase().contains(search) ?? false) ||
          (e.stackTrace?.toLowerCase().contains(search) ?? false);
    }
    return true;
  }).toList();
});

// ---- Error Counts ----

final errorCountProvider = Provider<int>((ref) {
  return ref.watch(filteredErrorEntriesProvider).length;
});

final fatalErrorCountProvider = Provider<int>((ref) {
  return ref.watch(errorEntriesProvider)
      .where((e) => e.severity == ErrorSeverity.fatal || e.severity == ErrorSeverity.crash)
      .length;
});

final crashCountProvider = Provider<int>((ref) {
  return ref.watch(errorEntriesProvider)
      .where((e) => e.severity == ErrorSeverity.crash)
      .length;
});

// ---- Platform-specific counts ----

final errorCountByPlatformProvider = Provider<Map<ErrorPlatform, int>>((ref) {
  final entries = ref.watch(filteredErrorEntriesProvider);
  return {
    ErrorPlatform.js: entries.where((e) => e.platform == ErrorPlatform.js).length,
    ErrorPlatform.native: entries.where((e) => e.platform == ErrorPlatform.native).length,
    ErrorPlatform.android: entries.where((e) => e.platform == ErrorPlatform.android).length,
    ErrorPlatform.ios: entries.where((e) => e.platform == ErrorPlatform.ios).length,
  };
});

final errorCountBySeverityProvider = Provider<Map<ErrorSeverity, int>>((ref) {
  final entries = ref.watch(filteredErrorEntriesProvider);
  return {
    ErrorSeverity.fatal: entries.where((e) => e.severity == ErrorSeverity.fatal).length,
    ErrorSeverity.crash: entries.where((e) => e.severity == ErrorSeverity.crash).length,
    ErrorSeverity.error: entries.where((e) => e.severity == ErrorSeverity.error).length,
    ErrorSeverity.warning: entries.where((e) => e.severity == ErrorSeverity.warning).length,
    ErrorSeverity.info: entries.where((e) => e.severity == ErrorSeverity.info).length,
  };
});

class ErrorNotifier extends Notifier<List<ErrorEvent>> {
  /// Total errors ever received, including ones dropped by the cap.
  int _totalSeen = 0;
  int get totalSeen => _totalSeen;

  @override
  List<ErrorEvent> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onError.listen((entry) {
      final limit = ref.read(retentionLimitProvider).limit ?? kRetentionSafetyCap;
      state = truncateList([...state, entry], limit);
      _totalSeen++;
    });
    ref.onDispose(() => sub.cancel());
    return [];
  }

  void clear() => state = [];
}