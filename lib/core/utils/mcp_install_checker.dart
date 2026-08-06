import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/mcp_clients.dart';
import 'cli_resolver.dart'
    show augmentedEnv, resolveCliBinary;

/// Status of a client's installed MCP-server entry. `unknown` means we
/// couldn't run the check (CLI missing, IO error) — distinct from
/// `notInstalled` which means we successfully ran the check and the
/// server isn't there.
enum McpInstallStatus {
  /// Server entry exists in the client's config and (where checkable)
  /// is currently connected / reachable.
  installed,

  /// Server entry exists but the client reports it's not running
  /// (Claude `Failed`, Codex `disabled`, etc.) — usually means the
  /// underlying process crashed.
  unhealthy,

  /// Client's MCP list returned without our server name — nothing
  /// to do.
  notInstalled,

  /// Check couldn't be performed. Either the CLI isn't on PATH or
  /// the config file (Cursor) doesn't exist.
  unknown,
}

class ClientInstallInfo {
  final McpInstallStatus status;

  /// Diagnostic text useful for the UI detail chip — e.g. Claude's
  /// "Connected", Codex's "enabled / disabled", or the config file
  /// path Cursor read from.
  final String? detail;

  const ClientInstallInfo({required this.status, this.detail});
}

/// Authoritative check: ask the client (or read Cursor's JSON file)
/// whether `devconnect-manage` is installed. Cached per-client so the
/// panel can re-show the same status without re-spawning the CLI on
/// every redraw.
///
/// Each check is bounded by a timeout (the slowest, Codex with --json
/// after npx warm-up, can take ~5s; everything else is sub-second).
class McpInstallChecker {
  static const Duration _checkTimeout = Duration(seconds: 8);

  /// Returns install status for [clientId]. Doesn't throw — unknown
  /// is the catch-all for IO failures.
  Future<ClientInstallInfo> check(McpClientId clientId) async {
    switch (clientId) {
      case McpClientId.claudeCode:
        return _checkClaude();
      case McpClientId.codex:
        return _checkCodex();
      case McpClientId.cursor:
        return _checkCursor();
    }
  }

  Future<ClientInstallInfo> _checkClaude() async {
    try {
      final exe = await resolveCliBinary('claude');
      if (exe == null) {
        return const ClientInstallInfo(
          status: McpInstallStatus.unknown,
          detail: '`claude` CLI not found in PATH',
        );
      }
      // `claude mcp get <name>` is targeted — single-server status,
      // faster than `mcp list` which health-checks every server.
      final result = await Process.run(
        exe,
        const ['mcp', 'get', 'devconnect-manage'],
        environment: augmentedEnv(),
      ).timeout(_checkTimeout);
      final out = result.stdout.toString();
      final err = result.stderr.toString();
      final parsed = parseClaudeGetOutput(
        stdout: out,
        stderr: err,
        exitCode: result.exitCode,
      );
      return ClientInstallInfo(
        status: parsed.status,
        detail: parsed.detail,
      );
    } on TimeoutException {
      return const ClientInstallInfo(
        status: McpInstallStatus.unknown,
        detail: 'claude mcp get timed out',
      );
    } catch (e) {
      return ClientInstallInfo(
        status: McpInstallStatus.unknown,
        detail: e.toString(),
      );
    }
  }

