import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/log/log_entry.dart';
import '../../../server/providers/server_providers.dart';
import '../../../server/ws_message_handler.dart';

final consoleEntriesProvider =
    StateNotifierProvider<ConsoleNotifier, List<LogEntry>>((ref) {
  final handler = ref.watch(wsMessageHandlerProvider);
  final notifier = ConsoleNotifier(handler);
  ref.onDispose(() => notifier.cancelSubscription());
  return notifier;
});

final consoleSearchProvider = StateProvider<String>((ref) => '');
final consoleFilterProvider = StateProvider<Set<LogLevel>>(
  (ref) => LogLevel.values.toSet(),
);

final filteredConsoleEntriesProvider = Provider<List<LogEntry>>((ref) {
  final entries = ref.watch(consoleEntriesProvider);
  final search = ref.watch(consoleSearchProvider).toLowerCase();
  final filters = ref.watch(consoleFilterProvider);
  final selectedDevice = ref.watch(selectedDeviceProvider);

  return entries.where((e) {
    // Filter by selected device
    if (selectedDevice != null && e.deviceId != selectedDevice) return false;
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

  ConsoleNotifier(WsMessageHandler wsMessageHandler) : super([]) {
    _sub = wsMessageHandler.onLog.listen((entry) {
      if (state.length > 10000) {
        state = [...state.skip(1000), entry];
      } else {
        state = [...state, entry];
      }
    });
  }

  void cancelSubscription() => _sub.cancel();

  void clear() => state = [];
}
