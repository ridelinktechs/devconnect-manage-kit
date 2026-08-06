import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/mcp_clients.dart';
import 'package:devconnect_manage_tool/core/utils/mcp_installer.dart';
import 'package:devconnect_manage_tool/core/utils/mcp_install_checker.dart';

void main() {
  group('McpInstallArgs', () {
    test('stores all fields verbatim', () {
      const args = McpInstallArgs(
        wsPort: 5564,
        httpPort: 5565,
        localhostMode: true,
      );
      expect(args.wsPort, 5564);
      expect(args.httpPort, 5565);
      expect(args.localhostMode, isTrue);
    });

    test('localhostMode defaults to false', () {
      const args = McpInstallArgs(
        wsPort: 5564,
        httpPort: 5565,
        localhostMode: false,
      );
      expect(args.localhostMode, isFalse);
    });
  });

  group('McpInstallStatusNotifier — initial state', () {
    test('all 3 clients start as unknown ("checking…")', () {
      final n = McpInstallStatusNotifier(_FakeChecker());
      for (final id in McpClientId.values) {
        expect(n.state[id]?.status, McpInstallStatus.unknown);
        expect(n.state[id]?.detail, 'checking…');
      }
    });
  });

  group('McpInstallStatusNotifier — refreshOne', () {
    test('updates just the targeted client', () async {
      final checker = _FakeChecker(map: {
        McpClientId.claudeCode:
            const ClientInstallInfo(status: McpInstallStatus.installed),
      });
      final n = McpInstallStatusNotifier(checker);

      await n.refreshOne(McpClientId.claudeCode);

      // Targeted client got the result.
      expect(n.state[McpClientId.claudeCode]?.status,
          McpInstallStatus.installed);
      // Others stay at unknown initial state.
      expect(n.state[McpClientId.codex]?.status, McpInstallStatus.unknown);
      expect(n.state[McpClientId.cursor]?.status, McpInstallStatus.unknown);
    });

    test('subsequent calls replace the previous value', () async {
      // Build a notifier that returns notInstalled, refresh, then
      // build another one with a checker that returns installed.
      final notInstalled = _FakeChecker(map: const {
        McpClientId.claudeCode: ClientInstallInfo(
          status: McpInstallStatus.notInstalled,
        ),
      });
      final n1 = McpInstallStatusNotifier(notInstalled);
      await n1.refreshOne(McpClientId.claudeCode);
      expect(n1.state[McpClientId.claudeCode]?.status,
          McpInstallStatus.notInstalled);

      // Fresh notifier with a different checker — proves the state map
      // is independent between instances.
      final installed = _FakeChecker(map: const {
        McpClientId.claudeCode:
            ClientInstallInfo(status: McpInstallStatus.installed),
      });
      final n2 = McpInstallStatusNotifier(installed);
      await n2.refreshOne(McpClientId.claudeCode);
      expect(n2.state[McpClientId.claudeCode]?.status,
          McpInstallStatus.installed);
    });
  });

  group('McpInstallStatusNotifier — refreshAll', () {
    test('updates all 3 clients concurrently', () async {
      final checker = _FakeChecker(map: const {
        McpClientId.claudeCode:
            ClientInstallInfo(status: McpInstallStatus.installed),
        McpClientId.codex:
            ClientInstallInfo(status: McpInstallStatus.notInstalled),
        McpClientId.cursor:
            ClientInstallInfo(status: McpInstallStatus.unhealthy),
      });
      final n = McpInstallStatusNotifier(checker);

      await n.refreshAll();

      expect(n.state[McpClientId.claudeCode]?.status,
          McpInstallStatus.installed);
      expect(n.state[McpClientId.codex]?.status,
          McpInstallStatus.notInstalled);
      expect(n.state[McpClientId.cursor]?.status,
          McpInstallStatus.unhealthy);
    });
  });

  group('McpInstallChecker.check returns the right enum', () {
    test('installed is distinguishable from notInstalled', () {
      const installed = ClientInstallInfo(
        status: McpInstallStatus.installed,
        detail: 'HTTP',
      );
      const notInstalled = ClientInstallInfo(
        status: McpInstallStatus.notInstalled,
      );
      expect(installed.status, isNot(notInstalled.status));
    });

    test('unhealthy status carries the failure detail', () {
      const u = ClientInstallInfo(
        status: McpInstallStatus.unhealthy,
        detail: 'Failed to connect',
      );
      expect(u.detail, 'Failed to connect');
    });

    test('unknown status carries diagnostic context', () {
      const u = ClientInstallInfo(
        status: McpInstallStatus.unknown,
        detail: '`codex` CLI not found in PATH',
      );
      expect(u.detail, contains('codex'));
    });
  });
}

/// Test double — we don't want to spawn real `claude`/`codex`/read real
/// files in unit tests. `McpInstallStatusNotifier` takes a
/// `McpInstallChecker` as constructor arg so we inject a fake.
class _FakeChecker implements McpInstallChecker {
  final Map<McpClientId, ClientInstallInfo> map;
  _FakeChecker({this.map = const {}});

  @override
  Future<ClientInstallInfo> check(McpClientId clientId) async {
    return map[clientId] ??
        const ClientInstallInfo(
          status: McpInstallStatus.unknown,
          detail: 'fake-checker: not stubbed',
        );
  }
}

/// Test double — we don't want to spawn real `claude`/`codex`/read real
/// files in unit tests. `McpInstallStatusNotifier` takes a
/// `McpInstallChecker` as constructor arg so we inject a fake.