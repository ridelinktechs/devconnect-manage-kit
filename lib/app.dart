import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components/viewers/json_viewer.dart';
import 'core/providers/locale_provider.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
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
    if (!server.isRunning) {
      try {
        await server.start();
        ref.read(serverStartErrorProvider.notifier).state = null;
      } catch (e) {
        ref.read(serverStartErrorProvider.notifier).state =
            _describeStartError(e);
      }
      // Force rebuild to update UI with server status
      if (mounted) setState(() {});
    }
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

    // Activate the persistent device-history mirror so connect/disconnect
    // events are recorded even when no Settings page is open.
    ref.watch(deviceHistoryMirrorProvider);

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
    );
  }
}
