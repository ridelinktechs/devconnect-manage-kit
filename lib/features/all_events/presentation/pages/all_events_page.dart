import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../core/utils/screenshot_utils.dart';
import '../../../../core/utils/screenshot_filename.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/preferences/app_preferences.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../components/feedback/empty_state.dart';
import '../../../../components/inputs/search_field.dart';
import '../../../../components/text/text_component.dart';
import '../../../../components/misc/status_badge.dart';
import '../../../../components/misc/service_tag.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/providers/tab_visibility_provider.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/code_generator.dart';
import '../../../../models/device_info.dart';
import '../../../../models/display/display_entry.dart';
import '../../../../models/log/log_entry.dart';
import '../../../../models/network/network_entry.dart';
import '../../../../models/state/state_change.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../../server/providers/server_providers.dart';
import '../../../console/provider/console_providers.dart';
import '../../../display/provider/display_providers.dart';
import '../../../error_inspector/provider/error_providers.dart';
import '../../../network_inspector/provider/network_providers.dart';
import '../../../performance/provider/performance_providers.dart';
import '../../../benchmark/provider/benchmark_providers.dart';
import '../../../state_inspector/provider/state_providers.dart';
import '../../../storage_viewer/provider/storage_providers.dart';
import '../../../../components/lists/stable_list_view.dart';
import '../../../../components/misc/jump_to_latest_fab.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
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
  final _scrollController = SmoothScrollController();
  final _selectedEventId = ValueNotifier<String?>(null);
  final _eventCount = ValueNotifier<int>(0);
  bool _autoScroll = true;
  bool _programmaticScroll = false;
  int _visibleCount = 0;
  int _generation = 0;
  final List<UnifiedEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    ref.listenManual(
      filteredAllEventsProvider,
      (previous, next) {
        _events..clear()..addAll(next);
        _eventCount.value = _events.length;
        _visibleCount = _events.length;
        _generation++;
        setState(() {});
        if (_autoScroll) _autoScrollIfNeeded();
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _selectedEventId.dispose();
    _eventCount.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final atBottom = pos.pixels >= pos.maxScrollExtent - 2.0;
    final distFromBottom = pos.maxScrollExtent - pos.pixels;

    if (!_autoScroll && atBottom) {
      _autoScroll = true;
      _visibleCount = _events.length;
      setState(() {});
      return;
    }

    if (_autoScroll && !_programmaticScroll && distFromBottom > 50.0) {
      _autoScroll = false;
      setState(() {});
      return;
    }

    if (!_autoScroll && _visibleCount < _events.length) {
      if (distFromBottom < pos.viewportDimension * 1.5) {
        _visibleCount = _events.length;
        setState(() {});
      }
    }
  }

  void _autoScrollIfNeeded() {
    if (!_autoScroll || _programmaticScroll) return;
    _programmaticScroll = true;
    _doAutoScroll();
  }

  void _doAutoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_autoScroll || !_scrollController.hasClients) {
        _programmaticScroll = false;
        return;
      }
      final pos = _scrollController.position;
      final target = pos.maxScrollExtent;
      final atTarget = pos.pixels >= pos.maxScrollExtent - 2.0;
      if (atTarget) {
        _programmaticScroll = false;
        return;
      }
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ).whenComplete(() {
        if (!mounted || !_autoScroll || !_scrollController.hasClients) {
          _programmaticScroll = false;
          return;
        }
        final p = _scrollController.position;
        final done = p.pixels >= p.maxScrollExtent - 2.0;
        if (!done) {
          _doAutoScroll();
        } else {
          _programmaticScroll = false;
        }
      });
    });
  }

  void _toggleAutoScroll() {
    if (_autoScroll) {
      _autoScroll = false;
      _programmaticScroll = false;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.offset);
      }
    } else {
      _autoScroll = true;
      _visibleCount = _events.length;
      _autoScrollIfNeeded();
    }
    setState(() {});
  }

  void _clearAll() {
    ref.read(consoleEntriesProvider.notifier).clear();
    ref.read(networkEntriesProvider.notifier).clear();
    ref.read(stateChangesProvider.notifier).clear();
    ref.read(storageEntriesProvider.notifier).clear();
    ref.read(displayEntriesProvider.notifier).clear();
    ref.read(asyncOperationEntriesProvider.notifier).clear();
    ref.read(errorEntriesProvider.notifier).clear();
    ref.read(performanceEntriesProvider.notifier).clear();
    ref.read(memoryLeakEntriesProvider.notifier).clear();
    ref.read(benchmarkEntriesProvider.notifier).clear();
    _selectedEventId.value = null;
    _events.clear();
    _eventCount.value = 0;
    _visibleCount = 0;
    setState(() {});
  }

  bool _restarting = false;

  /// Restart the WebSocket server. Forces every connected SDK into its
  /// reconnect path — useful when you've changed the port, switched WiFi,
  /// or want to verify the machineId handshake from scratch.
  /// Ask every connected device to reload its own app.
  ///
  /// Behaviour on each SDK:
  /// - **Flutter** → `WidgetsBinding.instance.reassembleApplication()` (full
  ///   widget tree rebuild — the same mechanism `flutter run -r` uses)
  /// - **React Native** → `DevSettings.reload()` (Metro reload)
  /// - **Android** → `Activity.recreate()` on the host activity
  ///
  /// We broadcast to ALL devices regardless of platform — the wire message
  /// is the same, the SDK knows what to do with it. The icon and tooltip on
  /// the button adapt to the dominant connected platform, but the click
  /// always sends the reload to every device.
  bool _reloading = false;

  Future<void> _reloadApp() async {
    if (_reloading) return;
    final handler = ref.read(wsMessageHandlerProvider);
    final devices = ref.read(connectedDevicesProvider);
    if (devices.isEmpty) {
      showInfoToast(
        context,
        message: S.of(context).reloadApp,
        subtitle: S.of(context).reloadAppNoDevices,
      );
      return;
    }
    setState(() => _reloading = true);
    try {
      handler.broadcastReload();
      if (!mounted) return;
      showSuccessToast(
        context,
        message: S.of(context).reloadSent,
        subtitle: S.of(context).sentReloadTo(devices.length),
      );
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  bool _hotRestarting = false;

  /// Hot restart — the heavier Flutter IDE action. Same broadcast semantics
  /// as [_reloadApp] but sends `server:hot_restart` so Flutter SDKs can
  /// branch into their heavy-weight handler (default still
  /// `reassembleApplication`; apps can register `onHotRestartRequest` to
  /// actually wipe state).
  Future<void> _hotRestartApp() async {
    if (_hotRestarting) return;
    final handler = ref.read(wsMessageHandlerProvider);
    final devices = ref.read(connectedDevicesProvider);
    if (devices.isEmpty) {
      showInfoToast(
        context,
        message: S.of(context).reloadAppHotRestart,
        subtitle: S.of(context).reloadAppNoDevices,
      );
      return;
    }
    setState(() => _hotRestarting = true);
    try {
      handler.broadcastReload(hotRestart: true);
      if (!mounted) return;
      showSuccessToast(
        context,
        message: S.of(context).reloadSent,
        subtitle: S.of(context).sentReloadTo(devices.length),
      );
    } finally {
      if (mounted) setState(() => _hotRestarting = false);
    }
  }

  Future<void> _restartServer() async {
    if (_restarting) return;
    setState(() => _restarting = true);
    final ws = ref.read(wsServerProvider);
    final port = ws.isRunning ? ws.port : 9090;
    final hadDevices = ref.read(connectedDevicesProvider).length;

    try {
      if (ws.isRunning) {
        try {
          await ws.stop();
          // Tiny gap so devices see a clean disconnect and reset their
          // reconnect timer (otherwise they reconnect so fast the user can't
          // tell anything happened).
          await Future.delayed(const Duration(milliseconds: 600));
        } catch (e) {
          ref.read(serverStartErrorProvider.notifier).state = e.toString();
          if (!mounted) return;
          showErrorToast(
            context,
            message: S.of(context).restartFailed,
            error: e.toString(),
          );
          return;
        }
      }
      ref.read(serverStartErrorProvider.notifier).state = null;

      try {
        await ws.start(port: port);
        ref.read(serverStartErrorProvider.notifier).state = null;

        // Toast: success. Wait one frame so connectedDevicesProvider picks
        // up any reconnects before we report the count.
        await Future.delayed(const Duration(milliseconds: 200));
        final reconnected = ref.read(connectedDevicesProvider).length;

        if (!mounted) return;
        if (hadDevices > 0 && reconnected == 0) {
          // Server up but no devices reconnected yet — informational.
          showInfoToast(
            context,
            message: S.of(context).serverRestarted,
            subtitle: S.of(context).waitingForReconnect(port),
          );
        } else if (reconnected > 0) {
          showSuccessToast(
            context,
            message: S.of(context).serverRestarted,
            subtitle: S.of(context).reconnectedCount(reconnected),
          );
        } else {
          showSuccessToast(
            context,
            message: S.of(context).serverRestarted,
            subtitle: S.of(context).listeningOnPort(port),
          );
        }
      } catch (e) {
        ref.read(serverStartErrorProvider.notifier).state = e.toString();
        if (!mounted) return;
        // Surface the friendly error message when possible.
        final msg = e.toString();
        final friendly = msg.contains('Address already in use') ||
                msg.contains('errno = 48') ||
                msg.contains('errno = 98')
            ? S.of(context).portStillInUse(port)
            : S.of(context).couldNotRestart(port);
        showErrorToast(
          context,
          message: S.of(context).restartFailed,
          error: friendly,
        );
      }
    } finally {
      if (mounted) setState(() => _restarting = false);
    }
  }

  UnifiedEvent? _findEvent(String? id) {
    if (id == null) return null;
    return _events.where((e) => e.id == id).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(connectedDevicesProvider);
    final server = ref.watch(wsServerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sortOrder = ref.watch(allEventsSortOrderProvider);

    return Stack(
      children: [
        Column(
          children: [
        // ── Header ──
        _Header(
          eventCount: _eventCount,
          serverRunning: server.isRunning,
          port: server.isRunning ? server.port : 9090,
          deviceCount: devices.length,
          devices: devices,
          autoScroll: _autoScroll,
          onToggleAutoScroll: _toggleAutoScroll,
          onClear: _clearAll,
          restarting: _restarting,
          onReload: _restartServer,
          reloading: _reloading,
          hotRestarting: _hotRestarting,
          onReloadApp: _reloadApp,
          onHotRestart: _hotRestartApp,
        ),
        // ── Stats + Filters ── (rebuilds via _eventCount, not setState)
        ValueListenableBuilder<int>(
          valueListenable: _eventCount,
          builder: (_, __, ___) => _FilterBar(events: _events),
        ),
        // ── Content ──
        Expanded(
          child: _events.isEmpty
              ? EmptyState(
                  icon: LucideIcons.layoutDashboard,
                  title: devices.isEmpty
                      ? S.of(context).noDevicesConnected
                      : S.of(context).noEventsYet,
                  subtitle: devices.isEmpty
                      ? S.of(context).startAppToSeeEvents
                      : S.of(context).eventsAppearHere,
                )
              : Stack(
                  children: [
                    Row(
                      children: [
                        // ── Event List ──
                        // List never rebuilds due to selection change.
                        Expanded(
                          child: ListView.custom(
                            controller: _scrollController,
                            itemExtent: 44,
                            childrenDelegate: StableBuilderDelegate(
                              generation: _generation,
                              childCount: _visibleCount,
                              findChildIndexCallback: (key) {
                                if (key is ValueKey<String>) {
                                  final idx = _events.indexWhere((e) => e.id == key.value);
                                  return idx == -1 ? null : idx;
                                }
                                return null;
                              },
                              builder: (context, index) {
                                final actualIndex = sortOrder == SortOrder.newestFirst
                                    ? _visibleCount - 1 - index
                                    : index;
                                if (actualIndex < 0 || actualIndex >= _events.length) {
                                  return const SizedBox.shrink();
                                }
                                final event = _events[actualIndex];
                                final device = devices
                                    .where(
                                        (d) => d.deviceId == event.deviceId)
                                    .firstOrNull;
                                return RepaintBoundary(
                                  key: ValueKey(event.id),
                                  child: ValueListenableBuilder<String?>(
                                    valueListenable: _selectedEventId,
                                    builder: (context, selectedId, _) {
                                      final isSelected = selectedId == event.id;
                                      return _EventRow(
                                        event: event,
                                        isSelected: isSelected,
                                        showDetail: false,
                                        platform: device?.platform,
                                        onTap: () {
                                          _selectedEventId.value =
                                              isSelected ? null : event.id;
                                          if (!isSelected && _autoScroll) {
                                            _autoScroll = false;
                                            _programmaticScroll = false;
                                            if (_scrollController.hasClients) {
                                              _scrollController.jumpTo(_scrollController.offset);
                                            }
                                            setState(() {});
                                          }
                                        },
                                        onCopyTitle: () =>
                                            _copy(context, event.title),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // ── Detail Panel ──
                        // Only the detail panel listens to selection changes.
                        ValueListenableBuilder<String?>(
                          valueListenable: _selectedEventId,
                          builder: (context, selectedId, _) {
                            final selectedEvent = _findEvent(selectedId);
                            if (selectedEvent == null) return const SizedBox.shrink();
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                VerticalDivider(
                                  width: 1,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.45,
                                  child: _EventDetailPanel(
                                    key: ValueKey(selectedEvent.id),
                                    event: selectedEvent,
                                    onClose: () => _selectedEventId.value = null,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    PositionedJumpToLatestFab(
                      scrollController: _scrollController,
                      reversed: sortOrder == SortOrder.newestFirst,
                    ),
                  ],
                ),
        ),
          ],
        ),
        // Draggable floating action button — sits on top of every panel
        // (header / filter bar / event list / detail panel / "jump to
        // latest" pill) so it's always reachable but never blocks data
        // because it lives at the screen edge by default and the user can
        // drag it anywhere within the viewport.
        _DraggableReloadFab(
          devices: devices,
          reloading: _reloading,
          hotRestarting: _hotRestarting,
          onReload: _reloadApp,
          onHotRestart: _hotRestartApp,
        ),
      ],
    );
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    showCopiedToast(context);
  }
}

// ═══════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════

class _Header extends ConsumerWidget {
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

  const _Header({
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
          _ServerStatusPill(
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
          _ReloadPill(
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
                // floating FAB (see `_DraggableReloadFab` rendered in the
                // page-level Stack) so the button stays out of the user's
                // way during long debug sessions.
                _IconBtn(
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
                    return _IconBtn(
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
                _IconBtn(
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
    final enabledTabs = ref.watch(tabVisibilityProvider);
    final errorsOnly = ref.watch(allEventsErrorsOnlyProvider);

    final logCount = events.where((e) => e.type == EventType.log).length;
    final netCount = events.where((e) => e.type == EventType.network).length;
    final stateCount = events.where((e) => e.type == EventType.state).length;
    final storeCount = events.where((e) => e.type == EventType.storage).length;
    final displayCount = events.where((e) => e.type == EventType.display).length;
    final asyncCount = events.where((e) => e.type == EventType.asyncOp).length;
    final errorCount = events.where((e) => e.level == 'error').length;

    // Only show filter chips for enabled tabs
    final chips = <Widget>[];
    if (enabledTabs.contains(TabKey.console)) {
      chips.add(_FilterChip(
        label: 'LOG',
        count: logCount,
        icon: LucideIcons.terminal,
        color: ColorTokens.logInfo,
        isActive: activeFilters.contains(EventType.log),
        onTap: () => _toggle(ref, EventType.log),
      ));
    }
    if (enabledTabs.contains(TabKey.network)) {
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
      chips.add(_FilterChip(
        label: 'API',
        count: netCount,
        icon: LucideIcons.globe,
        color: ColorTokens.success,
        isActive: activeFilters.contains(EventType.network),
        onTap: () => _toggle(ref, EventType.network),
      ));
    }
    if (enabledTabs.contains(TabKey.state)) {
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
      chips.add(_FilterChip(
        label: 'STATE',
        count: stateCount,
        icon: LucideIcons.layers,
        color: ColorTokens.secondary,
        isActive: activeFilters.contains(EventType.state),
        onTap: () => _toggle(ref, EventType.state),
      ));
    }
    if (enabledTabs.contains(TabKey.storage)) {
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
      chips.add(_FilterChip(
        label: 'STORE',
        count: storeCount,
        icon: LucideIcons.database,
        color: ColorTokens.warning,
        isActive: activeFilters.contains(EventType.storage),
        onTap: () => _toggle(ref, EventType.storage),
      ));
    }
    // Display events (always visible — no dedicated tab)
    if (displayCount > 0 || activeFilters.contains(EventType.display)) {
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
      chips.add(_FilterChip(
        label: 'DISPLAY',
        count: displayCount,
        icon: LucideIcons.monitor,
        color: const Color(0xFF9B59B6),
        isActive: activeFilters.contains(EventType.display),
        onTap: () => _toggle(ref, EventType.display),
      ));
    }
    // Async operation events (always visible — no dedicated tab)
    if (asyncCount > 0 || activeFilters.contains(EventType.asyncOp)) {
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
      chips.add(_FilterChip(
        label: 'ASYNC',
        count: asyncCount,
        icon: LucideIcons.zap,
        color: const Color(0xFFE67E22),
        isActive: activeFilters.contains(EventType.asyncOp),
        onTap: () => _toggle(ref, EventType.asyncOp),
      ));
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : ColorTokens.lightSurface,
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
          ...chips,
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
              isActive: errorsOnly,
              onTap: () => ref
                  .read(allEventsErrorsOnlyProvider.notifier)
                  .update((v) => !v),
            ),
          ],
          const Spacer(),
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

class _EventRow extends StatelessWidget {
  final UnifiedEvent event;
  final bool isSelected;
  final bool showDetail;
  final String? platform;
  final VoidCallback onTap;
  final VoidCallback onCopyTitle;

  const _EventRow({
    super.key,
    required this.event,
    required this.isSelected,
    required this.showDetail,
    this.platform,
    required this.onTap,
    required this.onCopyTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(event.timestamp),
    );

    final typeInfo = _typeInfo(event);

    // Left bar color: for network, show status-based color
    Color leftBarColor = typeInfo.color;
    if (event.type == EventType.network && event.rawData is NetworkEntry) {
      final netEntry = event.rawData as NetworkEntry;
      if (!netEntry.isComplete) {
        leftBarColor = ColorTokens.warning;
      } else if (netEntry.statusCode <= 0 || netEntry.statusCode >= 400) {
        leftBarColor = ColorTokens.error;
      } else {
        leftBarColor = ColorTokens.success;
      }
    }

    // Status-based background for network requests
    final isNetworkError = event.type == EventType.network &&
        event.rawData is NetworkEntry &&
        (event.rawData as NetworkEntry).isComplete &&
        ((event.rawData as NetworkEntry).statusCode <= 0 ||
            (event.rawData as NetworkEntry).statusCode >= 400);
    final isNetworkInProgress = event.type == EventType.network &&
        event.rawData is NetworkEntry &&
        !(event.rawData as NetworkEntry).isComplete;

    final bgColor = isSelected
        ? ColorTokens.selectedBg(isDark)
        : isNetworkError
            ? ColorTokens.error.withValues(alpha: isDark ? 0.08 : 0.05)
            : isNetworkInProgress
                ? ColorTokens.warning.withValues(alpha: isDark ? 0.08 : 0.05)
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
                color: isSelected ? ColorTokens.selectedAccent : leftBarColor,
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
                    fontFamily: AppConstants.monoFontFamily,
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
              if (platform != null) ...[
                PlatformBadge(platform: platform!),
                const SizedBox(width: 8),
              ],
              // Title
              Expanded(
                child: Text(
                  event.title,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    color: event.level == 'error'
                        ? ColorTokens.error
                        : isDark
                            ? ColorTokens.lightBackground
                            : ColorTokens.darkNeutral,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (event.type == EventType.network &&
                  event.rawData is NetworkEntry &&
                  (event.rawData as NetworkEntry).serviceName != null) ...[
                ServiceTag(
                    name: (event.rawData as NetworkEntry).serviceName!),
                const SizedBox(width: 6),
              ],
              // Subtitle / Status indicator
              if (!showDetail) ...[
                if (event.type == EventType.network &&
                    event.rawData is NetworkEntry) ...[
                  if (!(event.rawData as NetworkEntry).isComplete) ...[
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: ColorTokens.warning,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      S.of(context).inProgress,
                      style: TextStyle(
                        fontSize: 10,
                        color: ColorTokens.warning,
                        fontFamily: AppConstants.monoFontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    StatusBadge(
                        statusCode:
                            (event.rawData as NetworkEntry).statusCode),
                    const SizedBox(width: 6),
                    if ((event.rawData as NetworkEntry).duration != null)
                      Text(
                        formatDuration(
                            (event.rawData as NetworkEntry).duration!),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontFamily: AppConstants.monoFontFamily,
                        ),
                      ),
                  ],
                ] else
                  Text(
                    event.subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontFamily: AppConstants.monoFontFamily,
                    ),
                  ),
              ],
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
      case EventType.display:
        return _TypeInfo(
          color: const Color(0xFF9B59B6),
          icon: LucideIcons.monitor,
          label: 'DISPLAY',
        );
      case EventType.asyncOp:
        return _TypeInfo(
          color: const Color(0xFFE67E22),
          icon: LucideIcons.zap,
          label: event.rawData is AsyncOperationEntry
              ? (event.rawData as AsyncOperationEntry).status.name.toUpperCase()
              : 'ASYNC',
        );
      case EventType.error:
        return _TypeInfo(
          color: Colors.red,
          icon: LucideIcons.alertTriangle,
          label: 'ERROR',
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

// ═══════════════════════════════════════════════
// Detail Tab Bar
// ═══════════════════════════════════════════════

class _DetailTabBar extends StatelessWidget {
  final TabController controller;
  final bool isDark;
  final Color accentColor;
  final List<String> tabs;

  const _DetailTabBar({
    required this.controller,
    required this.isDark,
    required this.accentColor,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: controller,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        labelColor: accentColor,
        unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark
                ? accentColor.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        indicatorPadding: EdgeInsets.zero,
        dividerHeight: 0,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        padding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        tabs: tabs
            .map((t) => Tab(height: 28, text: t))
            .toList(),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final bool isDanger;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color iconColor;
    Color bgColor;

    if (widget.isActive) {
      iconColor = ColorTokens.primary;
      bgColor = ColorTokens.primary.withValues(alpha: 0.15);
    } else if (widget.isDanger && _hovered) {
      iconColor = ColorTokens.error;
      bgColor = ColorTokens.error.withValues(alpha: 0.12);
    } else if (_hovered) {
      iconColor = isDark ? Colors.grey[300]! : Colors.grey[700]!;
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06);
    } else {
      iconColor = isDark ? Colors.grey[500]! : Colors.grey[500]!;
      bgColor = Colors.transparent;
    }

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Slightly larger icon button used in the header next to the port/device
/// counters (the server restart "Reload" button).
class _HeaderActionIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool spinning;
  final VoidCallback onTap;

  const _HeaderActionIcon({
    required this.icon,
    required this.tooltip,
    required this.spinning,
    required this.onTap,
  });

  @override
  State<_HeaderActionIcon> createState() => _HeaderActionIconState();
}

class _HeaderActionIconState extends State<_HeaderActionIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.spinning) _spinCtrl.repeat();
  }

  @override
  void didUpdateWidget(covariant _HeaderActionIcon old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_spinCtrl.isAnimating) {
      _spinCtrl.repeat();
    } else if (!widget.spinning && _spinCtrl.isAnimating) {
      _spinCtrl.reset();
    }
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = _hovered || widget.spinning
        ? ColorTokens.primary
        : (isDark ? Colors.grey[400]! : Colors.grey[600]!);
    final bgColor = _hovered || widget.spinning
        ? ColorTokens.primary.withValues(alpha: 0.12)
        : Colors.transparent;

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.spinning ? null : widget.onTap,
        child: MouseRegion(
          cursor:
              widget.spinning ? SystemMouseCursors.basic : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: RotationTransition(
              turns: _spinCtrl,
              child: Icon(widget.icon, size: 12, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact status indicator for the All Events header.
///
/// Single rounded pill that conveys server state + port + device count.
/// Dot gently pulses when the server is running (perpetual micro-motion),
/// turns warning amber if the port is occupied, error red if stopped.
class _ServerStatusPill extends StatefulWidget {
  final bool serverRunning;
  final bool portOccupied;
  final int port;
  final int deviceCount;
  final String? startError;

  const _ServerStatusPill({
    required this.serverRunning,
    required this.portOccupied,
    required this.port,
    required this.deviceCount,
    required this.startError,
  });

  @override
  State<_ServerStatusPill> createState() => _ServerStatusPillState();
}

class _ServerStatusPillState extends State<_ServerStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.serverRunning) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _ServerStatusPill old) {
    super.didUpdateWidget(old);
    if (widget.serverRunning && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.serverRunning && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color _accent() {
    if (widget.portOccupied) return ColorTokens.warning;
    if (!widget.serverRunning) return ColorTokens.error;
    return ColorTokens.success;
  }

  String _label() {
    if (widget.portOccupied) return S.of(context).portOccupied(widget.port);
    if (!widget.serverRunning) return S.of(context).stopped;
    return 'Port ${widget.port}';
  }

  IconData _icon() {
    if (widget.portOccupied) return LucideIcons.triangleAlert;
    if (!widget.serverRunning) return LucideIcons.circlePause;
    return LucideIcons.radio;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent();
    final label = _label();
    final icon = _icon();

    return Tooltip(
      message: widget.portOccupied && widget.startError != null
          ? widget.startError!
          : label,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark
              ? accent.withValues(alpha: 0.08)
              : accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accent.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing dot
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                final scale = widget.serverRunning
                    ? 1.0 + 0.4 * _pulseCtrl.value
                    : 1.0;
                final alpha = widget.serverRunning
                    ? 1.0 - 0.5 * _pulseCtrl.value
                    : 1.0;
                return Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: alpha),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.45 * alpha),
                        blurRadius: 6 * scale,
                        spreadRadius: 1 * scale,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 11, color: accent.withValues(alpha: 0.85)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontFamily: AppConstants.monoFontFamily,
                color: accent.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
            if (widget.deviceCount > 0) ...[
              Container(
                width: 1,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: accent.withValues(alpha: 0.25),
              ),
              Text(
                '${widget.deviceCount}',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: AppConstants.monoFontFamily,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                widget.deviceCount == 1 ? 'device' : 'devices',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reload connection pill — sits next to the status pill and forces every
/// connected SDK into its reconnect path. Tactile feedback on press.
class _ReloadPill extends StatefulWidget {
  final bool restarting;
  final String tooltip;
  final VoidCallback onTap;

  const _ReloadPill({
    required this.restarting,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ReloadPill> createState() => _ReloadPillState();
}

class _ReloadPillState extends State<_ReloadPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.restarting) _spinCtrl.repeat();
  }

  @override
  void didUpdateWidget(covariant _ReloadPill old) {
    super.didUpdateWidget(old);
    if (widget.restarting && !_spinCtrl.isAnimating) {
      _spinCtrl.repeat();
    } else if (!widget.restarting && _spinCtrl.isAnimating) {
      _spinCtrl.reset();
    }
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.restarting ? null : widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: widget.restarting
                ? ColorTokens.primary.withValues(alpha: isDark ? 0.14 : 0.10)
                : isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.restarting
                  ? ColorTokens.primary.withValues(alpha: 0.35)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _spinCtrl,
                child: Icon(
                  LucideIcons.refreshCw,
                  size: 12,
                  color: widget.restarting
                      ? ColorTokens.primary
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                widget.restarting ? S.of(context).restarting : widget.tooltip,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.restarting
                      ? ColorTokens.primary
                      : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeInfo {
  final Color color;
  final IconData icon;
  final String label;
  _TypeInfo({required this.color, required this.icon, required this.label});
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
    return _PressableButton(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  size: 13,
                  color: isActive ? color : Colors.grey[600]),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive ? color : Colors.grey[600],
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
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

// (old `_ReloadAppBtn` removed — replaced by `_DraggableReloadFab` below)

/// Draggable floating action button — reload-app on connected devices.
///
/// Sits in a top-layer [Stack] over the All Events page content. Lives at
/// the bottom-right by default and snaps to the nearest corner on release,
/// with the user's last position persisted via [AppPreferences].
///
/// Visual treatment per `design-taste-frontend-v1`:
///
/// - True frosted glass: [BackdropFilter] blur, 1px inner border +
///   "1px inner highlight" gradient on top for edge refraction.
/// - No neon outer glow — drop shadow is tinted to the background hue.
/// - Idle footprint is a 40px circle, which expands into a pill (40 × N)
///   on hover when multiple reload actions are available (e.g. Flutter
///   → Hot Reload + Hot Restart).
/// - Drag handle is the whole surface; spring-physics snap on release.
/// - Spin animation while a reload is in flight; per-button independent
///   so Hot Reload + Hot Restart can run concurrently.
///
/// ### Behaviour matrix
///
/// | Devices               | Visible actions                              | Icon(s)         |
/// | --------------------- | -------------------------------------------- | --------------- |
/// | 0 devices             | (button dimmed, no-op)                       | `zap`           |
/// | Flutter only          | Hot Reload + Hot Restart                     | `zap`, `refreshCcw` |
/// | RN only               | Reload Metro                                 | `rocket`        |
/// | Android only          | Rebuild                                      | `hammer`        |
/// | Mixed platforms       | Reload app (sends `server:reload` to all)    | `zap`           |
class _DraggableReloadFab extends StatefulWidget {
  final List<DeviceInfo> devices;
  final bool reloading;
  final bool hotRestarting;
  final VoidCallback onReload;
  final VoidCallback onHotRestart;

  const _DraggableReloadFab({
    required this.devices,
    required this.reloading,
    required this.hotRestarting,
    required this.onReload,
    required this.onHotRestart,
  });

  @override
  State<_DraggableReloadFab> createState() => _DraggableReloadFabState();
}

class _DraggableReloadFabState extends State<_DraggableReloadFab>
    with SingleTickerProviderStateMixin {
  /// Distance from the bottom-right corner of the parent (the All Events
  /// page content). 20 = default 20px margin from bottom + right edges.
  double _right = 20;
  double _bottom = 20;

  bool _hovered = false;
  bool _dragging = false;

  // Drag tracking — we record the starting screen position and the
  // starting edge-distances, then compute new distances from the delta.
  late double _dragStartRight;
  late double _dragStartBottom;
  late Offset _dragStartGlobal;
  // Press feedback: a brief scale-down + opacity dip on the FAB.
  bool _pressed = false;

  static const double _fabHeight = 44;
  static const double _collapsedWidth = 44;
  static const double _actionWidth = 38; // each action button is 38px wide
  static const double _actionGap = 4;
  static const double _edgeMargin = 20; // distance from screen edges
  /// Combined height of the page chrome the FAB must never overlap:
  ///   • page header (48) — "All Events" title bar
  ///   • filter bar   (44) — LOG / API / STATE / ... chip row
  /// Mirrors the `Container(height: 48, ...)` at `_Header` and the
  /// `Container(height: 44, ...)` at `_FilterBar` in this file; if you
  /// change either, change the constants here.
  static const double _headerHeight = 48;
  static const double _filterBarHeight = 44;

  @override
  void initState() {
    super.initState();
    // Always start at the default position (bottom-right, 20px margin).
    // Position is NOT persisted across launches — every cold start
    // resets the FAB so the user always knows where to find it
    // without hunting around the screen for a previously-dragged ghost.
    _right = _edgeMargin;
    _bottom = _edgeMargin;
    // Eagerly allocate the controller so dispose() never trips over an
    // uninitialised `late` field. The FAB can be mounted without ever
    // triggering a reload (e.g. user has no devices), in which case the
    // old lazy form was never read and dispose() would throw
    // LateInitializationError.
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  // ── Drag handlers ────────────────────────────────────────────────────────
  //
  // The FAB drops **wherever the user releases it** within a safe area:
  // never above the header, never outside the viewport, never behind
  // the dock. Position is intentionally NOT persisted — every launch
  // starts fresh.

  void _onPanStart(DragStartDetails d) {
    _dragStartRight = _right;
    _dragStartBottom = _bottom;
    _dragStartGlobal = d.globalPosition;
    setState(() {
      _dragging = true;
      _pressed = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final delta = d.globalPosition - _dragStartGlobal;
    final media = MediaQuery.of(context);
    final size = media.size;

    // Clamp so the FAB:
    //   • is at least [_edgeMargin] from each viewport edge,
    //   • never overlaps the page chrome — its top edge stays at least
    //     [_edgeMargin] below the filter bar bottom (= header + filter
    //     bar height from the top of the screen). This ensures the FAB
    //     can never float on top of the title or chip rows.
    final minRight = _edgeMargin;
    final maxRight = (size.width - _collapsedWidth - _edgeMargin)
        .clamp(minRight, double.infinity);
    final minBottom = _edgeMargin;
    final maxBottom = (size.height -
            _fabHeight -
            _headerHeight -
            _filterBarHeight -
            _edgeMargin -
            media.padding.bottom)
        .clamp(minBottom, double.infinity);

    setState(() {
      _right = (_dragStartRight - delta.dx).clamp(minRight, maxRight);
      _bottom = (_dragStartBottom - delta.dy).clamp(minBottom, maxBottom);
    });
  }

  Future<void> _onPanEnd(DragEndDetails d) async {
    setState(() {
      _dragging = false;
      _pressed = false;
    });
    // Stay where the user dropped. Do NOT persist — see initState
    // for the rationale.
  }

  /// Dispatch a tap to the right action. We need this on the *outer*
  /// GestureDetector (alongside the pan handlers) because a nested
  /// GestureDetector around each action icon would out-compete the pan
  /// recognizer in the gesture arena and silently break dragging.
  ///
  /// For a single-action FAB the whole surface triggers that one action.
  /// For multi-action FABs (e.g. Flutter = Hot reload + Hot restart) we
  /// pick the action by horizontal position — each action owns a strip
  /// of width [_actionWidth] with [_actionGap] between strips.
  void _onTapUp(TapUpDetails details) {
    final actions = _actionsFor();
    if (actions.isEmpty) return;

    if (actions.length == 1) {
      actions[0].onTap();
      return;
    }
    final localX = details.localPosition.dx;
    for (var i = 0; i < actions.length; i++) {
      final start = i * (_actionWidth + _actionGap);
      final end = start + _actionWidth;
      if (localX >= start && localX <= end) {
        actions[i].onTap();
        return;
      }
    }
  }

  // ── Action discovery ─────────────────────────────────────────────────────

  /// Returns the list of available reload actions for the currently
  /// connected devices (in a stable, predictable order: hot reload before
  /// hot restart). Mirrors the per-platform IDE hotkeys:
  ///
  ///   Flutter → Hot Reload + Hot Restart
  ///   RN      → Reload Metro
  ///   Android → Rebuild
  ///   Mixed   → single universal "Reload app"
  List<_FabAction> _actionsFor() {
    if (widget.devices.isEmpty) return const [];
    bool isFlutter(String p) => p.toLowerCase() == 'flutter';
    bool isRN(String p) {
      final lo = p.toLowerCase();
      return lo == 'reactnative' || lo == 'react_native' || lo == 'rn';
    }
    bool isAndroid(String p) => p.toLowerCase() == 'android';

    final hasFlutter = widget.devices.any((d) => isFlutter(d.platform));
    final hasRN = widget.devices.any((d) => isRN(d.platform));
    final hasAndroid = widget.devices.any((d) => isAndroid(d.platform));
    final platforms = (hasFlutter ? 1 : 0) +
        (hasRN ? 1 : 0) +
        (hasAndroid ? 1 : 0);

    if (platforms > 1) {
      // Mixed: universal reload only.
      return [
        _FabAction(
          icon: LucideIcons.zap,
          tooltip: S.of(context).reloadApp,
          spinning: widget.reloading,
          onTap: widget.onReload,
        ),
      ];
    }
    if (hasFlutter) {
      return [
        _FabAction(
          icon: LucideIcons.zap,
          tooltip: S.of(context).reloadAppHotReload,
          spinning: widget.reloading,
          onTap: widget.onReload,
        ),
        _FabAction(
          icon: LucideIcons.refreshCcw,
          tooltip: S.of(context).reloadAppHotRestart,
          spinning: widget.hotRestarting,
          onTap: widget.onHotRestart,
        ),
      ];
    }
    if (hasRN) {
      return [
        _FabAction(
          icon: LucideIcons.rocket,
          tooltip: S.of(context).reloadAppMetro,
          spinning: widget.reloading,
          onTap: widget.onReload,
        ),
      ];
    }
    if (hasAndroid) {
      // Android: Activity.recreate() is a runtime state reset — NOT a real
      // "rebuild" of the APK. We label and icon this the same as Flutter's
      // "Hot restart" so the UI reflects what actually happens (full state
      // reset, no code recompile). For the *real* Android rebuild the
      // developer has to run gradle assembleDebug + reinstall — which is
      // outside what a runtime SDK can trigger.
      return [
        _FabAction(
          icon: LucideIcons.refreshCcw,
          tooltip: S.of(context).reloadAppHotRestart,
          spinning: widget.reloading,
          onTap: widget.onReload,
        ),
      ];
    }
    return [
      _FabAction(
        icon: LucideIcons.zap,
        tooltip: S.of(context).reloadApp,
        spinning: widget.reloading,
        onTap: widget.onReload,
      ),
    ];
  }

  // ── Sizing ──────────────────────────────────────────────────────────────

  double _currentFabWidth() {
    final actions = _actionsFor();
    if (actions.isEmpty) return _collapsedWidth;
    // When multiple actions exist, the FAB expands on hover to show them.
    // For single-action platforms it stays the same size (no expand needed).
    if (actions.length > 1 && _hovered) {
      return _actionWidth * actions.length +
          _actionGap * (actions.length - 1);
    }
    return _collapsedWidth;
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actions = _actionsFor();

    // When the FAB has multiple actions available (Flutter = Hot Reload +
    // Hot Restart) the *width* animates from 44 → 80 on hover — but the
    // *Row* underneath still tries to lay out every action. With a 44px
    // container and an 80px-tall row of two 38px icons + 4px gap, the
    // second one overflows invisibly until the user hovers. Drop it
    // until the pill actually expands.
    final visibleActions = (actions.length > 1 && !_hovered)
        ? actions.take(1).toList()
        : actions;

    final fabWidth = _currentFabWidth();
    final disabled = actions.isEmpty;

    // Shared spinner — whichever reload is in flight, the shared
    // `_spinCtrl` ticks. Toggled once per build so the multi-action case
    // doesn't fight itself (the old per-icon helper would reset the
    // controller while the other icon was still spinning).
    _syncSpinner(visibleActions.any((a) => a.spinning));

    // Clamp in build() too, not just `_onPanUpdate` — if the user
    // resizes the window smaller than the dragged position, the
    // Positioned offsets need to be re-clamped to the new viewport or
    // the FAB escapes the screen.
    final media = MediaQuery.of(context);
    final size = media.size;
    final maxRight = (size.width - fabWidth - _edgeMargin)
        .clamp(_edgeMargin, double.infinity);
    final maxBottom = (size.height -
            _fabHeight -
            _headerHeight -
            _filterBarHeight -
            _edgeMargin -
            media.padding.bottom)
        .clamp(_edgeMargin, double.infinity);
    final clampedRight = _right.clamp(_edgeMargin, maxRight);
    final clampedBottom = _bottom.clamp(_edgeMargin, maxBottom);

    return Positioned(
      // Plain Positioned (no AnimatedPositioned) so the FAB tracks the
      // cursor instantly during drag. Any animation here would lag behind
      // the pointer and feel sticky.
      right: clampedRight,
      bottom: clampedBottom,
      child: AnimatedScale(
        // Press feedback + slight grow while dragging.
        scale: _pressed ? 0.94 : (_dragging ? 1.04 : 1.0),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          onEnter: (_) {
            if (!_dragging) setState(() => _hovered = true);
          },
          onExit: (_) {
            if (!_dragging) setState(() => _hovered = false);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            // Single tap dispatch lives on the OUTER detector too — that way
            // the inner per-icon GestureDetectors can't out-compete the
            // pan recognizer in the gesture arena (which is what blocked
            // the drag from working). Tap vs. drag is decided by Flutter's
            // built-in slop: a quick release → onTapUp, a movement past
            // the touch slop → onPanStart.
            onTapUp: _onTapUp,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: _fabHeight,
              width: fabWidth,
              decoration: _decoration(isDark, disabled, _hovered || _dragging),
              child: Stack(
                children: [
                  // Inner top highlight — a 1px-tall gradient line simulating
                  // the refraction on a glass surface's top edge. Cheaper and
                  // crisper than a true inset shadow.
                  Positioned(
                    top: 0,
                    left: 10,
                    right: 10,
                    child: IgnorePointer(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              (isDark ? Colors.white : Colors.white)
                                  .withValues(alpha: isDark ? 0.35 : 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Action row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (actions.isEmpty)
                        _fabIcon(
                          icon: LucideIcons.zap,
                          tooltip: S.of(context).reloadAppNoDevices,
                          spinning: false,
                          disabled: true,
                          isDark: isDark,
                        )
                      else
                        for (int i = 0; i < visibleActions.length; i++) ...[
                          if (i > 0) const SizedBox(width: _actionGap),
                          _fabIcon(
                            icon: visibleActions[i].icon,
                            tooltip: visibleActions[i].tooltip,
                            spinning: visibleActions[i].spinning,
                            disabled: false,
                            isDark: isDark,
                          ),
                        ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Frosted-glass decoration. Three layers (top to bottom):
  ///   1. Outer drop shadow — tinted to the background, never pure black,
  ///      no neon glow.
  ///   2. Background fill — high-alpha neutral (260 of 255 alpha) so the
  ///      surface beneath shows through subtly without backdrop-blur cost.
  ///      For the *true* frosted look we wrap it in BackdropFilter so it
  ///      actually blurs what's behind when there's content (e.g. event
  ///      rows); we drop BackdropFilter when content is empty (no perf
  ///      cost on idle empty states).
  ///   3. 1px border — translucent white in dark, translucent black in light.
  BoxDecoration _decoration(bool isDark, bool disabled, bool emphasised) {
    final surfaceColor = isDark
        ? const Color(0xFF1B2129)
        : const Color(0xFFFDFEFF);
    return BoxDecoration(
      color: disabled
          ? surfaceColor.withValues(alpha: 0.72)
          : surfaceColor.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.06),
        width: 1,
      ),
      boxShadow: [
        // Drop shadow, tinted to background.
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.55)
              : Colors.black.withValues(alpha: 0.18),
          blurRadius: disabled ? 16 : 22,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
        // Slight forward "lift" when hovered/dragged — felt, not loud.
        if (emphasised)
          BoxShadow(
            color: ColorTokens.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
      ],
    );
  }

  /// One icon "slot" inside the pill. Spins while its action is in flight.
  ///
  /// IMPORTANT: this widget is purely visual. It does **not** wrap its child
  /// in a [GestureDetector] — taps are dispatched by the outer FAB-level
  /// handler via [_onTapUp] using horizontal position. Adding an inner
  /// `GestureDetector(onTap: ...)` here would out-compete the outer pan
  /// recognizer in the gesture arena and silently break dragging.
  Widget _fabIcon({
    required IconData icon,
    required String tooltip,
    required bool spinning,
    required bool disabled,
    required bool isDark,
  }) {
    final color = disabled
        ? (isDark ? Colors.grey[700]! : Colors.grey[400]!)
        : (isDark ? Colors.grey[200]! : Colors.grey[800]!);

    final iconWidget = spinning
        ? RotationTransition(
            // Always drive from the shared `_spinCtrl` — whether it's
            // actually animating or not is decided by `_syncSpinner()` in
            // `build()`, not per-icon here.
            turns: _spinCtrl,
            child: Icon(icon, size: 17, color: color),
          )
        : Icon(icon, size: 17, color: color);

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: _actionWidth,
        height: _fabHeight,
        child: Center(child: iconWidget),
      ),
    );
  }

  // Spinner — one controller, repeats when in flight. Cheap because every
  // icon uses the same controller (visual only; not part of any layout
  // pass that affects the parent). Initialised in initState() (not as a
  // `late final` with an initializer) so dispose() never trips over an
  // uninitialised controller — the FAB can be mounted without ever
  // triggering a reload, in which case the old lazy form threw
  // LateInitializationError when the widget tree was torn down.
  late AnimationController _spinCtrl;

  /// Single source of truth for the shared spinner: any action currently
  /// in flight → repeat; otherwise → stop. Called once per build so the
  /// multi-action case doesn't fight itself (the old `_spinController(bool)`
  /// helper toggled start/stop per icon and the second action would reset
  /// the controller while the first was still spinning).
  void _syncSpinner(bool shouldSpin) {
    if (shouldSpin && !_spinCtrl.isAnimating) {
      _spinCtrl.repeat();
    } else if (!shouldSpin && _spinCtrl.isAnimating) {
      _spinCtrl.stop();
    }
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }
}

class _FabAction {
  final IconData icon;
  final String tooltip;
  final bool spinning;
  final VoidCallback onTap;

  const _FabAction({
    required this.icon,
    required this.tooltip,
    required this.spinning,
    required this.onTap,
  });
}
///
/// Same shape and 28x28 size as every other [_IconBtn] in the action group,
/// same hover/active visuals, info via tooltip on hover — just with
/// a spinning icon while the reload is in flight.
///
/// The icon + tooltip + callback are passed in from the caller; this widget
/// only handles the visual state (hover / spin / disabled).
class _ReloadAppBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool reloading;
  final bool disabled;
  final VoidCallback onTap;

  const _ReloadAppBtn({
    required this.icon,
    required this.tooltip,
    required this.reloading,
    required this.disabled,
    required this.onTap,
  });

  @override
  State<_ReloadAppBtn> createState() => _ReloadAppBtnState();
}

class _ReloadAppBtnState extends State<_ReloadAppBtn>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.reloading) _spinCtrl.repeat();
  }

  @override
  void didUpdateWidget(covariant _ReloadAppBtn old) {
    super.didUpdateWidget(old);
    if (widget.reloading && !_spinCtrl.isAnimating) {
      _spinCtrl.repeat();
    } else if (!widget.reloading && _spinCtrl.isAnimating) {
      _spinCtrl.reset();
    }
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = widget.reloading || _hovered;

    // Match `_IconBtn`'s color logic exactly — keeps the action group visually
    // coherent so this button doesn't stand out as "the odd one".
    Color iconColor;
    Color bgColor;
    if (widget.disabled) {
      iconColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;
      bgColor = Colors.transparent;
    } else if (active) {
      iconColor = ColorTokens.primary;
      bgColor = ColorTokens.primary.withValues(alpha: 0.15);
    } else if (_hovered) {
      iconColor = isDark ? Colors.grey[300]! : Colors.grey[700]!;
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06);
    } else {
      iconColor = isDark ? Colors.grey[500]! : Colors.grey[500]!;
      bgColor = Colors.transparent;
    }

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.disabled ? null : widget.onTap,
        child: MouseRegion(
          cursor: widget.disabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: RotationTransition(
              turns: _spinCtrl,
              child: Icon(widget.icon, size: 14, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

/// Decides which reload buttons to render in the action group based on the
/// connected devices' platforms.
///
/// Mirrors what each SDK's IDE offers:
///   • **Flutter only**           → Hot Reload (`zap`) + Hot Restart (`refreshCcw`)
///   • **React Native only**      → Reload Metro (`rocket`)
///   • **Native Android only**    → Rebuild (`hammer`)
///   • **Mixed platforms**        → single universal Reload (`zap`)
///   • **No devices**             → no buttons
///
/// Each button is icon-only; tooltips appear on hover, like every other
/// button in this action group. Returns a list of `[btn, gap, btn, gap, ...]`
/// ready to splice into the action group's child list.
// (removed — replaced by _DraggableReloadFab)

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

// ═══════════════════════════════════════════════
// Detail Panel
// ═══════════════════════════════════════════════

class _EventDetailPanel extends StatefulWidget {
  final UnifiedEvent event;
  final VoidCallback onClose;

  const _EventDetailPanel({super.key, required this.event, required this.onClose});

  @override
  State<_EventDetailPanel> createState() => _EventDetailPanelState();
}

class _EventDetailPanelState extends State<_EventDetailPanel> {
  int _currentTabIndex = 0;
  bool _currentJsonMode = false;
  final _contentKey = GlobalKey();

  Future<void> _captureAndSave(Widget screenshotWidget,
      {String? fileName}) async {
    try {
      // Show capture flash animation
      _showCaptureFlash();

      final overlayKey = GlobalKey();
      final theme = Theme.of(context);

      late OverlayEntry overlayEntry;
      overlayEntry = OverlayEntry(
        builder: (_) => Positioned(
          left: -10000,
          top: 0,
          child: RepaintBoundary(
            key: overlayKey,
            child: Theme(
              data: theme,
              child: Material(
                child: SizedBox(
                  width: 600,
                  child: screenshotWidget,
                ),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(overlayEntry);
      await Future.delayed(const Duration(milliseconds: 600));

      final boundary = overlayKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        overlayEntry.remove();
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      overlayEntry.remove();

      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      final baseName = (fileName == null || fileName.isEmpty)
          ? 'dcmt_${DateTime.now().millisecondsSinceEpoch}'
          : fileName;
      final withExt =
          baseName.endsWith('.png') ? baseName : '$baseName.png';

      final location = await getSaveLocation(
        suggestedName: withExt,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'PNG Image', extensions: ['png']),
        ],
      );

      if (location == null) return;

      // Force saved file's name to withExt regardless of what OS returns.
      final savedPath = _ensureFilename(location.path, withExt);
      final xfile = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: withExt,
        length: pngBytes.lengthInBytes,
      );
      await xfile.saveTo(savedPath);

      if (mounted) showScreenshotSavedToast(context, filePath: savedPath);
    } catch (e) {
      if (mounted) _showErrorToast('$e');
    }
  }

  String _ensureFilename(String path, String desiredName) {
    final sep = path.contains(r'\') ? r'\' : '/';
    final last = path.lastIndexOf(sep);
    if (last == -1) return '$path$sep$desiredName';
    return '${path.substring(0, last + 1)}$desiredName';
  }

  void _showCaptureFlash() {
    final overlay = Overlay.of(context);
    late OverlayEntry flashEntry;
    flashEntry = OverlayEntry(
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.35, end: 0.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        onEnd: () {
          if (flashEntry.mounted) flashEntry.remove();
        },
        builder: (context, value, _) => IgnorePointer(
          child: Container(
            color: Colors.white.withValues(alpha: value),
          ),
        ),
      ),
    );
    overlay.insert(flashEntry);
  }

  void _showSavedToast(String path) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 32,
        left: 0,
        right: 0,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Transform.scale(
                  scale: 0.92 + 0.08 * value,
                  child: child,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF131A24)
                      : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    // Ambient shadow
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                    // Subtle glow
                    if (isDark)
                      BoxShadow(
                        color: ColorTokens.success.withValues(alpha: 0.08),
                        blurRadius: 40,
                        spreadRadius: -4,
                      ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top accent bar
                    Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ColorTokens.success.withValues(alpha: 0.0),
                            ColorTokens.success,
                            ColorTokens.success.withValues(alpha: 0.0),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      child: Row(
                        children: [
                          // Success icon with glow
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ColorTokens.success.withValues(alpha: 0.2),
                                  ColorTokens.success.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: ColorTokens.success
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.checkCheck,
                              size: 18,
                              color: ColorTokens.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextComponent(
                                  S.of(context).screenshotSaved,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? ColorTokens.lightBackground
                                        : const Color(0xFF1E293B),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                TextComponent(
                                  path.split('/').last,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: AppConstants.monoFontFamily,
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Show in Finder button
                          _PressableButton(
                            onTap: () {
                              entry.remove();
                              Process.run('open', ['-R', path]);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          const Color(0xFF1A2332),
                                          const Color(0xFF1E2A3A),
                                        ]
                                      : [
                                          const Color(0xFFF0F4F8),
                                          const Color(0xFFE8EDF2),
                                        ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.folderOpen,
                                    size: 13,
                                    color: isDark
                                        ? ColorTokens.lightBackground
                                        : const Color(0xFF374151),
                                  ),
                                  const SizedBox(width: 6),
                                  TextComponent(
                                    S.of(context).reveal,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? ColorTokens.lightBackground
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Close button
                          _PressableButton(
                            onTap: () => entry.remove(),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.black.withValues(alpha: 0.04),
                              ),
                              child: Icon(LucideIcons.x,
                                  size: 13,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) entry.remove();
    });
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TextComponent('Screenshot failed: $message'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _takeFullScreenshot() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final widget_ = _buildScreenshotWidget(theme, isDark);
    final fileName = _buildEventScreenshotName('_full');
    await _captureAndSave(widget_, fileName: fileName);
  }

  /// Builds a descriptive file name for event screenshots:
  /// `<type>_<keyOrTitle>_<isoTimestamp>_<suffix>.png`
  /// Falls back gracefully when key metadata is missing.
  /// Note: appName is intentionally NOT included — screenshots may be
  /// shared with clients and the internal app identifier must not leak.
  String _buildEventScreenshotName(String suffix) {
    final event = widget.event;
    final type = event.type.name;

    // Pick a meaningful subject: storage key, network URL path, log tag, etc.
    String subject = event.title;
    if (event.rawData is StorageEntry) {
      subject = (event.rawData as StorageEntry).key;
    } else if (event.rawData is NetworkEntry) {
      final url = (event.rawData as NetworkEntry).url;
      try {
        subject = Uri.parse(url).path.isEmpty ? url : Uri.parse(url).path;
      } catch (_) {
        subject = url;
      }
    } else if (event.rawData is LogEntry) {
      final tag = (event.rawData as LogEntry).tag;
      if (tag != null && tag.isNotEmpty) subject = tag;
    } else if (event.rawData is StateChange) {
      final sc = event.rawData as StateChange;
      subject = sc.actionName.isNotEmpty
          ? sc.actionName
          : sc.stateManagerType;
    }

    return buildRichScreenshotName(
      type: type,
      subject: subject,
      suffix: suffix,
    );
  }

  Future<void> _takeTabScreenshot() async {
    await _captureLiveContent();
  }

  /// Captures the currently visible content (with user's expand/collapse state).
  Future<void> _captureLiveContent() async {
    try {
      _showCaptureFlash();

      final boundary = _contentKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final fileName =
          'dcmt_${DateTime.now().millisecondsSinceEpoch}.png';
      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'PNG Image', extensions: ['png']),
        ],
      );
      if (location == null) return;

      final file = File(location.path);
      await file.writeAsBytes(pngBytes);
      if (mounted) _showSavedToast(file.path);
    } catch (e) {
      if (mounted) _showErrorToast('$e');
    }
  }

  /// Builds the full detail widget for screenshot (no scroll constraints).
  Widget _buildScreenshotWidget(ThemeData theme, bool isDark) {
    final event = widget.event;
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(event.timestamp),
    );

    Color typeColor;
    IconData typeIcon;
    String typeLabel;
    switch (event.type) {
      case EventType.log:
        typeColor = ColorTokens.logInfo;
        typeIcon = LucideIcons.terminal;
        typeLabel = S.of(context).logDetail;
        break;
      case EventType.network:
        typeColor = ColorTokens.success;
        typeIcon = LucideIcons.globe;
        typeLabel = S.of(context).networkDetail;
        break;
      case EventType.state:
        typeColor = ColorTokens.secondary;
        typeIcon = LucideIcons.layers;
        typeLabel = S.of(context).stateDetail;
        break;
      case EventType.storage:
        typeColor = ColorTokens.warning;
        typeIcon = LucideIcons.database;
        typeLabel = S.of(context).storageDetail;
        break;
      case EventType.display:
        typeColor = const Color(0xFF9B59B6);
        typeIcon = LucideIcons.monitor;
        typeLabel = S.of(context).displayDetail;
        break;
      case EventType.asyncOp:
        typeColor = const Color(0xFFE67E22);
        typeIcon = LucideIcons.zap;
        typeLabel = S.of(context).asyncOperation;
        break;
      case EventType.error:
        typeColor = Colors.red;
        typeIcon = LucideIcons.alertTriangle;
        typeLabel = S.of(context).errorDetail;
        break;
    }

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? ColorTokens.darkBackground : Colors.white,
            ),
            child: Row(
              children: [
                Icon(typeIcon, size: 14, color: typeColor),
                const SizedBox(width: 8),
                TextComponent(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
                const Spacer(),
                TextComponent(
                  time,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildScreenshotContent(isDark),
        ],
      ),
    );
  }

  /// Content for screenshot — no SingleChildScrollView, no Expanded.
  /// Tabbed views are rendered as stacked sections.
  Widget _buildScreenshotContent(bool isDark) {
    switch (widget.event.type) {
      case EventType.log:
        if (widget.event.rawData is LogEntry) {
          return _logScreenshot(widget.event.rawData as LogEntry, isDark);
        }
        return _fallbackScreenshot(widget.event, isDark);
      case EventType.network:
        if (widget.event.rawData is NetworkEntry) {
          return _networkScreenshot(
              widget.event.rawData as NetworkEntry, isDark);
        }
        return _fallbackScreenshot(widget.event, isDark);
      case EventType.state:
        if (widget.event.rawData is StateChange) {
          return _stateScreenshot(
              widget.event.rawData as StateChange, isDark);
        }
        return _fallbackScreenshot(widget.event, isDark);
      case EventType.storage:
        if (widget.event.rawData is StorageEntry) {
          return _storageScreenshot(
              widget.event.rawData as StorageEntry, isDark);
        }
        return _fallbackScreenshot(widget.event, isDark);
      case EventType.display:
      case EventType.asyncOp:
      case EventType.error:
        return _fallbackScreenshot(widget.event, isDark);
    }
  }

  Widget _logScreenshot(LogEntry entry, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            LogLevelBadge(level: entry.level.name),
            if (entry.tag != null) ...[
              const SizedBox(width: 8),
              _TagChip(entry.tag!),
            ],
          ]),
          const SizedBox(height: 16),
          const _SectionLabel('Message'),
          const SizedBox(height: 6),
          _CodeBlock(text: entry.message, isDark: isDark),
          if (entry.metadata != null && entry.metadata!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionLabel('Metadata'),
            const SizedBox(height: 6),
            JsonViewer(data: entry.metadata, initiallyExpanded: true),
          ],
          if (entry.stackTrace != null) ...[
            const SizedBox(height: 16),
            const _SectionLabel('Stack Trace'),
            const SizedBox(height: 6),
            _ErrorBlock(text: entry.stackTrace!, isDark: isDark),
          ],
        ],
      ),
    );
  }

  Widget _networkScreenshot(NetworkEntry entry, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // URL bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: Row(
            children: [
              HttpMethodBadge(method: entry.method),
              const SizedBox(width: 8),
              if (entry.isComplete) ...[
                StatusBadge(statusCode: entry.statusCode),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextComponent(
                  entry.url,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    color:
                        isDark ? ColorTokens.lightBackground : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Timing summary
        if (entry.duration != null)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _TimingBar(duration: entry.duration!),
          ),
        const Divider(height: 1),
        // Headers
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('REQUEST HEADERS'),
              const SizedBox(height: 8),
              _HeaderTable(headers: entry.requestHeaders, isScreenshot: true),
              const SizedBox(height: 20),
              const _SectionLabel('RESPONSE HEADERS'),
              const SizedBox(height: 8),
              _HeaderTable(headers: entry.responseHeaders, isScreenshot: true),
            ],
          ),
        ),
        const Divider(height: 1),
        // Request body
        if (entry.requestBody != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('REQUEST BODY'),
                const SizedBox(height: 8),
                if (_currentJsonMode ||
                    !(entry.requestBody is Map || entry.requestBody is List))
                  JsonPrettyViewer(data: entry.requestBody)
                else
                  JsonViewer(
                      data: entry.requestBody, initiallyExpanded: true),
              ],
            ),
          ),
        if (entry.requestBody != null) const Divider(height: 1),
        // Response body
        if (entry.responseBody != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('RESPONSE BODY'),
                const SizedBox(height: 8),
                if (_currentJsonMode ||
                    !(entry.responseBody is Map || entry.responseBody is List))
                  JsonPrettyViewer(data: entry.responseBody)
                else
                  JsonViewer(
                      data: entry.responseBody, initiallyExpanded: true),
              ],
            ),
          ),
        if (entry.responseBody != null) const Divider(height: 1),
        // Timing details
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('TIMING'),
              const SizedBox(height: 8),
              _InfoRow(
                'Start Time',
                DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
                  DateTime.fromMillisecondsSinceEpoch(entry.startTime),
                ),
              ),
              if (entry.endTime != null)
                _InfoRow(
                  'End Time',
                  DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
                    DateTime.fromMillisecondsSinceEpoch(entry.endTime!),
                  ),
                ),
              if (entry.duration != null)
                _InfoRow('Duration', formatDuration(entry.duration!)),
              if (entry.error != null) ...[
                const SizedBox(height: 12),
                const _SectionLabel('Error'),
                const SizedBox(height: 6),
                _ErrorBlock(text: entry.error!, isDark: isDark),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _stateScreenshot(StateChange entry, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              _TagChip(entry.stateManagerType,
                  color: ColorTokens.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: TextComponent(
                  entry.actionName,
                  style: const TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Diff
        if (entry.diff.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('DIFF'),
                const SizedBox(height: 8),
                ...entry.diff.map((d) => _DiffRow(diff: d)),
              ],
            ),
          ),
        if (entry.diff.isNotEmpty) const Divider(height: 1),
        // Previous state
        if (entry.previousState.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('PREVIOUS STATE'),
                const SizedBox(height: 8),
                JsonViewer(
                    data: entry.previousState, initiallyExpanded: true),
              ],
            ),
          ),
        if (entry.previousState.isNotEmpty) const Divider(height: 1),
        // Next state
        if (entry.nextState.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('NEXT STATE'),
                const SizedBox(height: 8),
                JsonViewer(
                    data: entry.nextState, initiallyExpanded: true),
              ],
            ),
          ),
      ],
    );
  }

  Widget _storageScreenshot(StorageEntry entry, bool isDark) {
    // Operation color matches the in-app panel: emerald/blue/red/amber.
    Color opColorFor(StorageEntry e) {
      switch (e.operation.toLowerCase()) {
        case 'write':
          return const Color(0xFF34D399);
        case 'read':
          return const Color(0xFF60A5FA);
        case 'delete':
        case 'clear':
          return const Color(0xFFF87171);
        default:
          return const Color(0xFFFBBF24);
      }
    }

    // Resolve platform from connected devices for code-mode export
    final devices = ProviderScope.containerOf(context, listen: false)
        .read(connectedDevicesProvider);
    final platform = devices
            .where((d) => d.deviceId == entry.deviceId)
            .map((d) => d.platform)
            .firstOrNull ??
        'react_native';
    final codeLang = CodeGenerator.langForPlatform(platform);
    final codeLabel = CodeGenerator.labelFor(codeLang);

    // Respect 3 view modes from global provider
    final mode = ProviderScope.containerOf(context, listen: false)
        .read(bodyViewModeProvider);

    // Design tokens
    final labelColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    // ── Helpers ─────────────────────────────────────────────
    String formatShape() {
      final v = entry.value;
      if (v == null) return 'null';
      if (v is Map) return 'Map · ${v.length} ${v.length == 1 ? "key" : "keys"}';
      if (v is List) return 'List · ${v.length} ${v.length == 1 ? "item" : "items"}';
      if (v is String) {
        if (v.isEmpty) return 'String · empty';
        final t = v.trim();
        if ((t.startsWith('{') && t.endsWith('}')) ||
            (t.startsWith('[') && t.endsWith(']'))) {
          return 'String · JSON-shaped';
        }
        return 'String';
      }
      return v.runtimeType.toString();
    }

    String formatSize() {
      final raw = entry.value is String
          ? entry.value as String
          : const JsonEncoder.withIndent('  ').convert(entry.value);
      return AppConstants.formatBytes(raw.length);
    }

    dynamic parseJson() {
      final v = entry.value;
      if (v is! String) return null;
      try {
        final p = jsonDecode(v);
        if (p is Map || p is List) return p;
      } catch (_) {}
      return null;
    }

    dynamic displayValue() {
      final v = entry.value;
      if (v is Map || v is List) return v;
      return parseJson() ?? v;
    }

    bool isJsonLike() {
      final v = entry.value;
      if (v is Map || v is List) return true;
      return parseJson() != null;
    }

    Widget buildValueWidget() {
      if (!isJsonLike()) {
        return _CodeBlock(text: '${entry.value}', isDark: isDark);
      }
      final value = displayValue();
      return switch (mode) {
        BodyViewMode.tree =>
          JsonViewer(data: value, initiallyExpanded: true),
        BodyViewMode.json => JsonPrettyViewer(data: value),
        BodyViewMode.code => CodeViewer(
            generated: CodeGenerator.generate(value, codeLang),
            lang: codeLang,
            languageLabel: codeLabel,
          ),
      };
    }

    // Match the in-app metadata bento grid (2x2: SHAPE/SIZE on row 1,
    // DEVICE/CAPTURED on row 2). Each cell has uppercase label + value.
    final monoPrimary = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 13,
      height: 1.5,
      color: isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A),
    );
    final monoSecondary = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 11,
      height: 1.5,
      color: labelColor,
    );
    final metaLabelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: labelColor,
    );

    Widget metaCell(String label, String value, TextStyle valueStyle,
            {bool monospace = false}) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextComponent(label, style: metaLabelStyle),
            const SizedBox(height: 4),
            TextComponent(
              value,
              style: monospace
                  ? valueStyle.copyWith(fontFamily: AppConstants.monoFontFamily)
                  : valueStyle,
            ),
          ],
        );

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Badges (mirror _StorageDetailRedesign header row) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _OpBadge(label: entry.operation, color: opColorFor(entry)),
                const SizedBox(width: 8),
                _TypeBadge(label: entry.storageType.name),
              ],
            ),
          ),
          // ── Metadata (matches the in-app bento grid) ──────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextComponent('METADATA', style: metaLabelStyle),
                const SizedBox(height: 10),
                // Row 1: SHAPE / SIZE
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: metaCell('SHAPE', formatShape(), monoPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: metaCell('SIZE', formatSize(), monoPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Row 2: DEVICE / CAPTURED
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: metaCell(
                          'DEVICE', entry.deviceId, monoSecondary,
                          monospace: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: metaCell(
                        'CAPTURED',
                        DateFormat('HH:mm:ss.SSS').format(
                          DateTime.fromMillisecondsSinceEpoch(
                              entry.timestamp),
                        ),
                        monoPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Divider ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Container(height: 1, color: dividerColor),
          ),
          // ── Key ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('Key'),
                const SizedBox(height: 6),
                _CodeBlock(text: entry.key, isDark: isDark),
              ],
            ),
          ),
          // ── Value (3 view modes when JSON-like) ──────────────
          if (entry.value != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Value'),
                  const SizedBox(height: 6),
                  buildValueWidget(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fallbackScreenshot(UnifiedEvent event, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Title'),
          const SizedBox(height: 6),
          _CodeBlock(text: event.title, isDark: isDark),
          const SizedBox(height: 16),
          const _SectionLabel('Details'),
          const SizedBox(height: 6),
          _CodeBlock(text: event.subtitle, isDark: isDark),
          if (event.rawData != null) ...[
            const SizedBox(height: 16),
            const _SectionLabel('Raw Data'),
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

  /// Builds a tab-only screenshot: header + URL bar (for network) + current tab content only.
  Widget _buildTabScreenshotWidget(
      ThemeData theme, bool isDark, int tabIndex) {
    final event = widget.event;
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(event.timestamp),
    );

    final (typeColor, typeIcon, typeLabel) =
        _DetailHeader._staticTypeDetails(event.type);

    final header = Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
      ),
      child: Row(
        children: [
          Icon(typeIcon, size: 14, color: typeColor),
          const SizedBox(width: 8),
          TextComponent(typeLabel,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: typeColor)),
          const SizedBox(width: 10),
          TextComponent(time,
              style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
                  fontSize: 10,
                  color: Colors.grey[500])),
        ],
      ),
    );

    Widget tabContent;
    if (event.type == EventType.network && event.rawData is NetworkEntry) {
      final entry = event.rawData as NetworkEntry;
      // URL bar always shown
      final urlBar = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? ColorTokens.darkBackground : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: Row(
          children: [
            HttpMethodBadge(method: entry.method),
            const SizedBox(width: 8),
            if (entry.isComplete) ...[
              StatusBadge(statusCode: entry.statusCode),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: TextComponent(entry.url,
                  style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 11,
                      color: isDark
                          ? ColorTokens.lightBackground
                          : Colors.black87)),
            ),
          ],
        ),
      );
      final timingBar = entry.duration != null
          ? Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: _TimingBar(duration: entry.duration!),
            )
          : null;

      final tabNames = ['Headers', 'Request', 'Response', 'Timing'];
      final tabLabel = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: _SectionLabel(tabNames[tabIndex]),
      );

      Widget body;
      switch (tabIndex) {
        case 0: // Headers
          body = Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('Request Headers'),
                const SizedBox(height: 8),
                _HeaderTable(headers: entry.requestHeaders, isScreenshot: true),
                const SizedBox(height: 20),
                const _SectionLabel('Response Headers'),
                const SizedBox(height: 8),
                _HeaderTable(headers: entry.responseHeaders, isScreenshot: true),
              ],
            ),
          );
          break;
        case 1: // Request
          body = _buildBodyScreenshot(
              entry.requestBody, 'Request Body', isDark);
          break;
        case 2: // Response
          body = _buildBodyScreenshot(
              entry.responseBody, 'Response Body', isDark);
          break;
        case 3: // Timing
        default:
          body = Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  'Start Time',
                  DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
                    DateTime.fromMillisecondsSinceEpoch(entry.startTime),
                  ),
                ),
                if (entry.endTime != null)
                  _InfoRow(
                    'End Time',
                    DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
                      DateTime.fromMillisecondsSinceEpoch(entry.endTime!),
                    ),
                  ),
                if (entry.duration != null)
                  _InfoRow('Duration', formatDuration(entry.duration!)),
                if (entry.error != null) ...[
                  const SizedBox(height: 12),
                  const _SectionLabel('Error'),
                  const SizedBox(height: 6),
                  _ErrorBlock(text: entry.error!, isDark: isDark),
                ],
              ],
            ),
          );
          break;
      }

      tabContent = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          urlBar,
          if (timingBar != null) timingBar,
          const Divider(height: 1),
          tabLabel,
          body,
        ],
      );
    } else if (event.type == EventType.state &&
        event.rawData is StateChange) {
      final entry = event.rawData as StateChange;
      final tabNames = ['Diff', 'Previous', 'Next'];
      Widget body;
      switch (tabIndex) {
        case 0:
          body = entry.diff.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: TextComponent('No diff'))
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        entry.diff.map((d) => _DiffRow(diff: d)).toList(),
                  ),
                );
          break;
        case 1:
          body = _buildBodyScreenshot(
              entry.previousState.isEmpty ? null : entry.previousState,
              'Previous State',
              isDark);
          break;
        case 2:
        default:
          body = _buildBodyScreenshot(
              entry.nextState.isEmpty ? null : entry.nextState,
              'Next State',
              isDark);
          break;
      }
      tabContent = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _SectionLabel(tabNames[tabIndex]),
          ),
          body,
        ],
      );
    } else {
      // Log / Storage / Fallback — no tabs, just use full content
      tabContent = _buildScreenshotContent(isDark);
    }

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const Divider(height: 1),
          tabContent,
        ],
      ),
    );
  }

  Widget _buildBodyScreenshot(dynamic body, String label, bool isDark) {
    if (body == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: TextComponent('No $label',
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      );
    }
    dynamic parsed = body;
    if (parsed is String) {
      try {
        parsed = jsonDecode(parsed);
      } catch (_) {}
    }
    final useJson = _currentJsonMode;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label),
          const SizedBox(height: 8),
          if (useJson || !(parsed is Map || parsed is List))
            JsonPrettyViewer(data: parsed)
          else
            JsonViewer(data: parsed, initiallyExpanded: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        children: [
          _DetailHeader(
            event: widget.event,
            onClose: widget.onClose,
            onFullScreenshot: _takeFullScreenshot,
            onTabScreenshot: _takeTabScreenshot,
            hasMultipleTabs: widget.event.type == EventType.network ||
                widget.event.type == EventType.state,
          ),
          const Divider(height: 1),
          Expanded(
            child: RepaintBoundary(
              key: _contentKey,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.event.type) {
      case EventType.log:
        if (widget.event.rawData is LogEntry) {
          return _LogDetail(entry: widget.event.rawData as LogEntry);
        }
        return _FallbackDetail(event: widget.event);
      case EventType.network:
        if (widget.event.rawData is NetworkEntry) {
          return _NetworkDetail(
            entry: widget.event.rawData as NetworkEntry,
            onTabChanged: (i) => _currentTabIndex = i,
            onJsonModeChanged: (v) => _currentJsonMode = v,
          );
        }
        return _FallbackDetail(event: widget.event);
      case EventType.state:
        if (widget.event.rawData is StateChange) {
          return _StateDetail(
            entry: widget.event.rawData as StateChange,
            onTabChanged: (i) => _currentTabIndex = i,
            onJsonModeChanged: (v) => _currentJsonMode = v,
          );
        }
        return _FallbackDetail(event: widget.event);
      case EventType.storage:
        if (widget.event.rawData is StorageEntry) {
          return _StorageDetailRedesign(
            entry: widget.event.rawData as StorageEntry,
          );
        }
        return _FallbackDetail(event: widget.event);
      case EventType.display:
      case EventType.asyncOp:
      case EventType.error:
        return _FallbackDetail(event: widget.event);
    }
  }
}

class _DetailHeader extends ConsumerWidget {
  final UnifiedEvent event;
  final VoidCallback onClose;
  final VoidCallback onFullScreenshot;
  final VoidCallback? onTabScreenshot;
  final bool hasMultipleTabs;

  const _DetailHeader({
    required this.event,
    required this.onClose,
    required this.onFullScreenshot,
    this.onTabScreenshot,
    this.hasMultipleTabs = false,
  });

  static (Color, IconData, String) _staticTypeDetails(EventType type) {
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
      case EventType.display:
        return (
          const Color(0xFF9B59B6),
          LucideIcons.monitor,
          'Display Detail'
        );
      case EventType.asyncOp:
        return (
          const Color(0xFFE67E22),
          LucideIcons.zap,
          'Async Operation'
        );
      case EventType.error:
        return (Colors.red, LucideIcons.alertTriangle, 'Error Detail');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(event.timestamp),
    );

    final devices = ref.watch(connectedDevicesProvider);
    final device =
        devices.where((d) => d.deviceId == event.deviceId).firstOrNull;

    final (typeColor, typeIcon, typeLabel) = _staticTypeDetails(event.type);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
      ),
      child: Row(
        children: [
          Icon(typeIcon, size: 14, color: typeColor),
          const SizedBox(width: 8),
          TextComponent(
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
          TextComponent(
            time,
            style: TextStyle(
              fontFamily: AppConstants.monoFontFamily,
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
          const Spacer(),
          // Screenshot buttons
          Tooltip(
            message: S.of(context).captureFullTooltip,
            waitDuration: const Duration(milliseconds: 400),
            child: _ActionButton(
              icon: LucideIcons.camera,
              label: S.of(context).captureFull,
              onTap: onFullScreenshot,
            ),
          ),
          if (hasMultipleTabs && onTabScreenshot != null) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: S.of(context).captureTabTooltip,
              waitDuration: const Duration(milliseconds: 400),
              child: _ActionButton(
                icon: LucideIcons.scanLine,
                label: S.of(context).captureTab,
                onTap: onTabScreenshot!,
              ),
            ),
          ],
          const SizedBox(width: 6),
          _PressableButton(
            onTap: onClose,
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
        ],
      ),
    );
  }
}

