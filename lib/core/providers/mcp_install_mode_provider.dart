import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/app_preferences.dart';

/// Two ways for an AI client (Claude Code / Codex / Cursor) to launch
/// the `devconnect-manage` process:
///
/// - **npx** (default): the AI client spawns `npx -y devconnect-manage`
///   which downloads the package from npm on first run. Easiest for users
///   who have published the package.
/// - **localhost**: the AI client is configured to run
///   `node <workspace>/client_sdks/devconnect-mcp/dist/index.js` directly.
///   DevConnect desktop can additionally spawn the same node process as a
///   child when the MCP panel opens (see [autoStartLocalServerProvider]) so
///   the user doesn't have to do anything beyond opening the panel.
enum McpInstallMode { npx, localhost }

/// Per-AI-client install-mode override. Falls back to a per-client
/// default if the user hasn't picked one (npx for Claude/Codex, localhost
/// for Cursor since it doesn't have a CLI).
class McpInstallModeNotifier extends StateNotifier<Map<String, McpInstallMode>> {
  static const _key = 'mcp_install_mode';

  McpInstallModeNotifier() : super({}) {
    _load();
  }

  void _load() {
    try {
      final raw = AppPreferences().get<String>(_key);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final loaded = <String, McpInstallMode>{};
      decoded.forEach((k, v) {
        final mode = McpInstallMode.values.firstWhere(
          (m) => m.name == v,
          orElse: () => McpInstallMode.npx,
        );
        loaded[k as String] = mode;
      });
      state = loaded;
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final encoded = jsonEncode({
        for (final entry in state.entries) entry.key: entry.value.name,
      });
      await AppPreferences().set(_key, encoded);
    } catch (_) {}
  }

  McpInstallMode modeFor(String clientId) =>
      state[clientId] ?? _defaultFor(clientId);

  Future<void> set(String clientId, McpInstallMode mode) async {
    // Cursor has no CLI — the npx path goes through `Directory.current`
    // which doesn't resolve to a usable absolute path inside a packaged
    // .app bundle. Force localhost so the JSON config we write points
    // at the local HTTP MCP server, not a (broken) absolute script path.
    final coerced =
        clientId == 'cursor' ? McpInstallMode.localhost : mode;
    state = {...state, clientId: coerced};
    await _save();
  }

  static McpInstallMode _defaultFor(String clientId) {
    // Cursor has no CLI — only localhost install makes sense for it.
    return clientId == 'cursor' ? McpInstallMode.localhost : McpInstallMode.npx;
  }
}

final mcpInstallModeProvider =
    StateNotifierProvider<McpInstallModeNotifier, Map<String, McpInstallMode>>(
  (ref) => McpInstallModeNotifier(),
);

/// Whether to start the desktop-side MCP WebSocket server on app launch.
/// Surfaced in Settings → "Auto-start MCP server". Persisted to
/// AppPreferences so the choice survives restarts.
class McpAutoStartNotifier extends StateNotifier<bool> {
  static const _key = 'mcp_auto_start_server';

  McpAutoStartNotifier() : super(true) {
    final stored = AppPreferences().get<bool>(_key);
    if (stored != null) state = stored;
  }

  Future<void> set(bool value) async {
    state = value;
    await AppPreferences().set(_key, value);
  }
}

final mcpAutoStartProvider =
    StateNotifierProvider<McpAutoStartNotifier, bool>((ref) => McpAutoStartNotifier());

/// Whether to spawn the local `node dist/index.js` MCP server as a child
/// process when the McpPanel opens. Useful for users on localhost mode
/// who want the panel to "just connect" without manually starting node.
class McpAutoSpawnLocalNotifier extends StateNotifier<bool> {
  static const _key = 'mcp_auto_spawn_local';

  McpAutoSpawnLocalNotifier() : super(true) {
    final stored = AppPreferences().get<bool>(_key);
    if (stored != null) state = stored;
  }

  Future<void> set(bool value) async {
    state = value;
    await AppPreferences().set(_key, value);
  }
}

final mcpAutoSpawnLocalProvider =
    StateNotifierProvider<McpAutoSpawnLocalNotifier, bool>(
  (ref) => McpAutoSpawnLocalNotifier(),
);