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
    StateNotifierProvider<ErrorNotifier, List<ErrorEvent>>((ref) {
  final handler = ref.watch(wsMessageHandlerProvider);
  final notifier = ErrorNotifier(handler, ref);
  ref.onDispose(() => notifier.cancelSubscription());
  return notifier;
});

/// Source-cached list (unlimited) trimmed to the user's
/// retention cap. Toolbars consume this so they can surface a
/// "Showing N of M" note when entries were dropped.
final errorDisplayProvider =
    Provider<RetentionCapped<ErrorEvent>>((ref) {
  final all = ref.watch(errorEntriesProvider);
  final limit = ref.watch(retentionLimitProvider.select((p) => p.limit));
  return applyRetentionCap(all, limit);
});

final errorSearchProvider = StateProvider<String>((ref) => '');
final errorFilterProvider = StateProvider<Set<ErrorPlatform>>(
  (ref) => ErrorPlatform.values.toSet(),
);
final errorSeverityFilterProvider = StateProvider<Set<ErrorSeverity>>(
  (ref) => ErrorSeverity.values.toSet(),
);

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

class ErrorNotifier extends StateNotifier<List<ErrorEvent>> {
  late final StreamSubscription<ErrorEvent> _sub;
  final Ref _ref;

  ErrorNotifier(WsMessageHandler handler, this._ref) : super([]) {
    _sub = handler.onError.listen((entry) {
      state = truncateList([...state, entry], null);
    });
  }

  void cancelSubscription() => _sub.cancel();
  void clear() => state = [];
}