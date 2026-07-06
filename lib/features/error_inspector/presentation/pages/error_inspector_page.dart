import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../components/lists/stable_list_view.dart';
import '../../../../components/misc/jump_to_latest_fab.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/position_retained_scroll_physics.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../models/log/error_event.dart';
import '../../provider/error_providers.dart';
import '../detail/error_detail_panel.dart';
import '../event_row/error_list_item.dart';
import '../header/toolbar.dart';
import '../shared/empty_state_with_pulse.dart';

/// Top-level Error Inspector page. Composes:
///
/// - [Toolbar] — title, error count + pulsing dot, platform filter chips,
///   search field, action group, plus the unified info bar (Total / Fatal /
///   per-platform counts).
/// - [ErrorListItem] list — the streaming error events
/// - [ErrorDetailPanel] — slides in when a row is selected
/// - [EmptyStateWithPulse] — the breathing-shield rich empty state
///   (replaces the bland `EmptyState` icon-only component)
///
/// Owns the page-level state: scroll controller, selection, auto-scroll,
/// search controller, and the in-memory entry cache populated from
/// [filteredErrorEntriesProvider].
class ErrorInspectorPage extends ConsumerStatefulWidget {
  const ErrorInspectorPage({super.key});

  @override
  ConsumerState<ErrorInspectorPage> createState() =>
      _ErrorInspectorPageState();
}

class _ErrorInspectorPageState extends ConsumerState<ErrorInspectorPage> {
  final _scrollController = SmoothScrollController();
  final _selectedId = ValueNotifier<String?>(null);
  final _entryCount = ValueNotifier<int>(0);
  final _searchController = TextEditingController();
  bool _autoScroll = true;
  bool _programmaticScroll = false;
  int _visibleCount = 0;
  int _generation = 0;
  final List<ErrorEvent> _entries = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    ref.listenManual<List<ErrorEvent>>(
      filteredErrorEntriesProvider,
      (previous, next) {
        final prevLen = _entries.length;
        if (next.length > prevLen &&
            previous != null &&
            next.length - prevLen == next.length - previous.length) {
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
    // Selection changes must also bump generation — StableBuilderDelegate
    // short-circuits shouldRebuild when generation is unchanged, which
    // would otherwise leave the selected row's tint stuck on the
    // previously-selected item.
    _selectedId.addListener(_onSelectionChanged);
  }

  void _onSelectionChanged() {
    if (!mounted) return;
    _generation++;
    setState(() {});
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
    _selectedId.dispose();
    _entryCount.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scrollDir = ref.watch(scrollDirectionProvider);
    final isReversed = scrollDir == ScrollDirection.top;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Toolbar(
          entryCount: _entryCount,
          searchController: _searchController,
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
        Expanded(
          child: _entries.isEmpty
              ? const EmptyStateWithPulse(
                  title: 'No errors recorded',
                  subtitle:
                      "When the connected app reports an error, it'll show up here.",
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
                            itemExtent: 76,
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
                                      final selectedIdValue =
                                          _selectedId.value;
                                      final isSelected =
                                          selectedIdValue == entry.id;
                                      return ErrorListItem(
                                        entry: entry,
                                        isSelected: isSelected,
                                        onTap: () {
                                          _selectedId.value =
                                              isSelected ? null : entry.id;
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
                                        onCopy: () => _copy(
                                          context,
                                          entry.message,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Detail panel
                        ValueListenableBuilder<String?>(
                          valueListenable: _selectedId,
                          builder: (context, selectedIdValue, _) {
                            final selected = selectedIdValue != null
                                ? _entries
                                    .where((e) => e.id == selectedIdValue)
                                    .firstOrNull
                                : null;
                            if (selected == null) {
                              return const SizedBox.shrink();
                            }
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                VerticalDivider(
                                    width: 1,
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.35,
                                  child: ErrorDetailPanel(
                                    key: ValueKey(selected.id),
                                    entry: selected,
                                    onClose: () =>
                                        _selectedId.value = null,
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

  void _copy(BuildContext context, String text) {
    // Local copy helper used by ErrorListItem.onCopy — same flow as
    // other features (clipboard + showCopiedToast).
    Clipboard.setData(ClipboardData(text: text));
    showCopiedToast(context);
  }
}