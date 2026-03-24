import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../components/inputs/search_field.dart';
import '../../../../components/misc/status_badge.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../models/log/log_entry.dart';
import '../../../../server/providers/server_providers.dart';
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
  static const _pageSize = 50;

  final _scrollController = ScrollController();
  bool _autoScroll = true;
  LogEntry? _selectedEntry;
  int _maxVisible = _pageSize;
  bool _loadingMore = false;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!_autoScroll &&
          !_loadingMore &&
          _scrollController.hasClients &&
          _scrollController.position.pixels < 50) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMore() {
    final totalEntries = ref.read(filteredConsoleEntriesProvider).length;
    if (_maxVisible >= totalEntries) return;

    _loadingMore = true;
    final oldMaxExtent = _scrollController.position.maxScrollExtent;

    setState(() {
      _maxVisible = (_maxVisible + _pageSize).clamp(0, totalEntries);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final newMaxExtent = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(
          _scrollController.position.pixels + (newMaxExtent - oldMaxExtent),
        );
      }
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(filteredConsoleEntriesProvider);
    final theme = Theme.of(context);

    // Compute visible subset for pagination
    final startIndex =
        (entries.length - _maxVisible).clamp(0, entries.length);
    final visibleEntries = entries.sublist(startIndex);
    final hasMore = startIndex > 0;

    // Auto scroll to bottom only when new items arrive
    if (_autoScroll && entries.length > _previousCount && entries.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    }
    _previousCount = entries.length;

    return Column(
      children: [
        _ConsoleToolbar(
          entryCount: entries.length,
          visibleCount:
              visibleEntries.length != entries.length
                  ? visibleEntries.length
                  : null,
          autoScroll: _autoScroll,
          onToggleAutoScroll: () {
            setState(() {
              _autoScroll = !_autoScroll;
              if (_autoScroll) _maxVisible = _pageSize;
            });
          },
          onClear: () {
            ref.read(consoleEntriesProvider.notifier).clear();
            setState(() {
              _selectedEntry = null;
              _maxVisible = _pageSize;
            });
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: entries.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.terminal,
                  title: 'No logs yet',
                  subtitle:
                      'Connect a device and start logging to see entries here',
                )
              : Row(
                  children: [
                    // Log list
                    Expanded(
                      flex: _selectedEntry != null ? 3 : 1,
                      child: Column(
                        children: [
                          if (hasMore && !_autoScroll)
                            GestureDetector(
                              onTap: _loadMore,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6),
                                  color: ColorTokens.primary
                                      .withValues(alpha: 0.05),
                                  child: Center(
                                    child: Text(
                                      '${entries.length - visibleEntries.length} older logs — tap to load more',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: ColorTokens.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6),
                              itemCount: visibleEntries.length,
                              itemExtent: 44,
                              itemBuilder: (context, index) {
                                final entry = visibleEntries[index];
                                final isSelected =
                                    _selectedEntry?.id == entry.id;
                                return _LogEntryCard(
                                  key: ValueKey(entry.id),
                                  entry: entry,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _selectedEntry =
                                          isSelected ? null : entry;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Detail panel
                    if (_selectedEntry != null) ...[
                      VerticalDivider(
                        width: 1,
                        color: theme.dividerColor,
                      ),
                      Expanded(
                        flex: 2,
                        child: _LogDetailPanel(
                          entry: _selectedEntry!,
                          onClose: () =>
                              setState(() => _selectedEntry = null),
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

// ---------------------------------------------------------------------------
// Toolbar
// ---------------------------------------------------------------------------

class _ConsoleToolbar extends ConsumerWidget {
  final int entryCount;
  final int? visibleCount;
  final bool autoScroll;
  final VoidCallback onToggleAutoScroll;
  final VoidCallback onClear;

  const _ConsoleToolbar({
    required this.entryCount,
    this.visibleCount,
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
        color: isDark ? const Color(0xFF161B22) : Colors.white,
      ),
      child: Row(
        children: [
          // Title section
          Icon(LucideIcons.terminal, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text('Console', style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          _CountPill(
            count: entryCount,
            visibleCount: visibleCount,
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
              hintText: 'Search logs...',
              onChanged: (value) {
                ref.read(consoleSearchProvider.notifier).state = value;
              },
            ),
          ),
          const SizedBox(width: 8),

          // Auto-scroll toggle
          _ToolbarIconButton(
            icon: LucideIcons.arrowDownToLine,
            tooltip: 'Auto-scroll',
            isActive: autoScroll,
            onTap: onToggleAutoScroll,
          ),
          const SizedBox(width: 4),

          // Clear
          _ToolbarIconButton(
            icon: LucideIcons.trash2,
            tooltip: 'Clear console',
            onTap: onClear,
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
  final int? visibleCount;

  const _CountPill({required this.count, this.visibleCount});

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
        visibleCount != null ? '$visibleCount / $count' : '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: 'JetBrains Mono',
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
// Toolbar icon button
// ---------------------------------------------------------------------------

class _ToolbarIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<_ToolbarIconButton> createState() => _ToolbarIconButtonState();
}

class _ToolbarIconButtonState extends State<_ToolbarIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final activeBg = ColorTokens.primary.withValues(alpha: 0.15);
    final hoverBg = Colors.grey.withValues(alpha: 0.1);

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: widget.isActive
                  ? activeBg
                  : _hovered
                      ? hoverBg
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              size: 15,
              color: widget.isActive
                  ? ColorTokens.primary
                  : Colors.grey[500],
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

class _LogEntryCard extends ConsumerStatefulWidget {
  final LogEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const _LogEntryCard({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  @override
  ConsumerState<_LogEntryCard> createState() => _LogEntryCardState();
}

class _LogEntryCardState extends ConsumerState<_LogEntryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entry = widget.entry;
    final color = _levelColor(entry.level);

    final time = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    // Lookup platform from connected devices
    final devices = ref.watch(connectedDevicesProvider);
    final device =
        devices.where((d) => d.deviceId == entry.deviceId).firstOrNull;

    final cardBg = widget.isSelected
        ? ColorTokens.primary.withValues(alpha: 0.08)
        : _hovered
            ? (isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02))
            : Colors.transparent;

    final borderColor = widget.isSelected
        ? ColorTokens.primary.withValues(alpha: 0.25)
        : _hovered
            ? (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06))
            : (isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.04));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left color bar
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
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row: badges and timestamp
                            Row(
                              children: [
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (device != null) ...[
                                  PlatformBadge(
                                      platform: device.platform),
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
                            // Message
                            Text(
                              entry.message,
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 12,
                                height: 1.4,
                                color: isDark
                                    ? const Color(0xFFE6EDF3)
                                    : const Color(0xFF1F2328),
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
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
          fontFamily: 'JetBrains Mono',
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

class _LogDetailPanel extends StatelessWidget {
  final LogEntry entry;
  final VoidCallback onClose;

  const _LogDetailPanel({
    required this.entry,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _levelColor(entry.level);
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    return Container(
      color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
      child: Column(
        children: [
          // Header bar
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
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
                  child: Text(
                    time,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                // Copy button
                Tooltip(
                  message: 'Copy message',
                  child: GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: entry.message));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          width: 180,
                        ),
                      );
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
                // Close button
                Tooltip(
                  message: 'Close panel',
                  child: GestureDetector(
                    onTap: onClose,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag
                  if (entry.tag != null) ...[
                    _SectionLabel(label: 'Tag'),
                    const SizedBox(height: 6),
                    _TagBadge(tag: entry.tag!),
                    const SizedBox(height: 16),
                  ],

                  // Message
                  _SectionLabel(label: 'Message'),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF161B22)
                          : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06),
                        width: 1,
                      ),
                    ),
                    child: SelectableText(
                      entry.message,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFFE6EDF3)
                            : const Color(0xFF1F2328),
                        height: 1.6,
                      ),
                    ),
                  ),

                  // Metadata
                  if (entry.metadata != null &&
                      entry.metadata!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionLabel(label: 'Metadata'),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF161B22)
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
                    _SectionLabel(label: 'Stack Trace'),
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
                      child: SelectableText(
                        entry.stackTrace!,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
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
    return Text(
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
