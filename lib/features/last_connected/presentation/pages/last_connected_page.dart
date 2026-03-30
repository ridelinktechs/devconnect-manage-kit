import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/duration_format.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../components/feedback/empty_state.dart';
import '../../../../components/misc/status_badge.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../models/disconnected_session.dart';
import '../../../../models/log/log_entry.dart';
import '../../../../models/network/network_entry.dart';
import '../../../../models/state/state_change.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../provider/last_connected_providers.dart';

class LastConnectedPage extends ConsumerStatefulWidget {
  const LastConnectedPage({super.key});

  @override
  ConsumerState<LastConnectedPage> createState() => _LastConnectedPageState();
}

class _LastConnectedPageState extends ConsumerState<LastConnectedPage> {
  int? _selectedSessionIndex;
  int _selectedTab = 0; // 0=all, 1=logs, 2=network, 3=state, 4=storage

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(lastConnectedProvider);
    final theme = Theme.of(context);

    // Reset selection if out of bounds
    if (_selectedSessionIndex != null && _selectedSessionIndex! >= sessions.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedSessionIndex = null);
      });
    }

    final selected = _selectedSessionIndex != null && _selectedSessionIndex! < sessions.length
        ? sessions[_selectedSessionIndex!]
        : null;

    return Column(
      children: [
        // Toolbar
        _Toolbar(
          sessionCount: sessions.length,
          onClearAll: () {
            ref.read(lastConnectedProvider.notifier).clearAll();
            setState(() => _selectedSessionIndex = null);
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: sessions.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.history,
                  title: 'No history',
                  subtitle:
                      'Sessions from disconnected devices will appear here',
                )
              : Row(
                  children: [
                    // Session list
                    SizedBox(
                      width: selected != null ? 260 : 360,
                      child: ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final isSelected = _selectedSessionIndex == index;
                          return _SessionTile(
                            session: session,
                            isSelected: isSelected,
                            onTap: () => setState(() {
                              _selectedSessionIndex = isSelected ? null : index;
                              _selectedTab = 0;
                            }),
                            onRemove: () {
                              ref
                                  .read(lastConnectedProvider.notifier)
                                  .removeSession(session.deviceInfo.deviceId);
                              if (isSelected) {
                                setState(() => _selectedSessionIndex = null);
                              }
                            },
                          );
                        },
                      ),
                    ),
                    // Detail panel
                    if (selected != null) ...[
                      VerticalDivider(width: 1, color: theme.dividerColor),
                      Expanded(
                        child: _SessionDetailPanel(
                          session: selected,
                          selectedTab: _selectedTab,
                          onTabChanged: (tab) =>
                              setState(() => _selectedTab = tab),
                          onClose: () =>
                              setState(() => _selectedSessionIndex = null),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Toolbar
// ──────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  final int sessionCount;
  final VoidCallback onClearAll;

  const _Toolbar({required this.sessionCount, required this.onClearAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.history, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text('Last Connected',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ColorTokens.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$sessionCount',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ColorTokens.primary,
              ),
            ),
          ),
          const Spacer(),
          if (sessionCount > 0)
            GestureDetector(
              onTap: onClearAll,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: ColorTokens.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: ColorTokens.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.trash2,
                          size: 12, color: ColorTokens.error),
                      const SizedBox(width: 4),
                      Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ColorTokens.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Session Tile
// ──────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  final DisconnectedSession session;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SessionTile({
    required this.session,
    required this.isSelected,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final d = session.deviceInfo;
    final time = DateFormat('HH:mm:ss').format(session.disconnectedAt);
    final platColor = _platformColor(d.platform);

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorTokens.selectedBg(Theme.of(context).brightness == Brightness.dark)
                : null,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.3),
                width: 0.5,
              ),
              left: BorderSide(
                color: isSelected ? ColorTokens.selectedAccent : platColor,
                width: isSelected ? 3 : 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Platform badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: platColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _platformLabel(d.platform),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: platColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      d.appName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Remove button
                  GestureDetector(
                    onTap: onRemove,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Icon(LucideIcons.x,
                          size: 12, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(LucideIcons.clock,
                      size: 10, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Disconnected $time',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    d.deviceName != d.osVersion
                        ? '${d.deviceName} · ${d.osVersion}'
                        : d.osVersion,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                      fontFamily: AppConstants.monoFontFamily,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Event counts
              Row(
                children: [
                  _CountChip(LucideIcons.terminal, session.logs.length,
                      ColorTokens.logInfo),
                  const SizedBox(width: 6),
                  _CountChip(LucideIcons.globe,
                      session.networkEntries.length, ColorTokens.success),
                  const SizedBox(width: 6),
                  _CountChip(LucideIcons.layers,
                      session.stateChanges.length, ColorTokens.secondary),
                  const SizedBox(width: 6),
                  _CountChip(LucideIcons.database,
                      session.storageEntries.length, ColorTokens.warning),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _CountChip(this.icon, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: color.withValues(alpha: 0.6)),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Session Detail Panel
// ──────────────────────────────────────────────

class _SessionDetailPanel extends StatelessWidget {
  final DisconnectedSession session;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onClose;

  const _SessionDetailPanel({
    required this.session,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onClose,
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
                Icon(LucideIcons.history,
                    size: 14, color: ColorTokens.primary),
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
                      child:
                          Icon(LucideIcons.x, size: 14, color: Colors.grey[500]),
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
                _TabButton('All', 0, selectedTab, onTabChanged,
                    session.totalEvents),
                _TabButton('Logs', 1, selectedTab, onTabChanged,
                    session.logs.length),
                _TabButton('Network', 2, selectedTab, onTabChanged,
                    session.networkEntries.length),
                _TabButton('State', 3, selectedTab, onTabChanged,
                    session.stateChanges.length),
                _TabButton('Storage', 4, selectedTab, onTabChanged,
                    session.storageEntries.length),
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
        return _LogList(entries: session.logs);
      case 2:
        return _NetworkList(entries: session.networkEntries);
      case 3:
        return _StateList(entries: session.stateChanges);
      case 4:
        return _StorageList(entries: session.storageEntries);
      default:
        return _AllEventsList(session: session);
    }
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int count;

  const _TabButton(
      this.label, this.index, this.selectedIndex, this.onTap, this.count);

  @override
  Widget build(BuildContext context) {
    final isActive = index == selectedIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? ColorTokens.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? ColorTokens.primary : Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? ColorTokens.primary.withValues(alpha: 0.7)
                        : Colors.grey[600],
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

// ──────────────────────────────────────────────
// Event Lists
// ──────────────────────────────────────────────

class _AllEventsList extends StatelessWidget {
  final DisconnectedSession session;

  const _AllEventsList({required this.session});

  @override
  Widget build(BuildContext context) {
    // Merge all events sorted by timestamp
    final events = <_TimelineEvent>[];
    for (final l in session.logs) {
      events.add(_TimelineEvent(
        timestamp: l.timestamp,
        type: 'LOG',
        color: _logColor(l.level),
        icon: LucideIcons.terminal,
        title: l.message,
        subtitle: l.level.name.toUpperCase(),
      ));
    }
    for (final n in session.networkEntries) {
      events.add(_TimelineEvent(
        timestamp: n.startTime,
        type: 'API',
        color: ColorTokens.success,
        icon: LucideIcons.globe,
        title: '${n.method} ${n.url}',
        subtitle: n.isComplete ? '${n.statusCode}' : 'in progress',
      ));
    }
    for (final s in session.stateChanges) {
      events.add(_TimelineEvent(
        timestamp: s.timestamp,
        type: 'STATE',
        color: ColorTokens.secondary,
        icon: LucideIcons.layers,
        title: s.actionName,
        subtitle: s.stateManagerType,
      ));
    }
    for (final s in session.storageEntries) {
      events.add(_TimelineEvent(
        timestamp: s.timestamp,
        type: 'STORE',
        color: ColorTokens.warning,
        icon: LucideIcons.database,
        title: s.key,
        subtitle: s.operation,
      ));
    }

    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (events.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.inbox,
        title: 'No events',
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final e = events[index];
        return _EventRow(event: e);
      },
    );
  }

  Color _logColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return ColorTokens.logDebug;
      case LogLevel.info:
        return ColorTokens.logInfo;
      case LogLevel.warn:
        return ColorTokens.logWarn;
      case LogLevel.error:
        return ColorTokens.logError;
    }
  }
}

class _TimelineEvent {
  final int timestamp;
  final String type;
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  _TimelineEvent({
    required this.timestamp,
    required this.type,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _EventRow extends StatelessWidget {
  final _TimelineEvent event;

  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(event.timestamp),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.05),
          ),
          left: BorderSide(color: event.color, width: 2),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              time,
              style: TextStyle(
                fontFamily: AppConstants.monoFontFamily,
                fontSize: 9,
                color: Colors.grey[500],
              ),
            ),
          ),
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(event.icon, size: 9, color: event.color),
                const SizedBox(width: 3),
                Text(
                  event.type,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: event.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.title,
              style: TextStyle(
                fontFamily: AppConstants.monoFontFamily,
                fontSize: 11,
                color: isDark ? ColorTokens.lightBackground : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            event.subtitle,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[500],
              fontFamily: AppConstants.monoFontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Typed event lists
// ──────────────────────────────────────────────

class _LogList extends StatelessWidget {
  final List<LogEntry> entries;

  const _LogList({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyState(icon: LucideIcons.terminal, title: 'No logs');
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[entries.length - 1 - index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final time = DateFormat('HH:mm:ss.SSS')
            .format(DateTime.fromMillisecondsSinceEpoch(e.timestamp));

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(time,
                    style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 9,
                        color: Colors.grey[500])),
              ),
              LogLevelBadge(level: e.level.name),
              const SizedBox(width: 8),
              if (e.tag != null) ...[
                Text(e.tag!,
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[500],
                        fontFamily: AppConstants.monoFontFamily)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  e.message,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    color: e.level == LogLevel.error
                        ? ColorTokens.error
                        : isDark
                            ? Colors.white
                            : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NetworkList extends StatelessWidget {
  final List<NetworkEntry> entries;

  const _NetworkList({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyState(
          icon: LucideIcons.globe, title: 'No network requests');
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[entries.length - 1 - index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final time = DateFormat('HH:mm:ss.SSS')
            .format(DateTime.fromMillisecondsSinceEpoch(e.startTime));

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(time,
                    style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 9,
                        color: Colors.grey[500])),
              ),
              HttpMethodBadge(method: e.method),
              const SizedBox(width: 6),
              if (e.isComplete)
                StatusBadge(statusCode: e.statusCode)
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorTokens.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('...',
                      style: TextStyle(
                          fontSize: 10, color: ColorTokens.warning)),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.url,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (e.duration != null) ...[
                const SizedBox(width: 8),
                Text(
                  formatDuration(e.duration!),
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 10,
                    color: e.duration! < 200
                        ? ColorTokens.success
                        : e.duration! < 500
                            ? ColorTokens.warning
                            : ColorTokens.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StateList extends StatelessWidget {
  final List<StateChange> entries;

  const _StateList({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyState(
          icon: LucideIcons.layers, title: 'No state changes');
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[entries.length - 1 - index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final time = DateFormat('HH:mm:ss.SSS')
            .format(DateTime.fromMillisecondsSinceEpoch(e.timestamp));

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(time,
                    style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 9,
                        color: Colors.grey[500])),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ColorTokens.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  e.stateManagerType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: ColorTokens.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.actionName,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (e.diff.isNotEmpty)
                Text(
                  '${e.diff.length} changes',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StorageList extends StatelessWidget {
  final List<StorageEntry> entries;

  const _StorageList({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyState(
          icon: LucideIcons.database, title: 'No storage operations');
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[entries.length - 1 - index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final time = DateFormat('HH:mm:ss.SSS')
            .format(DateTime.fromMillisecondsSinceEpoch(e.timestamp));

        Color opColor;
        switch (e.operation.toLowerCase()) {
          case 'write':
            opColor = ColorTokens.success;
            break;
          case 'delete':
          case 'clear':
            opColor = ColorTokens.error;
            break;
          default:
            opColor = ColorTokens.info;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(time,
                    style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 9,
                        color: Colors.grey[500])),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: opColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  e.operation.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: opColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.key,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                e.storageType.name,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────

Color _platformColor(String platform) {
  switch (platform.toLowerCase()) {
    case 'flutter':
      return const Color(0xFF02569B);
    case 'react_native':
    case 'reactnative':
      return const Color(0xFF61DAFB);
    case 'android':
      return const Color(0xFF3DDC84);
    default:
      return Colors.grey;
  }
}

String _platformLabel(String platform) {
  switch (platform.toLowerCase()) {
    case 'flutter':
      return 'FLUTTER';
    case 'react_native':
    case 'reactnative':
      return 'RN';
    case 'android':
      return 'ANDROID';
    default:
      return platform.toUpperCase();
  }
}