class _PressableButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _PressableButton({required this.onTap, required this.child});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedOpacity(
            opacity: _pressed ? 0.7 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: widget.child,
          ),
        ),
      ),
    );
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
    return _PressableButton(
      onTap: onTap,
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
            TextComponent(
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
    );
  }
}

// ═══════════════════════════════════════════════
// Log Detail
// ═══════════════════════════════════════════════

class _LogDetail extends StatefulWidget {
  final LogEntry entry;

  const _LogDetail({required this.entry});

  @override
  State<_LogDetail> createState() => _LogDetailState();
}

class _LogDetailState extends State<_LogDetail> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Try to extract JSON from the log message.
  /// Returns (prefix, parsedJson) or null if no JSON found.
  static (String, dynamic)? _extractJson(String message) {
    // Try full message first
    try {
      final parsed = jsonDecode(message.trim());
      if (parsed is Map || parsed is List) return ('', parsed);
    } catch (_) {}

    // Find all { or [ positions and try each
    for (var i = 0; i < message.length; i++) {
      final ch = message[i];
      if (ch != '{' && ch != '[') continue;
      final jsonStr = message.substring(i).trim();
      try {
        final parsed = jsonDecode(jsonStr);
        if (parsed is Map || parsed is List) {
          final prefix = message.substring(0, i).trim();
          return (prefix, parsed);
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jsonResult = _extractJson(entry.message);

    return SingleChildScrollView(
      controller: _scrollController,
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
          if (jsonResult != null) ...[
            if (jsonResult.$1.isNotEmpty) ...[
              _CodeBlock(text: jsonResult.$1, isDark: isDark),
              const SizedBox(height: 10),
            ],
            _InlineJsonView(data: jsonResult.$2, label: 'Data'),
          ] else
            _CodeBlock(text: entry.message, isDark: isDark),
          if (entry.metadata != null && entry.metadata!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _InlineJsonView(data: entry.metadata, label: 'Metadata'),
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

class _NetworkDetail extends ConsumerStatefulWidget {
  final NetworkEntry entry;
  final ValueChanged<int>? onTabChanged;
  final ValueChanged<bool>? onJsonModeChanged;

  const _NetworkDetail({
    required this.entry,
    this.onTabChanged,
    this.onJsonModeChanged,
  });

  @override
  ConsumerState<_NetworkDetail> createState() => _NetworkDetailState();
}

class _NetworkDetailState extends ConsumerState<_NetworkDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = _makeController();
    _tabController.addListener(_onTabIndexChange);
  }

  TabController _makeController([int initialIndex = 0]) {
    return TabController(
      length: 4,
      vsync: this,
      animationDuration: ref.read(tabAnimationProvider),
      initialIndex: initialIndex,
    );
  }

  void _onTabIndexChange() {
    if (!_tabController.indexIsChanging) {
      widget.onTabChanged?.call(_tabController.index);
    }
  }

  void _rebuildController() {
    final oldIndex = _tabController.index;
    _tabController.removeListener(_onTabIndexChange);
    _tabController.dispose();
    _tabController = _makeController(oldIndex);
    _tabController.addListener(_onTabIndexChange);
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabIndexChange);
    _tabController.dispose();
    super.dispose();
  }

  NetworkEntry get entry => widget.entry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.listen(tabAnimationProvider, (prev, next) {
      if (prev != next) _rebuildController();
    });

    return Column(
        children: [
          // URL bar + actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? ColorTokens.darkBackground : Colors.white,
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
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ColorTokens.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: ColorTokens.warning.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: ColorTokens.warning,
                              ),
                            ),
                            const SizedBox(width: 5),
                            TextComponent(
                              'In Progress...',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: ColorTokens.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Tooltip(
                        message: entry.url,
                        waitDuration: const Duration(milliseconds: 300),
                        child: TextComponent(
                          entry.url,
                          style: TextStyle(
                            fontFamily: AppConstants.monoFontFamily,
                            fontSize: 11,
                            color: isDark
                                ? ColorTokens.lightBackground
                                : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                      tooltip: 'Copy Path',
                      icon: LucideIcons.route,
                      onTap: () {
                        try {
                          final uri = Uri.parse(entry.url);
                          final path = uri.path.isNotEmpty ? uri.path : entry.url;
                          _copyText(context, path, 'Path');
                        } catch (_) {
                          _copyText(context, entry.url, 'Path');
                        }
                      },
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
                      tooltip: 'Copy request',
                      icon: LucideIcons.upload,
                      onTap: () {
                        final body = entry.requestBody;
                        final text = body is String
                            ? body
                            : (body != null
                                ? const JsonEncoder.withIndent('  ')
                                    .convert(body)
                                : '');
                        _copyText(context, text, 'Request');
                      },
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
          _DetailTabBar(
            controller: _tabController,
            isDark: isDark,
            accentColor: ColorTokens.primary,
            tabs: const ['Headers', 'Request', 'Response', 'Timing'],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LazyTab(
                  controller: _tabController,
                  index: 0,
                  builder: (_) => _HeadersView(entry: entry),
                ),
                LazyTab(
                  controller: _tabController,
                  index: 1,
                  builder: (_) => _BodyView(
                    body: entry.requestBody,
                    label: 'Request Body',
                    deviceId: entry.deviceId,
                    onJsonModeChanged: widget.onJsonModeChanged,
                  ),
                ),
                LazyTab(
                  controller: _tabController,
                  index: 2,
                  builder: (_) => _BodyView(
                    body: entry.responseBody,
                    label: 'Response Body',
                    deviceId: entry.deviceId,
                    onJsonModeChanged: widget.onJsonModeChanged,
                  ),
                ),
                LazyTab(
                  controller: _tabController,
                  index: 3,
                  builder: (_) => _TimingView(entry: entry),
                ),
              ],
            ),
          ),
        ],
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
        TextComponent(
          formatDuration(duration),
          style: TextStyle(
            fontFamily: AppConstants.monoFontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: barColor,
          ),
        ),
      ],
    );
  }
}

class _HeadersView extends StatefulWidget {
  final NetworkEntry entry;

  const _HeadersView({required this.entry});

  @override
  State<_HeadersView> createState() => _HeadersViewState();
}

class _HeadersViewState extends State<_HeadersView> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderSection(
            icon: LucideIcons.arrowUpRight,
            iconColor: ColorTokens.primary,
            title: 'Request Headers',
            count: entry.requestHeaders.length,
            headers: entry.requestHeaders,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _HeaderSection(
            icon: LucideIcons.arrowDownLeft,
            iconColor: ColorTokens.success,
            title: 'Response Headers',
            count: entry.responseHeaders.length,
            headers: entry.responseHeaders,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final Map<String, String> headers;
  final bool isDark;

  const _HeaderSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.headers,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C2128) : ColorTokens.lightSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
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
                Icon(icon, size: 13, color: iconColor),
                const SizedBox(width: 8),
                TextComponent(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextComponent(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Header rows
          if (headers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextComponent('No headers',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            )
          else
            ...headers.entries.toList().asMap().entries.map((entry) {
              final e = entry.value;
              final isLast = entry.key == headers.length - 1;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                child: _HeaderRowCopy(
                  headerKey: e.key,
                  headerValue: e.value,
                  isDark: isDark,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _HeaderTable extends StatelessWidget {
  final Map<String, String> headers;
  final bool isScreenshot;

  const _HeaderTable({required this.headers, this.isScreenshot = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (headers.isEmpty) {
      return TextComponent('No headers',
          style: TextStyle(color: Colors.grey[500], fontSize: 12));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: headers.entries.map((e) {
        if (isScreenshot) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 170,
                  child: TextComponent(e.key,
                      style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF9CDCFE)
                              : const Color(0xFF0451A5))),
                ),
                Expanded(
                  child: TextComponent(e.value,
                      style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFFCE9178)
                              : const Color(0xFFA31515))),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _HeaderRowCopy(
            headerKey: e.key,
            headerValue: e.value,
            isDark: isDark,
          ),
        );
      }).toList(),
    );
  }
}

class _HeaderRowCopy extends StatefulWidget {
  final String headerKey;
  final String headerValue;
  final bool isDark;

  const _HeaderRowCopy({
    required this.headerKey,
    required this.headerValue,
    required this.isDark,
  });

  @override
  State<_HeaderRowCopy> createState() => _HeaderRowCopyState();
}

class _HeaderRowCopyState extends State<_HeaderRowCopy> {
  bool _hovered = false;
  bool _copied = false;
  bool _expanded = false;

  static const _maxCollapsedLines = 4;

  bool get _isLong => '\n'.allMatches(widget.headerValue).length >= _maxCollapsedLines ||
      widget.headerValue.length > 200;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 11,
      color: widget.isDark
          ? const Color(0xFFCE9178)
          : const Color(0xFFA31515),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() { _hovered = false; _copied = false; }),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: TextComponent(
              widget.headerKey,
              style: TextStyle(
                fontFamily: AppConstants.monoFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: widget.isDark
                    ? const Color(0xFF9CDCFE)
                    : const Color(0xFF0451A5),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_expanded)
                  TextComponent(widget.headerValue, style: valueStyle)
                else
                  TextComponent(
                    widget.headerValue,
                    style: valueStyle,
                    maxLines: _maxCollapsedLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (_isLong)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: TextComponent(
                          _expanded ? 'Collapse' : 'Show more',
                          style: TextStyle(
                            fontSize: 10,
                            color: ColorTokens.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_hovered)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: '${widget.headerKey}: ${widget.headerValue}'));
                setState(() => _copied = true);
                showCopiedToast(context);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    _copied ? LucideIcons.check : LucideIcons.copy,
                    size: 12,
                    color: _copied
                        ? ColorTokens.chartGreen
                        : (widget.isDark ? Colors.white38 : Colors.black26),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BodyView extends ConsumerStatefulWidget {
  final dynamic body;
  final String label;
  final String? deviceId;
  final ValueChanged<bool>? onJsonModeChanged;

  const _BodyView({
    required this.body,
    required this.label,
    this.deviceId,
    this.onJsonModeChanged,
  });

  @override
  ConsumerState<_BodyView> createState() => _BodyViewState();
}

class _BodyViewState extends ConsumerState<_BodyView> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewMode = ref.watch(bodyViewModeProvider);

    if (widget.body == null) {
      return EmptyState(icon: LucideIcons.fileText, title: 'No ${widget.label}');
    }

    // Look up the connected device's platform to pick the Code language.
    final devices = ref.watch(connectedDevicesProvider);
    final platform = widget.deviceId == null
        ? 'react_native'
        : devices
                .where((d) => d.deviceId == widget.deviceId)
                .map((d) => d.platform)
                .firstOrNull ??
            'react_native';
    final codeLang = CodeGenerator.langForPlatform(platform);

    return AsyncJsonParser(
      rawData: widget.body,
      builder: (context, parsedBody, isJson) {
        final canToggle = isJson;
        final effectiveMode = canToggle ? viewMode : BodyViewMode.json;

        return Column(
          children: [
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
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
                  _SectionLabel(widget.label),
                  const Spacer(),
                  if (canToggle) ...[
                    ViewModeSegment(
                      label: 'Tree',
                      active: effectiveMode == BodyViewMode.tree,
                      position: ViewSegmentPosition.start,
                      onTap: () {
                        ref
                            .read(bodyViewModeProvider.notifier)
                            .set(BodyViewMode.tree);
                        widget.onJsonModeChanged?.call(false);
                      },
                    ),
                    ViewModeSegment(
                      label: 'JSON',
                      active: effectiveMode == BodyViewMode.json,
                      position: ViewSegmentPosition.middle,
                      onTap: () {
                        ref
                            .read(bodyViewModeProvider.notifier)
                            .set(BodyViewMode.json);
                        widget.onJsonModeChanged?.call(true);
                      },
                    ),
                    ViewModeSegment(
                      label: CodeGenerator.labelFor(codeLang),
                      active: effectiveMode == BodyViewMode.code,
                      position: ViewSegmentPosition.end,
                      onTap: () {
                        ref
                            .read(bodyViewModeProvider.notifier)
                            .set(BodyViewMode.code);
                        widget.onJsonModeChanged?.call(false);
                      },
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildContent(
                  parsedBody: parsedBody,
                  canToggle: canToggle,
                  mode: effectiveMode,
                  codeLang: codeLang,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent({
    required dynamic parsedBody,
    required bool canToggle,
    required BodyViewMode mode,
    required CodeLang codeLang,
  }) {
    if (!canToggle) {
      return JsonPrettyViewer(data: parsedBody);
    }
    return DeferredBuilder(
      key: ValueKey(mode),
      builder: (_) {
        switch (mode) {
          case BodyViewMode.tree:
            return JsonViewer(data: parsedBody, initiallyExpanded: true);
          case BodyViewMode.json:
            return JsonPrettyViewer(data: widget.body);
          case BodyViewMode.code:
            final generated = CodeGenerator.generate(parsedBody, codeLang);
            return SingleChildScrollView(
              child: CodeViewer(
                generated: generated,
                lang: codeLang,
                languageLabel: CodeGenerator.labelFor(codeLang),
              ),
            );
        }
      },
    );
  }
}

/// Inline Tree/JSON toggle for use inside ScrollView (non-tabbed contexts).
class _InlineJsonView extends ConsumerStatefulWidget {
  final dynamic data;
  final String label;

  const _InlineJsonView({required this.data, required this.label});

  @override
  ConsumerState<_InlineJsonView> createState() => _InlineJsonViewState();
}

class _InlineJsonViewState extends ConsumerState<_InlineJsonView> {
  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(bodyViewModeProvider);

    // Inline views don't know the device, so Code mode falls back to TS.
    final codeLang = CodeGenerator.langForPlatform('react_native');

    return AsyncJsonParser(
      rawData: widget.data,
      builder: (context, parsed, isJson) {
        final canToggle = isJson;
        final effectiveMode = canToggle ? viewMode : BodyViewMode.json;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SectionLabel(widget.label),
                const Spacer(),
                if (canToggle) ...[
                  ViewModeSegment(
                    label: 'Tree',
                    active: effectiveMode == BodyViewMode.tree,
                    position: ViewSegmentPosition.start,
                    onTap: () => ref
                        .read(bodyViewModeProvider.notifier)
                        .set(BodyViewMode.tree),
                  ),
                  ViewModeSegment(
                    label: 'JSON',
                    active: effectiveMode == BodyViewMode.json,
                    position: ViewSegmentPosition.middle,
                    onTap: () => ref
                        .read(bodyViewModeProvider.notifier)
                        .set(BodyViewMode.json),
                  ),
                  ViewModeSegment(
                    label: CodeGenerator.labelFor(codeLang),
                    active: effectiveMode == BodyViewMode.code,
                    position: ViewSegmentPosition.end,
                    onTap: () => ref
                        .read(bodyViewModeProvider.notifier)
                        .set(BodyViewMode.code),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            _buildInlineContent(
              parsed: parsed,
              canToggle: canToggle,
              mode: effectiveMode,
              codeLang: codeLang,
            ),
          ],
        );
      },
    );
  }

  Widget _buildInlineContent({
    required dynamic parsed,
    required bool canToggle,
    required BodyViewMode mode,
    required CodeLang codeLang,
  }) {
    if (!canToggle) return JsonPrettyViewer(data: widget.data);
    return DeferredBuilder(
      key: ValueKey(mode),
      builder: (_) {
        switch (mode) {
          case BodyViewMode.tree:
            return JsonViewer(data: parsed, initiallyExpanded: true);
          case BodyViewMode.json:
            return JsonPrettyViewer(data: widget.data);
          case BodyViewMode.code:
            final generated = CodeGenerator.generate(parsed, codeLang);
            return CodeViewer(
              generated: generated,
              lang: codeLang,
              languageLabel: CodeGenerator.labelFor(codeLang),
            );
        }
      },
    );
  }
}

class _TimingView extends StatefulWidget {
  final NetworkEntry entry;

  const _TimingView({required this.entry});

  @override
  State<_TimingView> createState() => _TimingViewState();
}

class _TimingViewState extends State<_TimingView> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duration = entry.duration;
    final startDt = DateTime.fromMillisecondsSinceEpoch(entry.startTime);
    final endDt = entry.endTime != null
        ? DateTime.fromMillisecondsSinceEpoch(entry.endTime!)
        : null;

    Color durationColor;
    String durationLabel;
    IconData durationIcon;
    if (duration == null) {
      durationColor = Colors.grey;
      durationLabel = 'In Progress';
      durationIcon = LucideIcons.loader;
    } else if (duration < 200) {
      durationColor = ColorTokens.success;
      durationLabel = 'Fast';
      durationIcon = LucideIcons.zap;
    } else if (duration < 500) {
      durationColor = ColorTokens.warning;
      durationLabel = 'Normal';
      durationIcon = LucideIcons.clock;
    } else if (duration < 2000) {
      durationColor = const Color(0xFFE5853D);
      durationLabel = 'Slow';
      durationIcon = LucideIcons.triangleAlert;
    } else {
      durationColor = ColorTokens.error;
      durationLabel = 'Very Slow';
      durationIcon = LucideIcons.circleAlert;
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loading indicator for pending requests
          if (duration == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorTokens.warning.withValues(alpha: 0.12),
                    ColorTokens.warning.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ColorTokens.warning.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: ColorTokens.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextComponent(
                    'Waiting for response...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorTokens.warning,
                    ),
                  ),
                ],
              ),
            ),
          if (duration == null) const SizedBox(height: 16),
          // Duration hero card
          if (duration != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    durationColor.withValues(alpha: 0.12),
                    durationColor.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: durationColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: durationColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(durationIcon, size: 22, color: durationColor),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextComponent(
                        formatDuration(duration),
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: durationColor,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TextComponent(
                        durationLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: durationColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Performance gauge
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CustomPaint(
                      painter: _GaugePainter(
                        ratio: (duration / 2000).clamp(0.0, 1.0),
                        color: durationColor,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // Timeline
          _TimingInfoCard(
            isDark: isDark,
            children: [
              _TimingInfoRow(
                icon: LucideIcons.play,
                iconColor: ColorTokens.success,
                label: 'Start Time',
                value: DateFormat('HH:mm:ss.SSS').format(startDt),
                subtitle: DateFormat('yyyy-MM-dd').format(startDt),
                isDark: isDark,
              ),
              if (endDt != null) ...[
                _TimingDividerLine(isDark: isDark),
                _TimingInfoRow(
                  icon: LucideIcons.square,
                  iconColor: ColorTokens.error,
                  label: 'End Time',
                  value: DateFormat('HH:mm:ss.SSS').format(endDt),
                  subtitle: DateFormat('yyyy-MM-dd').format(endDt),
                  isDark: isDark,
                ),
              ],
            ],
          ),
          // Status info
          if (entry.statusCode > 0) ...[
            const SizedBox(height: 12),
            _TimingInfoCard(
              isDark: isDark,
              children: [
                _TimingInfoRow(
                  icon: LucideIcons.arrowUpRight,
                  iconColor: ColorTokens.primary,
                  label: 'Method',
                  value: entry.method,
                  isDark: isDark,
                ),
                _TimingDividerLine(isDark: isDark),
                _TimingInfoRow(
                  icon: LucideIcons.hash,
                  iconColor: entry.statusCode >= 400
                      ? ColorTokens.error
                      : ColorTokens.success,
                  label: 'Status',
                  value: '${entry.statusCode}',
                  isDark: isDark,
                ),
              ],
            ),
          ],
          // Error section
          if (entry.error != null) ...[
            const SizedBox(height: 16),
            const _SectionLabel('Error'),
            const SizedBox(height: 8),
            _ErrorBlock(text: entry.error!, isDark: isDark),
          ],
        ],
      ),
    );
  }
}

class _TimingInfoCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _TimingInfoCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _TimingInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;
  final bool isDark;

  const _TimingInfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: TextComponent(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextComponent(
                  value,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (subtitle != null)
                  TextComponent(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimingDividerLine extends StatelessWidget {
  final bool isDark;
  const _TimingDividerLine({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 28),
      child: Divider(
        height: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double ratio;
  final Color color;
  final bool isDark;

  _GaugePainter({
    required this.ratio,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 4;
    const startAngle = 2.356; // 135 degrees
    const sweepTotal = 4.712; // 270 degrees

    // Background arc
    final bgPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweepTotal * ratio,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.ratio != ratio || old.color != color;
}

// ═══════════════════════════════════════════════
// State Detail
// ═══════════════════════════════════════════════

class _StateDetail extends ConsumerStatefulWidget {
  final StateChange entry;
  final ValueChanged<int>? onTabChanged;
  final ValueChanged<bool>? onJsonModeChanged;

  const _StateDetail({
    required this.entry,
    this.onTabChanged,
    this.onJsonModeChanged,
  });

  @override
  ConsumerState<_StateDetail> createState() => _StateDetailState();
}

class _StateDetailState extends ConsumerState<_StateDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _diffScrollController = SmoothScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = _makeController();
    _tabController.addListener(_onTabIndexChange);
  }

  TabController _makeController([int initialIndex = 0]) {
    return TabController(
      length: 3,
      vsync: this,
      animationDuration: ref.read(tabAnimationProvider),
      initialIndex: initialIndex,
    );
  }

  void _onTabIndexChange() {
    if (!_tabController.indexIsChanging) {
      widget.onTabChanged?.call(_tabController.index);
    }
  }

  void _rebuildController() {
    final oldIndex = _tabController.index;
    _tabController.removeListener(_onTabIndexChange);
    _tabController.dispose();
    _tabController = _makeController(oldIndex);
    _tabController.addListener(_onTabIndexChange);
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabIndexChange);
    _tabController.dispose();
    _diffScrollController.dispose();
    super.dispose();
  }

  StateChange get entry => widget.entry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.listen(tabAnimationProvider, (prev, next) {
      if (prev != next) _rebuildController();
    });
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              _TagChip(entry.stateManagerType,
                  color: ColorTokens.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: TextComponent(
                  entry.actionName,
                  style: const TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
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
        _DetailTabBar(
          controller: _tabController,
          isDark: isDark,
          accentColor: ColorTokens.secondary,
          tabs: const ['Diff', 'Previous', 'Next'],
        ),
        Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LazyTab(
                  controller: _tabController,
                  index: 0,
                  builder: (_) => entry.diff.isEmpty
                      ? EmptyState(
                          icon: LucideIcons.gitCompare, title: 'No diff')
                      : ListView.builder(
                          controller: _diffScrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: entry.diff.length,
                          itemBuilder: (context, index) =>
                              _DiffRow(diff: entry.diff[index]),
                        ),
                ),
                LazyTab(
                  controller: _tabController,
                  index: 1,
                  builder: (_) => entry.previousState.isEmpty
                      ? EmptyState(
                          icon: LucideIcons.layers,
                          title: 'No previous state')
                      : _BodyView(
                          body: entry.previousState,
                          label: 'Previous State',
                          deviceId: entry.deviceId,
                          onJsonModeChanged: widget.onJsonModeChanged,
                        ),
                ),
                LazyTab(
                  controller: _tabController,
                  index: 2,
                  builder: (_) => entry.nextState.isEmpty
                      ? EmptyState(
                          icon: LucideIcons.layers,
                          title: 'No next state')
                      : _BodyView(
                          body: entry.nextState,
                          label: 'Next State',
                          deviceId: entry.deviceId,
                          onJsonModeChanged: widget.onJsonModeChanged,
                        ),
                ),
              ],
            ),
        ),
      ],
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
              TextComponent(
                diff.path,
                style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
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
                child: TextComponent(
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
                TextComponent('- ',
                    style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 11,
                        color: ColorTokens.error)),
                Expanded(
                  child: TextComponent(
                    '${diff.oldValue}',
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
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
                TextComponent('+ ',
                    style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 11,
                        color: ColorTokens.success)),
                Expanded(
                  child: TextComponent(
                    '${diff.newValue}',
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
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

class _StorageDetail extends StatefulWidget {
  final StorageEntry entry;
  final ValueChanged<bool>? onFormatChanged;

  const _StorageDetail({required this.entry, this.onFormatChanged});

  @override
  State<_StorageDetail> createState() => _StorageDetailState();
}

class _StorageDetailState extends State<_StorageDetail> {
  bool _formatted = false;
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  StorageEntry get entry => widget.entry;

  /// Try to parse a string value as JSON
  dynamic _tryParseJson(dynamic value) {
    if (value is! String) return null;
    try {
      final parsed = jsonDecode(value);
      if (parsed is Map || parsed is List) return parsed;
    } catch (_) {}
    return null;
  }

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

    final parsedJson = _tryParseJson(entry.value);
    final isAlreadyJson = entry.value is Map || entry.value is List;
    final canFormat = parsedJson != null && !isAlreadyJson;
    final rawText = entry.value is String
        ? entry.value as String
        : const JsonEncoder.withIndent('  ').convert(entry.value);
    final sizeBytes = rawText.length;
    final sizeLabel = AppConstants.formatBytes(sizeBytes);

    // Off-black neutral palette per anti-AI-slop rules — no pure black,
    // no purple/blue glows. Subtle tonal hierarchy only.
    final surfaceColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final labelColor = isDark ? const Color(0xFF8B8B8B) : const Color(0xFF6B6B6B);
    final valueColor = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final monoStyle = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 12,
      height: 1.6,
      color: valueColor,
    );

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status row: operation + type + size + actions ──
          // Asymmetric per VARIANCE 8: action cluster right-aligned, no
          // centered chrome. Mathematically perfect 8px gaps.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _TagChip(entry.operation.toUpperCase(), color: opColor),
              const SizedBox(width: 8),
              _TagChip(entry.storageType.name, color: ColorTokens.warning),
              const SizedBox(width: 8),
              _TagChip(sizeLabel, color: Colors.grey),
              const Spacer(),
              _IconAction(
                icon: LucideIcons.copy,
                tooltip: 'Copy key',
                onTap: () => _copyText(context, entry.key, 'Key'),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ── Key section: label above value, monospace value ──
          _SectionLabel('Key'),
          const SizedBox(height: 8),
          _CodeBlock(text: entry.key, isDark: isDark),

          if (entry.value != null) ...[
            const SizedBox(height: 22),

            // ── Value section ──
            if (isAlreadyJson)
              _InlineJsonView(data: entry.value, label: 'Value')
            else ...[
              Row(
                children: [
                  _SectionLabel('Value'),
                  const Spacer(),
                  if (canFormat) ...[
                    _FormatToggleButton(
                      isFormatted: _formatted,
                      onToggle: () => setState(() {
                        _formatted = !_formatted;
                        widget.onFormatChanged?.call(_formatted);
                      }),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _IconAction(
                    icon: LucideIcons.copy,
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
              const SizedBox(height: 8),
              if (_formatted && parsedJson != null)
                _InlineJsonView(data: parsedJson, label: '')
              else
                _CodeBlock(text: '${entry.value}', isDark: isDark),
            ],

            const SizedBox(height: 26),

            // ── Metadata divider + key/value list ──
            // No card container — just a thin 1px line + tight rows.
            // Monospace values per dashboard rules; labels in neutral grey.
            Container(height: 1, color: borderColor),
            const SizedBox(height: 14),
            _MetaRow(label: 'Shape', value: _shapeOf(entry.value), monoStyle: monoStyle, labelColor: labelColor),
            _MetaRow(label: 'Length', value: '$sizeBytes chars', monoStyle: monoStyle, labelColor: labelColor),
            _MetaRow(label: 'Device', value: entry.deviceId, monoStyle: monoStyle, labelColor: labelColor),
            _MetaRow(
              label: 'Captured',
              value: DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
                DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
              ),
              monoStyle: monoStyle,
              labelColor: labelColor,
            ),
          ],
        ],
      ),
    );
  }

  String _shapeOf(dynamic v) {
    if (v == null) return 'null';
    if (v is Map) return 'Map · ${v.length} ${v.length == 1 ? "key" : "keys"}';
    if (v is List) return 'List · ${v.length} ${v.length == 1 ? "item" : "items"}';
    if (v is String) {
      if (v.isEmpty) return 'String · empty';
      final t = v.trim();
      if ((t.startsWith('{') && t.endsWith('}')) ||
          (t.startsWith('[') && t.endsWith(']'))) {
        return 'String · JSON-shaped';
      }
      return 'String';
    }
    return v.runtimeType.toString();
  }
}

/// Compact key/value row for the storage metadata footer.
class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle monoStyle;
  final Color labelColor;

  const _MetaRow({
    required this.label,
    required this.value,
    required this.monoStyle,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: labelColor,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SelectableText(
              value,
              style: monoStyle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle icon button with hover-state feedback. Replaces the hard-edged
/// `_CopyButton` for a calmer, more premium look (MOTION_INTENSITY 6).
class _IconAction extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: const Cubic(0.16, 1, 0.3, 1),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _hovered
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              size: 13,
              color: isDark ? const Color(0xFF8B8B8B) : const Color(0xFF6B6B6B),
            ),
          ),
        ),
      ),
    );
  }
}

/// Metadata footer for the storage detail view. Renders a border-top divider
/// followed by a clean key/value list — no card containers, just a thin line
/// and tight monospace rows, per the dashboard-hardening design rule.
class _StorageMetadataSection extends StatelessWidget {
  final StorageEntry entry;
  final bool isDark;

  const _StorageMetadataSection({required this.entry, required this.isDark});

  String _shape() {
    final v = entry.value;
    if (v == null) return 'null';
    if (v is Map) return 'Map · ${v.length} keys';
    if (v is List) return 'List · ${v.length} items';
    if (v is String) {
      if (v.isEmpty) return 'String · empty';
      final t = v.trim();
      if ((t.startsWith('{') && t.endsWith('}')) ||
          (t.startsWith('[') && t.endsWith(']'))) {
        return 'String · JSON';
      }
      return 'String · ${v.length} chars';
    }
    return v.runtimeType.toString();
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final valueColor = isDark ? const Color(0xFFD4D4D4) : const Color(0xFF1F2328);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final monoStyle = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 11,
      color: valueColor,
    );

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: labelColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: monoStyle,
                  softWrap: true,
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: dividerColor),
        const SizedBox(height: 14),
        row('Type', entry.storageType.name),
        row('Operation', entry.operation),
        row('Shape', _shape()),
        row('Device', entry.deviceId),
        row('Timestamp',
            DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
              DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
            )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// Storage Detail (Redesigned)
// ═══════════════════════════════════════════════

class _StorageDetailRedesign extends ConsumerStatefulWidget {
  final StorageEntry entry;
  final VoidCallback? onClose;
  const _StorageDetailRedesign({
    required this.entry,
    this.onClose,
  });

  @override
  ConsumerState<_StorageDetailRedesign> createState() =>
      _StorageDetailRedesignState();
}

class _StorageDetailRedesignState
    extends ConsumerState<_StorageDetailRedesign> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Design tokens ─────────────────────────────────────────────
  // Off-black neutrals (anti-pure-black rule). One accent reserved
  // for the operation chip — everything else is desaturated.
  Color _textPrimary(bool isDark) =>
      isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
  Color _textSecondary(bool isDark) =>
      isDark ? const Color(0xFF8B8B8B) : const Color(0xFF6B6B6B);
  Color _divider(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.06);

  Color _opColor() {
    switch (widget.entry.operation.toLowerCase()) {
      case 'write':
        return const Color(0xFF34D399); // emerald 400 — single accent
      case 'read':
        return const Color(0xFF60A5FA); // blue 400
      case 'delete':
      case 'clear':
        return const Color(0xFFF87171); // red 400
      default:
        return const Color(0xFFFBBF24); // amber 400
    }
  }

  String _shapeOf(dynamic v) {
    if (v == null) return 'null';
    if (v is Map) return 'Map · ${v.length} ${v.length == 1 ? "key" : "keys"}';
    if (v is List) return 'List · ${v.length} ${v.length == 1 ? "item" : "items"}';
    if (v is String) {
      if (v.isEmpty) return 'String · empty';
      final t = v.trim();
      if ((t.startsWith('{') && t.endsWith('}')) ||
          (t.startsWith('[') && t.endsWith(']'))) {
        return 'String · JSON-shaped';
      }
      return 'String';
    }
    return v.runtimeType.toString();
  }

  dynamic _parsedJson() {
    final v = widget.entry.value;
    if (v is! String) return null;
    try {
      final p = jsonDecode(v);
      if (p is Map || p is List) return p;
    } catch (_) {}
    return null;
  }

  dynamic _displayValue() {
    final v = widget.entry.value;
    if (v is Map || v is List) return v;
    return _parsedJson() ?? v;
  }

  bool get _isJsonLike {
    final v = widget.entry.value;
    if (v is Map || v is List) return true;
    return _parsedJson() != null;
  }

  String _sizeLabel() {
    final raw = widget.entry.value is String
        ? widget.entry.value as String
        : const JsonEncoder.withIndent('  ').convert(widget.entry.value);
    return AppConstants.formatBytes(raw.length);
  }

  String _captureText() {
    final v = widget.entry.value;
    return v is String ? v : const JsonEncoder.withIndent('  ').convert(v);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = ref.watch(bodyViewModeProvider);
    final devices = ref.watch(connectedDevicesProvider);
    final platform = devices
            .where((d) => d.deviceId == widget.entry.deviceId)
            .map((d) => d.platform)
            .firstOrNull ??
        'react_native';
    final codeLang = CodeGenerator.langForPlatform(platform);
    final codeLabel = CodeGenerator.labelFor(codeLang);

    final monoPrimary = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 13,
      height: 1.5,
      color: _textPrimary(isDark),
    );
    final monoSecondary = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 11,
      height: 1.5,
      color: _textSecondary(isDark),
    );

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ──────────────────────────────────────────────────────────
          // 1) HEADER — operation accent + storage type + key chip
          // ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _OpBadge(label: widget.entry.operation, color: _opColor()),
                const SizedBox(width: 8),
                _TypeBadge(label: widget.entry.storageType.name),
                const Spacer(),
                _HeaderIconButton(
                  icon: LucideIcons.copy,
                  tooltip: S.of(context).copyKey,
                  isDark: isDark,
                  onTap: () => _copyText(context, widget.entry.key, 'Key'),
                ),
                const SizedBox(width: 4),
                _HeaderIconButton(
                  icon: LucideIcons.camera,
                  tooltip: _isJsonLike
                      ? S.of(context).captureDataJson
                      : S.of(context).captureDataText,
                  isDark: isDark,
                  onTap: () =>
                      _captureData(isDark, devices, codeLang, codeLabel),
                ),
                const SizedBox(width: 4),
                _HeaderIconButton(
                  icon: LucideIcons.x,
                  tooltip: S.of(context).close,
                  isDark: isDark,
                  onTap: () => widget.onClose?.call(),
                ),
              ],
            ),
          ),

          // ──────────────────────────────────────────────────────────
          // 2) KEY DISPLAY — large monospace, hero element
          // ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Label(text: 'KEY', isDark: isDark),
                    const Spacer(),
                    _HeaderIconButton(
                      icon: LucideIcons.copy,
                      tooltip: 'Copy key',
                      isDark: isDark,
                      onTap: () => _copyText(context, widget.entry.key, 'Key'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  widget.entry.key,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: _textPrimary(isDark),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // ──────────────────────────────────────────────────────────
          // 3) METADATA GRID — 2x2 bento layout
          // ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label(text: 'METADATA', isDark: isDark),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _MetaCell(
                        label: 'SHAPE',
                        value: _shapeOf(widget.entry.value),
                        valueStyle: monoPrimary,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetaCell(
                        label: 'SIZE',
                        value: _sizeLabel(),
                        valueStyle: monoPrimary,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _MetaCell(
                        label: 'DEVICE',
                        value: widget.entry.deviceId,
                        valueStyle: monoSecondary,
                        isDark: isDark,
                        monospace: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetaCell(
                        label: 'CAPTURED',
                        value: DateFormat('HH:mm:ss.SSS').format(
                          DateTime.fromMillisecondsSinceEpoch(
                              widget.entry.timestamp),
                        ),
                        valueStyle: monoPrimary,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ──────────────────────────────────────────────────────────
          // 4) DIVIDER — separates data zones
          // ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Container(height: 1, color: _divider(isDark)),
          ),

          // ──────────────────────────────────────────────────────────
          // 5) VALUE SECTION — switcher + content
          // ──────────────────────────────────────────────────────────
          if (widget.entry.value != null && _isJsonLike) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: SizedBox(
                width: double.infinity,
                child: ViewModeSwitcher(
                  current: mode,
                  codeLabel: codeLabel,
                  onChanged: (m) =>
                      ref.read(bodyViewModeProvider.notifier).set(m),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _buildValueContent(
                isDark: isDark,
                mode: mode,
                codeLang: codeLang,
                codeLabel: codeLabel,
              ),
            ),
          ] else if (widget.entry.value != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                children: [
                  _Label(text: 'VALUE', isDark: isDark),
                  const Spacer(),
                  _HeaderIconButton(
                    icon: LucideIcons.copy,
                    tooltip: 'Copy value',
                    isDark: isDark,
                    onTap: () => _copyText(context, _captureText(), 'Value'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.025),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _divider(isDark)),
                ),
                child: SelectableText(
                  widget.entry.value.toString(),
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    height: 1.6,
                    color: _textPrimary(isDark),
                  ),
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: _EmptyValue(isDark: isDark),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValueContent({
    required bool isDark,
    required BodyViewMode mode,
    required CodeLang codeLang,
    required String codeLabel,
  }) {
    final value = _displayValue();

    return DeferredBuilder(
      key: ValueKey(mode),
      builder: (_) {
        switch (mode) {
          case BodyViewMode.tree:
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: JsonViewer(data: value, initiallyExpanded: true),
            );
          case BodyViewMode.json:
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: JsonPrettyViewer(data: value),
            );
          case BodyViewMode.code:
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: CodeViewer(
                generated: CodeGenerator.generate(value, codeLang),
                lang: codeLang,
                languageLabel: codeLabel,
              ),
            );
        }
      },
    );
  }

  void _copyText(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    showCopiedToast(context, label: '$label copied');
  }

  // ── Screenshot: data only (KEY + VALUE in current view mode) ──
  void _captureData(
    bool isDark,
    List<DeviceInfo> devices,
    CodeLang codeLang,
    String codeLabel,
  ) {
    final value = _displayValue();
    final monoKey = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: _textPrimary(isDark),
    );
    final labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF8B8B8B),
    );
    final divider = _divider(isDark);
    final mode = ref.read(bodyViewModeProvider);

    // Value widget: respect 3-mode only when the payload is JSON-like.
    // Plain text/number/bool capture as raw text — no switcher chrome.
    final Widget valueWidget;
    if (_isJsonLike) {
      valueWidget = switch (mode) {
        BodyViewMode.tree => JsonViewer(data: value, initiallyExpanded: true),
        BodyViewMode.json => JsonPrettyViewer(data: value),
        BodyViewMode.code => CodeViewer(
            generated: CodeGenerator.generate(value, codeLang),
            lang: codeLang,
            languageLabel: codeLabel,
          ),
      };
    } else if (widget.entry.value == null) {
      valueWidget = const SizedBox.shrink();
    } else {
      valueWidget = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: divider),
        ),
        child: SelectableText(
          widget.entry.value.toString(),
          style: TextStyle(
            fontFamily: AppConstants.monoFontFamily,
            fontSize: 12,
            height: 1.6,
            color: _textPrimary(isDark),
          ),
        ),
      );
    }

    // Header style matches _storageScreenshot for visual consistency
    // between full and data captures.
    final capturedAt = DateTime.now().toIso8601String().split('.').first;
    final labelColor = isDark ? Colors.grey[500] : Colors.grey[600];

    final capture = Container(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header context (matches _storageScreenshot) ──
          Row(
            children: [
              Icon(LucideIcons.database,
                  size: 14, color: ColorTokens.warning),
              const SizedBox(width: 6),
              Text(
                'Storage Detail',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: labelColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '· ${widget.entry.storageType.name.toUpperCase()} · $capturedAt',
                  style: TextStyle(
                    fontSize: 10,
                    color: labelColor,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // ── Badges (mirror _StorageDetailRedesign header row) ──
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _OpBadge(label: widget.entry.operation, color: _opColor()),
              const SizedBox(width: 8),
              _TypeBadge(label: widget.entry.storageType.name),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: divider),
          const SizedBox(height: 18),
          Text('KEY', style: labelStyle),
          const SizedBox(height: 8),
          SelectableText(widget.entry.key, style: monoKey),
          const SizedBox(height: 18),
          Container(height: 1, color: divider),
          const SizedBox(height: 18),
          Text('VALUE', style: labelStyle),
          const SizedBox(height: 10),
          valueWidget,
        ],
      ),
    );

    captureWidgetAsImage(
      context,
      capture,
      fileName: _buildScreenshotName(devices, '_data'),
      onSaved: (path) {
        if (mounted) showScreenshotSavedToast(context, filePath: path);
      },
    );
  }

  String _buildScreenshotName(List<DeviceInfo> devices, String suffix) {
    final entry = widget.entry;
    // Note: appName intentionally omitted to avoid leaking the app
    // identifier into filenames shared with clients.
    return buildRichScreenshotName(
      type: entry.storageType.name,
      subject: entry.key,
      suffix: suffix,
    );
  }
}

// ── Helper widgets for the redesign ───────────────────────────

class _Label extends StatelessWidget {
  final String text;
  final bool isDark;
  const _Label({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF8B8B8B),
      ),
    );
  }
}

class _OpBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _OpBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: AppConstants.monoFontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  const _TypeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF4A4A4A);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppConstants.monoFontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final iconColor = widget.isDark
        ? const Color(0xFF9A9A9A)
        : const Color(0xFF6B6B6B);
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: const Cubic(0.16, 1, 0.3, 1),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _hovered ? hoverColor : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(widget.icon, size: 14, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _MetaCell extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle valueStyle;
  final bool isDark;
  final bool monospace;

  const _MetaCell({
    required this.label,
    required this.value,
    required this.valueStyle,
    required this.isDark,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(text: label, isDark: isDark),
        const SizedBox(height: 6),
        SelectableText(
          value,
          style: valueStyle,
          maxLines: 1,
        ),
      ],
    );
  }
}

