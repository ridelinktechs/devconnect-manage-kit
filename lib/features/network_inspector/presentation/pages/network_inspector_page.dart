import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../components/lists/stable_list_view.dart';
import '../../../../components/misc/jump_to_latest_fab.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/position_retained_scroll_physics.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/network/network_entry.dart';
import '../../provider/network_providers.dart';
import '../request/request_card.dart';
import '../request/request_detail_panel.dart';
import '../toolbar/toolbar.dart';

/// Top-level Network Inspector page. Composes:
///
/// - [Toolbar] — title, count, method + source filters, search, actions
/// - [RequestCard] list — the streaming network requests
/// - [RequestDetailPanel] — slides in when a row is selected
///
/// Owns the page-level state: scroll controller, selection, auto-scroll,
/// and the in-memory entry cache populated from
/// [filteredNetworkEntriesProvider].
class NetworkInspectorPage extends ConsumerStatefulWidget {
  const NetworkInspectorPage({super.key});

  @override
  ConsumerState<NetworkInspectorPage> createState() =>
      _NetworkInspectorPageState();
}

class _NetworkInspectorPageState
    extends ConsumerState<NetworkInspectorPage> {
  final _scrollController = SmoothScrollController();
  final _entryCount = ValueNotifier<int>(0);
  bool _autoScroll = true;
  bool _programmaticScroll = false;
  int _visibleCount = 0;
  int _generation = 0;
  final List<NetworkEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    ref.listenManual(
      filteredNetworkEntriesProvider,
      (previous, next) {
        // Network has in-place updates (response arrives for pending request).
        // Always full sync to ensure tiles reflect latest data.
        final grew = next.length > _entries.length;
        final shrunk = next.length < _entries.length;
        _entries..clear()..addAll(next);
        _entryCount.value = _entries.length;
        if (grew || shrunk || _autoScroll) _visibleCount = _entries.length;
        _generation++;
        setState(() {});
        if (_autoScroll) _autoScrollIfNeeded();
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

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
          count: _entryCount,
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
        ),
        const Divider(height: 1),
        Expanded(
          child: _entries.isEmpty
              ? EmptyState(
                  icon: LucideIcons.globe,
                  title: S.of(context).noNetworkRequests,
                  subtitle: S.of(context).apiCallsAppearHere,
                )
              : Stack(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ListView.custom(
                            controller: _scrollController,
                            reverse: isReversed,
                            physics: isReversed
                                ? const PositionRetainedScrollPhysics()
                                : null,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            childrenDelegate: StableBuilderDelegate(
                              generation: _generation,
                              childCount: _visibleCount,
                              findChildIndexCallback: (key) {
                                if (key is ValueKey<String>) {
                                  final idx = _entries
                                      .indexWhere((e) => e.id == key.value);
                                  return idx == -1 ? null : idx;
                                }
                                return null;
                              },
                              builder: (context, index) {
                                final entry = _entries[index];
                                return RepaintBoundary(
                                  key: ValueKey(entry.id),
                                  child: Consumer(
                                    builder: (context, ref, _) {
                                      final selected =
                                          ref.watch(selectedNetworkEntryProvider);
                                      final isSelected =
                                          selected?.id == entry.id;
                                      return RequestCard(
                                        entry: entry,
                                        isSelected: isSelected,
                                        onTap: () {
                                          ref
                                              .read(selectedNetworkIdProvider
                                                  .notifier)
                                              .state = isSelected ? null : entry.id;
                                          if (!isSelected && _autoScroll) {
                                            _autoScroll = false;
                                            _programmaticScroll = false;
                                            if (_scrollController.hasClients) {
                                              _scrollController.jumpTo(
                                                  _scrollController.offset);
                                            }
                                            setState(() {});
                                          }
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Detail panel reacts to selection via Consumer,
                        // without rebuilding the list column.
                        Consumer(
                          builder: (context, ref, _) {
                            final selected =
                                ref.watch(selectedNetworkEntryProvider);
                            if (selected == null) return const SizedBox.shrink();
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                VerticalDivider(width: 1, color: theme.dividerColor),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.45,
                                  child: RequestDetailPanel(
                                    key: ValueKey(selected.id),
                                    entry: selected,
                                    onClose: () {
                                      ref
                                          .read(selectedNetworkIdProvider.notifier)
                                          .state = null;
                                    },
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