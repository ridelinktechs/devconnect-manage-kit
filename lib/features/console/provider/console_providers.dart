import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/retention_provider.dart';
import '../../../core/utils/list_retention.dart';
import '../../../core/utils/retention_capped.dart';
import '../../../models/log/log_entry.dart';
import '../../../server/providers/server_providers.dart';
import '../../../server/ws_message_handler.dart';

final consoleEntriesProvider =
    NotifierProvider<ConsoleNotifier, List<LogEntry>>(
        ConsoleNotifier.new);

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

final consoleSearchProvider =
    NotifierProvider<_ConsoleSearchNotifier, String>(
  _ConsoleSearchNotifier.new,
);

class _ConsoleSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String v) => state = v;
}

final consoleFilterProvider =
    NotifierProvider<_ConsoleFilterNotifier, Set<LogLevel>>(
  _ConsoleFilterNotifier.new,
);

class _ConsoleFilterNotifier extends Notifier<Set<LogLevel>> {
  @override
  Set<LogLevel> build() => LogLevel.values.toSet();

  void set(Set<LogLevel> v) => state = v;

  void toggle(LogLevel level) {
    state = state.contains(level)
        ? state.difference({level})
        : {...state, level};
  }
}

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

class ConsoleNotifier extends Notifier<List<LogEntry>> {
  /// Total log entries ever received, including ones dropped by the cap.
  int _totalSeen = 0;
  int get totalSeen => _totalSeen;

  @override
  List<LogEntry> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onLog.listen((entry) {
      final limit = ref.read(retentionLimitProvider).limit ?? kRetentionHighVolumeCap;
      state = truncateList([...state, entry], limit);
      _totalSeen++;
    });
    ref.onDispose(() => sub.cancel());
    return [];
  }

  void clear() => state = [];
}