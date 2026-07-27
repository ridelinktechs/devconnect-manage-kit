import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/mcp_clients.dart';
import '../../features/settings/presentation/mcp/cli_resolver.dart'
    show augmentedEnv;

/// Lifecycle state of the local HTTP MCP server. Surfaced through a
/// Riverpod provider so the UI can show a "Running / Stopped / Crashed"
/// indicator next to the localhost install cards.
enum LocalMcpServerState { stopped, starting, running, crashed }

class LocalMcpServerStatus {
  final LocalMcpServerState state;
  final int port;
  final String? lastError;

  /// Tail of the node stderr buffer from the most recent run. Useful
  /// when status flips to `crashed` and the user wants to see *why*
  /// (EADDRINUSE, ENOENT, Module not found, …).
  final String? lastStderr;

  const LocalMcpServerStatus({
    required this.state,
    required this.port,
    this.lastError,
    this.lastStderr,
  });

  static const idle = LocalMcpServerStatus(
    state: LocalMcpServerState.stopped,
    port: defaultLocalMcpHttpPort,
  );
}

/// Owns the lifecycle of a single `node dist/index.js --http` child
/// process. Singleton-ish via a Riverpod provider so every widget that
/// watches it sees the same status. Calling [start] when already running
/// is a no-op; calling [stop] when not running is a no-op.
///
/// Process management is deliberately simple:
///   - Single [Process] handle stored in a private field.
///   - SIGTERM on stop; if the child doesn't exit in 2s we kill -9.
///   - On unexpected exit we flip state to `crashed` with the stderr tail
///     so the UI can show "node crashed — see log" instead of silently
///     pretending everything's fine.
///
/// ponytail: launching node on macOS GUI app inherits the same PATH
/// problem as the CLI resolver — fix is [augmentedEnv].
class LocalMcpServerManager {
  Process? _proc;
  LocalMcpServerStatus _status = LocalMcpServerStatus.idle;
  /// Rolling tail of the most recent stderr stream. Capped at 2KB so
  /// a verbose node script doesn't blow memory. Cleared on each new
  /// start.
  final StringBuffer _stderrTail = StringBuffer();
  final _statusCtrl = StreamController<LocalMcpServerStatus>.broadcast();

  LocalMcpServerStatus get status => _status;
  Stream<LocalMcpServerStatus> get statusStream => _statusCtrl.stream;