class _EmptyValue extends StatelessWidget {
  final bool isDark;
  const _EmptyValue({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            LucideIcons.database,
            size: 24,
            color: isDark ? const Color(0xFF4A4A4A) : const Color(0xFFB0B0B0),
          ),
          const SizedBox(height: 10),
          Text(
            'No value stored',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF8B8B8B) : const Color(0xFF6B6B6B),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Fallback Detail
// ═══════════════════════════════════════════════

class _FallbackDetail extends StatefulWidget {
  final UnifiedEvent event;

  const _FallbackDetail({required this.event});

  @override
  State<_FallbackDetail> createState() => _FallbackDetailState();
}

class _FallbackDetailState extends State<_FallbackDetail> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      controller: _scrollController,
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
    return TextComponent(
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
      child: TextComponent(
        label,
        style: TextStyle(
          fontFamily: AppConstants.monoFontFamily,
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
    return _PressableButton(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
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

class _FormatToggleButton extends StatelessWidget {
  final bool isFormatted;
  final VoidCallback onToggle;

  const _FormatToggleButton({
    required this.isFormatted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableButton(
      onTap: onToggle,
      child: Tooltip(
        message: isFormatted ? 'Show raw' : 'Format JSON',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isFormatted
                  ? ColorTokens.primary.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.08),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.braces,
                  size: 12,
                  color: isFormatted ? ColorTokens.primary : Colors.grey[500],
                ),
                const SizedBox(width: 4),
                TextComponent(
                  isFormatted ? 'Raw' : 'Format',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color:
                        isFormatted ? ColorTokens.primary : Colors.grey[500],
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
        color: isDark ? ColorTokens.darkBackground : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: TextComponent(
        text,
        style: TextStyle(
          fontFamily: AppConstants.monoFontFamily,
          fontSize: 12,
          color: isDark ? ColorTokens.lightBackground : Colors.black87,
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
      child: TextComponent(
        text,
        style: TextStyle(
          fontFamily: AppConstants.monoFontFamily,
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
            child: TextComponent(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextComponent(
            value,
            style: const TextStyle(
              fontFamily: AppConstants.monoFontFamily,
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
  showCopiedToast(context, label: '$label copied');
}
