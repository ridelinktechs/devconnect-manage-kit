import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'server/providers/server_providers.dart';

class DevConnectApp extends ConsumerStatefulWidget {
  const DevConnectApp({super.key});

  @override
  ConsumerState<DevConnectApp> createState() => _DevConnectAppState();
}

class _DevConnectAppState extends ConsumerState<DevConnectApp> {
  @override
  void initState() {
    super.initState();
    // Auto-start WebSocket server on app launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoStartServer();
    });
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

    return MaterialApp.router(
      title: 'DevConnect Manage Tool',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