  Future<void> start({
    required int desktopWsPort,
    int httpPort = defaultLocalMcpHttpPort,
  }) async {
    if (_status.state == LocalMcpServerState.starting ||
        _status.state == LocalMcpServerState.running) {
      return;
    }

    _update(LocalMcpServerStatus(
      state: LocalMcpServerState.starting,
      port: httpPort,
    ));

    try {
      final scriptPath = await _resolveScriptPath();
      if (scriptPath == null) {
        _update(LocalMcpServerStatus(
          state: LocalMcpServerState.crashed,
          port: httpPort,
          lastError:
              'client_sdks/devconnect-mcp not found. Tried likely workspace locations.',
        ));
        return;
      }
      var scriptFile = File(scriptPath);
      if (!scriptFile.existsSync()) {
        // dist/ is missing — try to auto-build before giving up. This
        // covers fresh checkouts where the user hasn't run `npm run
        // build` yet.
        final pkgDir = File(scriptPath).parent.parent.path;
        final built = await _autoBuildScript(pkgDir);
        if (!built) {
          _update(LocalMcpServerStatus(
            state: LocalMcpServerState.crashed,
            port: httpPort,
            lastError:
                'dist/index.js missing and `npm run build` failed in $pkgDir.',
          ));
          return;
        }
        scriptFile = File(scriptPath);
        if (!scriptFile.existsSync()) {
          _update(LocalMcpServerStatus(
            state: LocalMcpServerState.crashed,
            port: httpPort,
            lastError:
                'Build reported success but dist/index.js still missing in $pkgDir.',
          ));
          return;
        }
      }

      final nodeBin = await _resolveNodeBinary();
      if (nodeBin == null) {
        _update(LocalMcpServerStatus(
          state: LocalMcpServerState.crashed,
          port: httpPort,
          lastError: 'Could not locate a `node` binary in PATH.',
        ));
        return;
      }

      // The Node script needs the desktop's MCP WebSocket control channel
      // up on `desktopWsPort`. Without it the script's `desktop.connect()`
      // throws and the process exits before binding the HTTP listener —
      // the user would see a misleading "port already in use" error.
      // Probe the port first so we can fail with an actionable message.
      if (!await _isPortListening(desktopWsPort)) {
        _update(LocalMcpServerStatus(
          state: LocalMcpServerState.crashed,
          port: httpPort,
          lastError:
              'Desktop MCP server not running on port $desktopWsPort. '
              'Start it from Settings → Server → MCP Port, or enable MCP '
              'Auto-start.',
          lastStderr: 'connect ECONNREFUSED 127.0.0.1:$desktopWsPort',
        ));
        return;
      }

      // Pick the first free port for the local HTTP listener, starting
      // at [httpPort] and trying up to 10 higher. Without this, an old
      // crashed process stuck in TIME_WAIT would make the new node exit
      // with EADDRINUSE within milliseconds — before stdout flush —
      // and we'd surface a generic "did not become healthy" error.
      final chosenPort = await _pickFreePort(httpPort);
      if (chosenPort == null) {
        _update(LocalMcpServerStatus(
          state: LocalMcpServerState.crashed,
          port: httpPort,
          lastError:
              'No free port for local HTTP MCP server (tried $httpPort–${httpPort + 10}). '
              'Close other node processes or set a different port.',
          lastStderr: 'EADDRINUSE on every probed port',
        ));
        return;
      }

      _stderrTail.clear();
      _update(LocalMcpServerStatus(
        state: LocalMcpServerState.starting,
        port: chosenPort,
      ));

      final proc = await Process.start(
        nodeBin,
        [scriptPath, '--http', '--port', '$chosenPort'],
        environment: {
          ...augmentedEnv(),
          'DEVCONNECT_HOST': '127.0.0.1',
          'DEVCONNECT_PORT': '$desktopWsPort',
          'DEVCONNECT_HTTP_PORT': '$chosenPort',
        },
      );
      _proc = proc;

      // Drain stdout to prevent the process from blocking due to full buffer
      proc.stdout.transform(utf8.decoder).listen((s) {
        debugPrint('[local-mcp-stdout] $s');
      });

      // Drain stderr into both the debug log and a rolling tail buffer
      // capped at 2KB — surfaced via LocalMcpServerStatus.lastStderr
      // when the process exits so the UI can show *why* it crashed.
      proc.stderr.transform(utf8.decoder).listen((s) {
        _stderrTail.write(s);
        // Cap at 2KB. StringBuffer has no removeRange, so rebuild.
        if (_stderrTail.length > 2048) {
          final cur = _stderrTail.toString();
          _stderrTail
            ..clear()
            ..write(cur.substring(cur.length - 2048));
        }
        debugPrint('[local-mcp-stderr] $s');
      });

      proc.exitCode.then((code) {
        if (_proc == proc) {
          _proc = null;
          _update(LocalMcpServerStatus(
            state: code == 0
                ? LocalMcpServerState.stopped
                : LocalMcpServerState.crashed,
            port: chosenPort,
            lastError: code == 0
                ? null
                : 'Local MCP server exited with code $code',
            lastStderr: _stderrTail.toString().trim().isEmpty
                ? null
                : _stderrTail.toString(),
          ));
        }
      });

      final ready = await _waitForHealth(chosenPort, proc);
      if (_proc != proc) {
        // The process has already exited (or been stopped), and the exit handler
        // has already updated the state appropriately. Do not overwrite it.
        return;
      }
      if (!ready) {
        final stderr = _stderrTail.toString().trim();
        await stop(httpPort: chosenPort);
        // If stderr is empty the most likely cause is EADDRINUSE on a
        // port we just confirmed was free — race with another bind
        // landing between our probe and node's listen(). Surface a
        // specific message so the user isn't guessing.
        final isEaddrinuse = stderr.isEmpty;
        _update(LocalMcpServerStatus(
          state: LocalMcpServerState.crashed,
          port: chosenPort,
          lastError: stderr.isNotEmpty
              ? 'Local MCP server failed to start. Tail of stderr below.'
              : (isEaddrinuse
                  ? 'Local MCP server failed to bind port $chosenPort (EADDRINUSE). '
                      'Close other node processes or set a different port.'
                  : 'Local MCP server did not become healthy within 5s on port $chosenPort.'),
          lastStderr: stderr.isEmpty ? null : stderr,
        ));
        return;
      }

      _update(LocalMcpServerStatus(
        state: LocalMcpServerState.running,
        port: chosenPort,
      ));
    } catch (e) {
      _update(LocalMcpServerStatus(
        state: LocalMcpServerState.crashed,
        port: httpPort,
        lastError: e.toString(),
        lastStderr: _stderrTail.toString().trim().isEmpty
            ? null
            : _stderrTail.toString(),
      ));
    }
  }

