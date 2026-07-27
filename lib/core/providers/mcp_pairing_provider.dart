import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/mcp_clients.dart';
import '../preferences/app_preferences.dart';

/// One log entry in the install-history timeline.
enum McpAction { copy, run, uninstall }
enum McpResult { success, failed, timeout, notFound }

class InstallAttempt {
  final String id;
  final McpAction action;
  final McpClientId? clientId;
  final McpResult? result;
  final String? command;
  final String? stdout;
  final String? stderr;
  final int? exitCode;
  final int? durationMs;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime timestamp;

  InstallAttempt({
    required this.id,
    required this.action,
    this.clientId,
    this.result,
    this.command,
    this.stdout,
    this.stderr,
    this.exitCode,
    this.durationMs,
    this.startedAt,
    this.finishedAt,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action.name,
        if (clientId != null) 'clientId': clientId!.name,
        if (result != null) 'result': result!.name,
        if (command != null) 'command': command,
        if (stdout != null) 'stdout': stdout,
        if (stderr != null) 'stderr': stderr,
        if (exitCode != null) 'exitCode': exitCode,
        if (durationMs != null) 'durationMs': durationMs,
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        if (finishedAt != null) 'finishedAt': finishedAt!.toIso8601String(),
        'timestamp': timestamp.toIso8601String(),
      };

  factory InstallAttempt.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw FormatException('InstallAttempt missing id');
    }
    return InstallAttempt(
      id: id,
      action: McpAction.values.firstWhere(
        (a) => a.name == (json['action'] as String? ?? 'run'),
        orElse: () => McpAction.run,
      ),
      clientId: json['clientId'] is String
          ? McpClientId.values.firstWhere(
              (c) => c.name == json['clientId'],
              orElse: () => McpClientId.claudeCode,
            )
          : null,
      result: json['result'] is String
          ? McpResult.values.firstWhere(
              (r) => r.name == json['result'],
              orElse: () => McpResult.failed,
            )
          : null,
      command: json['command'] as String?,
      stdout: json['stdout'] as String?,
      stderr: json['stderr'] as String?,
      exitCode: json['exitCode'] is int ? json['exitCode'] as int : null,
      durationMs: json['durationMs'] is int ? json['durationMs'] as int : null,
      startedAt: json['startedAt'] is String
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      finishedAt: json['finishedAt'] is String
          ? DateTime.tryParse(json['finishedAt'] as String)
          : null,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class McpInstallHistoryNotifier extends StateNotifier<List<InstallAttempt>> {
  static const _prefsKey = 'mcp_install_history';
  static const _cap = 200;

  McpInstallHistoryNotifier() : super([]) {
    _load();
  }

  void _load() {
    try {
      final raw = AppPreferences().get<String>(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final loaded = <InstallAttempt>[];
      for (final r in decoded) {
        if (r is! Map<String, dynamic>) continue;
        try {
          loaded.add(InstallAttempt.fromJson(r));
        } catch (_) {}
      }
      loaded.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = loaded;
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
      await AppPreferences().set(_prefsKey, encoded);
    } catch (_) {}
  }

  Future<void> append(InstallAttempt attempt) async {
    state = [attempt, ...state];
    if (state.length > _cap) {
      state = state.sublist(0, _cap);
    }
    await _save();
  }

  Future<void> loadOlder() async {}
}

final mcpInstallHistoryProvider =
    StateNotifierProvider<McpInstallHistoryNotifier, List<InstallAttempt>>(
  (ref) => McpInstallHistoryNotifier(),
);