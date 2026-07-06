import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../components/lists/stable_list_view.dart';
import '../../../../components/misc/jump_to_latest_fab.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/log/log_entry.dart';
import '../../../../server/providers/server_providers.dart';
import '../../provider/console_providers.dart';
import '../detail/detail_panel.dart';
import '../event_row/log_entry_content.dart';
import '../header/toolbar.dart';

/// ═══════════════════════════════════════════════════════════════════
/// Console Page — streaming log entries with optional right-pane
/// detail panel. Composes [Toolbar] (top) + a `StableListView` of
/// [LogEntryContent] rows inside a `JumpToLatestFab`-decorated
/// Stack.
/// ═══════════════════════════════════════════════════════════════════

class ConsolePage extends ConsumerStatefulWidget {
  const ConsolePage({super.key});

  @override
  ConsumerState<ConsolePage> createState() => _ConsolePageState();
}

class _ConsolePageState extends ConsumerState<ConsolePage> {
  final _scrollController = SmoothScrollController();
  final _selectedId = ValueNotifier<String?>(null);
  final _entryCount = ValueNotifier<int>(0);
  bool _autoScroll = true;
  bool _programmaticScroll = false;
  int _visibleCount = 0;
  int _generation = 0;
  final List<LogEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    ref.listenManual<List<LogEntry>>(
      filteredConsoleEntriesProvider,
      (previous, next) {
        final prevLen = _entries.length;
        if (next.length > prevLen && previous != null && next.length - prevLen == next.length - previous.length) {
          _entries.addAll(next.sublist(prevLen));
          _entryCount.value = _entries.length;
          if (!_autoScroll) return;
          _visibleCount = _entries.length;
          setState(() {});
          _autoScrollIfNeeded();
        } else {
          _entries..clear()..addAll(next);
          _entryCount.value = _entries.length;
          _visibleCount = _entries.length;
          _generation++;
          setState(() {});
          if (_autoScroll) _autoScrollIfNeeded();
        }
      },
      fireImmediately: true,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final reversed = ref.read(scrollDirectionProvider) == ScrollDirection.top;
    final atBottom = reversed
        ? pos.pixels <= pos.minScrollExtent + 2.0
        : pos.pixels >= pos.maxScrollExtent - 2.0;
    final distFromBottom = reversed
        ? pos.pixels - pos.minScrollExtent
        : pos.maxScrollExtent - pos.pixels;

    if (!_autoScroll && atBottom) {
      _autoScroll = true;
      _visibleCount = _entries.length;
      setState(() {});
      return;
    }

    if (_autoScroll && !_programmaticScroll && distFromBottom > 50.0) {
      _autoScroll = false;
      setState(() {});
      return;
    }

    if (!_autoScroll && _visibleCount < _entries.length) {
      if (distFromBottom < pos.viewportDimension * 1.5) {
        _visibleCount = _entries.length;
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
      final reversed = ref.read(scrollDirectionProvider) == ScrollDirection.top;
      final pos = _scrollController.position;
      final target = reversed ? pos.minScrollExtent : pos.maxScrollExtent;
      final atTarget = reversed
          ? pos.pixels <= pos.minScrollExtent + 2.0
          : pos.pixels >= pos.maxScrollExtent - 2.0;
      if (atTarget) {
        _programmaticScroll = false;
        return;
      }
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      ).whenComplete(() {
        if (!mounted || !_autoScroll || !_scrollController.hasClients) {
          _programmaticScroll = false;
          return;
        }
        final p = _scrollController.position;
        final done = reversed
            ? p.pixels <= p.minScrollExtent + 2.0
            : p.pixels >= p.maxScrollExtent - 2.0;
        if (!done) {
          _doAutoScroll();
        } else {
          _programmaticScroll = false;
        }
      });
    });
  }

  LogEntry? _findEntry(String? id) {
    if (id == null) return null;
    return _entries.where((e) => e.id == id).firstOrNull;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _selectedId.dispose();
    _entryCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scrollDir = ref.watch(scrollDirectionProvider);
    final isReversed = scrollDir == ScrollDirection.top;

    return Column(
      children: [
        Toolbar(
          entryCount: _entryCount,
          autoScroll: _autoScroll,
          onToggleAutoScroll: () {
            if (_autoScroll) {
              _autoScroll = false;
              _programmaticScroll = false;
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(_scrollController.offset);
              }
            } else {
              _autoScroll = true;
              _visibleCount = _entries.length;
              _autoScrollIfNeeded();
            }
            setState(() {});
          },
          onClear: () {
            ref.read(consoleEntriesProvider.notifier).clear();
            _selectedId.value = null;
            _entries.clear();
            _entryCount.value = 0;
            _visibleCount = 0;
            setState(() {});
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: _entries.isEmpty
              ? EmptyState(
                  icon: LucideIcons.terminal,
                  title: S.of(context).noLogsYet,
                  subtitle:
                      S.of(context).connectDeviceToSeeLogs,
                )
              : Stack(
                  children: [
                    Row(
                      children: [
                        // ── List panel ──
                        // The list never rebuilds due to selection change.
                        // PositionRetainedScrollPhysics is ALWAYS used to
                        // guarantee the user's scroll position is stable when
                        // new entries arrive.
                        Expanded(
                          child: StableListView<LogEntry>(
                            controller: _scrollController,
                            reverse: isReversed,
                            generation: _generation,
                            childCount: _visibleCount,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            entries: _entries,
                            itemExtent: 64,
                            idOf: (e) => e.id,
                            selectedId: _selectedId,
                            onSelect: (entry) {
                              final wasSelected = _selectedId.value == entry.id;
                              _selectedId.value = wasSelected ? null : entry.id;
                              if (!wasSelected && _autoScroll) {
                                _autoScroll = false;
                                _programmaticScroll = false;
                                if (_scrollController.hasClients) {
                                  _scrollController.jumpTo(_scrollController.offset);
                                }
                                setState(() {});
                              }
                            },
                            contentBuilder: (context, entry) {
                              final devices = ref.read(connectedDevicesProvider);
                              final device = devices.where((d) => d.deviceId == entry.deviceId).firstOrNull;
                              return LogEntryContent(
                                entry: entry,
                                platform: device?.platform,
                              );
                            },
                            decorationBuilder: (isSelected, isDark) {
                              return BoxDecoration(
                                color: isSelected
                                    ? ColorTokens.selectedBg(isDark)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? ColorTokens.selectedBorder(isDark)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.04)
                                          : Colors.black.withValues(alpha: 0.04)),
                                  width: 1,
                                ),
                              );
                            },
                          ),
                        ),
                        // ── Detail panel ──
                        // Only the detail panel listens to _selectedId changes,
                        // preventing list layout from shifting on selection.
                        ValueListenableBuilder<String?>(
                          valueListenable: _selectedId,
                          builder: (context, selectedIdValue, _) {
                            final selected = _findEntry(selectedIdValue);
                            if (selected == null) return const SizedBox.shrink();
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                VerticalDivider(
                                  width: 1,
                                  color: theme.dividerColor,
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  child: LogDetailPanel(
                                    key: ValueKey(selected.id),
                                    entry: selected,
                                    onClose: () => _selectedId.value = null,
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
                      reversed: isReversed,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}