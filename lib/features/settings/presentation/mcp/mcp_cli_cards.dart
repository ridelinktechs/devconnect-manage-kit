import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mcp_clients.dart';
import '../../../../core/providers/mcp_install_mode_provider.dart';
import '../../../../core/providers/mcp_pairing_provider.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/cursor_configurator.dart';
import '../../../../core/utils/local_mcp_server_manager.dart';
import '../../../../core/utils/mcp_install_checker.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../server/providers/server_providers.dart';
import '../../../../l10n/app_localizations.dart';
import 'cli_resolver.dart';
import 'mcp_install_result_dialog.dart';

class McpCliCards extends ConsumerWidget {
  const McpCliCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = S.of(context);
    final port = ref.watch(mcpWsServerProvider).port;
    final localMcp = ref.watch(localMcpServerProvider);
    // Resolve the workspace path used for Cursor's stdio JSON snippet.
    // Directory.current returns '/' in packaged .app bundles — fall
    // back to DEVCONNECT_WORKSPACE env or common dev locations.
    final workspacePath = _resolveWorkspaceForSnippet();
    final mcpScriptPath = '$workspacePath/client_sdks/devconnect-mcp/dist/index.js';

    final cursorNpxSnippet = '''
"devconnect-manage": {
  "command": "node",
  "args": ["$mcpScriptPath"],
  "env": {
    "DEVCONNECT_PORT": "$port"
  }
}''';

