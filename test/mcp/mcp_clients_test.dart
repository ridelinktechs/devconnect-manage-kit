import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/mcp_clients.dart';

void main() {
  group('defaultLocalMcpHttpPort', () {
    test('is 5565 (avoids desktop MCP WS port 5564)', () {
      expect(defaultLocalMcpHttpPort, 5565);
    });
  });

  group('localhostCommandAt', () {
    test('Claude HTTP — URL positional, no --url flag', () {
      final cmd = localhostCommandAt(McpClientId.claudeCode, 5565);
      // Must NOT contain `--url` — Claude uses positional URL.
      expect(cmd, isNot(contains('--url')));
      expect(cmd, startsWith('claude mcp add --transport http'));
      expect(cmd, contains('devconnect-manage'));
      expect(cmd, contains('http://127.0.0.1:5565/mcp'));
      expect(cmd, contains('--scope user'));
    });

    test('Codex HTTP — uses --url flag', () {
      final cmd = localhostCommandAt(McpClientId.codex, 5567);
      expect(cmd, contains('--url'));
      expect(cmd, contains('codex mcp add devconnect-manage'));
      expect(cmd, contains('http://127.0.0.1:5567/mcp'));
      // Codex does NOT use --scope.
      expect(cmd, isNot(contains('--scope')));
    });

    test('Cursor — no CLI, hint to edit mcp.json', () {
      final cmd = localhostCommandAt(McpClientId.cursor, 6000);
      expect(cmd, contains('Run install'));
      expect(cmd, contains('~/.cursor/mcp.json'));
      expect(cmd, contains('http://127.0.0.1:6000/mcp'));
    });
  });

  group('mcpClients catalog', () {
    test('covers all 3 clientIds', () {
      expect(mcpClients.length, McpClientId.values.length);
      expect(mcpClients.keys, containsAll(McpClientId.values));
    });

    test('every entry has a non-empty uninstall command', () {
      for (final entry in mcpClients.values) {
        expect(entry.uninstallCommand, isNotEmpty,
            reason: '${entry.displayName} missing uninstallCommand');
        // Claude uses -s user flag in its uninstall.
        if (entry.clientId == McpClientId.claudeCode) {
          expect(entry.uninstallCommand, contains('remove'));
        }
      }
    });

    test('Cursor install command defaults to localhost only', () {
      // Cursor has no CLI; the install snippet is informational only.
      // We verify the catalog entry wires the localhost command into
      // it (Cursor is forced to localhost mode in the UI).
      final cursor = mcpClients[McpClientId.cursor]!;
      expect(cursor.command, contains('Run install'));
      expect(cursor.localhostCommand, contains('mcp.json'));
    });

    test('Claude Code npx command uses --transport stdio', () {
      final claude = mcpClients[McpClientId.claudeCode]!;
      expect(claude.command, contains('--transport stdio'));
      expect(claude.command, contains('npx -y devconnect-manage'));
    });

    test('Codex npx command matches Codex CLI syntax', () {
      final codex = mcpClients[McpClientId.codex]!;
      expect(codex.command, contains('codex mcp add devconnect-manage'));
      expect(codex.command, contains('npx -y devconnect-manage'));
      // Codex does NOT use --scope user.
      expect(codex.command, isNot(contains('--scope')));
    });
  });

  group('localhostCommandAt — port substitution', () {
    test('uses supplied port verbatim', () {
      expect(
        localhostCommandAt(McpClientId.claudeCode, 9999),
        contains('http://127.0.0.1:9999/mcp'),
      );
    });

    test('handles non-default port (e.g. after fallback)', () {
      // If 5565 was busy and we fell back to 5566, the command must
      // reflect that — the install command is generated from
      // localMcp.port, not from the constant.
      expect(
        localhostCommandAt(McpClientId.codex, 5566),
        contains(':5566/mcp'),
      );
    });
  });
}