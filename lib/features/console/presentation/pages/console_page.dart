import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/text/text_component.dart';
import '../../../../core/utils/log_message_summary.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../components/feedback/empty_state.dart';

import '../../../../components/inputs/search_field.dart';
import '../../../../components/lists/stable_list_view.dart';
import '../../../../components/misc/status_badge.dart';
import '../../../../components/misc/jump_to_latest_fab.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/screenshot_utils.dart';
import '../../../../models/log/log_entry.dart';
import '../../../../server/providers/server_providers.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../provider/console_providers.dart';

Color _levelColor(LogLevel level) {
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

  void _takeDetailScreenshot(BuildContext context, LogEntry entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _levelColor(entry.level);
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    captureWidgetAsImage(
      context,
      Container(
        color: isDark ? ColorTokens.darkSurface : Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? ColorTokens.darkBackground : ColorTokens.lightSurface,
              child: Row(
                children: [
                  Icon(LucideIcons.terminal, size: 16, color: ColorTokens.primary),
                  const SizedBox(width: 8),
                  LogLevelBadge(level: entry.level.name),
                  const SizedBox(width: 10),
                  Text(
                    time,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Tag
            if (entry.tag != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.of(context).tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(entry.tag!, style: TextStyle(fontFamily: AppConstants.monoFontFamily, fontSize: 10, color: Colors.grey[500])),
                    ),
                  ],
                ),
              ),
            // Message
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.of(context).message, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? ColorTokens.darkBackground : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Text(
                      entry.message,
                      style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 12,
                        height: 1.6,
                        color: isDark ? ColorTokens.lightBackground : ColorTokens.darkNeutral,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Metadata
            if (entry.metadata != null && entry.metadata!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.of(context).metadata, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? ColorTokens.darkBackground : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: JsonViewer(data: entry.metadata, initiallyExpanded: true),
                    ),
                  ],
                ),
              ),
            // Stack trace
            if (entry.stackTrace != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.of(context).stackTrace, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        entry.stackTrace!,
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 11,
                          color: color.withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      width: 600,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scrollDir = ref.watch(scrollDirectionProvider);
    final isReversed = scrollDir == ScrollDirection.top;

    return Column(
      children: [
        _ConsoleToolbar(
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
                              return _LogEntryContent(
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
                                  child: _LogDetailPanel(
                                    key: ValueKey(selected.id),
                                    entry: selected,
                                    onClose: () => _selectedId.value = null,
                                    onScreenshot: () =>
                                        _takeDetailScreenshot(context, selected),
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

// ---------------------------------------------------------------------------
// Toolbar
// ---------------------------------------------------------------------------

class _ConsoleToolbar extends ConsumerWidget {
  final ValueNotifier<int> entryCount;
  final bool autoScroll;
  final VoidCallback onToggleAutoScroll;
  final VoidCallback onClear;

  const _ConsoleToolbar({
    required this.entryCount,
    required this.autoScroll,
    required this.onToggleAutoScroll,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeFilters = ref.watch(consoleFilterProvider);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
      ),
      child: Row(
        children: [
          // Title section
          Icon(LucideIcons.terminal, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text('Console', style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: entryCount,
            builder: (_, count, __) => _CountPill(count: count),
          ),
          const SizedBox(width: 16),

          // Level filter chips
          ...LogLevel.values.map((level) {
            final isActive = activeFilters.contains(level);
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _LevelFilterChip(
                label: level.name.toUpperCase(),
                isActive: isActive,
                color: _levelColor(level),
                onTap: () {
                  final current = ref.read(consoleFilterProvider);
                  if (isActive) {
                    ref.read(consoleFilterProvider.notifier).state =
                        current.difference({level});
                  } else {
                    ref.read(consoleFilterProvider.notifier).state = {
                      ...current,
                      level,
                    };
                  }
                },
              ),
            );
          }),

          const Spacer(),

          // Search
          SizedBox(
            width: 220,
            child: SearchField(
              hintText: S.of(context).searchLogs,
              onChanged: (value) {
                ref.read(consoleSearchProvider.notifier).state = value;
              },
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
                  tooltip: S.of(context).autoScroll,
                  isActive: autoScroll,
                  onTap: onToggleAutoScroll,
                ),
                const SizedBox(width: 2),
                Consumer(
                  builder: (context, ref, _) {
                    final dir = ref.watch(scrollDirectionProvider);
                    final isTop = dir == ScrollDirection.top;
                    return _IconBtn(
                      icon: isTop
                          ? LucideIcons.arrowUpNarrowWide
                          : LucideIcons.arrowDownNarrowWide,
                      tooltip: isTop ? S.of(context).newestFirst : S.of(context).oldestFirst,
                      isActive: isTop,
                      onTap: () =>
                          ref.read(scrollDirectionProvider.notifier).state =
                              isTop ? ScrollDirection.bottom : ScrollDirection.top,
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
                  tooltip: S.of(context).clearConsole,
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

// ---------------------------------------------------------------------------
// Count pill
// ---------------------------------------------------------------------------

class _CountPill extends StatelessWidget {
  final int count;

  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
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
    );
  }
}

// ---------------------------------------------------------------------------
// Level filter chip
// ---------------------------------------------------------------------------

class _LevelFilterChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _LevelFilterChip({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  State<_LevelFilterChip> createState() => _LevelFilterChipState();
}

class _LevelFilterChipState extends State<_LevelFilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isActive
        ? widget.color.withValues(alpha: 0.15)
        : _hovered
            ? widget.color.withValues(alpha: 0.07)
            : Colors.transparent;

    final borderColor = widget.isActive
        ? widget.color.withValues(alpha: 0.4)
        : _hovered
            ? widget.color.withValues(alpha: 0.25)
            : Colors.grey.withValues(alpha: 0.2);

    return Tooltip(
      message: '${widget.isActive ? "Hide" : "Show"} ${widget.label} logs',
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: widget.isActive ? widget.color : Colors.grey[500],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Icon button (matches All Events style)
// ---------------------------------------------------------------------------

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
      iconColor = Colors.grey[500]!;
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

// ---------------------------------------------------------------------------
// Log entry card
// ---------------------------------------------------------------------------

class _LogEntryContent extends StatelessWidget {
  final LogEntry entry;
  final String? platform;

  const _LogEntryContent({
    required this.entry,
    this.platform,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _levelColor(entry.level);
    final time = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (platform != null) ...[
                        PlatformBadge(platform: platform!),
                        const SizedBox(width: 6),
                      ],
                      LogLevelBadge(level: entry.level.name),
                      if (entry.tag != null) ...[
                        const SizedBox(width: 6),
                        _TagBadge(tag: entry.tag!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summarizeLogMessage(entry.message),
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 12,
                      height: 1.4,
                      color: isDark
                          ? ColorTokens.lightBackground
                          : ColorTokens.darkNeutral,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tag badge
// ---------------------------------------------------------------------------

class _TagBadge extends StatelessWidget {
  final String tag;

  const _TagBadge({required this.tag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontFamily: AppConstants.monoFontFamily,
          fontSize: 10,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Log detail panel
// ---------------------------------------------------------------------------

class _LogDetailPanel extends StatefulWidget {
  final LogEntry entry;
  final VoidCallback onClose;
  final VoidCallback onScreenshot;

  const _LogDetailPanel({
    super.key,
    required this.entry,
    required this.onClose,
    required this.onScreenshot,
  });

  @override
  State<_LogDetailPanel> createState() => _LogDetailPanelState();
}

class _LogDetailPanelState extends State<_LogDetailPanel> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _levelColor(entry.level);
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        children: [
          // Header bar
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? ColorTokens.darkBackground : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                LogLevelBadge(level: entry.level.name),
                const SizedBox(width: 10),
                Expanded(
                  child: TextComponent(
                    time,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                // Copy button
                Tooltip(
                  message: S.of(context).copyMessage,
                  child: GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: entry.message));
                      showCopiedToast(context, label: S.of(context).logCopied);
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          LucideIcons.copy,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Screenshot button
                Tooltip(
                  message: 'Capture detail as image',
                  child: GestureDetector(
                    onTap: widget.onScreenshot,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          LucideIcons.camera,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Close button
                Tooltip(
                  message: S.of(context).closePanel,
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag
                  if (entry.tag != null) ...[
                    _SectionLabel(label: S.of(context).tag),
                    const SizedBox(height: 6),
                    _TagBadge(tag: entry.tag!),
                    const SizedBox(height: 16),
                  ],

                  // Message — with 3 view modes (Tree / JSON / Code), same
                  // pattern as the All Events detail panel.
                  _SectionLabel(label: S.of(context).message),
                  const SizedBox(height: 6),
                  _LogMessageBlock(message: entry.message, isDark: isDark),

                  // Metadata
                  if (entry.metadata != null &&
                      entry.metadata!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionLabel(label: S.of(context).metadata),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? ColorTokens.darkBackground
                            : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 1,
                        ),
                      ),
                      child: JsonViewer(data: entry.metadata),
                    ),
                  ],

                  // Stack trace
                  if (entry.stackTrace != null) ...[
                    const SizedBox(height: 20),
                    _SectionLabel(label: S.of(context).stackTrace),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: color.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: TextComponent(
                        entry.stackTrace!,
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 11,
                          color: color.withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label used in the detail panel
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return TextComponent(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Colors.grey[500],
      ),
    );
  }
}


/// 3-mode view toggle (Tree / JSON / Code) for the log message body — same
/// pattern as the All Events detail panel.
class _LogMessageBlock extends StatefulWidget {
  final String message;
  final bool isDark;

  const _LogMessageBlock({required this.message, required this.isDark});

  @override
  State<_LogMessageBlock> createState() => _LogMessageBlockState();
}

class _LogMessageBlockState extends State<_LogMessageBlock> {
  /// 0 = Tree, 1 = JSON, 2 = Code.
  int _mode = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    // Try to parse as JSON so Tree/JSON modes can render structured data.
    // If the payload isn't valid JSON, both Tree and JSON fall back to
    // the raw text — only Code mode has a guaranteed different rendering
    // (and even that is identical for non-JSON messages).
    dynamic parsed;
    try {
      parsed = jsonDecode(widget.message);
    } catch (_) {
      parsed = null;
    }
    final isJson = parsed is Map || parsed is List;

    Widget body;
    switch (_mode) {
      case 0: // Tree
        body = isJson
            ? JsonViewer(data: parsed, initiallyExpanded: true)
            : _CodeBlock(text: widget.message, isDark: isDark);
        break;
      case 1: // JSON
        body = isJson
            ? _CodeBlock(
                text: const JsonEncoder.withIndent('  ').convert(parsed),
                isDark: isDark,
              )
            : _CodeBlock(text: widget.message, isDark: isDark);
        break;
      case 2: // Code
      default:
        body = _CodeBlock(text: widget.message, isDark: isDark);
        break;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode tabs — same style as the All Events Tree/JSON toggle.
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: _DetailTabBar(
              tabs: const ['Tree', 'JSON', 'Code'],
              currentIndex: _mode,
              onSelect: (i) => setState(() => _mode = i),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: body,
          ),
        ],
      ),
    );
  }
}

/// Plain monospace text block with theme-aware colors. Used by Code mode
/// (and as the fallback for Tree/JSON when the message isn't valid JSON).
class _CodeBlock extends StatelessWidget {
  final String text;
  final bool isDark;

  const _CodeBlock({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return TextComponent(
      text,
      style: TextStyle(
        fontFamily: AppConstants.monoFontFamily,
        fontSize: 12,
        color: isDark ? ColorTokens.lightBackground : ColorTokens.darkNeutral,
        height: 1.6,
      ),
    );
  }
}

/// Compact pill-style tab bar for the message view-mode toggle. Same visual
/// pattern as `_DetailTabBar` in `all_events_page.dart` but with a
/// `currentIndex + onSelect` callback instead of a `TabController` — simpler
/// to wire up in a private widget that already manages its own state.
class _DetailTabBar extends StatelessWidget {
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _DetailTabBar({
    required this.tabs,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ColorTokens.primary;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < tabs.length; i++)
            _buildSegment(tabs[i], i, isDark, accent),
        ],
      ),
    );
  }

  Widget _buildSegment(String label, int index, bool isDark, Color accent) {
    final selected = index == currentIndex;
    return GestureDetector(
      onTap: () => onSelect(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: selected
              ? Border.all(
                  color: isDark
                      ? accent.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.06),
                )
              : Border.all(color: Colors.transparent),
          boxShadow: selected && !isDark
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.2,
            color: selected
                ? accent
                : (isDark ? Colors.grey[500] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}
