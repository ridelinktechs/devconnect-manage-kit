import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../components/inputs/search_field.dart';
import '../../../../components/misc/status_badge.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../models/log/log_entry.dart';
import '../../../../models/network/network_entry.dart';
import '../../../../models/state/state_change.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../../server/providers/server_providers.dart';
import '../../provider/all_events_provider.dart';

// ═══════════════════════════════════════════════
// All Events Page
// ═══════════════════════════════════════════════

class AllEventsPage extends ConsumerStatefulWidget {
  const AllEventsPage({super.key});

  @override
  ConsumerState<AllEventsPage> createState() => _AllEventsPageState();
}

class _AllEventsPageState extends ConsumerState<AllEventsPage> {
  final _scrollController = ScrollController();
  UnifiedEvent? _selectedEvent;
  bool _autoScroll = true;
  int _maxVisible = _pageSize;
  bool _loadingMore = false;
  int _previousCount = 0;

  static const _pageSize = 80;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_autoScroll &&
        !_loadingMore &&
        _scrollController.hasClients &&
        _scrollController.position.pixels < 50) {
      _loadMore();
    }
  }

  void _loadMore() {
    final totalCount = ref.read(filteredAllEventsProvider).length;
    if (_maxVisible >= totalCount) return;

    _loadingMore = true;
    final oldMaxExtent = _scrollController.position.maxScrollExtent;

    setState(() {
      _maxVisible = (_maxVisible + _pageSize).clamp(0, totalCount);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final newMaxExtent = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(
          _scrollController.position.pixels + (newMaxExtent - oldMaxExtent),
        );
      }
      _loadingMore = false;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleAutoScroll() {
    setState(() {
      _autoScroll = !_autoScroll;
      if (_autoScroll) {
        _maxVisible = _pageSize;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
    });
  }

  void _clearAll() {
    setState(() {
      _selectedEvent = null;
      _maxVisible = _pageSize;
      _previousCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allEvents = ref.watch(filteredAllEventsProvider);
    final devices = ref.watch(connectedDevicesProvider);
    final server = ref.watch(wsServerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Slice visible items
    final startIndex =
        (allEvents.length - _maxVisible).clamp(0, allEvents.length);
    final visibleEvents = allEvents.sublist(startIndex);
    final hasMore = startIndex > 0;

    // Auto-scroll on new items
    if (_autoScroll &&
        allEvents.length > _previousCount &&
        allEvents.isNotEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom());
    }
    _previousCount = allEvents.length;

    // Clear selection if event removed
    if (_selectedEvent != null &&
        !allEvents.any((e) => e.id == _selectedEvent!.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedEvent = null);
      });
    }

    return Column(
      children: [
        // ── Header ──
        _Header(
          eventCount: allEvents.length,
          deviceCount: devices.length,
          serverRunning: server.isRunning,
          port: server.isRunning ? server.port : 9090,
          autoScroll: _autoScroll,
          onToggleAutoScroll: _toggleAutoScroll,
          onClear: _clearAll,
        ),
        // ── Stats + Filters ──
        _FilterBar(events: allEvents),
        // ── Content ──
        Expanded(
          child: visibleEvents.isEmpty
              ? EmptyState(
                  icon: LucideIcons.layoutDashboard,
                  title: devices.isEmpty
                      ? 'No devices connected'
                      : 'No events yet',
                  subtitle: devices.isEmpty
                      ? 'Start your app with DevConnect SDK to see events'
                      : 'Events will appear here in real-time',
                )
              : Row(
                  children: [
                    // ── Event List ──
                    Expanded(
                      flex: _selectedEvent != null ? 4 : 1,
                      child: Column(
                        children: [
                          if (hasMore && !_autoScroll)
                            _LoadMoreBanner(
                              count: allEvents.length -
                                  visibleEvents.length,
                              onTap: _loadMore,
                            ),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: visibleEvents.length,
                              itemExtent: 44,
                              itemBuilder: (context, index) {
                                final event = visibleEvents[index];
                                final isSelected =
                                    _selectedEvent?.id == event.id;
                                return _EventRow(
                                  key: ValueKey(event.id),
                                  event: event,
                                  isSelected: isSelected,
                                  showDetail: _selectedEvent != null,
                                  onTap: () {
                                    setState(() {
                                      _selectedEvent =
                                          isSelected ? null : event;
                                    });
                                  },
                                  onCopyTitle: () =>
                                      _copy(context, event.title),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Detail Panel ──
                    if (_selectedEvent != null) ...[
                      VerticalDivider(
                        width: 1,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                      Expanded(
                        flex: 5,
                        child: _EventDetailPanel(
                          event: _selectedEvent!,
                          onClose: () =>
                              setState(() => _selectedEvent = null),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied'),
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════

class _Header extends ConsumerWidget {
  final int eventCount;
  final int deviceCount;
  final bool serverRunning;
  final int port;
  final bool autoScroll;
  final VoidCallback onToggleAutoScroll;
  final VoidCallback onClear;

  const _Header({
    required this.eventCount,
    required this.deviceCount,
    required this.serverRunning,
    required this.port,
    required this.autoScroll,
    required this.onToggleAutoScroll,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          // Title
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF8B7EF0)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.activity, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            'All Events',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 10),
          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ColorTokens.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$eventCount',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ColorTokens.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Status pills
          _StatusPill(
            color: serverRunning ? ColorTokens.success : ColorTokens.error,
            label: serverRunning ? 'Port $port' : 'Stopped',
          ),
          const SizedBox(width: 6),
          _StatusPill(
            color: deviceCount > 0 ? ColorTokens.info : Colors.grey,
            label: '$deviceCount device${deviceCount != 1 ? 's' : ''}',
          ),

          const Spacer(),

          // Auto-scroll toggle
          _ToolbarButton(
            icon: LucideIcons.arrowDownToLine,
            label: 'AUTO',
            isActive: autoScroll,
            color: ColorTokens.primary,
            onTap: onToggleAutoScroll,
          ),
          const SizedBox(width: 6),
          // Search
          SizedBox(
            width: 200,
            child: SearchField(
              hintText: 'Search events...',
              onChanged: (v) =>
                  ref.read(allEventsSearchProvider.notifier).state = v,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Filter Bar
// ═══════════════════════════════════════════════

class _FilterBar extends ConsumerWidget {
  final List<UnifiedEvent> events;

  const _FilterBar({required this.events});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeFilters = ref.watch(allEventsFilterProvider);

    final logCount = events.where((e) => e.type == EventType.log).length;
    final netCount = events.where((e) => e.type == EventType.network).length;
    final stateCount = events.where((e) => e.type == EventType.state).length;
    final storeCount = events.where((e) => e.type == EventType.storage).length;
    final errorCount = events.where((e) => e.level == 'error').length;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : const Color(0xFFF6F8FA),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'LOG',
            count: logCount,
            icon: LucideIcons.terminal,
            color: ColorTokens.logInfo,
            isActive: activeFilters.contains(EventType.log),
            onTap: () => _toggle(ref, EventType.log),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'API',
            count: netCount,
            icon: LucideIcons.globe,
            color: ColorTokens.success,
            isActive: activeFilters.contains(EventType.network),
            onTap: () => _toggle(ref, EventType.network),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'STATE',
            count: stateCount,
            icon: LucideIcons.layers,
            color: ColorTokens.secondary,
            isActive: activeFilters.contains(EventType.state),
            onTap: () => _toggle(ref, EventType.state),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'STORE',
            count: storeCount,
            icon: LucideIcons.database,
            color: ColorTokens.warning,
            isActive: activeFilters.contains(EventType.storage),
            onTap: () => _toggle(ref, EventType.storage),
          ),
          if (errorCount > 0) ...[
            const SizedBox(width: 10),
            Container(
              width: 1,
              height: 18,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            const SizedBox(width: 10),
            _FilterChip(
              label: 'ERRORS',
              count: errorCount,
              icon: LucideIcons.triangleAlert,
              color: ColorTokens.error,
              isActive: true,
              onTap: () {},
            ),
          ],
          const Spacer(),
          // Show all / only active
          Text(
            '${activeFilters.length}/${EventType.values.length} filters',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(WidgetRef ref, EventType type) {
    final current = ref.read(allEventsFilterProvider);
    if (current.contains(type)) {
      ref.read(allEventsFilterProvider.notifier).state =
          current.difference({type});
    } else {
      ref.read(allEventsFilterProvider.notifier).state = {...current, type};
    }
  }
}

// ═══════════════════════════════════════════════
// Event Row (optimized: fixed height, minimal rebuild)
// ═══════════════════════════════════════════════

class _EventRow extends ConsumerWidget {
  final UnifiedEvent event;
  final bool isSelected;
  final bool showDetail;
  final VoidCallback onTap;
  final VoidCallback onCopyTitle;

  const _EventRow({
    super.key,
    required this.event,
    required this.isSelected,
    required this.showDetail,
    required this.onTap,
    required this.onCopyTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(event.timestamp),
    );

    final typeInfo = _typeInfo(event);
    final devices = ref.watch(connectedDevicesProvider);
    final device =
        devices.where((d) => d.deviceId == event.deviceId).firstOrNull;

    final bgColor = isSelected
        ? ColorTokens.primary.withValues(alpha: 0.08)
        : isDark
            ? Colors.transparent
            : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              left: BorderSide(
                color: isSelected ? ColorTokens.primary : typeInfo.color,
                width: isSelected ? 3 : 2,
              ),
            ),
          ),
          child: Row(
            children: [
              // Time
              SizedBox(
                width: 84,
                child: Text(
                  time,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    color: Colors.grey[500],
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              // Type badge
              Container(
                width: 56,
                height: 22,
                decoration: BoxDecoration(
                  color: typeInfo.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(typeInfo.icon, size: 10, color: typeInfo.color),
                    const SizedBox(width: 3),
                    Text(
                      typeInfo.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: typeInfo.color,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Platform badge
              if (device != null) ...[
                PlatformBadge(platform: device.platform),
                const SizedBox(width: 8),
              ],
              // Title
              Expanded(
                child: Text(
                  event.title,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    color: event.level == 'error'
                        ? ColorTokens.error
                        : isDark
                            ? const Color(0xFFE6EDF3)
                            : const Color(0xFF1F2328),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Subtitle
              if (!showDetail)
                Text(
                  event.subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              // Copy button (only visible on hover would be ideal,
              // but for desktop quick-access is better)
              const SizedBox(width: 4),
              _MiniIconButton(
                icon: LucideIcons.copy,
                tooltip: 'Copy',
                onTap: onCopyTitle,
              ),
              if (isSelected) ...[
                const SizedBox(width: 2),
                Icon(LucideIcons.chevronRight,
                    size: 12, color: ColorTokens.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static _TypeInfo _typeInfo(UnifiedEvent event) {
    switch (event.type) {
      case EventType.log:
        return _TypeInfo(
          color: _logColor(event.level),
          icon: LucideIcons.terminal,
          label: event.level.toUpperCase(),
        );
      case EventType.network:
        return _TypeInfo(
          color: event.level == 'error'
              ? ColorTokens.error
              : ColorTokens.success,
          icon: LucideIcons.globe,
          label: 'API',
        );
      case EventType.state:
        return _TypeInfo(
          color: ColorTokens.secondary,
          icon: LucideIcons.layers,
          label: 'STATE',
        );
      case EventType.storage:
        return _TypeInfo(
          color: ColorTokens.warning,
          icon: LucideIcons.database,
          label: 'STORE',
        );
    }
  }

  static Color _logColor(String level) {
    switch (level) {
      case 'debug':
        return ColorTokens.logDebug;
      case 'warn':
        return ColorTokens.logWarn;
      case 'error':
        return ColorTokens.logError;
      default:
        return ColorTokens.logInfo;
    }
  }
}

// ═══════════════════════════════════════════════
// Small UI Components
// ═══════════════════════════════════════════════

class _TypeInfo {
  final Color color;
  final IconData icon;
  final String label;
  _TypeInfo({required this.color, required this.icon, required this.label});
}

class _StatusPill extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusPill({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 12, color: isActive ? color : Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isActive ? color : Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 10,
                  color: isActive ? color : Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isActive ? color : Colors.grey[600],
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: isActive
                      ? color.withValues(alpha: 0.7)
                      : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MiniIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.withValues(alpha: 0.06),
            ),
            child: Icon(icon, size: 11, color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }
}

class _LoadMoreBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _LoadMoreBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: ColorTokens.primary.withValues(alpha: 0.04),
          child: Center(
            child: Text(
              '$count older events — click to load more',
              style: const TextStyle(
                fontSize: 10,
                color: ColorTokens.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Detail Panel
// ═══════════════════════════════════════════════

class _EventDetailPanel extends StatelessWidget {
  final UnifiedEvent event;
  final VoidCallback onClose;

  const _EventDetailPanel({required this.event, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
      child: Column(
        children: [
          _DetailHeader(event: event, onClose: onClose),
          const Divider(height: 1),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (event.type) {
      case EventType.log:
        if (event.rawData is LogEntry) {
          return _LogDetail(entry: event.rawData as LogEntry);
        }
        return _FallbackDetail(event: event);
      case EventType.network:
        if (event.rawData is NetworkEntry) {
          return _NetworkDetail(entry: event.rawData as NetworkEntry);
        }
        return _FallbackDetail(event: event);
      case EventType.state:
        if (event.rawData is StateChange) {
          return _StateDetail(entry: event.rawData as StateChange);
        }
        return _FallbackDetail(event: event);
      case EventType.storage:
        if (event.rawData is StorageEntry) {
          return _StorageDetail(entry: event.rawData as StorageEntry);
        }
        return _FallbackDetail(event: event);
    }
  }
}

class _DetailHeader extends ConsumerWidget {
  final UnifiedEvent event;
  final VoidCallback onClose;

  const _DetailHeader({required this.event, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(event.timestamp),
    );

    final devices = ref.watch(connectedDevicesProvider);
    final device =
        devices.where((d) => d.deviceId == event.deviceId).firstOrNull;

    final (typeColor, typeIcon, typeLabel) = _typeDetails(event.type);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
      ),
      child: Row(
        children: [
          Icon(typeIcon, size: 14, color: typeColor),
          const SizedBox(width: 8),
          Text(
            typeLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: typeColor,
            ),
          ),
          const SizedBox(width: 10),
          if (device != null) ...[
            PlatformBadge(platform: device.platform),
            const SizedBox(width: 8),
          ],
          Text(
            time,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
          const Spacer(),
          // Copy all as JSON
          _ActionButton(
            icon: LucideIcons.braces,
            label: 'JSON',
            onTap: () {
              final json = const JsonEncoder.withIndent('  ')
                  .convert(_eventToJson(event));
              Clipboard.setData(ClipboardData(text: json));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('JSON copied'),
                  duration: Duration(milliseconds: 800),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
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
                child: Icon(LucideIcons.x, size: 14, color: Colors.grey[500]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, String) _typeDetails(EventType type) {
    switch (type) {
      case EventType.log:
        return (ColorTokens.logInfo, LucideIcons.terminal, 'Log Detail');
      case EventType.network:
        return (ColorTokens.success, LucideIcons.globe, 'Network Detail');
      case EventType.state:
        return (
          ColorTokens.secondary,
          LucideIcons.layers,
          'State Detail'
        );
      case EventType.storage:
        return (
          ColorTokens.warning,
          LucideIcons.database,
          'Storage Detail'
        );
    }
  }

  Map<String, dynamic> _eventToJson(UnifiedEvent e) {
    return {
      'type': e.type.name,
      'id': e.id,
      'deviceId': e.deviceId,
      'timestamp': e.timestamp,
      'title': e.title,
      'subtitle': e.subtitle,
      'level': e.level,
    };
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.grey.withValues(alpha: 0.08),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Log Detail
// ═══════════════════════════════════════════════

class _LogDetail extends StatelessWidget {
  final LogEntry entry;

  const _LogDetail({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LogLevelBadge(level: entry.level.name),
              if (entry.tag != null) ...[
                const SizedBox(width: 8),
                _TagChip(entry.tag!),
              ],
              const Spacer(),
              _CopyButton(
                tooltip: 'Copy message',
                onTap: () => _copyText(context, entry.message, 'Message'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionLabel('Message'),
          const SizedBox(height: 6),
          _CodeBlock(text: entry.message, isDark: isDark),
          if (entry.metadata != null && entry.metadata!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel('Metadata'),
            const SizedBox(height: 6),
            JsonViewer(data: entry.metadata, initiallyExpanded: true),
          ],
          if (entry.stackTrace != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _SectionLabel('Stack Trace'),
                const Spacer(),
                _CopyButton(
                  tooltip: 'Copy stack trace',
                  onTap: () =>
                      _copyText(context, entry.stackTrace!, 'Stack trace'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _ErrorBlock(text: entry.stackTrace!, isDark: isDark),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Network Detail
// ═══════════════════════════════════════════════

class _NetworkDetail extends StatelessWidget {
  final NetworkEntry entry;

  const _NetworkDetail({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // URL bar + actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HttpMethodBadge(method: entry.method),
                    const SizedBox(width: 8),
                    if (entry.isComplete) ...[
                      StatusBadge(statusCode: entry.statusCode),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        entry.url,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFFE6EDF3)
                              : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Action buttons row
                Row(
                  children: [
                    if (entry.duration != null) ...[
                      _TimingBar(duration: entry.duration!),
                      const Spacer(),
                    ] else
                      const Spacer(),
                    _CopyButton(
                      tooltip: 'Copy URL',
                      icon: LucideIcons.link,
                      onTap: () =>
                          _copyText(context, entry.url, 'URL'),
                    ),
                    const SizedBox(width: 4),
                    _CopyButton(
                      tooltip: 'Copy as cURL',
                      icon: LucideIcons.terminal,
                      onTap: () => _copyText(
                          context, _buildCurl(entry), 'cURL'),
                    ),
                    const SizedBox(width: 4),
                    _CopyButton(
                      tooltip: 'Copy response',
                      icon: LucideIcons.download,
                      onTap: () {
                        final body = entry.responseBody;
                        final text = body is String
                            ? body
                            : (body != null
                                ? const JsonEncoder.withIndent('  ')
                                    .convert(body)
                                : '');
                        _copyText(context, text, 'Response');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tabs
          TabBar(
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            indicatorColor: ColorTokens.primary,
            tabs: const [
              Tab(text: 'Headers'),
              Tab(text: 'Request'),
              Tab(text: 'Response'),
              Tab(text: 'Timing'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                _HeadersView(entry: entry),
                _BodyView(body: entry.requestBody, label: 'Request Body'),
                _BodyView(body: entry.responseBody, label: 'Response Body'),
                _TimingView(entry: entry),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildCurl(NetworkEntry e) {
    final buf = StringBuffer("curl -X ${e.method} '${e.url}'");
    e.requestHeaders.forEach((k, v) {
      buf.write(" \\\n  -H '$k: $v'");
    });
    if (e.requestBody != null) {
      final body = e.requestBody is String
          ? e.requestBody as String
          : const JsonEncoder().convert(e.requestBody);
      buf.write(" \\\n  -d '$body'");
    }
    return buf.toString();
  }
}

class _TimingBar extends StatelessWidget {
  final int duration;

  const _TimingBar({required this.duration});

  @override
  Widget build(BuildContext context) {
    final maxWidth = 200.0;
    final ratio = (duration / 2000).clamp(0.0, 1.0);

    Color barColor;
    if (duration < 200) {
      barColor = ColorTokens.success;
    } else if (duration < 500) {
      barColor = ColorTokens.warning;
    } else {
      barColor = ColorTokens.error;
    }

    return Row(
      children: [
        SizedBox(
          width: maxWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: barColor.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${duration}ms',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: barColor,
          ),
        ),
      ],
    );
  }
}

class _HeadersView extends StatelessWidget {
  final NetworkEntry entry;

  const _HeadersView({required this.entry});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Request Headers'),
          const SizedBox(height: 8),
          _HeaderTable(headers: entry.requestHeaders),
          const SizedBox(height: 20),
          _SectionLabel('Response Headers'),
          const SizedBox(height: 8),
          _HeaderTable(headers: entry.responseHeaders),
        ],
      ),
    );
  }
}

class _HeaderTable extends StatelessWidget {
  final Map<String, String> headers;

  const _HeaderTable({required this.headers});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (headers.isEmpty) {
      return Text('No headers',
          style: TextStyle(color: Colors.grey[500], fontSize: 12));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: headers.entries.toList().asMap().entries.map((entry) {
          final e = entry.value;
          final isLast = entry.key == headers.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: isLast
                ? null
                : BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 160,
                  child: Text(
                    e.key,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ColorTokens.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BodyView extends StatelessWidget {
  final dynamic body;
  final String label;

  const _BodyView({required this.body, required this.label});

  @override
  Widget build(BuildContext context) {
    if (body == null) {
      return EmptyState(icon: LucideIcons.fileText, title: 'No $label');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label),
          const SizedBox(height: 8),
          if (body is Map || body is List)
            JsonViewer(data: body, initiallyExpanded: true)
          else
            JsonPrettyViewer(data: body),
        ],
      ),
    );
  }
}

class _TimingView extends StatelessWidget {
  final NetworkEntry entry;

  const _TimingView({required this.entry});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            'Start Time',
            DateFormat('HH:mm:ss.SSS').format(
              DateTime.fromMillisecondsSinceEpoch(entry.startTime),
            ),
          ),
          if (entry.endTime != null)
            _InfoRow(
              'End Time',
              DateFormat('HH:mm:ss.SSS').format(
                DateTime.fromMillisecondsSinceEpoch(entry.endTime!),
              ),
            ),
          if (entry.duration != null)
            _InfoRow('Duration', '${entry.duration}ms'),
          if (entry.error != null) ...[
            const SizedBox(height: 12),
            _SectionLabel('Error'),
            const SizedBox(height: 6),
            _ErrorBlock(
              text: entry.error!,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// State Detail
// ═══════════════════════════════════════════════

class _StateDetail extends StatelessWidget {
  final StateChange entry;

  const _StateDetail({required this.entry});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _TagChip(entry.stateManagerType,
                    color: ColorTokens.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.actionName,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _CopyButton(
                  tooltip: 'Copy action',
                  onTap: () =>
                      _copyText(context, entry.actionName, 'Action'),
                ),
              ],
            ),
          ),
          TabBar(
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            indicatorColor: ColorTokens.secondary,
            tabs: const [
              Tab(text: 'Diff'),
              Tab(text: 'Previous'),
              Tab(text: 'Next'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                entry.diff.isEmpty
                    ? const EmptyState(
                        icon: LucideIcons.gitCompare, title: 'No diff')
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: entry.diff.length,
                        itemBuilder: (context, index) =>
                            _DiffRow(diff: entry.diff[index]),
                      ),
                entry.previousState.isEmpty
                    ? const EmptyState(
                        icon: LucideIcons.layers,
                        title: 'No previous state')
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: JsonViewer(
                            data: entry.previousState,
                            initiallyExpanded: true),
                      ),
                entry.nextState.isEmpty
                    ? const EmptyState(
                        icon: LucideIcons.layers,
                        title: 'No next state')
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: JsonViewer(
                            data: entry.nextState,
                            initiallyExpanded: true),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  final StateDiffEntry diff;

  const _DiffRow({required this.diff});

  @override
  Widget build(BuildContext context) {
    Color opColor;
    IconData opIcon;
    switch (diff.operation) {
      case 'add':
        opColor = ColorTokens.success;
        opIcon = LucideIcons.plus;
        break;
      case 'remove':
        opColor = ColorTokens.error;
        opIcon = LucideIcons.minus;
        break;
      default:
        opColor = ColorTokens.warning;
        opIcon = LucideIcons.penLine;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: opColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: opColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(opIcon, size: 12, color: opColor),
              const SizedBox(width: 6),
              Text(
                diff.path,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: opColor,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: opColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  diff.operation.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: opColor,
                  ),
                ),
              ),
            ],
          ),
          if (diff.oldValue != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('- ',
                    style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        color: ColorTokens.error)),
                Expanded(
                  child: Text(
                    '${diff.oldValue}',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      color: ColorTokens.error.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (diff.newValue != null) ...[
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('+ ',
                    style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        color: ColorTokens.success)),
                Expanded(
                  child: Text(
                    '${diff.newValue}',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      color: ColorTokens.success.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Storage Detail
// ═══════════════════════════════════════════════

class _StorageDetail extends StatelessWidget {
  final StorageEntry entry;

  const _StorageDetail({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color opColor;
    switch (entry.operation.toLowerCase()) {
      case 'write':
        opColor = ColorTokens.success;
        break;
      case 'read':
        opColor = ColorTokens.info;
        break;
      case 'delete':
      case 'clear':
        opColor = ColorTokens.error;
        break;
      default:
        opColor = ColorTokens.warning;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TagChip(entry.operation.toUpperCase(), color: opColor),
              const SizedBox(width: 8),
              _TagChip(entry.storageType.name, color: ColorTokens.warning),
              const Spacer(),
              _CopyButton(
                tooltip: 'Copy key',
                onTap: () => _copyText(context, entry.key, 'Key'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionLabel('Key'),
          const SizedBox(height: 6),
          _CodeBlock(text: entry.key, isDark: isDark),
          if (entry.value != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _SectionLabel('Value'),
                const Spacer(),
                _CopyButton(
                  tooltip: 'Copy value',
                  onTap: () {
                    final text = entry.value is String
                        ? entry.value as String
                        : const JsonEncoder.withIndent('  ')
                            .convert(entry.value);
                    _copyText(context, text, 'Value');
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (entry.value is Map || entry.value is List)
              JsonViewer(data: entry.value, initiallyExpanded: true)
            else
              _CodeBlock(text: '${entry.value}', isDark: isDark),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Fallback Detail
// ═══════════════════════════════════════════════

class _FallbackDetail extends StatelessWidget {
  final UnifiedEvent event;

  const _FallbackDetail({required this.event});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Title'),
          const SizedBox(height: 6),
          _CodeBlock(text: event.title, isDark: isDark),
          const SizedBox(height: 16),
          _SectionLabel('Details'),
          const SizedBox(height: 6),
          _CodeBlock(text: event.subtitle, isDark: isDark),
          if (event.rawData != null) ...[
            const SizedBox(height: 16),
            _SectionLabel('Raw Data'),
            const SizedBox(height: 6),
            if (event.rawData is Map || event.rawData is List)
              JsonViewer(data: event.rawData, initiallyExpanded: true)
            else
              _CodeBlock(text: '${event.rawData}', isDark: isDark),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Shared Widgets
// ═══════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey[500],
        letterSpacing: 0.5,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TagChip(this.label, {this.color = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  final IconData icon;

  const _CopyButton({
    required this.tooltip,
    required this.onTap,
    this.icon = LucideIcons.copy,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey.withValues(alpha: 0.08),
            ),
            child: Icon(icon, size: 13, color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String text;
  final bool isDark;

  const _CodeBlock({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 12,
          color: isDark ? const Color(0xFFE6EDF3) : Colors.black87,
          height: 1.6,
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String text;
  final bool isDark;

  const _ErrorBlock({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorTokens.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: ColorTokens.error.withValues(alpha: 0.15)),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 11,
          color: ColorTokens.error.withValues(alpha: 0.9),
          height: 1.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Helper
// ═══════════════════════════════════════════════

void _copyText(BuildContext context, String text, String label) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$label copied'),
      duration: const Duration(milliseconds: 800),
    ),
  );
}
