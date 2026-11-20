import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state_with_pulse.dart';
import '../../../../components/lists/stable_list_view.dart';
import '../../../../components/misc/jump_to_latest_fab.dart';
import '../../../../core/routes/listen_while_shown.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/scroll/position_retained_scroll_physics.dart';
import '../../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../../server/providers/server_providers.dart';
import '../../../console/presentation/empty/no_match_state.dart';
import '../../provider/storage_providers.dart';
import '../detail/detail_panel.dart';
import '../event_row/storage_entry_tile.dart';
import '../header/storage_tab_bar.dart';
import '../header/toolbar.dart';
import '../key_value/storage_key_value_panel.dart';
import '../shared/storage_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════
/// Storage Viewer Page — streaming list of storage operations with
/// optional right-pane detail panel. Composes [Toolbar] (top) + a
/// `StableBuilderDelegate` list of [StorageEntryTile]s inside a
/// `JumpToLatestFab`-decorated Stack.
/// ═══════════════════════════════════════════════════════════════════

class StorageViewerPage extends ConsumerStatefulWidget {
  const StorageViewerPage({super.key});

  @override
  ConsumerState<StorageViewerPage> createState() => _StorageViewerPageState();
}

class _StorageViewerPageState extends ConsumerState<StorageViewerPage>
    with ListenWhileShown {
  final ScrollController _scrollController = SmoothScrollController();
  final _entryCount = ValueNotifier<int>(0);

  /// The key filter's text, kept here so it survives tab switches.
  final _search = TextEditingController();

  /// Operations that arrived in the last update, which glow.
  Set<String> _fresh = const {};
  bool _autoScroll = true;
  bool _programmaticScroll = false;
  int _visibleCount = 0;
  int _generation = 0;
  final List<StorageEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    listenWhileShown(
      filteredStorageEntriesProvider,
      (previous, next) {
        // Storage has in-place updates (value changes for existing key).
        // Always full sync to ensure tiles reflect latest data.
        final grew = next.length > _entries.length;
        final shrunk = next.length < _entries.length;
        final known = {for (final e in _entries) e.id};
        _fresh = previous == null || !grew
            ? const {}
            : {for (final e in next) if (!known.contains(e.id)) e.id};
        _entries..clear()..addAll(next);
        _entryCount.value = _entries.length;
        if (grew || shrunk || _autoScroll) _visibleCount = _entries.length;
        _generation++;
        setState(() {});
        if (_autoScroll) _autoScrollIfNeeded();
      },
    );
    // Selection changes must also bump generation — StableBuilderDelegate
    // short-circuits shouldRebuild when generation is unchanged, which
    // would otherwise leave tile decorations (selected bg, accent border)
    // stuck on the previously-selected item.
    ref.listenManual<String?>(
      selectedStorageIdProvider,
      (_, _) {
        _generation++;
        setState(() {});
      },
      fireImmediately: false,
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
    final theme = Theme.of(context);
    final scrollDir = ref.watch(scrollDirectionProvider);
    final isReversed = scrollDir == ScrollDirection.top;

    // History of operations | the stores' live contents, editable.
    return DefaultTabController(
      length: 2,
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
          const StorageTabBar(),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _history(theme, isReversed),
                const StorageKeyValuePanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ways out of an empty history whose operations the filters hide: each
  /// drops one filter and says how many operations it brings back.
  List<NoMatchFix> _fixes() {
    final loc = S.of(context);
    final all = ref.watch(storageDisplayProvider).items;
    final device = ref.watch(selectedDeviceProvider);
    final hiddenOps = ref.watch(storageHiddenOpsProvider);
    final types = ref.watch(storageTypeFilterProvider);
    final search = ref.watch(storageSearchProvider).toLowerCase();
    final mine = [for (final e in all) if (storageOnDevice(e, device)) e];
    bool opOk(StorageEntry e) => !hiddenOps.contains(e.operation.toLowerCase());
    bool typeOk(StorageEntry e) => types.contains(e.storageType);
    final withAllOps = mine
        .where((e) => typeOk(e) && storageMatchesSearch(e, search))
        .length;
    final withAllTypes = mine
        .where((e) => opOk(e) && storageMatchesSearch(e, search))
        .length;
    final withoutSearch = mine.where((e) => opOk(e) && typeOk(e)).length;
    final hiddenTypes = {
      for (final e in mine)
        if (!typeOk(e)) storageTypeName(e.storageType),
    };
    String drops(Iterable<String> names) => names.length <= 2
        ? names.join(' · ')
        : '${names.first} +${names.length - 1}';
    void showAllOps() => ref.read(storageHiddenOpsProvider.notifier).set({});
    void showAllTypes() => ref
        .read(storageTypeFilterProvider.notifier)
        .set(StorageType.values.toSet());
    void clearSearch() {
      _search.clear();
      ref.read(storageSearchProvider.notifier).set('');
    }

    return [
      if (hiddenOps.isNotEmpty && withAllOps > 0)
        (
          drops: drops(hiddenOps.map((op) => op.toUpperCase())),
          label: loc.storageShowAllOps,
          count: withAllOps,
          apply: showAllOps,
        ),
      if (hiddenTypes.isNotEmpty && withAllTypes > 0)
        (
          drops: drops(hiddenTypes),
          label: loc.storageShowAllTypes,
          count: withAllTypes,
          apply: showAllTypes,
        ),
      if (search.isNotEmpty && withoutSearch > 0)
        (
          drops: '"${_search.text}"',
          label: loc.consoleClearSearch,
          count: withoutSearch,
          apply: clearSearch,
        ),
      if (withAllOps == 0 && withAllTypes == 0 && withoutSearch == 0)
        (
          drops: loc.consoleResetFilters,
          label: loc.consoleResetFilters,
          count: mine.length,
          apply: () {
            showAllOps();
            showAllTypes();
            clearSearch();
          },
        ),
    ];
  }

  Widget _history(ThemeData theme, bool isReversed) {
    final device = ref.watch(selectedDeviceProvider);
    final hasAny = _entries.isNotEmpty ||
        ref.watch(
          storageDisplayProvider.select(
            (c) => c.items.any((e) => storageOnDevice(e, device)),
          ),
        );
    return Column(
      children: [
        Expanded(
          child: _entries.isEmpty
              ? hasAny
                  ? NoMatchState(
                      title: S.of(context).storageNoMatchTitle,
                      subtitle: S.of(context).storageNoMatchSubtitle,
                      fixes: _fixes(),
                    )
                  : EmptyStateWithPulse(
                      icon: LucideIcons.database,
                      title: S.of(context).noStorageData,
                      subtitle:
                          S.of(context).storageEntriesAppearHere,
                    )
              : Stack(
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final selected = ref.watch(selectedStorageEntryProvider);
                        return Row(
                          children: [
                            // Key list
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
                                    final isSelected = selected?.id == entry.id;
                                    return RepaintBoundary(
                                      key: ValueKey(entry.id),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        child: StorageEntryTile(
                                        entry: entry,
                                        isSelected: isSelected,
                                        fresh: _fresh.contains(entry.id),
                                        onTap: () {
                                          ref
                                              .read(selectedStorageIdProvider.notifier)
                                              .set(isSelected ? null : entry.id);
                                          if (!isSelected && _autoScroll) {
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
                                child: StorageDetailPanel(
                                  // Recycle the panel state when the entry
                                  // changes — without this, Flutter reuses
                                  // the State across entries, which can
                                  // leave the GestureDetector inside the
                                  // JsonPrettyViewer's deferred subtree in
                                  // a state that captures subsequent pointer
                                  // events.
                                  key: ValueKey(selected.id),
                                  entry: selected,
                                  onClose: () => ref
                                      .read(selectedStorageIdProvider.notifier)
                                      .set(null),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
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
