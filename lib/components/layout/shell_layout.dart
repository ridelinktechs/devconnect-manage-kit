import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/theme/theme_provider.dart';
import 'sidebar.dart';

class ShellLayout extends ConsumerStatefulWidget {
  final Widget child;
  final int selectedIndex;

  const ShellLayout({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  @override
  ConsumerState<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends ConsumerState<ShellLayout> {
  @override
  Widget build(BuildContext context) {
    final isCollapsed = ref.watch(sidebarCollapsedProvider);
    final sidebarWidth = isCollapsed ? 36.0 : 68.0;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              Sidebar(
                selectedIndex: widget.selectedIndex,
                onItemSelected: (index) {
                  final item = sidebarItems[index];
                  _navigateTo(item.routePath);
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(height: Platform.isMacOS ? 64 : Platform.isWindows || Platform.isLinux ? 32 : 0),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
          // Draggable title bar area (desktop window chrome)
          if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
            Positioned(
              top: 0,
              left: sidebarWidth,
              right: 0,
              height: Platform.isMacOS ? 64 : 32,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (_) => windowManager.startDragging(),
                onDoubleTap: () async {
                  if (await windowManager.isMaximized()) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  void _navigateTo(String path) {
    // Using GoRouter context extension
    // GoRouter.of(context).go(path);
    // We'll use the callback approach through the router
    final router =
        ModalRoute.of(context)?.settings.arguments as Function(String)?;
    if (router != null) {
      router(path);
    }
  }
}
