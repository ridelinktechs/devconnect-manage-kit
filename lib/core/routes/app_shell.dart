import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

import '../../components/layout/device_bottom_bar.dart';
import '../../components/layout/sidebar.dart';
import '../providers/tab_visibility_provider.dart';
import '../theme/theme_provider.dart';
import '../../features/last_connected/provider/last_connected_providers.dart';
import '../../server/providers/server_providers.dart';

/// Breakpoint below which sidebar auto-collapses
const _collapseBreakpoint = 920.0;

class AppShell extends ConsumerStatefulWidget {
  final String currentPath;
  final Widget child;

  const AppShell({
    super.key,
    required this.currentPath,
    required this.child,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int get _selectedIndex {
    for (int i = 0; i < sidebarItems.length; i++) {
      if (sidebarItems[i].routePath == widget.currentPath) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Initialize the last connected provider so disconnect listeners are active
    ref.watch(lastConnectedProvider);
    // Auto-select device when exactly one is connected
    ref.watch(autoSelectDeviceProvider);
    final isCollapsed = ref.watch(sidebarCollapsedProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Auto-collapse sidebar at narrow widths
          if (constraints.maxWidth < _collapseBreakpoint && !isCollapsed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref.read(sidebarCollapsedProvider.notifier).state = true;
              }
            });
          }

          final enabledTabs = ref.watch(tabVisibilityProvider);
          final isLocked = !isTabEnabled(enabledTabs, widget.currentPath);

          return Stack(
            children: [
              Row(
                children: [
                  Sidebar(
                    selectedIndex: _selectedIndex,
                    onItemSelected: (index) {
                      context.go(sidebarItems[index].routePath);
                    },
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(height: Platform.isMacOS ? 64 : Platform.isWindows || Platform.isLinux ? 32 : 0),
                        Expanded(
                          child: isLocked
                              ? const _LockedTabOverlay()
                              : widget.child,
                        ),
                        const DeviceBottomBar(),
                      ],
                    ),
                  ),
                ],
              ),
              // Draggable title bar (desktop)
              if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
                Positioned(
                  top: 0,
                  left: isCollapsed ? 36 : 68,
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
          );
        },
      ),
    );
  }
}

class _LockedTabOverlay extends StatelessWidget {
  const _LockedTabOverlay();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: isDark
              ? Colors.black.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.7),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.lock,
                    size: 28,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tab Disabled',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enable this tab in Settings > Tab Visibility',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