    final cursorLocalhostSnippet = '''
"devconnect-manage": {
  "url": "http://127.0.0.1:${localMcp.port}/mcp"
}''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Stagger(
          index: 0,
          child: _ClientCard(
            client: mcpClients[McpClientId.claudeCode]!,
            onCopy: (snippet) {
              Clipboard.setData(ClipboardData(text: snippet));
              showCopiedToast(context, label: loc.mcpCommandCopied);
            },
          ),
        ),
        const SizedBox(height: 10),
        _Stagger(
          index: 1,
          child: _ClientCard(
            client: mcpClients[McpClientId.codex]!,
            onCopy: (snippet) {
              Clipboard.setData(ClipboardData(text: snippet));
              showCopiedToast(context, label: loc.mcpCommandCopied);
            },
          ),
        ),
        const SizedBox(height: 10),
        _Stagger(
          index: 2,
          child: _ClientCard(
            client: mcpClients[McpClientId.cursor]!,
            cursorNpxSnippet: cursorNpxSnippet,
            cursorLocalhostSnippet: cursorLocalhostSnippet,
            onCopy: (snippet) {
              Clipboard.setData(ClipboardData(text: snippet));
              showCopiedToast(
                context,
                label: 'JSON configuration copied to clipboard!',
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Staggered fade + slide-up reveal. Items 0/1/2 cascade in over 60ms
/// each so the three cards feel choreographed rather than instant.
class _Stagger extends StatefulWidget {
  final int index;
  final Widget child;
  const _Stagger({required this.index, required this.child});

  @override
  State<_Stagger> createState() => _StaggerState();
}

class _StaggerState extends State<_Stagger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_ctrl);
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class _ClientCard extends ConsumerStatefulWidget {
  final TokenCommandTemplate client;
  final String? cursorNpxSnippet;
  final String? cursorLocalhostSnippet;
  final void Function(String snippet) onCopy;

  const _ClientCard({
    required this.client,
    required this.onCopy,
    this.cursorNpxSnippet,
    this.cursorLocalhostSnippet,
  });

  @override
  ConsumerState<_ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends ConsumerState<_ClientCard> {
  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = const Color(0xFFFBBF24);
    final surface = isDark
        ? const Color(0xFF1F242B).withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.97);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

final isCursor = widget.client.clientId == McpClientId.cursor;
    final modeMap = ref.watch(mcpInstallModeProvider);
    final mode = modeMap[widget.client.clientId.name] ?? McpInstallMode.npx;
    final localMcp = ref.watch(localMcpServerProvider);
    // Cursor has no CLI + the script-path resolves to `//` in a packaged
    // app — force localhost-only rendering for it.
    final isLocalhost = isCursor || mode == McpInstallMode.localhost;
    final isRunning = localMcp.state == LocalMcpServerState.running;
    final wsPort = ref.watch(mcpWsServerProvider).port;
    final httpPort = localMcp.port;
    final command = isCursor
        ? (widget.cursorLocalhostSnippet ?? widget.client.localhostCommand)
        : (isLocalhost
            ? localhostCommandAt(widget.client.clientId, httpPort)
            : widget.client.command);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: [
          // Liquid-glass refraction: tinted shadow + 1px inner
          // highlight along the top edge.
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.10 : 0.06),
            blurRadius: 14,
            spreadRadius: -3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(LucideIcons.terminal, size: 13, color: accent),
              const SizedBox(width: 6),
              Text(
                widget.client.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 6),
              _InstallStatusBadge(
                clientId: widget.client.clientId,
                isDark: isDark,
              ),
              const Spacer(),
              if (!isCursor)
                _ModeToggle(
                  mode: mode,
                  onChanged: (next) async {
                    await ref
                        .read(mcpInstallModeProvider.notifier)
                        .set(widget.client.clientId.name, next);
                  },
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24)
                        .withValues(alpha: isDark ? 0.18 : 0.14),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: const Color(0xFFFBBF24)
                          .withValues(alpha: isDark ? 0.32 : 0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.server,
                        size: 10,
                        color: const Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Localhost',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: const Color(0xFFFBBF24),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (isLocalhost) ...[
            const SizedBox(height: 6),
            _LocalServerStatus(
              status: localMcp,
              onStart: isRunning
                  ? null
                  : () => ref
                      .read(localMcpServerProvider.notifier)
                      .start(desktopWsPort: wsPort),
              onStop: isRunning
                  ? () => ref
                      .read(localMcpServerProvider.notifier)
                      .stop()
                  : null,
            ),
          ],
          const SizedBox(height: 8),

          // Install block. For Cursor the command is a multi-line JSON
          // snippet — render it as a code block with no maxLines cap so
          // the whole thing is selectable. For Claude / Codex (single-
          // line commands) the same widget works fine.
          _CommandBlock(
            label: 'Install',
            labelIcon: LucideIcons.download,
            accent: accent,
            isDark: isDark,
            tone: _CommandTone.install,
            text: command,
            maxLines: widget.client.clientId == McpClientId.cursor ? null : 4,
          ),
          const SizedBox(height: 6),

          // Uninstall block — danger-toned but readable. Same code-block
          // treatment so multi-line Cursor JSON snippets render fully.
          _CommandBlock(
            label: 'Uninstall',
            labelIcon: LucideIcons.unplug,
            accent: const Color(0xFFFF6B6B),
            isDark: isDark,
            tone: _CommandTone.uninstall,
            text: widget.client.uninstallCommand,
            maxLines: widget.client.clientId == McpClientId.cursor ? null : 3,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TactileButton(
                  label: loc.mcpCopyInstallCommand,
                  icon: LucideIcons.copy,
                  accent: accent,
                  onTap: () => widget.onCopy(command),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _TactileButton(
                  label: loc.mcpRunInstall,
                  icon: LucideIcons.play,
                  accent: const Color(0xFF00CEC9),
                  // Cursor's localhost install just writes
                  // `~/.cursor/mcp.json` — it does NOT require the
                  // local node server to be running. Allow the button
                  // for Cursor in localhost mode even when the server
                  // is crashed/stopped so the user can still configure.
                  enabled: !Platform.isWindows &&
                      (!isLocalhost || isRunning || isCursor),
                  onTap: () => _spawnClient(
                    widget.client,
                    mode: mode,
                    httpPort: httpPort,
                    action: McpAction.run,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _TactileButton(
                  label: loc.mcpCopyUninstallCommand,
                  icon: LucideIcons.clipboardCopy,
                  accent: const Color(0xFFFF6B6B).withValues(alpha: 0.85),
                  onTap: () => widget.onCopy(widget.client.uninstallCommand),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _TactileButton(
                  label: loc.mcpUninstall,
                  icon: LucideIcons.unplug,
                  accent: const Color(0xFFFF6B6B),
                  enabled: !Platform.isWindows,
                  onTap: () async {
                    final confirmed = await _confirmUninstall(context, loc);
                    if (!confirmed) return;
                    if (!context.mounted) return;
                    await _spawnClient(
                      widget.client,
                      mode: mode,
                      httpPort: httpPort,
                      action: McpAction.uninstall,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmUninstall(BuildContext context, S loc) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? const Color(0xFF1F242B)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(LucideIcons.unplug,
                size: 16, color: Color(0xFFFF6B6B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                loc.mcpUninstallConfirmTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(ctx).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          loc.mcpUninstallConfirmBody(widget.client.displayName),
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Theme.of(ctx).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.cancel, style: const TextStyle(fontSize: 12)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.mcpUninstall,
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _spawnClient(
    TokenCommandTemplate client, {
    required McpInstallMode mode,
    required McpAction action,
    required int httpPort,
  }) async {
    // Capture context-dependent handles before any async gap.
    final ctx = context;
    final container = ProviderScope.containerOf(ctx, listen: false);
    final wsPort = container.read(mcpWsServerProvider).port;
    final isLocalhost = mode == McpInstallMode.localhost;

    // Show a spinner dialog while the command runs. Cursor writes to
    // disk in <100ms but `claude mcp add` / `codex mcp add` can take
    // a few seconds (npm fetch on first run, MCP server spin-up,
    // OAuth prompt). Without this, the user sees the panel freeze
    // and wonders if the click registered.
    final verb = action == McpAction.uninstall ? 'Uninstalling' : 'Installing';
    final progressFuture = showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Theme.of(dialogCtx).brightness == Brightness.dark
              ? const Color(0xFF1F242B)
              : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text('$verb ${client.displayName}…'),
            ],
          ),
          content: Text(
            action == McpAction.uninstall
                ? 'Removing devconnect-manage from ${client.displayName} configuration.'
                : 'Running the MCP install command. This can take up to 30s the first time.',
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
        ),
      ),
    );

    Future<T> runWithProgress<T>(Future<T> Function() body) async {
      try {
        return await body();
      } finally {
        // Dismiss the spinner regardless of success/failure — the
        // result dialog shows the outcome below.
        if (ctx.mounted) Navigator.of(ctx, rootNavigator: true).pop();
        await progressFuture;
      }
    }

    if (client.clientId == McpClientId.cursor) {
      final started = DateTime.now();
      bool success = await runWithProgress<bool>(() async {
        if (action == McpAction.uninstall) {
          return await CursorConfigurator.uninstall();
        } else if (isLocalhost) {
          return await CursorConfigurator.configureHttp(httpPort: httpPort);
        } else {
          return await CursorConfigurator.configure(wsPort: wsPort);
        }
      });

      if (!ctx.mounted) return;
      if (success) {
        final list = AppPreferences().get<List<dynamic>>('installed_mcp_clients')?.cast<String>() ?? [];
        if (action == McpAction.uninstall) {
          list.remove(client.clientId.name);
        } else if (action == McpAction.run) {
          if (!list.contains(client.clientId.name)) {
            list.add(client.clientId.name);
          }
        }
        await AppPreferences().set('installed_mcp_clients', list);
        _refreshInstallStatusAfterAction(ref, client.clientId);
      }
      final status = success ? McpResult.success : McpResult.failed;
      final command = action == McpAction.uninstall
          ? 'Remove devconnect-manage from ~/.cursor/mcp.json'
          : (isLocalhost
              ? 'Write http://127.0.0.1:$httpPort/mcp to ~/.cursor/mcp.json'
              : 'Write devconnect-manage to ~/.cursor/mcp.json');

      await showMcpInstallResultDialog(
        ctx,
        client: client,
        command: command,
        stdout: success
            ? (action == McpAction.uninstall
                ? 'Removed configuration successfully!'
                : 'Configured ~/.cursor/mcp.json successfully! Restart Cursor to apply.')
            : '',
        stderr: success
            ? ''
            : (action == McpAction.uninstall
                ? 'Failed to remove configuration from ~/.cursor/mcp.json'
                : 'Failed to configure ~/.cursor/mcp.json. Make sure ~/.cursor directory exists.'),
        exitCode: success ? 0 : -1,
        status: status,
        downloadUrl: client.downloadUrl,
      );

      container.read(mcpInstallHistoryProvider.notifier).append(
            InstallAttempt(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              action: action,
              clientId: client.clientId,
              result: status,
              command: command,
              stdout: success ? 'Success' : '',
              stderr: success ? '' : 'Failed',
              exitCode: success ? 0 : -1,
              durationMs: DateTime.now().difference(started).inMilliseconds,
              startedAt: started,
              finishedAt: DateTime.now(),
              timestamp: started,
            ),
          );
      return;
    }

    final exe = await resolveCliBinary(client.binaryName);
    if (exe == null) {
      if (!ctx.mounted) return;
      await showMcpInstallResultDialog(
        ctx,
        client: client,
        command: client.uninstallCommand,
        stdout: '',
        stderr: '',
        exitCode: -2,
        status: McpResult.notFound,
        downloadUrl: client.downloadUrl,
      );
      return;
    }

    // Per-client CLI semantics:
    //  - Claude Code:   `claude mcp add --transport http <name> <url> [--scope user]`
    //                   URL is a POSITIONAL arg, no `--url` flag.
    //  - Codex:         `codex mcp add <name> --url <url>`
    //                   URL is a `--url` flag value.
    //  - stdio (both):  `<cli> mcp add <name> -- <stdio command>`
    final cliArgs = action == McpAction.uninstall
        ? ['mcp', 'remove', 'devconnect-manage']
        : (isLocalhost
            ? (client.clientId == McpClientId.claudeCode
                ? [
                    'mcp',
                    'add',
                    '--transport',
                    'http',
                    'devconnect-manage',
                    'http://127.0.0.1:$httpPort/mcp',
                  ]
                : [
                    'mcp',
                    'add',
                    'devconnect-manage',
                    '--url',
                    'http://127.0.0.1:$httpPort/mcp',
                  ])
            : ['mcp', 'add', 'devconnect-manage']);
    final command = action == McpAction.uninstall
        ? client.uninstallCommand
        : (isLocalhost
            ? localhostCommandAt(client.clientId, httpPort)
            : client.command);

    final started = DateTime.now();
    // Wrap the CLI Process.run in the same progress dialog — Claude
    // and Codex can take a few seconds the first time they launch
    // their MCP server as a child process.
    ProcessResult result = await runWithProgress<ProcessResult>(() async {
      try {
        return await Process.run(exe, cliArgs, environment: augmentedEnv())
            .timeout(const Duration(seconds: 30));
      } on Exception catch (e) {
        return ProcessResult(0, -1, '', e.toString());
      }
    });

    if (!ctx.mounted) return;
    final success = result.exitCode == 0;
    if (success) {
      final list = AppPreferences().get<List<dynamic>>('installed_mcp_clients')?.cast<String>() ?? [];
      if (action == McpAction.uninstall) {
        list.remove(client.clientId.name);
      } else if (action == McpAction.run) {
        if (!list.contains(client.clientId.name)) {
          list.add(client.clientId.name);
        }
      }
      await AppPreferences().set('installed_mcp_clients', list);
      // Re-check the actual install state via the CLI — the
      // `installed_mcp_clients` list is our optimistic cache; the
      // badge in the card title reflects whatever the client says.
      _refreshInstallStatusAfterAction(ref, client.clientId);
    }
    final status = success
        ? McpResult.success
        : (result.exitCode == -1 ? McpResult.timeout : McpResult.failed);

    await showMcpInstallResultDialog(
      ctx,
      client: client,
      command: command,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
      exitCode: result.exitCode,
      status: status,
      downloadUrl: client.downloadUrl,
    );

    container.read(mcpInstallHistoryProvider.notifier).append(
          InstallAttempt(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            action: action,
            clientId: client.clientId,
            result: status,
            command: command,
            stdout: result.stdout.toString().length > 5000
                ? '${result.stdout.toString().substring(0, 5000)}\n…(truncated)'
                : result.stdout.toString(),
            stderr: result.stderr.toString().length > 5000
                ? '${result.stderr.toString().substring(0, 5000)}\n…(truncated)'
                : result.stderr.toString(),
            exitCode: result.exitCode,
            durationMs: DateTime.now().difference(started).inMilliseconds,
            startedAt: started,
            finishedAt: DateTime.now(),
            timestamp: started,
          ),
        );
  }
}

/// Compact status row shown under the title when localhost mode is on.
/// Pulsing dot + Start/Stop control. Tells the user whether the local
/// node process is alive before they hit "Run install". When crashed,
/// expands inline to show the lastError + stderr tail so the user can
/// diagnose without digging through system logs.
class _LocalServerStatus extends StatefulWidget {
  final LocalMcpServerStatus status;
  final VoidCallback? onStart;
  final VoidCallback? onStop;

  const _LocalServerStatus({
    required this.status,
    required this.onStart,
    required this.onStop,
  });

  @override
  State<_LocalServerStatus> createState() => _LocalServerStatusState();
}

class _LocalServerStatusState extends State<_LocalServerStatus> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = widget.status.state;
    final (label, dotColor) = switch (status) {
      LocalMcpServerState.running => ('Running', const Color(0xFF22C55E)),
      LocalMcpServerState.starting => ('Starting…', const Color(0xFFFBBF24)),
      LocalMcpServerState.crashed => ('Crashed', const Color(0xFFFF6B6B)),
      LocalMcpServerState.stopped => ('Stopped', Colors.grey),
    };
    final isRunning = status == LocalMcpServerState.running;
    final onTap = isRunning ? widget.onStop : widget.onStart;
    final muted = isDark ? Colors.white60 : Colors.black54;
    final isCrashed = status == LocalMcpServerState.crashed;
    final hasDetail = isCrashed &&
        (widget.status.lastError != null || widget.status.lastStderr != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              'Local node: $label',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  isRunning ? 'Stop' : 'Start',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: onTap == null
                        ? (isDark ? Colors.white24 : Colors.black26)
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
            ),
            if (hasDetail) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _expanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 9,
                        color: const Color(0xFFFF6B6B),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF6B6B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_expanded && hasDetail) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.status.lastError != null) ...[
                  Text(
                    widget.status.lastError!,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.35,
                      color: const Color(0xFFFF6B6B),
                    ),
                  ),
                ],
                if (widget.status.lastStderr != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.status.lastStderr!,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontFamily: AppConstants.monoFontFamily,
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Small segmented chip — `npx` vs `localhost` — anchored to the right
/// of each client card title. Persists per-client via [mcpInstallModeProvider].
class _ModeToggle extends StatelessWidget {
  final McpInstallMode mode;
  final ValueChanged<McpInstallMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.04);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.10);

    Widget seg(String label, McpInstallMode value) {
      final selected = mode == value;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFBBF24).withValues(alpha: isDark ? 0.20 : 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: selected
                  ? const Color(0xFFFBBF24)
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('NPX', McpInstallMode.npx),
          seg('LOCAL', McpInstallMode.localhost),
        ],
      ),
    );
  }
}

/// Button with the project's tactile press feel (AnimatedScale 0.96).
class _TactileButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool enabled;
  final VoidCallback? onTap;

  const _TactileButton({
    required this.label,
    required this.icon,
    required this.accent,
    this.enabled = true,
    required this.onTap,
  });

  @override
  State<_TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<_TactileButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent;
    final disabled = !widget.enabled || widget.onTap == null;
    final bg = disabled
        ? (isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04))
        : accent.withValues(alpha: isDark ? 0.16 : 0.14);
    final fg = disabled
        ? (isDark ? Colors.white38 : Colors.black38)
        : accent;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: fg.withValues(alpha: 0.30),
              width: 0.7,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 11, color: fg),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visual tone for [_CommandBlock] — install is amber-positive,
/// uninstall is red-destructive. Each tone has its own surface tint,
/// border, and label color so the two boxes are unmistakably different
/// at a glance.
enum _CommandTone { install, uninstall }

/// Code-style command block. Used for both Install + Uninstall in the
/// client card. Renders the label + tinted surface + selectable mono
/// text inside a 1px border with a soft inset highlight. Pass
/// `maxLines: null` to render a multi-line JSON snippet in full (Cursor).
class _CommandBlock extends StatelessWidget {
  final String label;
  final IconData labelIcon;
  final Color accent;
  final bool isDark;
  final _CommandTone tone;
  final String text;
  final int? maxLines;

  const _CommandBlock({
    required this.label,
    required this.labelIcon,
    required this.accent,
    required this.isDark,
    required this.tone,
    required this.text,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, border, labelFg, monoFg) = switch (tone) {
      _CommandTone.install => (
          isDark
              ? const Color(0xFF0D1117).withValues(alpha: 0.92)
              : const Color(0xFFF5F6F8),
          accent.withValues(alpha: isDark ? 0.22 : 0.20),
          accent,
          ColorTokens.secondary,
        ),
      _CommandTone.uninstall => (
          isDark
              ? const Color(0xFF2A1414).withValues(alpha: 0.45)
              : const Color(0xFFFCEDED),
          accent.withValues(alpha: isDark ? 0.32 : 0.28),
          accent,
          isDark ? const Color(0xFFE8B4B4) : const Color(0xFF8B2C2C),
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.20 : 0.14),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(labelIcon, size: 10, color: labelFg),
                    const SizedBox(width: 3),
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: labelFg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            text,
            style: TextStyle(
              fontFamily: AppConstants.monoFontFamily,
              fontSize: 10.5,
              height: 1.45,
              color: monoFg,
            ),
            maxLines: maxLines,
            // No maxLines = full multi-line render for Cursor JSON.
          ),
        ],
      ),
    );
  }
}
/// Tiny install-status pill shown next to the client name in
/// `_ClientCard`. Watches [mcpInstallStatusProvider] so it stays in
/// sync with the auto-check on panel open + the post-install refresh.
class _InstallStatusBadge extends ConsumerWidget {
  final McpClientId clientId;
  final bool isDark;
  const _InstallStatusBadge({
    required this.clientId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(mcpInstallStatusProvider.select(
      (m) => m[clientId] ??
          const ClientInstallInfo(
            status: McpInstallStatus.unknown,
            detail: 'unknown',
          ),
    ));

    final (icon, label, bg, fg) = switch (info.status) {
      McpInstallStatus.installed => (
        LucideIcons.circleCheck,
        'Installed',
        const Color(0xFF22C55E).withValues(alpha: isDark ? 0.18 : 0.16),
        const Color(0xFF22C55E),
      ),
      McpInstallStatus.unhealthy => (
        LucideIcons.circleAlert,
        'Unhealthy',
        const Color(0xFFFF6B6B).withValues(alpha: isDark ? 0.18 : 0.16),
        const Color(0xFFFF6B6B),
      ),
      McpInstallStatus.notInstalled => (
        LucideIcons.circle,
        'Not installed',
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        isDark ? Colors.white54 : Colors.black54,
      ),
      McpInstallStatus.unknown => (
        LucideIcons.circleDashed,
        'Checking…',
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        isDark ? Colors.white54 : Colors.black54,
      ),
    };

    return Tooltip(
      message: info.detail ?? label,
      waitDuration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: () =>
            ref.read(mcpInstallStatusProvider.notifier).refreshOne(clientId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 9, color: fg),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// After a successful Run install / Uninstall, re-check this one
/// client only so the install-status badge updates immediately
/// instead of waiting for the next panel open.
void _refreshInstallStatusAfterAction(
  WidgetRef ref,
  McpClientId clientId,
) {
  ref.read(mcpInstallStatusProvider.notifier).refreshOne(clientId);
}

/// Resolve the workspace root for the Cursor JSON snippet shown in
/// the card. `Directory.current.path` returns `/` inside a packaged
/// macOS .app — fall back to env / common dev locations.
String _resolveWorkspaceForSnippet() {
  final home = Platform.environment['HOME'] ?? '';
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
    if (File('$root/client_sdks/devconnect-mcp/package.json').existsSync()) {
      return root;
    }
  }
  // Last resort — at least show something selectable so the user can
  // manually fix the path in the snippet.
  return Directory.current.path;
}