  Future<ClientInstallInfo> _checkCodex() async {
    try {
      final exe = await resolveCliBinary('codex');
      if (exe == null) {
        return const ClientInstallInfo(
          status: McpInstallStatus.unknown,
          detail: '`codex` CLI not found in PATH',
        );
      }
      final result = await Process.run(
        exe,
        const ['mcp', 'list', '--json'],
        environment: augmentedEnv(),
      ).timeout(_checkTimeout);
      final raw = result.stdout.toString();
      if (raw.trim().isEmpty) {
        return const ClientInstallInfo(
          status: McpInstallStatus.unknown,
          detail: 'codex returned empty output',
        );
      }
      // Try to parse as JSON array. Older codex versions print help
      // text instead — fall through to grep on raw text.
      final dyn = _tryParseJsonArray(raw);
      if (dyn != null) {
        final picked = pickCodexEntry(dyn);
        if (picked.found) {
          if (!picked.enabled) {
            return const ClientInstallInfo(
              status: McpInstallStatus.unhealthy,
              detail: 'disabled in codex config',
            );
          }
          return ClientInstallInfo(
            status: McpInstallStatus.installed,
            detail: picked.transportKind,
          );
        }
        return const ClientInstallInfo(status: McpInstallStatus.notInstalled);
      }
      if (raw.split('\n').any((l) => l.contains('devconnect-manage'))) {
        return const ClientInstallInfo(
          status: McpInstallStatus.installed,
          detail: 'stdio',
        );
      }
      return const ClientInstallInfo(status: McpInstallStatus.notInstalled);
    } on TimeoutException {
      return const ClientInstallInfo(
        status: McpInstallStatus.unknown,
        detail: 'codex mcp list timed out',
      );
    } catch (e) {
      return ClientInstallInfo(
        status: McpInstallStatus.unknown,
        detail: e.toString(),
      );
    }
  }

  Future<ClientInstallInfo> _checkCursor() async {
    try {
      final home = Platform.environment['HOME'] ?? '';
      if (home.isEmpty) {
        return const ClientInstallInfo(
          status: McpInstallStatus.unknown,
          detail: '\$HOME is not set',
        );
      }
      final file = File('$home/.cursor/mcp.json');
      if (!await file.exists()) {
        return const ClientInstallInfo(
          status: McpInstallStatus.notInstalled,
          detail: '~/.cursor/mcp.json does not exist',
        );
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const ClientInstallInfo(
          status: McpInstallStatus.notInstalled,
        );
      }
      final decoded = jsonDecodeSafe(raw);
      if (decoded is! Map) {
        return ClientInstallInfo(
          status: McpInstallStatus.unknown,
          detail: '~/.cursor/mcp.json is not valid JSON',
        );
      }
      final picked = pickCursorEntry(Map<String, dynamic>.from(decoded));
      if (picked.found) {
        return ClientInstallInfo(
          status: McpInstallStatus.installed,
          detail: picked.transportKind,
        );
      }
      return const ClientInstallInfo(status: McpInstallStatus.notInstalled);
    } catch (e) {
      return ClientInstallInfo(
        status: McpInstallStatus.unknown,
        detail: e.toString(),
      );
    }
  }

  /// Cheap JSON parser that returns the inner array even if there's
  /// stray non-JSON text around it. Older codex versions print help
  /// text on stderr but useful output on stdout.
  List<dynamic>? _tryParseJsonArray(String raw) {
    try {
      final decoded = jsonDecodeSafe(raw);
      if (decoded is List) return decoded;
      final start = raw.indexOf('[');
      final end = raw.lastIndexOf(']');
      if (start >= 0 && end > start) {
        final sub = jsonDecodeSafe(raw.substring(start, end + 1));
        if (sub is List) return sub;
      }
    } catch (_) {}
    return null;
  }
}

