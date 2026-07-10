import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/retention_provider.dart';
import '../../../core/utils/list_retention.dart';
import '../../../core/utils/retention_capped.dart';
import '../../../models/log/log_entry.dart';
import '../../../server/providers/server_providers.dart';
import '../../../server/ws_message_handler.dart';

final consoleEntriesProvider =
    StateNotifierProvider<ConsoleNotifier, List<LogEntry>>((ref) {
  final handler = ref.watch(wsMessageHandlerProvider);
  final notifier = ConsoleNotifier(handler, ref);
  ref.onDispose(() => notifier.cancelSubscription());
  return notifier;
});

/// Total log entries ever received by [ConsoleNotifier], including
/// ones dropped by the retention cap. Drives the "Showing N of M" hint.
///
/// Watches [consoleEntriesProvider] (not just the notifier) so this
/// rebuilds every time a new entry is appended — the notifier's
/// [ConsoleNotifier.totalSeen] getter is otherwise non-reactive.
final consoleTotalSeenProvider = Provider<int>((ref) {
  ref.watch(consoleEntriesProvider); // subscribe to state changes
  return ref.read(consoleEntriesProvider.notifier).totalSeen;
});

/// Source-cached list (capped to the user's retention limit) plus the
/// lifetime total (including dropped entries). Toolbars consume this
/// so they can surface a "Showing N of M" note when entries were
/// dropped by the cap.
final consoleDisplayProvider =
    Provider<RetentionCapped<LogEntry>>((ref) {
  final all = ref.watch(consoleEntriesProvider);
  final limit = ref.watch(retentionLimitProvider.select((p) => p.limit));
  final totalSeen = ref.watch(consoleTotalSeenProvider);
  return applyRetentionCap(all, limit, totalSeen: totalSeen);
});

final consoleSearchProvider = StateProvider<String>((ref) => '');
final consoleFilterProvider = StateProvider<Set<LogLevel>>(
  (ref) => LogLevel.values.toSet(),
);

final filteredConsoleEntriesProvider = Provider<List<LogEntry>>((ref) {
  final entries = ref.watch(consoleDisplayProvider).items;
  final search = ref.watch(consoleSearchProvider).toLowerCase();
  final filters = ref.watch(consoleFilterProvider);
  final selectedDevice = ref.watch(selectedDeviceProvider);

  return entries.where((e) {
    // Filter by selected device
    if (selectedDevice == null) return false;
    if (selectedDevice != allDevicesValue && e.deviceId != selectedDevice) return false;
    if (!filters.contains(e.level)) return false;
    if (search.isNotEmpty) {
      return e.message.toLowerCase().contains(search) ||
          (e.tag?.toLowerCase().contains(search) ?? false);
    }
    return true;
  }).toList();
});

class ConsoleNotifier extends StateNotifier<List<LogEntry>> {
  late final StreamSubscription<LogEntry> _sub;
  final Ref _ref;

  /// Total log entries ever received, including ones dropped by the cap.
  int _totalSeen = 0;
  int get totalSeen => _totalSeen;

  ConsoleNotifier(WsMessageHandler wsMessageHandler, this._ref) : super([]) {
    _sub = wsMessageHandler.onLog.listen((entry) {
      final limit = _ref.read(retentionLimitProvider).limit;
      state = truncateList([...state, entry], limit);
      _totalSeen++;
    });
  }

  void cancelSubscription() => _sub.cancel();

  void clear() => state = [];
}
