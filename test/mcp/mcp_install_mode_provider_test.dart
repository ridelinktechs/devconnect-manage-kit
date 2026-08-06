import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/preferences/app_preferences.dart';
import 'package:devconnect_manage_tool/core/providers/mcp_install_mode_provider.dart';

void main() {
  // AppPreferences is a process-wide singleton. Wipe the relevant
  // key between tests so isolation holds (otherwise test N's `set()`
  // leaks into test N+1's notifier constructor that reads prefs).
  setUp(() async {
    await AppPreferences().set('mcp_install_mode', '');
  });

  group('default mode per client', () {
    test('Cursor defaults to localhost (no CLI, force URL mode)', () {
      final n = McpInstallModeNotifier();
      expect(n.modeFor('cursor'), McpInstallMode.localhost);
    });

    test('Claude defaults to npx', () {
      final n = McpInstallModeNotifier();
      expect(n.modeFor('claudeCode'), McpInstallMode.npx);
    });

    test('Codex defaults to npx', () {
      final n = McpInstallModeNotifier();
      expect(n.modeFor('codex'), McpInstallMode.npx);
    });

    test('Unknown client defaults to npx (safe fallback)', () {
      final n = McpInstallModeNotifier();
      expect(n.modeFor('windsurf'), McpInstallMode.npx);
    });
  });

  group('Cursor coercion (path bug fix)', () {
    test('set(cursor, npx) → coerced to localhost', () async {
      final n = McpInstallModeNotifier();
      await n.set('cursor', McpInstallMode.npx);
      expect(n.modeFor('cursor'), McpInstallMode.localhost);
    });

    test('set(cursor, localhost) → stays localhost (idempotent)', () async {
      final n = McpInstallModeNotifier();
      await n.set('cursor', McpInstallMode.localhost);
      expect(n.modeFor('cursor'), McpInstallMode.localhost);
    });

    test('Cursor coercion survives re-reads', () async {
      final n = McpInstallModeNotifier();
      await n.set('cursor', McpInstallMode.npx);
      // Re-reads after more sets keep the coerced value.
      await n.set('cursor', McpInstallMode.npx);
      expect(n.modeFor('cursor'), McpInstallMode.localhost);
    });
  });

  group('Claude/Codex — no coercion', () {
    test('Claude honors npx', () async {
      final n = McpInstallModeNotifier();
      await n.set('claudeCode', McpInstallMode.npx);
      expect(n.modeFor('claudeCode'), McpInstallMode.npx);
    });

    test('Claude can switch to localhost', () async {
      final n = McpInstallModeNotifier();
      await n.set('claudeCode', McpInstallMode.localhost);
      expect(n.modeFor('claudeCode'), McpInstallMode.localhost);
    });

    test('Codex honors npx', () async {
      final n = McpInstallModeNotifier();
      await n.set('codex', McpInstallMode.npx);
      expect(n.modeFor('codex'), McpInstallMode.npx);
    });

    test('Codex can switch to localhost', () async {
      final n = McpInstallModeNotifier();
      await n.set('codex', McpInstallMode.localhost);
      expect(n.modeFor('codex'), McpInstallMode.localhost);
    });
  });

  group('per-client isolation', () {
    test('Setting Claude to localhost doesn\'t touch Codex', () async {
      final n = McpInstallModeNotifier();
      await n.set('claudeCode', McpInstallMode.localhost);
      expect(n.modeFor('codex'), McpInstallMode.npx);
      // And vice versa.
      await n.set('codex', McpInstallMode.localhost);
      expect(n.modeFor('claudeCode'), McpInstallMode.localhost);
    });

    test('Cursor forced to localhost doesn\'t affect Claude/Codex', () async {
      final n = McpInstallModeNotifier();
      await n.set('cursor', McpInstallMode.npx); // coerced
      expect(n.modeFor('claudeCode'), McpInstallMode.npx);
      expect(n.modeFor('codex'), McpInstallMode.npx);
    });
  });

  group('McpInstallMode enum', () {
    test('has exactly npx + localhost', () {
      expect(McpInstallMode.values, [
        McpInstallMode.npx,
        McpInstallMode.localhost,
      ]);
    });
  });
}