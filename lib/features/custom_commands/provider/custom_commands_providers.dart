import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../server/providers/server_providers.dart';

/// The custom commands each connected device's app registered, by device id.
/// Watched from the app shell: the list arrives right after the handshake,
/// before anyone opens the Commands page.
final customCommandsProvider =
    NotifierProvider<CustomCommandsNotifier, Map<String, List<String>>>(
      CustomCommandsNotifier.new,
    );

class CustomCommandsNotifier extends Notifier<Map<String, List<String>>> {
  @override
  Map<String, List<String>> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final subs = [
      handler.onCustomCommands.listen((m) {
        state = {
          ...state,
          m['deviceId'] as String: m['commands'] as List<String>,
        };
      }),
      handler.onDeviceDisconnected.listen((id) {
        state = {...state}..remove(id);
      }),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        s.cancel();
      }
    });
    return const {};
  }
}

enum CommandRunStatus { pending, ok, error, noResponse }

/// One command sent to an app, and what came back.
class CommandRun {
  final String id;
  final String deviceId;
  final String command;
  final Map<String, dynamic>? args;
  final DateTime sentAt;
  final CommandRunStatus status;

  /// What the app's handler returned.
  final Object? result;
  final String? error;
  final Duration? took;

  const CommandRun({
    required this.id,
    required this.deviceId,
    required this.command,
    required this.args,
    required this.sentAt,
    this.status = CommandRunStatus.pending,
    this.result,
    this.error,
    this.took,
  });

  CommandRun settle(CommandRunStatus status, {Object? result, String? error}) =>
      CommandRun(
        id: id,
        deviceId: deviceId,
        command: command,
        args: args,
        sentAt: sentAt,
        status: status,
        result: result,
        error: error,
        took: DateTime.now().difference(sentAt),
      );
}

/// Commands run from the desktop, newest first.
final commandRunsProvider =
    NotifierProvider<CommandRunsNotifier, List<CommandRun>>(
      CommandRunsNotifier.new,
    );

class CommandRunsNotifier extends Notifier<List<CommandRun>> {
  /// An app that doesn't know the command never answers.
  static const timeout = Duration(seconds: 10);

  @override
  List<CommandRun> build() {
    final sub = ref
        .watch(wsMessageHandlerProvider)
        .onCustomResult
        .listen(_onResult);
    ref.onDispose(sub.cancel);
    return const [];
  }

  /// Sends [command] to [deviceId]; the run stays pending until the app
  /// answers or [timeout] passes.
  void run(String deviceId, String command, Map<String, dynamic>? args) {
    final id = ref
        .read(wsMessageHandlerProvider)
        .sendCustomCommand(deviceId, command, args: args);
    state = [
      CommandRun(
        id: id,
        deviceId: deviceId,
        command: command,
        args: args,
        sentAt: DateTime.now(),
      ),
      ...state,
    ];
    Timer(timeout, () {
      if (!ref.mounted) return;
      final i = state.indexWhere(
        (r) => r.id == id && r.status == CommandRunStatus.pending,
      );
      if (i >= 0) {
        state = [...state]..[i] = state[i].settle(CommandRunStatus.noResponse);
      }
    });
  }

  void clear() => state = const [];

  void _onResult(Map<String, dynamic> m) {
    final correlationId = m['correlationId'] as String?;
    // The Android SDK doesn't echo the id: settle the oldest pending run of
    // that command on that device instead.
    final i = correlationId != null
        ? state.indexWhere((r) => r.id == correlationId)
        : state.lastIndexWhere(
            (r) =>
                r.status == CommandRunStatus.pending &&
                r.deviceId == m['deviceId'] &&
                r.command == m['command'],
          );
    if (i < 0) return;
    final error = m['error'];
    state = [...state]
      ..[i] = state[i].settle(
        error != null || m['status'] == 'error'
            ? CommandRunStatus.error
            : CommandRunStatus.ok,
        result: m['result'],
        error: error?.toString(),
      );
  }
}