/// Catch-all JSON decoder — returns `null` on malformed input so
/// callers can branch on `unknown` instead of try/catching.
Object? jsonDecodeSafe(String s) {
  try {
    return json.decode(s);
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Pure parsers — exported so unit tests can hit them without spawning a
// real `claude`/`codex` subprocess or reading a real ~/.cursor/mcp.json.
// ---------------------------------------------------------------------------

/// Parses the output of `claude mcp get <name>`. Returns the inferred
/// status + a detail string (the raw "Status: …" line) for tooltips.
({McpInstallStatus status, String? detail}) parseClaudeGetOutput({
  required String stdout,
  required String stderr,
  required int exitCode,
}) {
  if (stdout.toLowerCase().contains('not found') ||
      stderr.toLowerCase().contains('not found')) {
    return (status: McpInstallStatus.notInstalled, detail: null);
  }
  if (exitCode != 0) {
    return (
      status: McpInstallStatus.unknown,
      detail: 'claude mcp get exited $exitCode',
    );
  }
  final match = RegExp(r'Status:\s*([^\n]+)').firstMatch(stdout);
  final statusLine = match?.group(1)?.trim() ?? '';
  final connected = statusLine.toLowerCase().contains('connected');
  return (
    status:
        connected ? McpInstallStatus.installed : McpInstallStatus.unhealthy,
    detail: statusLine.isEmpty ? null : statusLine,
  );
}

/// Picks our server's entry out of a parsed Codex list. Returns
/// `(found: false)` when not present. The transport kind is exposed
/// for tooltips ("HTTP" vs "stdio") so users see what they configured.
({bool found, bool enabled, String transportKind}) pickCodexEntry(
  List<dynamic> entries,
) {
  for (final entry in entries) {
    if (entry is Map && entry['name'] == 'devconnect-manage') {
      final enabled = entry['enabled'] != false;
      final transport = entry['transport'];
      final isHttp = transport is Map &&
          (transport['type']?.toString().contains('http') ?? false);
      return (
        found: true,
        enabled: enabled,
        transportKind: isHttp ? 'HTTP' : 'stdio',
      );
    }
  }
  return (found: false, enabled: false, transportKind: 'unknown');
}

/// Extracts our entry from a parsed Cursor mcpServers map. Cursor's
/// config is a hand-edited JSON file; `null` keys, alternate
/// capitalization, etc. shouldn't crash the checker.
({bool found, String transportKind}) pickCursorEntry(
  Map<String, dynamic> root,
) {
  final servers = root['mcpServers'];
  if (servers is! Map) return (found: false, transportKind: 'unknown');
  for (final entry in servers.entries) {
    if (entry.key.toLowerCase() != 'devconnect-manage') continue;
    final value = entry.value;
    if (value is Map) {
      final isHttp = value['url'] != null ||
          value['type']?.toString().contains('http') == true;
      return (found: true, transportKind: isHttp ? 'HTTP' : 'stdio');
    }
  }
  return (found: false, transportKind: 'unknown');
}

/// Riverpod notifier that fans the checker out across all 3 clients
/// in parallel and exposes a single Map of ClientId → info.
class McpInstallStatusNotifier
    extends StateNotifier<Map<McpClientId, ClientInstallInfo>> {
  McpInstallStatusNotifier(this._checker)
      : super({
          for (final c in McpClientId.values)
            c: const ClientInstallInfo(
              status: McpInstallStatus.unknown,
              detail: 'checking…',
            ),
        });

  final McpInstallChecker _checker;
  bool _running = false;

  /// Run the check for every client and update the map. Re-runs are
  /// ignored while one is in-flight — the panel can keep calling
  /// this from `initState` without piling up spawns.
  Future<void> refreshAll() async {
    if (_running) return;
    _running = true;
    try {
      final results = await Future.wait(
        McpClientId.values.map(_checker.check),
      );
      if (!mounted) return;
      final next = <McpClientId, ClientInstallInfo>{
        for (var i = 0; i < McpClientId.values.length; i++)
          McpClientId.values[i]: results[i],
      };
      state = next;
    } finally {
      _running = false;
    }
  }

  /// Run the check for a single client only — used after a Run
  /// install / Uninstall so the badge updates without re-running
  /// the other 2 clients' checks.
  Future<void> refreshOne(McpClientId id) async {
    final info = await _checker.check(id);
    if (!mounted) return;
    state = {...state, id: info};
  }
}

final mcpInstallCheckerProvider =
    Provider<McpInstallChecker>((ref) => McpInstallChecker());

final mcpInstallStatusProvider =
    StateNotifierProvider<McpInstallStatusNotifier,
        Map<McpClientId, ClientInstallInfo>>((ref) {
  return McpInstallStatusNotifier(ref.watch(mcpInstallCheckerProvider));
});
