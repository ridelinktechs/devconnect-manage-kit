import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/retention_provider.dart';
import '../../../core/utils/collections/list_retention.dart';
import '../../../core/utils/collections/retention_capped.dart';
import '../../../models/log/log_entry.dart';
import '../../../server/providers/server_providers.dart';

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

/// Whether consecutive identical logs fold into one row with a repeat
/// count, as in Chrome DevTools.
final consoleGroupRepeatsProvider =
    NotifierProvider<_ConsoleGroupRepeatsNotifier, bool>(
  _ConsoleGroupRepeatsNotifier.new,
);

class _ConsoleGroupRepeatsNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

/// [entries] with each run of identical consecutive logs (same device,
/// level, tag and message) folded into its first entry, which keeps its row
/// as the run grows; `runs` holds every log of each folded run, oldest
/// first, under the first one's id.
({List<LogEntry> entries, Map<String, List<LogEntry>> runs}) groupRepeats(
  List<LogEntry> entries,
) {
  final kept = <LogEntry>[];
  final runs = <String, List<LogEntry>>{};
  for (final e in entries) {
    final last = kept.lastOrNull;
    if (last != null &&
        last.deviceId == e.deviceId &&
        last.level == e.level &&
        last.tag == e.tag &&
        last.message == e.message) {
      (runs[last.id] ??= [last]).add(e);
    } else {
      kept.add(e);
    }
  }
  return (entries: kept, runs: runs);
}

/// What the Console lists: [filteredConsoleEntriesProvider], with repeats
/// folded when [consoleGroupRepeatsProvider] is on.
final groupedConsoleEntriesProvider =
    Provider<({List<LogEntry> entries, Map<String, List<LogEntry>> runs})>((ref) {
  final entries = ref.watch(filteredConsoleEntriesProvider);
  return ref.watch(consoleGroupRepeatsProvider)
      ? groupRepeats(entries)
      : (entries: entries, runs: const <String, List<LogEntry>>{});
});

/// [entries] as plain text, one `time [LEVEL] [tag] message` line each,
/// with stack trace and metadata indented below.
String formatLogsAsText(List<LogEntry> entries) {
  final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
  final out = StringBuffer();
  for (final e in entries) {
    out.write(time.format(DateTime.fromMillisecondsSinceEpoch(e.timestamp)));
    out.write(' [${e.level.name.toUpperCase()}]');
    if (e.tag != null) out.write(' [${e.tag}]');
    out.writeln(' ${e.message}');
    for (final line in (e.stackTrace ?? '').trimRight().split('\n')) {
      if (line.isNotEmpty) out.writeln('    $line');
    }
    if (e.metadata case final metadata? when metadata.isNotEmpty) {
      String text;
      try {
        text = jsonEncode(metadata);
      } catch (_) {
        text = '$metadata';
      }
      out.writeln('    $text');
    }
  }
  return '$out';
}

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