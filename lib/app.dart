import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components/viewers/json_viewer.dart';
import 'components/misc/mcp_confirmation_overlay.dart';
import 'core/preferences/app_preferences.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/mcp_install_mode_provider.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/local_mcp_server_manager.dart';
import 'core/utils/toast_utils.dart';
import 'l10n/app_localizations.dart';
import 'server/providers/server_providers.dart';

class DevConnectApp extends ConsumerStatefulWidget {
  const DevConnectApp({super.key});

  @override
  ConsumerState<DevConnectApp> createState() => _DevConnectAppState();
}

class _DevConnectAppState extends ConsumerState<DevConnectApp> {
  /// Device IDs we've already seen, so a freshly-connected device (vs an
  /// existing one re-emitting) is the trigger for cache invalidation.
  Set<String>? _knownDeviceIds;

  @override
  void initState() {
    super.initState();
    // Auto-clear the JSON highlight cache after long background sessions.
    HighlightCacheLifecycleObserver.instance.attach();
    // Auto-start WebSocket server on app launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoStartServer();
    });
  }

  @override
  void dispose() {
    HighlightCacheLifecycleObserver.instance.detach();
    super.dispose();
  }

  Future<void> _autoStartServer() async {
    final server = ref.read(wsServerProvider);
    final mcpServer = ref.read(mcpWsServerProvider);
    final mcpAutoStart = ref.read(mcpAutoStartProvider);

    if (!server.isRunning) {
      try {
        await server.start();
        ref.read(serverStartErrorProvider.notifier).state = null;
      } catch (e) {
        ref.read(serverStartErrorProvider.notifier).state =
            _describeStartError(e);
      }
    }

    if (mcpAutoStart && !mcpServer.isRunning) {
      try {
        final mcpPort = AppPreferences().get<int>('mcp_server_port') ?? 5564;
        await mcpServer.start(port: mcpPort);
        ref.read(mcpStartErrorProvider.notifier).state = null;
      } catch (e) {
        ref.read(mcpStartErrorProvider.notifier).state = e.toString();
      }
    }

        // Once the desktop's MCP control channel is up (or attempted), kick
    // off the local HTTP MCP server too if the user opted into auto-
    // spawn. The MCP panel just reflects this state — opening it does
    // not trigger a spawn — so making sure it starts at launch means
    // a healthy green dot by the time the user looks.
    if (ref.read(mcpAutoSpawnLocalProvider)) {
      final localStatus = ref.read(localMcpServerProvider);
      if (localStatus.state == LocalMcpServerState.stopped) {
        ref.read(localMcpServerProvider.notifier).start(
              desktopWsPort: mcpServer.isRunning ? mcpServer.port : 5564,
            );
      }
    }

    if (mounted) setState(() {});
  }

  String _describeStartError(Object error) {
    final msg = error.toString();
    if (msg.contains('Address already in use') ||
        msg.contains('errno = 48') ||
        msg.contains('errno = 98')) {
      return 'Port is already in use. '
          'Close the other app using this port, or pick a different port in Settings.';
    }
    return 'Failed to start server: $msg';
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    // Keep message handler alive so it processes incoming messages
    ref.watch(wsMessageHandlerProvider);
    // Activate the MCP control-channel dispatcher so `devconnect-manage`
    // can talk to the desktop even when no Settings page is open.
    ref.watch(mcpHandlerProvider);

    // Activate the persistent device-history mirror so connect/disconnect
    // events are recorded even when no Settings page is open.
    ref.watch(deviceHistoryMirrorProvider);

    // Watch the local-node status so we can surface a toast when the
    // auto-spawn at launch succeeds / fails. ignore: true so we don't
    // rebuild on every state change — only the ref.listen below fires.
    ref.watch(localMcpServerProvider);
    ref.listen<LocalMcpServerStatus>(
      localMcpServerProvider,
      (prev, next) {
        if (!mounted) return;
        final ps = prev?.state;
        if (ps == next.state) return;
        final toastContext = rootNavigatorKey.currentContext ?? context;
        final overlay = rootNavigatorKey.currentState?.overlay;
        switch (next.state) {
          case LocalMcpServerState.running:
            showSuccessToast(
              toastContext,
              message: 'Local MCP server running',
              subtitle: 'http://127.0.0.1:${next.port}/mcp — '
                  'ready for Claude Code / Codex / Cursor',
              overlay: overlay,
            );
            break;
          case LocalMcpServerState.crashed:
            showErrorToast(
              toastContext,
              message: 'Local MCP server crashed',
              error: next.lastError ?? 'see MCP panel → Details',
              overlay: overlay,
            );
            break;
          default:
            break;
        }
      },
    );

    // A. Invalidate the JSON highlight cache when the user picks a
    // different device — data is filtered per-device, so old highlights
    // belong to a different payload.
    ref.listen<String?>(selectedDeviceProvider, (_, next) {
      HighlightCacheLifecycleObserver.instance.clearCache();
    });

    // B. Invalidate the JSON highlight cache when a NEW device connects.
    // A reconnect of an already-known device (e.g. hot reload) does NOT
    // trigger this — only an addition to the device list.
    final devices = ref.watch(connectedDevicesProvider);
    final ids = devices.map((d) => d.deviceId).toSet();
    if (_knownDeviceIds != null && ids.any((id) => !_knownDeviceIds!.contains(id))) {
      HighlightCacheLifecycleObserver.instance.clearCache();
    }
    _knownDeviceIds = ids;

    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'DevConnect Manage Tool',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            const McpConfirmationOverlay(),
          ],
        );
      },
    );
  }
}