  Future<void> stop({int httpPort = defaultLocalMcpHttpPort}) async {
    final proc = _proc;
    if (proc == null) return;
    _proc = null;
    try {
      proc.kill(ProcessSignal.sigterm);
    } catch (_) {}
    try {
      await proc.exitCode.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      try {
        proc.kill(ProcessSignal.sigkill);
      } catch (_) {}
    }
    _update(LocalMcpServerStatus(
      state: LocalMcpServerState.stopped,
      port: httpPort,
    ));
  }

  void _update(LocalMcpServerStatus next) {
    _status = next;
    _statusCtrl.add(next);
  }

  void dispose() {
    _proc?.kill(ProcessSignal.sigkill);
    _proc = null;
    _statusCtrl.close();
  }

/// Walk a list of likely workspace roots and return the absolute path
/// to `client_sdks/devconnect-mcp/dist/index.js` if any of them
/// resolves to an existing project. `Directory.current` is unreliable
/// inside a packaged .app (returns `/`), so we also probe common dev
/// locations and the `DEVCONNECT_WORKSPACE` env override.
///
/// ponytail: scanning ~ for a project named connect-totron would be
/// the most "works-everywhere" option but might match unrelated dirs.
/// Sticking to fixed candidates and the env var.
Future<String?> _resolveScriptPath() async {
  final home = Platform.environment['HOME'] ?? '';
  final docDir = '$home/Documents';
  final candidates = <String>[
    if (Platform.environment.containsKey('DEVCONNECT_WORKSPACE'))
      Platform.environment['DEVCONNECT_WORKSPACE']!,
    Directory.current.path,
    '$docDir/ridelink-techs/connect-totron',
    '$docDir/connect-totron',
    '$home/ridelink-techs/connect-totron',
    '$home/connect-totron',
  ];
  for (final root in candidates) {
    if (root.isEmpty) continue;
    final script = '$root/client_sdks/devconnect-mcp/dist/index.js';
    if (File(script).existsSync()) return script;
    final pkg = File('$root/client_sdks/devconnect-mcp/package.json');
    if (pkg.existsSync()) {
      // Project exists but dist/ hasn't been built yet — return the
      // would-be path so the caller can run _autoBuildScript against it.
      return script;
    }
  }
  return null;
}

/// Run `npm install` (if needed) + `npm run build` in [pkgDir] so the
/// Node script exists. Pipes stderr into the rolling tail so a failure
/// surfaces via `lastError` + `lastStderr` in the status UI.
Future<bool> _autoBuildScript(String pkgDir) async {
  debugPrint('[local-mcp] auto-building MCP server in $pkgDir');
  _stderrTail.clear();
  try {
    final hasNodeModules = Directory('$pkgDir/node_modules').existsSync();
    final steps = <List<String>>[
      if (!hasNodeModules) ...[
        ['npm', 'install', '--no-audit', '--no-fund'],
        ['npm', 'run', 'build'],
      ] else ...[
        ['npm', 'run', 'build'],
      ],
    ];
    for (final cmd in steps) {
      final r = await Process.run(
        cmd.first,
        cmd.sublist(1),
        workingDirectory: pkgDir,
        environment: augmentedEnv(),
      ).timeout(const Duration(minutes: 3));
      _stderrTail.write(r.stderr.toString());
      if (r.exitCode != 0) {
        debugPrint(
          '[local-mcp] ${cmd.join(" ")} failed: exit ${r.exitCode}',
        );
        return false;
      }
    }
    return true;
  } catch (e) {
    _stderrTail.write(e.toString());
    return false;
  }
}

/// Cheap TCP probe that returns true if some process is already
/// listening on [port] on 127.0.0.1. Used to detect whether the
/// desktop's MCP WebSocket server is up before we spawn the local
/// Node child — saves us from the "Node silently exits because
/// desktop.connect() refused" failure mode.
Future<bool> _isPortListening(int port) async {
  try {
    final s = await Socket.connect('127.0.0.1', port,
        timeout: const Duration(milliseconds: 500));
    s.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

/// Scan [start..start+10] for the first port we can actually bind a
/// socket to. Uses [ServerSocket.bind] (with the kernel's default
/// SO_REUSEADDR handling) so TIME_WAIT — which a plain
/// [Socket.connect] probe would mis-report as "free" — is detected
/// correctly. Returns the chosen port, or null if every candidate is
/// occupied.
Future<int?> _pickFreePort(int start) async {
  for (var p = start; p < start + 11; p++) {
    try {
      final s = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        p,
      );
      await s.close();
      return p;
    } catch (_) {
      // Try the next port.
    }
  }
  return null;
}

Future<String?> _resolveNodeBinary() async {
    try {
      final r = await Process.run('which', ['node'])
          .timeout(const Duration(seconds: 2));
      if (r.exitCode == 0) {
        final p = r.stdout.toString().trim().split('\n').first.trim();
        if (p.isNotEmpty && File(p).existsSync()) return p;
      }
    } catch (_) {}
    final home = Platform.environment['HOME'] ?? '';
    final candidates = Platform.isMacOS
        ? const ['/opt/homebrew/bin/node', '/usr/local/bin/node']
        : const ['/usr/local/bin/node', '/usr/bin/node'];
    for (final c in candidates) {
      if (File(c).existsSync()) return c;
    }
    if (home.isNotEmpty) {
      final nvm = Directory('$home/.nvm/versions/node');
      if (nvm.existsSync()) {
        try {
          for (final entry in nvm.listSync()) {
            if (entry is Directory) {
              final p = '${entry.path}/bin/node';
              if (File(p).existsSync()) return p;
            }
          }
        } catch (_) {}
      }
    }
    return null;
  }

  Future<bool> _waitForHealth(int port, Process proc) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 1);
    for (var i = 0; i < 10; i++) {
      if (_proc != proc) {
        client.close(force: true);
        return false;
      }
      try {
        final req = await client.getUrl(Uri.parse('http://127.0.0.1:$port/health'));
        final resp = await req.close().timeout(const Duration(seconds: 1));
        if (resp.statusCode == 200) {
          client.close(force: true);
          return true;
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
    }
    client.close(force: true);
    return false;
  }
}

class LocalMcpServerNotifier extends StateNotifier<LocalMcpServerStatus> {
  final LocalMcpServerManager _manager;

  LocalMcpServerNotifier(this._manager)
      : super(LocalMcpServerStatus.idle) {
    _manager.statusStream.listen((next) {
      if (mounted) state = next;
    });
  }

  Future<void> start({required int desktopWsPort}) =>
      _manager.start(desktopWsPort: desktopWsPort, httpPort: state.port);

  Future<void> stop() => _manager.stop(httpPort: state.port);

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }
}

final localMcpServerProvider = StateNotifierProvider<LocalMcpServerNotifier,
    LocalMcpServerStatus>((ref) {
  final manager = LocalMcpServerManager();
  ref.onDispose(manager.dispose);
  return LocalMcpServerNotifier(manager);
});