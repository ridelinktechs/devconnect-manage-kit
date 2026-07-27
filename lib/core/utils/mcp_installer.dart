import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/mcp_clients.dart';
import 'cli_resolver.dart';
import 'cursor_configurator.dart';

/// Args threaded into the install/uninstall flows so the right transport
/// (stdio vs HTTP) gets written for the right AI client.
class McpInstallArgs {
  final int wsPort;
  final int httpPort;
  final bool localhostMode;

  const McpInstallArgs({
    required this.wsPort,
    required this.httpPort,
    required this.localhostMode,
  });
}

class McpInstaller {
  /// Write the MCP config for [clientId] using the right transport.
  /// Cursor: edits `~/.cursor/mcp.json`. Claude Code / Codex: shells out
  /// to the CLI's `mcp add` command.
  static Future<bool> runInstall(
    ProviderContainer container,
    McpClientId clientId,
    McpInstallArgs args,
  ) async {
    if (clientId == McpClientId.cursor) {
      return args.localhostMode
          ? await CursorConfigurator.configureHttp(httpPort: args.httpPort)
          : await CursorConfigurator.configure(wsPort: args.wsPort);
    }

    final client = mcpClients[clientId]!;
    final exe = await resolveCliBinary(client.binaryName);
    if (exe == null) return false;

    try {
      // Per-client CLI semantics for HTTP install:
      //  - Claude Code: `claude mcp add --transport http <name> <url>`
      //                 URL is positional, no --url flag.
      //  - Codex:       `codex mcp add <name> --url <url>`
      //                 URL is a --url flag value.
      final cliArgs = args.localhostMode
          ? (clientId == McpClientId.claudeCode
              ? [
                  'mcp',
                  'add',
                  '--transport',
                  'http',
                  'devconnect-manage',
                  'http://127.0.0.1:${args.httpPort}/mcp',
                ]
              : [
                  'mcp',
                  'add',
                  'devconnect-manage',
                  '--url',
                  'http://127.0.0.1:${args.httpPort}/mcp',
                ])
          : [
              'mcp',
              'add',
              'devconnect-manage',
              '--',
              'npx',
              '-y',
              'devconnect-manage',
            ];
      final result = await Process.run(exe, cliArgs, environment: augmentedEnv())
          .timeout(const Duration(seconds: 30));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> runUninstall(
    ProviderContainer container,
    McpClientId clientId,
  ) async {
    if (clientId == McpClientId.cursor) {
      return await CursorConfigurator.uninstall();
    }

    final client = mcpClients[clientId]!;
    final exe = await resolveCliBinary(client.binaryName);
    if (exe == null) return false;

    try {
      final result = await Process.run(
        exe,
        ['mcp', 'remove', 'devconnect-manage'],
        environment: augmentedEnv(),
      ).timeout(const Duration(seconds: 30));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}