import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/utils/mcp_install_checker.dart';

void main() {
  group('parseClaudeGetOutput', () {
    test('"not found" on stdout → notInstalled', () {
      final r = parseClaudeGetOutput(
        stdout: 'Server devconnect-manage not found',
        stderr: '',
        exitCode: 1,
      );
      expect(r.status, McpInstallStatus.notInstalled);
    });

    test('"not found" on stderr → notInstalled', () {
      final r = parseClaudeGetOutput(
        stdout: '',
        stderr: 'Error: devconnect-manage not found in registry',
        exitCode: 2,
      );
      expect(r.status, McpInstallStatus.notInstalled);
    });

    test('"Status: ! Connected" → installed with detail line', () {
      final r = parseClaudeGetOutput(
        stdout: 'Name: devconnect-manage\nStatus: ! Connected\nTools: 17',
        stderr: '',
        exitCode: 0,
      );
      expect(r.status, McpInstallStatus.installed);
      expect(r.detail, '! Connected');
    });

    test('"Status: X Failed to connect" → unhealthy', () {
      final r = parseClaudeGetOutput(
        stdout: 'Name: devconnect-manage\nStatus: ✘ Failed to connect',
        stderr: '',
        exitCode: 0,
      );
      expect(r.status, McpInstallStatus.unhealthy);
      expect(r.detail, contains('Failed'));
    });

    test('non-zero exit without "not found" → unknown', () {
      final r = parseClaudeGetOutput(
        stdout: '',
        stderr: 'panic: something else',
        exitCode: 137,
      );
      expect(r.status, McpInstallStatus.unknown);
      expect(r.detail, contains('137'));
    });

    test('empty output + zero exit → installed (Status: empty)', () {
      // Edge case: claude prints nothing on success in some configs.
      final r = parseClaudeGetOutput(
        stdout: '',
        stderr: '',
        exitCode: 0,
      );
      // No "Status:" line means we can't say connected; falls through
      // to `connected = false` → unhealthy. That's the safe default.
      expect(r.status, McpInstallStatus.unhealthy);
      expect(r.detail, isNull);
    });
  });

  group('pickCodexEntry', () {
    test('returns found=true with HTTP transport', () {
      final list = [
        {
          'name': 'devconnect-manage',
          'enabled': true,
          'transport': {
            'type': 'streamable_http',
            'url': 'http://127.0.0.1:5565/mcp',
          },
        },
      ];
      final r = pickCodexEntry(list);
      expect(r.found, isTrue);
      expect(r.enabled, isTrue);
      expect(r.transportKind, 'HTTP');
    });

    test('returns found=true with stdio transport', () {
      final list = [
        {
          'name': 'devconnect-manage',
          'enabled': true,
          'transport': {'type': 'stdio'},
        },
      ];
      final r = pickCodexEntry(list);
      expect(r.found, isTrue);
      expect(r.transportKind, 'stdio');
    });

    test('detects disabled entries', () {
      final list = [
        {
          'name': 'devconnect-manage',
          'enabled': false,
          'transport': {'type': 'stdio'},
        },
      ];
      final r = pickCodexEntry(list);
      expect(r.found, isTrue);
      expect(r.enabled, isFalse);
    });

    test('returns found=false when our name is missing', () {
      final list = [
        {'name': 'context7', 'transport': {'type': 'stdio'}},
      ];
      final r = pickCodexEntry(list);
      expect(r.found, isFalse);
    });

    test('handles missing transport field', () {
      // Some codex versions omit transport.type for unknown reasons.
      final list = [
        {'name': 'devconnect-manage', 'enabled': true},
      ];
      final r = pickCodexEntry(list);
      expect(r.found, isTrue);
      expect(r.transportKind, 'stdio'); // default fallback
    });
  });

  group('pickCursorEntry', () {
    test('HTTP entry (localhost mode)', () {
      final root = {
        'mcpServers': {
          'devconnect-manage': {
            'url': 'http://127.0.0.1:5565/mcp',
          },
        },
      };
      final r = pickCursorEntry(root);
      expect(r.found, isTrue);
      expect(r.transportKind, 'HTTP');
    });

    test('stdio entry (npx mode)', () {
      final root = {
        'mcpServers': {
          'devconnect-manage': {
            'command': 'node',
            'args': ['/path/to/dist/index.js'],
          },
        },
      };
      final r = pickCursorEntry(root);
      expect(r.found, isTrue);
      expect(r.transportKind, 'stdio');
    });

    test('returns found=false when entry absent', () {
      final root = {
        'mcpServers': {'context7': {}},
      };
      final r = pickCursorEntry(root);
      expect(r.found, isFalse);
    });

    test('handles missing mcpServers', () {
      final root = <String, dynamic>{};
      final r = pickCursorEntry(root);
      expect(r.found, isFalse);
    });

    test('mcpServers not a Map → false', () {
      final root = {'mcpServers': 'broken'};
      final r = pickCursorEntry(root);
      expect(r.found, isFalse);
    });

    test('case-insensitive lookup (defensive)', () {
      // Hand-edited file → user typed "DevConnect-Manage" instead of
      // the canonical "devconnect-manage".
      final root = {
        'mcpServers': {
          'DevConnect-Manage': {
            'url': 'http://127.0.0.1:5565/mcp',
          },
        },
      };
      final r = pickCursorEntry(root);
      expect(r.found, isTrue);
      expect(r.transportKind, 'HTTP');
    });
  });

  group('jsonDecodeSafe', () {
    test('returns null for malformed JSON', () {
      expect(jsonDecodeSafe('{not json'), isNull);
    });

    test('returns null for empty input', () {
      expect(jsonDecodeSafe(''), isNull);
      expect(jsonDecodeSafe('   '), isNull);
    });

    test('roundtrips valid JSON', () {
      expect(jsonDecodeSafe('{"a": 1}'), {'a': 1});
      expect(jsonDecodeSafe('[1, 2, 3]'), [1, 2, 3]);
    });
  });
}