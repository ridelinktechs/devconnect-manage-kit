import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/all_events/presentation/pages/all_events_page.dart';
import '../../features/async_ops/presentation/pages/async_ops_page.dart';
import '../../features/console/presentation/pages/console_page.dart';
import '../../features/custom_commands/presentation/pages/custom_commands_page.dart';
import '../../features/database_viewer/presentation/pages/database_viewer_page.dart';
import '../../features/display/presentation/pages/display_page.dart';
import '../../features/layout_inspector/presentation/layout_inspector_page.dart';
import '../../features/network_inspector/presentation/pages/network_inspector_page.dart';
import '../../features/last_connected/presentation/pages/last_connected_page.dart';
import '../../features/mock_server/presentation/mock_server_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/state_inspector/presentation/pages/state_inspector_page.dart';
import '../../features/performance/presentation/pages/performance_page.dart';
import '../../features/performance/presentation/pages/memory_leaks_page.dart';
import '../../features/benchmark/presentation/pages/benchmark_page.dart';
import '../../features/error_inspector/presentation/pages/error_inspector_page.dart';
import '../../features/storage_viewer/presentation/pages/storage_viewer_page.dart';
import 'app_shell.dart';

/// The pages by path. Each is a branch of its own, kept alive with its
/// selection, scroll and fields while another page is shown.
const _pages = <(String, Widget)>[
  ('/all', AllEventsPage()),
  ('/console', ConsolePage()),
  ('/network', NetworkInspectorPage()),
  ('/state', StateInspectorPage()),
  ('/storage', StorageViewerPage()),
  ('/database', DatabaseViewerPage()),
  ('/performance', PerformancePage()),
  ('/memory-leaks', MemoryLeaksPage()),
  ('/benchmark', BenchmarkPage()),
  ('/errors', ErrorInspectorPage()),
  ('/display', DisplayPage()),
  ('/async', AsyncOpsPage()),
  ('/commands', CustomCommandsPage()),
  ('/layout', LayoutInspectorPage()),
  ('/mock-server', MockServerPage()),
  ('/history', LastConnectedPage()),
  ('/settings', SettingsPage()),
];

final appRouter = GoRouter(
  initialLocation: '/all',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          AppShell(currentPath: state.uri.path, child: shell),
      branches: [
        for (final (path, page) in _pages)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: path,
                pageBuilder: (context, state) => NoTransitionPage(child: page),
              ),
            ],
          ),
      ],
    ),
  ],
);
