import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' hide ScrollDirection;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/duration_format.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../components/feedback/empty_state.dart';
import '../../../../components/inputs/search_field.dart';
import '../../../../components/misc/status_badge.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/code_generator.dart';
import '../../../../models/network/network_entry.dart';
import '../../../../server/providers/server_providers.dart';
import '../../../../components/lists/stable_list_view.dart';
import '../../../../core/utils/position_retained_scroll_physics.dart';
import '../../provider/network_providers.dart';

// ---------------------------------------------------------------------------
// Root page
// ---------------------------------------------------------------------------

class NetworkInspectorPage extends ConsumerStatefulWidget {
  const NetworkInspectorPage({super.key});

  @override
  ConsumerState<NetworkInspectorPage> createState() =>
      _NetworkInspectorPageState();
}

class _NetworkInspectorPageState extends ConsumerState<NetworkInspectorPage> {
  final _scrollController = ScrollController();
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
        _Toolbar(
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
              ? const EmptyState(
                  icon: LucideIcons.globe,
                  title: 'No network requests',
                  subtitle: 'API calls will appear here in real-time',
                )
              : Row(
                  children: [
                    Expanded(
                      child: ListView.custom(
                        controller: _scrollController,
                        reverse: isReversed,
                        physics: isReversed ? const PositionRetainedScrollPhysics() : null,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemExtent: 62,
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
                              child: Consumer(
                                builder: (context, ref, _) {
                                  final selected = ref.watch(selectedNetworkEntryProvider);
                                  final isSelected = selected?.id == entry.id;
                                  return _RequestCard(
                                    entry: entry,
                                    isSelected: isSelected,
                                    onTap: () {
                                      ref.read(selectedNetworkIdProvider.notifier).state =
                                          isSelected ? null : entry.id;
                                      if (!isSelected && _autoScroll) {
                                        _autoScroll = false;
              _programmaticScroll = false;
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(_scrollController.offset);
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
                        final selected = ref.watch(selectedNetworkEntryProvider);
                        if (selected == null) return const SizedBox.shrink();
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VerticalDivider(width: 1, color: theme.dividerColor),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.45,
                              child: _RequestDetailPanel(
                                key: ValueKey(selected.id),
                                entry: selected,
                                onClose: () {
                                  ref.read(selectedNetworkIdProvider.notifier).state = null;
                                },
                              ),
                            ),
                          ],
                        );
                      },
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

class _Toolbar extends ConsumerWidget {
  final ValueNotifier<int> count;
  final bool autoScroll;
  final VoidCallback onToggleAutoScroll;

  const _Toolbar({
    required this.count,
    required this.autoScroll,
    required this.onToggleAutoScroll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final methodFilter = ref.watch(networkMethodFilterProvider);
    final sourceFilter = ref.watch(networkSourceFilterProvider);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
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
          // Title + count
          Icon(LucideIcons.globe, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text('Network', style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: count,
            builder: (_, c, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ColorTokens.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$c',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ColorTokens.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // ── Method segment group ──
          _SegmentGroup(
            isDark: isDark,
            children: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'].map((m) {
              final isActive = methodFilter == m;
              final color = ColorTokens.httpMethodColor(m);
              return _SegmentChip(
                label: m,
                isActive: isActive,
                color: color,
                isMono: true,
                onTap: () => ref
                    .read(networkMethodFilterProvider.notifier)
                    .state = isActive ? null : m,
              );
            }).toList(),
          ),
          const SizedBox(width: 10),

          // ── Source segment group ──
          _SegmentGroup(
            isDark: isDark,
            children: [
              _SegmentChip(
                label: 'App',
                isActive: sourceFilter.contains('app'),
                color: ColorTokens.primary,
                onTap: () => _toggleSource(ref, 'app'),
              ),
              _SegmentChip(
                label: 'Library',
                isActive: sourceFilter.contains('library'),
                color: ColorTokens.warning,
                onTap: () => _toggleSource(ref, 'library'),
              ),
              _SegmentChip(
                label: 'System',
                isActive: sourceFilter.contains('system'),
                color: Colors.grey,
                onTap: () => _toggleSource(ref, 'system'),
              ),
            ],
          ),

          const Spacer(),

          // Search
          SizedBox(
            width: 200,
            child: SearchField(
              hintText: 'Filter URLs...',
              onChanged: (v) =>
                  ref.read(networkSearchProvider.notifier).state = v,
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
                Consumer(
                  builder: (context, ref, _) {
                    final dir = ref.watch(scrollDirectionProvider);
                    final isTop = dir == ScrollDirection.top;
                    return _IconBtn(
                      icon: isTop
                          ? LucideIcons.arrowUpNarrowWide
                          : LucideIcons.arrowDownNarrowWide,
                      tooltip: isTop ? 'Newest first' : 'Oldest first',
                      isActive: isTop,
                      onTap: () => ref
                          .read(scrollDirectionProvider.notifier)
                          .state = isTop
                              ? ScrollDirection.bottom
                              : ScrollDirection.top,
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
                  tooltip: 'Clear',
                  isDanger: true,
                  onTap: () => ref.read(networkEntriesProvider.notifier).clear(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSource(WidgetRef ref, String key) {
    final current = ref.read(networkSourceFilterProvider);
    if (current.contains(key)) {
      ref.read(networkSourceFilterProvider.notifier).state =
          current.difference({key});
    } else {
      ref.read(networkSourceFilterProvider.notifier).state = {...current, key};
    }
  }
}

/// Grouped segment container with shared background — DevTools style.
class _SegmentGroup extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SegmentGroup({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// Individual segment chip inside a group.
class _SegmentChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final Color color;
  final bool isMono;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.isActive,
    required this.color,
    this.isMono = false,
    required this.onTap,
  });

  @override
  State<_SegmentChip> createState() => _SegmentChipState();
}

class _SegmentChipState extends State<_SegmentChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.color.withValues(alpha: 0.15)
                : _hovered
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 6,
                      spreadRadius: -1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: widget.isMono ? AppConstants.monoFontFamily : null,
                fontSize: 10,
                fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                color: widget.isActive
                    ? widget.color
                    : isDark
                        ? Colors.grey[500]
                        : Colors.grey[600],
                letterSpacing: widget.isMono ? 0.3 : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbar button (same style as console page)
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

// ---------------------------------------------------------------------------
// Request card tile
// ---------------------------------------------------------------------------

class _RequestCard extends ConsumerWidget {
  final NetworkEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const _RequestCard({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final time = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.startTime),
    );

    final devices = ref.watch(connectedDevicesProvider);
    final device =
        devices.where((d) => d.deviceId == entry.deviceId).firstOrNull;

    // Parse URL
    Uri? uri;
    try {
      uri = Uri.parse(entry.url);
    } catch (_) {}
    final displayUrl = uri?.path ?? entry.url;
    final host = uri?.host ?? '';

    // Left bar color based on status code
    final Color leftBarColor;
    if (!entry.isComplete) {
      leftBarColor = ColorTokens.info;
    } else if (entry.statusCode <= 0 || entry.statusCode >= 400) {
      leftBarColor = ColorTokens.error;
    } else if (entry.statusCode < 300) {
      leftBarColor = ColorTokens.success;
    } else {
      leftBarColor = ColorTokens.warning;
    }

    // Source badge color
    Color sourceColor;
    String sourceLabel;
    switch (entry.source) {
      case 'library':
        sourceColor = ColorTokens.warning;
        sourceLabel = 'LIB';
        break;
      case 'system':
        sourceColor = Colors.grey;
        sourceLabel = 'SYS';
        break;
      default:
        sourceColor = ColorTokens.primary;
        sourceLabel = 'APP';
    }

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorTokens.selectedBg(isDark)
                  : (entry.isComplete && (entry.statusCode <= 0 || entry.statusCode >= 400))
                      ? ColorTokens.error.withValues(alpha: isDark ? 0.08 : 0.05)
                      : !entry.isComplete
                          ? ColorTokens.warning.withValues(alpha: isDark ? 0.08 : 0.05)
                          : isDark
                              ? ColorTokens.darkBackground
                              : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? ColorTokens.selectedBorder(isDark)
                    : (entry.isComplete && (entry.statusCode <= 0 || entry.statusCode >= 400))
                        ? ColorTokens.error.withValues(alpha: isDark ? 0.25 : 0.2)
                        : !entry.isComplete
                            ? ColorTokens.warning.withValues(alpha: isDark ? 0.2 : 0.15)
                            : isDark
                                ? const Color(0xFF30363D)
                                : const Color(0xFFE1E4E8),
                width: 1,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Left color bar
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: leftBarColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          // Badges row (compact)
                          if (device != null) ...[
                            PlatformBadge(platform: device.platform),
                            const SizedBox(width: 4),
                          ],
                          HttpMethodBadge(method: entry.method),
                          const SizedBox(width: 4),
                          // URL + host
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  displayUrl,
                                  style: TextStyle(
                                    fontFamily: AppConstants.monoFontFamily,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: (entry.isComplete && (entry.statusCode <= 0 || entry.statusCode >= 400))
                                        ? ColorTokens.error
                                        : isDark
                                            ? ColorTokens.lightBackground
                                            : ColorTokens.darkNeutral,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    // Source badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: sourceColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        sourceLabel,
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: sourceColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    if (entry.isComplete)
                                      StatusBadge(statusCode: entry.statusCode)
                                    else ...[
                                      SizedBox(
                                        width: 10,
                                        height: 10,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: ColorTokens.warning,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'in progress',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: ColorTokens.warning,
                                          fontFamily: AppConstants.monoFontFamily,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    if (host.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          host,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[500],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Duration + timestamp
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (entry.duration != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _durationColor(entry.duration!)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    formatDuration(entry.duration!),
                                    style: TextStyle(
                                      fontFamily: AppConstants.monoFontFamily,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _durationColor(entry.duration!),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                time,
                                style: TextStyle(
                                  fontFamily: AppConstants.monoFontFamily,
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _durationColor(int ms) {
    if (ms < 200) return ColorTokens.success;
    if (ms < 500) return ColorTokens.warning;
    return ColorTokens.error;
  }
}

// ---------------------------------------------------------------------------
// Request detail panel
// ---------------------------------------------------------------------------

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
        tabs: tabs.map((t) => Tab(height: 28, text: t)).toList(),
      ),
    );
  }
}

class _RequestDetailPanel extends ConsumerStatefulWidget {
  final NetworkEntry entry;
  final VoidCallback onClose;

  const _RequestDetailPanel({
    super.key,
    required this.entry,
    required this.onClose,
  });

  @override
  ConsumerState<_RequestDetailPanel> createState() =>
      _RequestDetailPanelState();
}

class _RequestDetailPanelState extends ConsumerState<_RequestDetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      animationDuration: ref.read(tabAnimationProvider),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _rebuildController() {
    final oldIndex = _tabController.index;
    _tabController.dispose();
    _tabController = TabController(
      length: 4,
      vsync: this,
      animationDuration: ref.read(tabAnimationProvider),
      initialIndex: oldIndex,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entry = widget.entry;

    ref.listen(tabAnimationProvider, (prev, next) {
      if (prev != next) _rebuildController();
    });

    return Column(
      children: [
        // ---- Header bar ----
        Container(
          color: isDark ? ColorTokens.darkBackground : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Method + status + URL + screenshot buttons + close
              Padding(
                padding:
                    const EdgeInsets.only(left: 12, right: 4, top: 8, bottom: 4),
                child: Row(
                  children: [
                    HttpMethodBadge(method: entry.method),
                    const SizedBox(width: 6),
                    if (entry.isComplete) ...[
                      StatusBadge(statusCode: entry.statusCode),
                      const SizedBox(width: 8),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ColorTokens.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
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
                            Text(
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
                        child: Text(
                          entry.url,
                          style: TextStyle(
                            fontFamily: AppConstants.monoFontFamily,
                            fontSize: 12,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Screenshot buttons
                    Tooltip(
                      message: 'Capture full detail as image',
                      waitDuration: const Duration(milliseconds: 400),
                      child: _HeaderIconButton(
                        icon: LucideIcons.camera,
                        tooltip: 'Full',
                        onPressed: _takeFullScreenshot,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Tooltip(
                      message: 'Capture current tab only',
                      waitDuration: const Duration(milliseconds: 400),
                      child: _HeaderIconButton(
                        icon: LucideIcons.scanLine,
                        tooltip: 'Tab',
                        onPressed: _takeTabScreenshot,
                      ),
                    ),
                    const SizedBox(width: 2),
                    // Close button
                    _HeaderIconButton(
                      icon: LucideIcons.x,
                      tooltip: 'Close',
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),

              // Timing bar
              if (entry.duration != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _TimingBar(duration: entry.duration!),
                ),

              const SizedBox(height: 6),

              // Copy actions row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _CopyActionChip(
                      icon: LucideIcons.link,
                      label: 'Copy URL',
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: entry.url));
                        _showCopied('URL copied');
                      },
                    ),
                    const SizedBox(width: 6),
                    _CopyActionChip(
                      icon: LucideIcons.terminal,
                      label: 'Copy cURL',
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: _buildCurl(entry)));
                        _showCopied('cURL copied');
                      },
                    ),
                    const SizedBox(width: 6),
                    _CopyActionChip(
                      icon: LucideIcons.upload,
                      label: 'Copy Request',
                      onTap: () {
                        final body = entry.requestBody;
                        final text = body is String
                            ? body
                            : (body != null
                                ? const JsonEncoder.withIndent('  ')
                                    .convert(body)
                                : '');
                        Clipboard.setData(ClipboardData(text: text));
                        _showCopied('Request copied');
                      },
                    ),
                    const SizedBox(width: 6),
                    _CopyActionChip(
                      icon: LucideIcons.download,
                      label: 'Copy Response',
                      onTap: () {
                        final body = entry.responseBody;
                        final text = body is String
                            ? body
                            : (body != null
                                ? const JsonEncoder.withIndent('  ')
                                    .convert(body)
                                : '');
                        Clipboard.setData(ClipboardData(text: text));
                        _showCopied('Response copied');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Tabs
              _DetailTabBar(
                controller: _tabController,
                isDark: isDark,
                accentColor: ColorTokens.primary,
                tabs: const ['Headers', 'Request', 'Response', 'Timing'],
              ),
            ],
          ),
        ),

        // ---- Tab views ----
        Expanded(
          child: Container(
            color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
            child: TabBarView(
              controller: _tabController,
              children: [
                _HeadersTab(entry: entry),
                _BodyTab(
                  body: entry.requestBody,
                  label: 'Request Body',
                  deviceId: entry.deviceId,
                ),
                _BodyTab(
                  body: entry.responseBody,
                  label: 'Response Body',
                  deviceId: entry.deviceId,
                ),
                _TimingTab(entry: entry),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---- Screenshot ----

  Future<void> _captureAndSave(Widget screenshotWidget) async {
    try {
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
      await Future.delayed(const Duration(milliseconds: 300));

      final boundary = overlayKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        overlayEntry.remove();
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      overlayEntry.remove();

      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final fileName =
          'devconnect_network_${DateTime.now().millisecondsSinceEpoch}.png';
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Screenshot failed: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Screenshot saved',
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
                                Text(
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
                          GestureDetector(
                            onTap: () {
                              entry.remove();
                              Process.run('open', ['-R', path]);
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
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
                                    Text(
                                      'Reveal',
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
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => entry.remove(),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
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

  Future<void> _takeFullScreenshot() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    await _captureAndSave(_buildFullScreenshotWidget(isDark));
  }

  Future<void> _takeTabScreenshot() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    await _captureAndSave(
        _buildTabScreenshotWidget(isDark, _tabController.index));
  }

  Widget _buildFullScreenshotWidget(bool isDark) {
    final entry = widget.entry;
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.startTime),
    );

    dynamic parsedReqBody = entry.requestBody;
    if (parsedReqBody is String) {
      try { parsedReqBody = jsonDecode(parsedReqBody); } catch (_) {}
    }
    dynamic parsedResBody = entry.responseBody;
    if (parsedResBody is String) {
      try { parsedResBody = jsonDecode(parsedResBody); } catch (_) {}
    }

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HttpMethodBadge(method: entry.method),
                    const SizedBox(width: 6),
                    if (entry.isComplete)
                      StatusBadge(statusCode: entry.statusCode),
                    const Spacer(),
                    Text(time,
                        style: TextStyle(
                            fontSize: 10,
                            fontFamily: AppConstants.monoFontFamily,
                            color: Colors.grey[500])),
                  ],
                ),
                const SizedBox(height: 6),
                Text(entry.url,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 11,
                      color: (entry.isComplete &&
                              (entry.statusCode <= 0 ||
                                  entry.statusCode >= 400))
                          ? ColorTokens.error
                          : isDark
                              ? ColorTokens.lightBackground
                              : ColorTokens.darkNeutral,
                    )),
                if (entry.duration != null) ...[
                  const SizedBox(height: 6),
                  _TimingBar(duration: entry.duration!),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // Headers section
          _screenshotSection('Request Headers', isDark),
          ...entry.requestHeaders.entries.map((e) =>
              _screenshotHeaderRow(e.key, e.value, isDark)),
          if (entry.responseHeaders.isNotEmpty) ...[
            _screenshotSection('Response Headers', isDark),
            ...entry.responseHeaders.entries.map((e) =>
                _screenshotHeaderRow(e.key, e.value, isDark)),
          ],
          // Request body
          if (parsedReqBody != null) ...[
            _screenshotSection('Request Body', isDark),
            Padding(
              padding: const EdgeInsets.all(12),
              child: parsedReqBody is Map || parsedReqBody is List
                  ? JsonViewer(data: parsedReqBody, initiallyExpanded: true)
                  : JsonPrettyViewer(data: parsedReqBody),
            ),
          ],
          // Response body
          if (parsedResBody != null) ...[
            _screenshotSection('Response Body', isDark),
            Padding(
              padding: const EdgeInsets.all(12),
              child: parsedResBody is Map || parsedResBody is List
                  ? JsonViewer(data: parsedResBody, initiallyExpanded: true)
                  : JsonPrettyViewer(data: parsedResBody),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabScreenshotWidget(bool isDark, int tabIndex) {
    final entry = widget.entry;
    final tabNames = ['Headers', 'Request', 'Response', 'Timing'];

    Widget tabContent;
    switch (tabIndex) {
      case 0: // Headers
        tabContent = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _screenshotSection('Request Headers', isDark),
            ...entry.requestHeaders.entries.map((e) =>
                _screenshotHeaderRow(e.key, e.value, isDark)),
            if (entry.responseHeaders.isNotEmpty) ...[
              _screenshotSection('Response Headers', isDark),
              ...entry.responseHeaders.entries.map((e) =>
                  _screenshotHeaderRow(e.key, e.value, isDark)),
            ],
          ],
        );
        break;
      case 1: // Request body
        tabContent = _buildBodyScreenshot(
            entry.requestBody, 'Request Body', isDark);
        break;
      case 2: // Response body
        tabContent = _buildBodyScreenshot(
            entry.responseBody, 'Response Body', isDark);
        break;
      case 3: // Timing
      default:
        tabContent = Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.duration != null) ...[
                Text('Duration: ${formatDuration(entry.duration!)}',
                    style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 8),
                _TimingBar(duration: entry.duration!),
              ],
              const SizedBox(height: 8),
              Text(
                  'Start: ${DateFormat('HH:mm:ss.SSS').format(DateTime.fromMillisecondsSinceEpoch(entry.startTime))}',
                  style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 11,
                      color: Colors.grey[500])),
              if (entry.endTime != null)
                Text(
                    'End: ${DateFormat('HH:mm:ss.SSS').format(DateTime.fromMillisecondsSinceEpoch(entry.endTime!))}',
                    style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 11,
                        color: Colors.grey[500])),
            ],
          ),
        );
        break;
    }

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini header
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            child: Row(
              children: [
                HttpMethodBadge(method: entry.method),
                const SizedBox(width: 6),
                if (entry.isComplete)
                  StatusBadge(statusCode: entry.statusCode),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(entry.url,
                      style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 11,
                        color: isDark
                            ? ColorTokens.lightBackground
                            : ColorTokens.darkNeutral,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorTokens.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(tabNames[tabIndex],
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: ColorTokens.primary)),
                ),
              ],
            ),
          ),
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
        child: Text('No $label',
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      );
    }
    dynamic parsed = body;
    if (parsed is String) {
      try { parsed = jsonDecode(parsed); } catch (_) {}
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: parsed is Map || parsed is List
          ? JsonViewer(data: parsed, initiallyExpanded: true)
          : JsonPrettyViewer(data: parsed),
    );
  }

  Widget _screenshotSection(String title, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: isDark ? const Color(0xFF1C2128) : const Color(0xFFEEF0F2),
      child: Text(title,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87)),
    );
  }

  Widget _screenshotHeaderRow(String key, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(key,
                style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF9CDCFE)
                        : const Color(0xFF0451A5))),
          ),
          Expanded(
            child: Text(value,
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

  void _showCopied(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 180,
      ),
    );
  }

  String _buildCurl(NetworkEntry entry) {
    final buf = StringBuffer("curl -X ${entry.method} '${entry.url}'");
    entry.requestHeaders.forEach((k, v) {
      buf.write(" \\\n  -H '$k: $v'");
    });
    if (entry.requestBody != null) {
      final body = entry.requestBody is String
          ? entry.requestBody as String
          : const JsonEncoder().convert(entry.requestBody);
      buf.write(" \\\n  -d '$body'");
    }
    return buf.toString();
  }
}

// ---------------------------------------------------------------------------
// Copy action chip (small button used in detail header)
// ---------------------------------------------------------------------------

class _CopyActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CopyActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF21262D)
                : const Color(0xFFEEF0F2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF30363D)
                  : const Color(0xFFD0D7DE),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header icon button (close, etc.)
// ---------------------------------------------------------------------------

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey.withValues(alpha: 0.1),
            ),
            child: Icon(icon, size: 14, color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timing bar
// ---------------------------------------------------------------------------

class _TimingBar extends StatelessWidget {
  final int duration;

  const _TimingBar({required this.duration});

  @override
  Widget build(BuildContext context) {
    const maxWidth = 300.0;
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
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: barColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatDuration(duration),
          style: TextStyle(
            fontFamily: AppConstants.monoFontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: barColor,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Headers tab
// ---------------------------------------------------------------------------

class _HeadersTab extends StatelessWidget {
  final NetworkEntry entry;

  const _HeadersTab({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
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
                Text(
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
                  child: Text(
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
          if (headers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No headers',
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
                child: _HeaderRowWithCopy(
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

class _HeaderRowWithCopy extends StatefulWidget {
  final String headerKey;
  final String headerValue;
  final bool isDark;

  const _HeaderRowWithCopy({
    required this.headerKey,
    required this.headerValue,
    required this.isDark,
  });

  @override
  State<_HeaderRowWithCopy> createState() => _HeaderRowWithCopyState();
}

class _HeaderRowWithCopyState extends State<_HeaderRowWithCopy> {
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
            width: 180,
            child: SelectableText(
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
                  SelectableText(widget.headerValue, style: valueStyle)
                else
                  Text(
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
                        child: Text(
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
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    _copied ? LucideIcons.check : LucideIcons.copy,
                    size: 12,
                    color: _copied
                        ? ColorTokens.success
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

// ---------------------------------------------------------------------------
// Body tab (request / response)
// ---------------------------------------------------------------------------

class _BodyTab extends ConsumerStatefulWidget {
  final dynamic body;
  final String label;
  final String deviceId;

  const _BodyTab({
    required this.body,
    required this.label,
    required this.deviceId,
  });

  @override
  ConsumerState<_BodyTab> createState() => _BodyTabState();
}

class _BodyTabState extends ConsumerState<_BodyTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewMode = ref.watch(bodyViewModeProvider);

    if (widget.body == null) {
      return EmptyState(
        icon: LucideIcons.fileText,
        title: 'No ${widget.label}',
      );
    }

    // Try to parse string body as JSON
    dynamic parsedBody = widget.body;
    if (parsedBody is String) {
      try {
        parsedBody = jsonDecode(parsedBody);
      } catch (_) {
        // Not valid JSON, keep as string
      }
    }

    final canToggle = parsedBody is Map || parsedBody is List;
    // When the body is a primitive string, Tree mode can't show anything
    // structured so we implicitly fall back to JSON mode.
    final effectiveMode = canToggle ? viewMode : BodyViewMode.json;

    // Look up the connected device's platform so Code mode exports the
    // right language. Falls back to TypeScript (RN) when not connected.
    final devices = ref.watch(connectedDevicesProvider);
    final platform = devices
            .where((d) => d.deviceId == widget.deviceId)
            .map((d) => d.platform)
            .firstOrNull ??
        'react_native';
    final codeLang = CodeGenerator.langForPlatform(platform);

    return Column(
      children: [
        // Toggle bar — 3-way Tree / JSON / Code segmented toggle
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
              Text(widget.label, style: theme.textTheme.titleSmall),
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
              const SizedBox(width: 8),
              // Copy body button
              GestureDetector(
                onTap: () {
                  final text = parsedBody is String
                      ? parsedBody
                      : const JsonEncoder.withIndent('  ')
                          .convert(parsedBody);
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.label} copied'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      width: 180,
                    ),
                  );
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(LucideIcons.copy,
                      size: 14, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
        ),
        // Body content
        Expanded(
          child: SingleChildScrollView(
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
  }

  Widget _buildContent({
    required dynamic parsedBody,
    required bool canToggle,
    required BodyViewMode mode,
    required CodeLang codeLang,
  }) {
    if (!canToggle) {
      // Primitive / non-JSON body: only the pretty JSON viewer is meaningful.
      return JsonPrettyViewer(data: parsedBody);
    }
    switch (mode) {
      case BodyViewMode.tree:
        return JsonViewer(data: parsedBody, initiallyExpanded: true);
      case BodyViewMode.json:
        return JsonPrettyViewer(data: parsedBody);
      case BodyViewMode.code:
        final generated = CodeGenerator.generate(parsedBody, codeLang);
        return CodeViewer(
          generated: generated,
          lang: codeLang,
          languageLabel: CodeGenerator.labelFor(codeLang),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Timing tab
// ---------------------------------------------------------------------------

class _TimingTab extends StatelessWidget {
  final NetworkEntry entry;

  const _TimingTab({required this.entry});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      Text(
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
                      Text(
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
          // Timeline card
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
          if (entry.error != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorTokens.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: ColorTokens.error.withValues(alpha: 0.15)),
              ),
              child: SelectableText(
                entry.error!,
                style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
                  fontSize: 11,
                  color: ColorTokens.error.withValues(alpha: 0.9),
                  height: 1.5,
                ),
              ),
            ),
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
      child: Column(children: children),
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
            child: Text(
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
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (subtitle != null)
                  Text(
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
    const startAngle = 2.356;
    const sweepTotal = 4.712;

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
