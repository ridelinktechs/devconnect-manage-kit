import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/inputs/search_field.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/device_info.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../provider/all_events_provider.dart';
import '../buttons/icon_btn.dart';
import '../status/reload_pill.dart';
import '../status/server_status_pill.dart';

/// Top toolbar of the All Events page.
///
/// Three regions, left → right:
///   1. **Identity** — title, live event count, server status pill,
///      reload-connection pill.
///   2. **Search** — search field that drives [allEventsSearchProvider].
///   3. **Actions** — auto-scroll, sort order, and clear-all grouped in a
///      single rounded container.
class Header extends ConsumerWidget {
  final ValueNotifier<int> eventCount;
  final bool serverRunning;
  final int port;
  final int deviceCount;
  final List<DeviceInfo> devices;
  final bool autoScroll;
  final bool restarting;
  final bool reloading;
  final bool hotRestarting;
  final VoidCallback onToggleAutoScroll;
  final VoidCallback onClear;
  final VoidCallback onReload;
  final VoidCallback onReloadApp;
  final VoidCallback onHotRestart;

  const Header({
    super.key,
    required this.eventCount,
    required this.serverRunning,
    required this.port,
    required this.deviceCount,
    required this.devices,
    required this.autoScroll,
    required this.onToggleAutoScroll,
    required this.onClear,
    required this.restarting,
    required this.onReload,
    required this.reloading,
    required this.hotRestarting,
    required this.onReloadApp,
    required this.onHotRestart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Port-occupied detection: server failed to start (typically "Address
    // already in use") AND is currently not running.
    final startError = ref.watch(serverStartErrorProvider);
    final portOccupied = !serverRunning && startError != null;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
      ),
      child: Row(
        children: [
          // ── Left: Title + meta ──
          Icon(LucideIcons.activity, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text('All Events', style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: eventCount,
            builder: (_, count, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppConstants.monoFontFamily,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Unified server-status pill — port + device count + state
          ServerStatusPill(
            serverRunning: serverRunning,
            portOccupied: portOccupied,
            port: port,
            deviceCount: deviceCount,
            startError: startError,
          ),

          // Reload connection — sits next to the status pill so it's
          // obvious that this action restarts the server (and therefore
          // forces every connected SDK into its reconnect path).
          const SizedBox(width: 8),
          ReloadPill(
            restarting: restarting,
            tooltip: S.of(context).restartServer,
            onTap: restarting ? () {} : onReload,
          ),

          const Spacer(),

          SizedBox(
            width: 200,
            child: SearchField(
              hintText: S.of(context).searchEvents,
              onChanged: (v) =>
                  ref.read(allEventsSearchProvider.notifier).state = v,
            ),
          ),
          const SizedBox(width: 12),

          // ── Action group ──
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reload-app buttons were here — moved to a draggable
                // floating FAB (see `DraggableReloadFab` rendered in the
                // page-level Stack) so the button stays out of the user's
                // way during long debug sessions.
                IconBtn(
                  icon: LucideIcons.arrowDownToLine,
                  tooltip: S.of(context).autoScroll,
                  isActive: autoScroll,
                  onTap: onToggleAutoScroll,
                ),
                const SizedBox(width: 2),
                Consumer(
                  builder: (context, ref, _) {
                    final sort = ref.watch(allEventsSortOrderProvider);
                    final isNewest = sort == SortOrder.newestFirst;
                    return IconBtn(
                      icon: isNewest ? LucideIcons.arrowUpNarrowWide : LucideIcons.arrowDownNarrowWide,
                      tooltip: isNewest ? S.of(context).newestFirst : S.of(context).oldestFirst,
                      isActive: isNewest,
                      onTap: () => ref.read(allEventsSortOrderProvider.notifier).state =
                          isNewest ? SortOrder.oldestFirst : SortOrder.newestFirst,
                    );
                  },
                ),
                const SizedBox(width: 2),
                Container(
                  width: 1,
                  height: 18,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                ),
                const SizedBox(width: 2),
                IconBtn(
                  icon: LucideIcons.trash2,
                  tooltip: S.of(context).clearAll,
                  isDanger: true,
                  onTap: onClear,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}