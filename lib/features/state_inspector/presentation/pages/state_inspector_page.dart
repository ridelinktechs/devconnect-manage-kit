import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state_with_pulse.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../models/state/state_change.dart';
import '../../../../components/lists/stable_list_view.dart';
import '../../../../components/misc/jump_to_latest_fab.dart';
import '../../../../core/utils/scroll/position_retained_scroll_physics.dart';
import '../../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../../core/utils/ui/toast_utils.dart';
import '../../provider/state_providers.dart';
import '../../provider/state_tools_providers.dart';
import '../../../round/presentation/state_round_panel.dart';
import '../detail/state_detail_panel.dart';
import '../event_row/state_change_tile.dart';
import '../header/state_manager_tab_bar.dart';
import '../header/toolbar.dart';
import '../widgets/state_tools_panel.dart';

class StateInspectorPage extends ConsumerStatefulWidget {
  const StateInspectorPage({super.key});

  @override
  ConsumerState<StateInspectorPage> createState() =>
      _StateInspectorPageState();
}

class _StateInspectorPageState extends ConsumerState<StateInspectorPage> {
  final ScrollController _scrollController = SmoothScrollController();
  final _entryCount = ValueNotifier<int>(0);
  final _search = TextEditingController();
  Set<String> _fresh = const {};
  bool _autoScroll = true;
  bool _programmaticScroll = false;
  int _visibleCount = 0;
  int _generation = 0;
  final List<StateChange> _entries = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    ref.listenManual(
      filteredStateChangesProvider,
      (previous, next) {
        final prevLen = _entries.length;
        if (next.length > prevLen && previous != null && next.length - prevLen == next.length - previous.length) {
          _fresh = {for (final e in next.sublist(prevLen)) e.id};
          _entries.addAll(next.sublist(prevLen));
          _entryCount.value = _entries.length;
          if (!_autoScroll) return;
          _visibleCount = _entries.length;
          setState(() {});
          _autoScrollIfNeeded();
        } else {
          _fresh = const {};
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

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _entryCount.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedStateChangeProvider);
    final theme = Theme.of(context);
    final scrollDir = ref.watch(scrollDirectionProvider);
    final isReversed = scrollDir == ScrollDirection.top;

    return DefaultTabController(
      length: 3,
      animationDuration: ref.watch(tabAnimationProvider),
      child: Column(
        children: [
          Toolbar(
            totalCount: _entryCount,
            searchController: _search,
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
          const StateManagerTabBar(),
          Expanded(
            child: TabBarView(
              children: [
                _buildReduxTab(selected, theme, isReversed),
                const StateRoundPanel(),
                const StateToolsPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReduxTab(dynamic selected, ThemeData theme, bool isReversed) {
    return Column(
      children: [
        Expanded(
          child: _entries.isEmpty
              ? ref.watch(stateManagerCountsProvider).isEmpty &&
                      ref.watch(stateSearchProvider).isEmpty
                  ? EmptyStateWithPulse(
                      icon: LucideIcons.layers,
                      title: S.of(context).noStateChanges,
                      subtitle: S.of(context).stateChangesAppearHere,
                    )
                  : const EmptyStateWithPulse(
                      icon: LucideIcons.listFilter,
                      title: 'No changes match',
                      subtitle:
                          'Turn a state library back on, or clear the filter.',
                    )
              : Stack(
                  children: [
                    Row(
                      children: [
                        // Timeline — full width when no selection
                        Expanded(
                          flex: 2,
                          child: ListView.custom(
                            controller: _scrollController,
                            reverse: isReversed,
                            physics: isReversed ? const PositionRetainedScrollPhysics() : null,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemExtent: 90,
                            childrenDelegate: StableBuilderDelegate(
                              generation: _generation,
                              childCount: _visibleCount,
                              findChildIndexCallback: (key) {
                                if (key is ValueKey<String>) {
                                  final idx = _entries.indexWhere((e) => e.id == key.value);
                                  return idx == -1 ? null : idx;
                                }
                                return null;
                              },
                              builder: (context, index) {
                                final entry = _entries[index];
                                return RepaintBoundary(
                                  key: ValueKey(entry.id),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    child: StateChangeTile(
                                    entry: entry,
                                    fresh: _fresh.contains(entry.id),
                                    onTap: () {
                                      final currentlySelected =
                                          ref.read(selectedStateChangeIdProvider) ==
                                              entry.id;
                                      ref
                                          .read(selectedStateChangeIdProvider.notifier)
                                          .set(currentlySelected ? null : entry.id);
                                      if (!currentlySelected && _autoScroll) {
                                        _autoScroll = false;
                                        _programmaticScroll = false;
                                        if (_scrollController.hasClients) {
                                          _scrollController.jumpTo(_scrollController.offset);
                                        }
                                        setState(() {});
                                      }
                                    },
                                  ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        if (selected != null) ...[
                          VerticalDivider(width: 1, color: theme.dividerColor),
                          Expanded(
                            flex: 3,
                            child: StateDetailPanel(
                              entry: selected,
                              onClose: () => ref
                                  .read(selectedStateChangeIdProvider.notifier)
                                  .set(null),
                              // Time travel: send the app back to the state
                              // after this action.
                              onRestore: () => restoreAppState(
                                context,
                                ref,
                                selected.deviceId,
                                selected.nextState,
                              ),
                              onSnapshot: () {
                                ref.read(stateSnapshotsProvider.notifier).add(
                                      '${selected.actionName} · ${DateFormat.Hms().format(DateTime.fromMillisecondsSinceEpoch(selected.timestamp))}',
                                      selected.deviceId,
                                      selected.nextState,
                                    );
                                showSuccessToast(context,
                                    message: S.of(context).stateSnapshotSaved);
                              },
                            ),
                          ),
                        ],
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
