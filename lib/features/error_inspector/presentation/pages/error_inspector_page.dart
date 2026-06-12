import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/text/text_component.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../components/feedback/empty_state.dart';
import '../../../../components/inputs/search_field.dart';
import '../../../../components/lists/stable_list_view.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/screenshot_utils.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../models/log/error_event.dart';
import '../../provider/error_providers.dart';

Color _severityColor(ErrorSeverity severity) {
  switch (severity) {
    case ErrorSeverity.fatal:
      return Colors.red.shade900;
    case ErrorSeverity.crash:
      return Colors.red;
    case ErrorSeverity.error:
      return ColorTokens.logError;
    case ErrorSeverity.warning:
      return ColorTokens.logWarn;
    case ErrorSeverity.info:
      return ColorTokens.logInfo;
  }
}

String _platformLabel(ErrorPlatform platform) {
  switch (platform) {
    case ErrorPlatform.js: return 'JS';
    case ErrorPlatform.native: return 'Native';
    case ErrorPlatform.android: return 'Android';
    case ErrorPlatform.ios: return 'iOS';
  }
}

Color _platformColor(ErrorPlatform platform) {
  switch (platform) {
    case ErrorPlatform.js: return Colors.blue;
    case ErrorPlatform.native: return Colors.purple;
    case ErrorPlatform.android: return Colors.green;
    case ErrorPlatform.ios: return Colors.orange;
  }
}

class ErrorInspectorPage extends ConsumerStatefulWidget {
  const ErrorInspectorPage({super.key});

  @override
  ConsumerState<ErrorInspectorPage> createState() => _ErrorInspectorPageState();
}

