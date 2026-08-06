import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/mcp_clients.dart';
import 'package:devconnect_manage_tool/core/providers/mcp_pairing_provider.dart';

void main() {
  group('McpInstallHistoryNotifier — append', () {
    test('starts empty', () {
      final n = McpInstallHistoryNotifier();
      expect(n.state, isEmpty);
    });

    test('append() prepends new entry (newest first)', () async {
      final n = McpInstallHistoryNotifier();
      await n.append(_entry(id: '1', action: McpAction.run));
      await n.append(_entry(id: '2', action: McpAction.copy));
      expect(n.state.length, 2);
      expect(n.state.first.id, '2');
      expect(n.state.last.id, '1');
    });

    test('caps at 200 entries — oldest get pruned', () async {
      final n = McpInstallHistoryNotifier();
      for (var i = 0; i < 250; i++) {
        await n.append(_entry(id: '$i'));
      }
      expect(n.state.length, 200);
      // Newest (i=249) at front, oldest kept (i=50) at back.
      expect(n.state.first.id, '249');
      expect(n.state.last.id, '50');
    });

    test('preserves action / clientId / result', () async {
      final n = McpInstallHistoryNotifier();
      await n.append(InstallAttempt(
        id: 'a',
        action: McpAction.uninstall,
        clientId: McpClientId.cursor,
        result: McpResult.success,
        timestamp: DateTime.now(),
      ));
      expect(n.state.first.action, McpAction.uninstall);
      expect(n.state.first.clientId, McpClientId.cursor);
      expect(n.state.first.result, McpResult.success);
    });
  });

  group('InstallAttempt JSON roundtrip', () {
    test('round-trips through toJson / fromJson', () {
      final original = InstallAttempt(
        id: 'abc',
        action: McpAction.run,
        clientId: McpClientId.claudeCode,
        result: McpResult.failed,
        command: 'install',
        stdout: 'hello',
        stderr: 'oops',
        exitCode: 1,
        durationMs: 1234,
        startedAt: DateTime.utc(2026, 7, 27, 10),
        finishedAt: DateTime.utc(2026, 7, 27, 10, 1),
        timestamp: DateTime.utc(2026, 7, 27, 10, 1),
      );
      final json = original.toJson();
      final restored = InstallAttempt.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.action, original.action);
      expect(restored.clientId, original.clientId);
      expect(restored.result, original.result);
      expect(restored.exitCode, original.exitCode);
      expect(restored.durationMs, original.durationMs);
    });

    test('fromJson tolerates missing fields', () {
      // Older payloads may omit optional fields.
      final restored = InstallAttempt.fromJson({
        'id': 'x',
        'timestamp': '2026-07-27T10:00:00Z',
      });
      expect(restored.id, 'x');
      expect(restored.action, McpAction.run); // default
      expect(restored.clientId, isNull);
      expect(restored.result, isNull);
    });

    test('fromJson throws on missing id', () {
      expect(
        () => InstallAttempt.fromJson({'timestamp': '2026-07-27T10:00:00Z'}),
        throwsFormatException,
      );
    });
  });

  group('McpAction / McpResult enums', () {
    test('action enum values', () {
      expect(McpAction.values, hasLength(3));
      expect(McpAction.values, containsAll([
        McpAction.copy,
        McpAction.run,
        McpAction.uninstall,
      ]));
    });

    test('result enum values', () {
      expect(McpResult.values, hasLength(4));
      expect(McpResult.values, containsAll([
        McpResult.success,
        McpResult.failed,
        McpResult.timeout,
        McpResult.notFound,
      ]));
    });
  });
}

InstallAttempt _entry({required String id, McpAction action = McpAction.run}) {
  return InstallAttempt(
    id: id,
    action: action,
    timestamp: DateTime.now(),
  );
}