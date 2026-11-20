import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/misc/status_badge.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../models/disconnected_session.dart';
import '../events/all_events_list.dart';
import '../events/log_list.dart';
import '../events/network_list.dart';
import '../events/state_list.dart';
import '../events/storage_list.dart';
import 'tab_button.dart';

class SessionDetailPanel extends StatelessWidget {
  final DisconnectedSession session;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onClose;
  final ScrollController allEventsScrollController;
  final ScrollController logsScrollController;
  final ScrollController networkScrollController;
  final ScrollController stateScrollController;
  final ScrollController storageScrollController;

  const SessionDetailPanel({
    super.key,
    required this.session,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onClose,
    required this.allEventsScrollController,
    required this.logsScrollController,
    required this.networkScrollController,
    required this.stateScrollController,
    required this.storageScrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        children: [
          // Header
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? ColorTokens.darkBackground : Colors.white,
            ),
            child: Row(
              children: [
                Icon(LucideIcons.history, size: 14, color: ColorTokens.primary),
                const SizedBox(width: 8),
                Text(
                  session.deviceInfo.appName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                PlatformBadge(platform: session.deviceInfo.platform),
                const Spacer(),
                Text(
                  '${session.totalEvents} events',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontFamily: AppConstants.monoFontFamily,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onClose,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.grey.withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        LucideIcons.x,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tab bar
          Container(
            height: 36,
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            child: Row(
              children: [
                TabButton(
                  'All',
                  0,
                  selectedTab,
                  onTabChanged,
                  session.totalEvents,
                ),
                TabButton(
                  'Logs',
                  1,
                  selectedTab,
                  onTabChanged,
                  session.logs.length,
                ),
                TabButton(
                  'Network',
                  2,
                  selectedTab,
                  onTabChanged,
                  session.networkEntries.length,
                ),
                TabButton(
                  'State',
                  3,
                  selectedTab,
                  onTabChanged,
                  session.stateChanges.length,
                ),
                TabButton(
                  'Storage',
                  4,
                  selectedTab,
                  onTabChanged,
                  session.storageEntries.length,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (selectedTab) {
      case 1:
        return LogList(entries: session.logs, controller: logsScrollController);
      case 2:
        return NetworkList(
          entries: session.networkEntries,
          controller: networkScrollController,
        );
      case 3:
        return StateList(
          entries: session.stateChanges,
          controller: stateScrollController,
        );
      case 4:
        return StorageList(
          entries: session.storageEntries,
          controller: storageScrollController,
        );
      default:
        return AllEventsList(
          session: session,
          controller: allEventsScrollController,
        );
    }
  }
}
