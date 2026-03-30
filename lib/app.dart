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
      await server.start();
      // Force rebuild to update UI with server status
      if (mounted) setState(() {});
    }
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
