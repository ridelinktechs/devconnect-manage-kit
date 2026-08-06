import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/mcp_clients.dart';
import 'package:devconnect_manage_tool/core/utils/local_mcp_server_manager.dart';

void main() {
  group('LocalMcpServerStatus (data class)', () {
    test('default idle status has expected fields', () {
      const s = LocalMcpServerStatus.idle;
      expect(s.state, LocalMcpServerState.stopped);
      expect(s.port, defaultLocalMcpHttpPort);
      expect(s.lastError, isNull);
      expect(s.lastStderr, isNull);
    });

    test('all fields are stored verbatim', () {
      const s = LocalMcpServerStatus(
        state: LocalMcpServerState.crashed,
        port: 6000,
        lastError: 'oops',
        lastStderr: 'EADDRINUSE',
      );
      expect(s.state, LocalMcpServerState.crashed);
      expect(s.port, 6000);
      expect(s.lastError, 'oops');
      expect(s.lastStderr, 'EADDRINUSE');
    });
  });

  group('LocalMcpServerState enum', () {
    test('has the 4 expected states', () {
      expect(LocalMcpServerState.values, hasLength(4));
      expect(LocalMcpServerState.values, containsAll([
        LocalMcpServerState.stopped,
        LocalMcpServerState.starting,
        LocalMcpServerState.running,
        LocalMcpServerState.crashed,
      ]));
    });
  });

  group('defaultLocalMcpHttpPort', () {
    test('is 5565 (avoids 5564 desktop WS port)', () {
      expect(defaultLocalMcpHttpPort, 5565);
    });
  });

  group('isPortListening', () {
    test('returns true for a port a ServerSocket is bound to', () async {
      // Bind a real listener on an ephemeral port so the test doesn't
      // collide with anything in the CI env.
      final server = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(() => unawaited(server.close()));
      expect(await LocalMcpServerManager.isPortListening(server.port), isTrue);
    });

    test('returns false for an unused port', () async {
      // Pick a high random port unlikely to be in use. The probe has
      // a 500ms timeout, so a refused connect returns within the
      // test budget.
      expect(await LocalMcpServerManager.isPortListening(1), isFalse);
    });

    test('returns false after the listener closes', () async {
      final server = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final port = server.port;
      await server.close();
      expect(await LocalMcpServerManager.isPortListening(port), isFalse);
    });
  });

  group('pickFreePort', () {
    test('returns the requested port when free', () async {
      final p = await LocalMcpServerManager.pickFreePort(40000);
      expect(p, 40000);
    });

    test('skips an occupied port and returns the next free one',
        () async {
      // Occupy port 40010.
      final blocker = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        40010,
      );
      addTearDown(() => unawaited(blocker.close()));
      final p = await LocalMcpServerManager.pickFreePort(40010);
      expect(p, 40011);
    });

    test('skips multiple occupied ports in order', () async {
      final servers = <ServerSocket>[];
      try {
        for (final p in [40020, 40021, 40022]) {
          servers.add(await ServerSocket.bind(
            InternetAddress.loopbackIPv4,
            p,
          ));
        }
        final picked = await LocalMcpServerManager.pickFreePort(40020);
        expect(picked, 40023);
      } finally {
        for (final s in servers) {
          await s.close();
        }
      }
    });

    test('returns null when all 11 candidates are occupied', () async {
      final servers = <ServerSocket>[];
      try {
        for (final p in List.generate(11, (i) => 40030 + i)) {
          servers.add(await ServerSocket.bind(
            InternetAddress.loopbackIPv4,
            p,
          ));
        }
        final picked = await LocalMcpServerManager.pickFreePort(40030);
        expect(picked, isNull);
      } finally {
        for (final s in servers) {
          await s.close();
        }
      }
    });
  });
}