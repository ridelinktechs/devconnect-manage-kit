import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../components/lists/stable_list_view.dart';
import '../../../../components/misc/jump_to_latest_fab.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/device_info.dart';
import '../../../../server/providers/server_providers.dart';
import '../../../benchmark/provider/benchmark_providers.dart';
import '../../../console/provider/console_providers.dart';
import '../../../display/provider/display_providers.dart';
import '../../../error_inspector/provider/error_providers.dart';
import '../../../network_inspector/provider/network_providers.dart';
import '../../../performance/provider/performance_providers.dart';
import '../../../state_inspector/provider/state_providers.dart';
import '../../../storage_viewer/provider/storage_providers.dart';
import '../../provider/all_events_provider.dart';
import '../detail/event_detail_panel.dart';
import '../event_row/event_row.dart';
import '../fab/draggable_reload_fab.dart';
import '../header/filter_bar.dart';
import '../header/header_bar.dart';

/// Top-level All Events page. Composes:
///
/// - [Header] — title, search, sort, action group, server status pill
/// - [FilterBar] — per-type filter chips
/// - [EventRow] list — the streaming events
/// - [EventDetailPanel] — slides in when a row is selected
/// - [DraggableReloadFab] — draggable, glass FAB for reload / hot-restart
///
/// Owns the page-level state: scroll controller, selection, auto-scroll,
/// and the in-memory event cache populated from [filteredAllEventsProvider].
class AllEventsPage extends ConsumerStatefulWidget {
  const AllEventsPage({super.key});

  @override
  ConsumerState<AllEventsPage> createState() => _AllEventsPageState();
}

class _AllEventsPageState extends ConsumerState<AllEventsPage> {
  final _scrollController = SmoothScrollController();
  final _selectedEventId = ValueNotifier<String?>(null);
  final _eventCount = ValueNotifier<int>(0);
  final _untrimmedCount = ValueNotifier<int>(0);
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
        _events..clear()..addAll(next.items);
        _eventCount.value = next.items.length;
        _visibleCount = next.items.length;
        _untrimmedCount.value = next.total;
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
    _untrimmedCount.dispose();
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
      _scrollController
          .animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      )
          .whenComplete(() {
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
    _untrimmedCount.value = 0;
    _visibleCount = 0;
    setState(() {});
  }

  bool _restarting = false;

  /// Restart the WebSocket server. Forces every connected SDK into its
  /// reconnect path — useful when the port changed, WiFi switched, or the
  /// machineId handshake needs to be verified from scratch.
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

  /// Ask every connected device to reload its own app.
  ///
  /// Behaviour on each SDK:
  /// - **Flutter** → `WidgetsBinding.instance.reassembleApplication()` (full
  ///   widget tree rebuild — the same mechanism `flutter run -r` uses)
  /// - **React Native** → `DevSettings.reload()` (Metro reload)
  /// - **Android** → `Activity.recreate()` on the host activity
  ///
  /// We broadcast to ALL devices regardless of platform — the wire message
  /// is the same, the SDK knows what to do with it.
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

    // Pre-index devices by id so each EventRow can resolve its device
    // in O(1). Without this, every row did `devices.where(...)` which
    // was O(M) per row × N rows = O(N×M) per rebuild — visible jank
    // around 500+ events with several connected devices.
    final deviceById = <String, DeviceInfo>{
      for (final d in devices) d.deviceId: d,
    };

    return Stack(
      children: [
        Column(
          children: [
            // ── Header ──
            Header(
              eventCount: _eventCount,
              untrimmedCount: _untrimmedCount,
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
              builder: (_, count, __) => FilterBar(events: _events),
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
                                      final idx = _events
                                          .indexWhere((e) => e.id == key.value);
                                      return idx == -1 ? null : idx;
                                    }
                                    return null;
                                  },
                                  builder: (context, index) {
                                    final actualIndex = sortOrder ==
                                            SortOrder.newestFirst
                                        ? _visibleCount - 1 - index
                                        : index;
                                    if (actualIndex < 0 ||
                                        actualIndex >= _events.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final event = _events[actualIndex];
                                    final device = deviceById[event.deviceId];
                                    return RepaintBoundary(
                                      key: ValueKey(event.id),
                                      child: ValueListenableBuilder<String?>(
                                        valueListenable: _selectedEventId,
                                        builder: (context, selectedId, _) {
                                          final isSelected =
                                              selectedId == event.id;
                                          return EventRow(
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
                                                if (_scrollController
                                                    .hasClients) {
                                                  _scrollController.jumpTo(
                                                      _scrollController.offset);
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
                                if (selectedEvent == null) {
                                  return const SizedBox.shrink();
                                }
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
                                      width: MediaQuery.of(context).size.width *
                                          0.45,
                                      child: EventDetailPanel(
                                        key: ValueKey(selectedEvent.id),
                                        event: selectedEvent,
                                        onClose: () =>
                                            _selectedEventId.value = null,
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
        DraggableReloadFab(
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