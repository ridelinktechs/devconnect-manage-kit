import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../components/feedback/empty_state.dart';
import '../../../../components/inputs/search_field.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/screenshot_utils.dart';
import '../../../../models/state/state_change.dart';
import '../../../../components/lists/stable_list_view.dart';
import '../../../../core/utils/position_retained_scroll_physics.dart';
import '../../provider/state_providers.dart';

class StateInspectorPage extends ConsumerStatefulWidget {
  const StateInspectorPage({super.key});

  @override
  ConsumerState<StateInspectorPage> createState() =>
      _StateInspectorPageState();
}

class _StateInspectorPageState extends ConsumerState<StateInspectorPage> {
  final ScrollController _scrollController = ScrollController();
  final _entryCount = ValueNotifier<int>(0);
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

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _entryCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedStateChangeProvider);
    final theme = Theme.of(context);
    final scrollDir = ref.watch(scrollDirectionProvider);
    final isReversed = scrollDir == ScrollDirection.top;

    return Column(
      children: [
        _Toolbar(
          totalCount: _entryCount,
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
              ? const EmptyState(
                  icon: LucideIcons.layers,
                  title: 'No state changes',
                  subtitle:
                      'Redux, BLoC, Riverpod, and MobX state changes appear here',
                )
              : Row(
                  children: [
                    // Timeline — full width when no selection
                    Expanded(
                      flex: 2,
                      child: ListView.custom(
                        controller: _scrollController,
                        reverse: isReversed,
                        physics: isReversed ? const PositionRetainedScrollPhysics() : null,
                        itemExtent: 44,
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
                              child: _StateChangeTile(
                                entry: entry,
                                isSelected: isSelected,
                                onTap: () {
                                  ref
                                      .read(selectedStateChangeIdProvider.notifier)
                                      .state = isSelected ? null : entry.id;
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
                            );
                          },
                        ),
                      ),
                    ),
                    if (selected != null) ...[
                      VerticalDivider(width: 1, color: theme.dividerColor),
                      Expanded(
                        flex: 3,
                        child: _StateDetailPanel(
                          entry: selected,
                          onClose: () => ref
                              .read(selectedStateChangeIdProvider.notifier)
                              .state = null,
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

class _Toolbar extends ConsumerWidget {
  final ValueNotifier<int> totalCount;
  final bool autoScroll;
  final VoidCallback onToggleAutoScroll;

  const _Toolbar({
    required this.totalCount,
    required this.autoScroll,
    required this.onToggleAutoScroll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scrollDir = ref.watch(scrollDirectionProvider);
    final isTop = scrollDir == ScrollDirection.top;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.layers, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text('State Inspector', style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: totalCount,
            builder: (_, c, __) => Text('$c changes', style: theme.textTheme.bodySmall),
          ),
          const Spacer(),
          SizedBox(
            width: 200,
            child: SearchField(
              hintText: 'Filter actions...',
              onChanged: (v) =>
                  ref.read(stateSearchProvider.notifier).state = v,
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
                _IconBtn(
                  icon: LucideIcons.arrowDownToLine,
                  tooltip: 'Auto-scroll',
                  isActive: autoScroll,
                  onTap: onToggleAutoScroll,
                ),
                const SizedBox(width: 2),
                _IconBtn(
                  icon: isTop ? LucideIcons.arrowUpNarrowWide : LucideIcons.arrowDownNarrowWide,
                  tooltip: isTop ? 'Newest at top' : 'Newest at bottom',
                  isActive: isTop,
                  onTap: () => ref.read(scrollDirectionProvider.notifier).state =
                      isTop ? ScrollDirection.bottom : ScrollDirection.top,
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
                  tooltip: 'Clear all',
                  isDanger: true,
                  onTap: () => ref.read(stateChangesProvider.notifier).clear(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateChangeTile extends StatelessWidget {
  final StateChange entry;
  final bool isSelected;
  final VoidCallback onTap;

  const _StateChangeTile({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );
    final changes = entry.diff.length;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 44,
          padding: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorTokens.selectedBg(isDark)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              left: BorderSide(
                color: isSelected
                    ? ColorTokens.selectedAccent
                    : ColorTokens.secondary,
                width: isSelected ? 3 : 2,
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              // Timestamp
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
              // State manager badge
              Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: ColorTokens.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.layers, size: 10,
                        color: ColorTokens.secondary),
                    const SizedBox(width: 3),
                    Text(
                      entry.stateManagerType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: ColorTokens.secondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Action name
              Expanded(
                child: Text(
                  entry.actionName,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    color: isDark
                        ? ColorTokens.lightBackground
                        : ColorTokens.darkNeutral,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Changes count
              if (changes > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '$changes change${changes > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontFamily: AppConstants.monoFontFamily,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StateDetailPanel extends StatefulWidget {
  final StateChange entry;
  final VoidCallback onClose;

  const _StateDetailPanel({required this.entry, required this.onClose});

  @override
  State<_StateDetailPanel> createState() => _StateDetailPanelState();
}

class _StateDetailPanelState extends State<_StateDetailPanel> {
  bool _jsonPrettyMode = false;

  StateChange get entry => widget.entry;

  void _takeScreenshot(BuildContext context, bool isDark) {
    final screenshotWidget = Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            child: Row(
              children: [
                Icon(LucideIcons.gitCommitHorizontal,
                    size: 16, color: ColorTokens.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.actionName,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Diff
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DIFF',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500],
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                if (entry.diff.isEmpty)
                  Text('No changes',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12))
                else
                  ...entry.diff.map((d) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${d.operation} ${d.path}: ${d.oldValue} → ${d.newValue}',
                          style: TextStyle(
                            fontFamily: AppConstants.monoFontFamily,
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      )),
              ],
            ),
          ),
          const Divider(height: 1),
          // Before
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BEFORE',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500],
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                JsonViewer(
                    data: entry.previousState, initiallyExpanded: false),
              ],
            ),
          ),
          const Divider(height: 1),
          // After
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AFTER',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500],
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                JsonViewer(
                    data: entry.nextState, initiallyExpanded: false),
              ],
            ),
          ),
        ],
      ),
    );
    captureWidgetAsImage(context, screenshotWidget);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(LucideIcons.gitCommitHorizontal,
                          size: 16, color: ColorTokens.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.actionName,
                          style: TextStyle(
                            fontFamily: AppConstants.monoFontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      // JSON mode toggle
                      GestureDetector(
                        onTap: () =>
                            setState(() => _jsonPrettyMode = !_jsonPrettyMode),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: _jsonPrettyMode
                                  ? ColorTokens.secondary.withValues(alpha: 0.15)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.06)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _jsonPrettyMode
                                      ? LucideIcons.braces
                                      : LucideIcons.list,
                                  size: 12,
                                  color: _jsonPrettyMode
                                      ? ColorTokens.secondary
                                      : Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _jsonPrettyMode ? 'Pretty' : 'Tree',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _jsonPrettyMode
                                        ? ColorTokens.secondary
                                        : Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Screenshot button
                      _DetailIconBtn(
                        icon: LucideIcons.camera,
                        tooltip: 'Capture as image',
                        isDark: isDark,
                        onTap: () => _takeScreenshot(context, isDark),
                      ),
                      const SizedBox(width: 4),
                      // Close button
                      _DetailIconBtn(
                        icon: LucideIcons.x,
                        tooltip: 'Close',
                        isDark: isDark,
                        onTap: widget.onClose,
                      ),
                    ],
                  ),
                ),
                _DetailTabBar(
                  isDark: isDark,
                  accentColor: ColorTokens.secondary,
                  tabs: const ['Diff', 'Before', 'After'],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Diff tab
                _DiffView(diff: entry.diff),
                // Before tab
                _StateJsonToggleView(
                  data: entry.previousState,
                  jsonMode: _jsonPrettyMode,
                ),
                // After tab
                _StateJsonToggleView(
                  data: entry.nextState,
                  jsonMode: _jsonPrettyMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateJsonToggleView extends StatefulWidget {
  final dynamic data;
  final bool jsonMode;

  const _StateJsonToggleView({
    required this.data,
    required this.jsonMode,
  });

  @override
  State<_StateJsonToggleView> createState() => _StateJsonToggleViewState();
}

class _StateJsonToggleViewState extends State<_StateJsonToggleView> {
  bool _jsonEverOpened = false;

  @override
  void didUpdateWidget(_StateJsonToggleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.jsonMode && !_jsonEverOpened) {
      _jsonEverOpened = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.jsonMode && !_jsonEverOpened) {
      _jsonEverOpened = true;
    }
    return Stack(
      children: [
        Offstage(
          offstage: widget.jsonMode,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: JsonViewer(data: widget.data, initiallyExpanded: true),
          ),
        ),
        if (_jsonEverOpened)
          Offstage(
            offstage: !widget.jsonMode,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: JsonPrettyViewer(data: widget.data),
            ),
          ),
      ],
    );
  }
}

class _DiffView extends StatelessWidget {
  final List<StateDiffEntry> diff;

  const _DiffView({required this.diff});

  @override
  Widget build(BuildContext context) {
    if (diff.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.equal,
        title: 'No changes detected',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: diff.length,
      itemBuilder: (context, index) {
        final d = diff[index];
        Color opColor;
        IconData opIcon;
        switch (d.operation) {
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
            opIcon = LucideIcons.arrowRight;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: opColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: opColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(opIcon, size: 12, color: opColor),
                  const SizedBox(width: 6),
                  Text(
                    d.path,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: opColor,
                    ),
                  ),
                ],
              ),
              if (d.oldValue != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '- ',
                      style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 11,
                        color: ColorTokens.error,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${d.oldValue}',
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 11,
                          color: ColorTokens.error.withValues(alpha: 0.8),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (d.newValue != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '+ ',
                      style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 11,
                        color: ColorTokens.success,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${d.newValue}',
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 11,
                          color: ColorTokens.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
// Detail Tab Bar (pill style)
// ═══════════════════════════════════════════════

class _DetailIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;

  const _DetailIconBtn({
    required this.icon,
    required this.tooltip,
    required this.isDark,
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            child: Icon(icon, size: 13, color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }
}

class _DetailTabBar extends StatelessWidget {
  final bool isDark;
  final Color accentColor;
  final List<String> tabs;

  const _DetailTabBar({
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
        tabs: tabs.map((t) => Tab(height: 28, text: t)).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Icon Button (28x28, hover, active, danger)
// ═══════════════════════════════════════════════

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