class _ErrorInspectorPageState extends ConsumerState<ErrorInspectorPage> {
  final _scrollController = ScrollController();
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
    _selectedId.dispose();
    _entryCount.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _takeDetailScreenshot(BuildContext context, ErrorEvent entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _severityColor(entry.severity);
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? ColorTokens.darkBackground : ColorTokens.lightSurface,
              child: Row(
                children: [
                  Icon(LucideIcons.alertTriangle, size: 16, color: color),
                  const SizedBox(width: 8),
                  _SeverityBadge(severity: entry.severity),
                  const SizedBox(width: 10),
                  _PlatformBadge(platform: entry.platform),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.message,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (entry.stackTrace != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Stack Trace',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.stackTrace!,
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final errorCount = ref.watch(errorCountProvider);
    final fatalCount = ref.watch(fatalErrorCountProvider);
    final activeFilters = ref.watch(errorFilterProvider);

    return Column(
      children: [
        // Header bar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
          ),
          child: Row(
            children: [
              // Title section
              Icon(LucideIcons.alertTriangle, size: 16, color: ColorTokens.logError),
              const SizedBox(width: 8),
              Text('Errors', style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              ValueListenableBuilder<int>(
                valueListenable: _entryCount,
                builder: (context, count, _) => _CountPill(count: count),
              ),
              const SizedBox(width: 16),

              // Platform filter chips
              ...ErrorPlatform.values.map((platform) {
                final isActive = activeFilters.contains(platform);
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _PlatformFilterChip(
                    label: _platformLabel(platform),
                    isActive: isActive,
                    color: _platformColor(platform),
                    onTap: () {
                      final current = ref.read(errorFilterProvider);
                      if (isActive) {
                        ref.read(errorFilterProvider.notifier).state =
                            current.difference({platform});
                      } else {
                        ref.read(errorFilterProvider.notifier).state = {
                          ...current,
                          platform,
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
                  hintText: 'Search errors...',
                  controller: _searchController,
                  onClear: () {
                    _searchController.clear();
                    ref.read(errorSearchProvider.notifier).state = '';
                  },
                  onChanged: (v) => ref.read(errorSearchProvider.notifier).state = v,
                ),
              ),
              const SizedBox(width: 12),

              // Action group
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
                      tooltip: _autoScroll ? 'Auto-scroll' : 'Pause',
                      isActive: _autoScroll,
                      onTap: () => setState(() => _autoScroll = !_autoScroll),
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
                          onTap: () => ref.read(scrollDirectionProvider.notifier).state =
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
                      tooltip: 'Clear errors',
                      isDanger: true,
                      onTap: () => ref.read(errorEntriesProvider.notifier).clear(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Summary cards
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _SummaryCard(
                label: 'Total Errors',
                value: errorCount.toString(),
                icon: LucideIcons.alertTriangle,
                color: ColorTokens.logError,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                label: 'Fatal/Crash',
                value: fatalCount.toString(),
                icon: LucideIcons.skull,
                color: Colors.red,
              ),
              const SizedBox(width: 12),
              _buildPlatformCounts(),
            ],
          ),
        ),
        // Error list + detail panel
        Expanded(
          child: _entries.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.checkCircle,
                  title: 'No errors captured',
                  subtitle: 'Errors from React Native and Flutter will appear here',
                )
              : Row(
                  children: [
                    Expanded(
                      child: StableListView<ErrorEvent>(
                        controller: _scrollController,
                        reverse: ref.read(scrollDirectionProvider) == ScrollDirection.top,
                        generation: _generation,
                        childCount: _visibleCount,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        entries: _entries,
                        itemExtent: 80,
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
                          return _ErrorListItem(
                            entry: entry,
                            isSelected: _selectedId.value == entry.id,
                            onTap: () {
                              final wasSelected = _selectedId.value == entry.id;
                              _selectedId.value = wasSelected ? null : entry.id;
                            },
                            onCopy: () {
                              Clipboard.setData(ClipboardData(text: entry.stackTrace ?? entry.message));
                              showCopiedToast(context, label: 'Stack trace copied');
                            },
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
                    // Detail panel
                    ValueListenableBuilder<String?>(
                      valueListenable: _selectedId,
                      builder: (context, selectedIdValue, _) {
                        final selected = selectedIdValue != null
                            ? _entries.where((e) => e.id == selectedIdValue).firstOrNull
                            : null;
                        if (selected == null) return const SizedBox.shrink();
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VerticalDivider(width: 1, color: isDark ? Colors.white10 : Colors.black12),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.35,
                              child: _ErrorDetailPanel(
                                key: ValueKey(selected.id),
                                entry: selected,
                                onClose: () => _selectedId.value = null,
                                onScreenshot: () => _takeDetailScreenshot(context, selected),
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

  Widget _buildPlatformCounts() {
    final counts = ref.watch(errorCountByPlatformProvider);
    return Row(
      children: [
        _CountChip(label: 'JS', count: counts[ErrorPlatform.js] ?? 0, color: Colors.blue),
        const SizedBox(width: 8),
        _CountChip(label: 'Native', count: counts[ErrorPlatform.native] ?? 0, color: Colors.purple),
        const SizedBox(width: 8),
        _CountChip(label: 'Android', count: counts[ErrorPlatform.android] ?? 0, color: Colors.green),
        const SizedBox(width: 8),
        _CountChip(label: 'iOS', count: counts[ErrorPlatform.ios] ?? 0, color: Colors.orange),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Count Pill
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
// Platform filter chip
// ---------------------------------------------------------------------------

class _PlatformFilterChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _PlatformFilterChip({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PlatformFilterChip> createState() => _PlatformFilterChipState();
}

class _PlatformFilterChipState extends State<_PlatformFilterChip> {
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
      message: '${widget.isActive ? "Hide" : "Show"} ${widget.label} errors',
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: widget.color,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Icon Button
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final ErrorSeverity severity;

  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        severity.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  final ErrorPlatform platform;

  const _PlatformBadge({required this.platform});

  @override
  Widget build(BuildContext context) {
    final color = _platformColor(platform);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _platformLabel(platform),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ErrorListItem extends StatelessWidget {
  final ErrorEvent entry;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const _ErrorListItem({
    required this.entry,
    required this.isSelected,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final severityColor = _severityColor(entry.severity);
    final time = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))
              : null,
          border: Border(
            left: BorderSide(
              color: severityColor,
              width: 3,
            ),
            bottom: BorderSide(
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity & Platform
            Column(
              children: [
                _SeverityBadge(severity: entry.severity),
                const SizedBox(height: 4),
                _PlatformBadge(platform: entry.platform),
              ],
            ),
            const SizedBox(width: 12),
            // Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.message,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: AppConstants.monoFontFamily,
                      color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.stackTrace != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.stackTrace!.split('\n').first,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: AppConstants.monoFontFamily,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Time & Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: AppConstants.monoFontFamily,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.copy, size: 14),
                      onPressed: onCopy,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Copy',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error Detail Panel
// ---------------------------------------------------------------------------

class _ErrorDetailPanel extends ConsumerStatefulWidget {
  final ErrorEvent entry;
  final VoidCallback onClose;
  final VoidCallback onScreenshot;

  const _ErrorDetailPanel({
    super.key,
    required this.entry,
    required this.onClose,
    required this.onScreenshot,
  });

  @override
  ConsumerState<_ErrorDetailPanel> createState() => _ErrorDetailPanelState();
}

class _ErrorDetailPanelState extends ConsumerState<_ErrorDetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
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
      length: 3,
      vsync: this,
      animationDuration: ref.read(tabAnimationProvider),
      initialIndex: oldIndex,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entry = widget.entry;
    final severityColor = _severityColor(entry.severity);

    ref.listen(tabAnimationProvider, (prev, next) {
      if (prev != next) _rebuildController();
    });

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.alertTriangle, size: 16, color: severityColor),
              const SizedBox(width: 8),
              _SeverityBadge(severity: entry.severity),
              const SizedBox(width: 8),
              _PlatformBadge(platform: entry.platform),
              const SizedBox(width: 8),
              TextComponent(
                DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
                  DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
                ),
                style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              const Spacer(),
              Tooltip(
                message: 'Capture full detail as image',
                waitDuration: const Duration(milliseconds: 400),
                child: GestureDetector(
                  onTap: _takeFullScreenshot,
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
              const SizedBox(width: 2),
              Tooltip(
                message: 'Capture current tab only',
                waitDuration: const Duration(milliseconds: 400),
                child: GestureDetector(
                  onTap: _takeTabScreenshot,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        LucideIcons.scanLine,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: 'Close panel',
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
        // Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            labelColor: ColorTokens.primary,
            unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark
                    ? ColorTokens.primary.withValues(alpha: 0.25)
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
            tabs: const [
              Tab(height: 28, text: 'Message'),
              Tab(height: 28, text: 'Stack Trace'),
              Tab(height: 28, text: 'Details'),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Message tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: TextComponent(
                  entry.message,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              // Stack trace tab
              entry.stackTrace != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: TextComponent(
                        entry.stackTrace!,
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    )
                  : const Center(
                      child: TextComponent('No stack trace available'),
                    ),
              // Details tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(label: 'Platform', value: entry.platform.name),
                    _DetailRow(label: 'Severity', value: entry.severity.name),
                    _DetailRow(label: 'Source', value: entry.source ?? 'unknown'),
                    _DetailRow(label: 'Device ID', value: entry.deviceId),
                    _DetailRow(label: 'Device Info', value: entry.deviceInfo ?? 'unknown'),
                    if (entry.metadata != null) ...[
                      const SizedBox(height: 12),
                      TextComponent(
                        'Metadata',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextComponent(
                          entry.metadata.toString(),
                          style: TextStyle(
                            fontFamily: AppConstants.monoFontFamily,
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Screenshot ----

  Future<void> _takeFullScreenshot() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await captureWidgetAsImage(
      context,
      _buildFullScreenshotWidget(isDark),
    );
  }

  Future<void> _takeTabScreenshot() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await captureWidgetAsImage(
      context,
      _buildTabScreenshotWidget(isDark, _tabController.index),
    );
  }

  Widget _buildFullScreenshotWidget(bool isDark) {
    final entry = widget.entry;
    final severityColor = _severityColor(entry.severity);
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    return Container(
      color: isDark ? ColorTokens.darkSurface : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, size: 16, color: severityColor),
                const SizedBox(width: 8),
                _SeverityBadge(severity: entry.severity),
                const SizedBox(width: 8),
                _PlatformBadge(platform: entry.platform),
                const SizedBox(width: 8),
                TextComponent(
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
          // Message section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextComponent(
                  'Message',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? ColorTokens.darkBackground : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: TextComponent(
                    entry.message,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 12,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Stack trace section
          if (entry.stackTrace != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextComponent(
                    'Stack Trace',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: severityColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: TextComponent(
                      entry.stackTrace!,
                      style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Details section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextComponent(
                  'Details',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? ColorTokens.darkBackground : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _screenshotDetailRow('Platform', entry.platform.name, isDark),
                      _screenshotDetailRow('Severity', entry.severity.name, isDark),
                      _screenshotDetailRow('Source', entry.source ?? 'unknown', isDark),
                      _screenshotDetailRow('Device ID', entry.deviceId, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      width: 600,
    );
  }

  Widget _buildTabScreenshotWidget(bool isDark, int tabIndex) {
    final entry = widget.entry;
    final severityColor = _severityColor(entry.severity);
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    final tabLabels = ['Message', 'Stack Trace', 'Details'];
    final tabLabel = tabIndex >= 0 && tabIndex < tabLabels.length
        ? tabLabels[tabIndex]
        : 'Message';

    return Container(
      color: isDark ? ColorTokens.darkSurface : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, size: 16, color: severityColor),
                const SizedBox(width: 8),
                _SeverityBadge(severity: entry.severity),
                const SizedBox(width: 8),
                _PlatformBadge(platform: entry.platform),
                const SizedBox(width: 8),
                TextComponent(time, style: TextStyle(fontFamily: AppConstants.monoFontFamily, fontSize: 11, color: Colors.grey[500])),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorTokens.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextComponent(tabLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ColorTokens.primary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tab content
          Padding(
            padding: const EdgeInsets.all(16),
            child: tabIndex == 0
                ? TextComponent(entry.message, style: TextStyle(fontFamily: AppConstants.monoFontFamily, fontSize: 12, color: isDark ? Colors.white : Colors.black87))
                : tabIndex == 1
                    ? (entry.stackTrace != null
                        ? TextComponent(entry.stackTrace!, style: TextStyle(fontFamily: AppConstants.monoFontFamily, fontSize: 11, color: isDark ? Colors.white70 : Colors.black87))
                        : const TextComponent('No stack trace available'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _screenshotDetailRow('Platform', entry.platform.name, isDark),
                          _screenshotDetailRow('Severity', entry.severity.name, isDark),
                          _screenshotDetailRow('Source', entry.source ?? 'unknown', isDark),
                          _screenshotDetailRow('Device ID', entry.deviceId, isDark),
                        ],
                      ),
          ),
        ],
      ),
      width: 600,
    );
  }

  Widget _screenshotDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: TextComponent(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500])),
          ),
          Expanded(
            child: TextComponent(value, style: TextStyle(fontFamily: AppConstants.monoFontFamily, fontSize: 10, color: isDark ? Colors.white70 : Colors.black87)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: TextComponent(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: TextComponent(
              value,
              style: TextStyle(
                fontFamily: AppConstants.monoFontFamily,
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}