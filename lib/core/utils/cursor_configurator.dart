import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class CursorConfigurator {
  /// npx install: writes a stdio entry pointing at
  /// `$workspace/client_sdks/devconnect-mcp/dist/index.js`. Cursor spawns
  /// the node process itself, so no separate server has to be running.
  static Future<bool> configure({
    required int wsPort,
    @visibleForTesting String? homeOverride,
  }) async {
    try {
      final home = homeOverride ?? _homeDir();
      if (home == null || home.isEmpty) return false;

      final cursorDir = Directory('$home/.cursor');
      if (!await cursorDir.exists()) {
        await cursorDir.create(recursive: true);
      }

      final configFile = File('${cursorDir.path}/mcp.json');
      Map<String, dynamic> config = _readExistingConfig(configFile);

      final mcpServers = config['mcpServers'] as Map<String, dynamic>? ?? {};
      config['mcpServers'] = mcpServers;

      final workspacePath = _resolveWorkspacePath(home);
      if (workspacePath == null) return false;
      final mcpScriptPath = '$workspacePath/client_sdks/devconnect-mcp/dist/index.js';

      mcpServers['devconnect-manage'] = {
        'command': 'node',
        'args': [mcpScriptPath],
        'env': {
          'DEVCONNECT_PORT': '$wsPort',
        },
      };

      const encoder = JsonEncoder.withIndent('  ');
      await configFile.writeAsString(encoder.convert(config));
      return true;
    } catch (_) {
      return false;
    }
  }


  /// Localhost install: writes an HTTP entry pointing at the local MCP
  /// server. The user must have the local server running (the desktop
  /// auto-spawns it when the panel opens, see [LocalMcpServerManager]).
  static Future<bool> configureHttp({
    required int httpPort,
    @visibleForTesting String? homeOverride,
  }) async {
    try {
      final home = homeOverride ?? _homeDir();
      if (home == null || home.isEmpty) return false;

      final cursorDir = Directory('$home/.cursor');
      if (!await cursorDir.exists()) {
        await cursorDir.create(recursive: true);
      }

      final configFile = File('${cursorDir.path}/mcp.json');
      Map<String, dynamic> config = _readExistingConfig(configFile);

      final mcpServers = config['mcpServers'] as Map<String, dynamic>? ?? {};
      config['mcpServers'] = mcpServers;

      mcpServers['devconnect-manage'] = {
        'url': 'http://127.0.0.1:$httpPort/mcp',
      };

      const encoder = JsonEncoder.withIndent('  ');
      await configFile.writeAsString(encoder.convert(config));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> uninstall({
    @visibleForTesting String? homeOverride,
  }) async {
    try {
      final home = homeOverride ?? _homeDir();
      if (home == null || home.isEmpty) return false;

      final configFile = File('$home/.cursor/mcp.json');
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        if (content.trim().isNotEmpty) {
          try {
            final config = jsonDecode(content) as Map<String, dynamic>;
            final mcpServers = config['mcpServers'] as Map<String, dynamic>?;
            if (mcpServers != null) {
              mcpServers.remove('devconnect-manage');
              const encoder = JsonEncoder.withIndent('  ');
              await configFile.writeAsString(encoder.convert(config));
              return true;
            }
          } catch (_) {}
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static String? _homeDir() {
    final home = Platform.isWindows
        ? Platform.environment['USERPROFILE']
        : Platform.environment['HOME'];
    if (home == null || home.isEmpty) return null;
    return home;
  }

  static Map<String, dynamic> _readExistingConfig(File configFile) {
    if (!configFile.existsSync()) return {};
    final content = configFile.readAsStringSync();
    if (content.trim().isEmpty) return {};
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Resolve the workspace root directory. `Directory.current` is
  /// unreliable inside a packaged macOS .app (returns `/`), so we also
  /// probe common dev locations and the DEVCONNECT_WORKSPACE env override.
  static String? _resolveWorkspacePath(String home) {
    final candidates = <String>[
      if (Platform.environment.containsKey('DEVCONNECT_WORKSPACE'))
        Platform.environment['DEVCONNECT_WORKSPACE']!,
      Directory.current.path,
      '$home/Documents/ridelink-techs/connect-totron',
      '$home/Documents/connect-totron',
      '$home/ridelink-techs/connect-totron',
      '$home/connect-totron',
    ];
    for (final root in candidates) {
      if (root.isEmpty || root == '/') continue;
      final pkg = File('$root/client_sdks/devconnect-mcp/package.json');
      if (pkg.existsSync()) return root;
    }
    return null;
  }
}

