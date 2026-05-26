import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../components/feedback/empty_state.dart';
import '../../../../components/inputs/search_field.dart';
import '../../../../components/lists/stable_list_view.dart';
import '../../../../components/misc/status_badge.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/screenshot_utils.dart';
import '../../../../models/log/error_event.dart';
import '../../../../server/providers/server_providers.dart';
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

  ErrorEvent? _findEntry(String? id) {
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
                  SelectableText(
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
                      child: SelectableText(
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
    final errorCount = ref.watch(errorCountProvider);
    final fatalCount = ref.watch(fatalErrorCountProvider);

    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? ColorTokens.darkSurface : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SearchField(
                  hintText: 'Search errors...',
                  onChanged: (v) => ref.read(errorSearchProvider.notifier).state = v,
                ),
              ),
              const SizedBox(width: 12),
              _buildFilterChips(),
              const SizedBox(width: 12),
              ValueListenableBuilder<int>(
                valueListenable: _entryCount,
                builder: (context, count, _) {
                  return Text(
                    '$count errors',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _autoScroll ? LucideIcons.pause : LucideIcons.play,
                  size: 16,
                ),
                onPressed: () => setState(() => _autoScroll = !_autoScroll),
                tooltip: _autoScroll ? 'Pause auto-scroll' : 'Resume auto-scroll',
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 16),
                onPressed: () => ref.read(errorEntriesProvider.notifier).clear(),
                tooltip: 'Clear errors',
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
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return _ErrorListItem(
                            entry: entry,
                            isSelected: _selectedId.value == entry.id,
                            onTap: () => _selectedId.value = entry.id,
                            onCopy: () {
                              Clipboard.setData(ClipboardData(text: entry.stackTrace ?? entry.message));
                            },
                          );
                        },
                      ),
                    ),
                    // Detail panel
                    Consumer(
                      builder: (context, ref, _) {
                        final selectedId = _selectedId.value;
                        final selected = selectedId != null
                            ? _entries.where((e) => e.id == selectedId).firstOrNull
                            : null;
                        if (selected == null) return const SizedBox.shrink();
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VerticalDivider(width: 1, color: isDark ? Colors.white10 : Colors.black12),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.4,
                              child: _ErrorDetailPanel(
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

  Widget _buildFilterChips() {
    return Row(
      children: [
        ...ErrorPlatform.values.map((platform) {
          final selected = ref.watch(errorFilterProvider).contains(platform);
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: FilterChip(
              label: Text(_platformLabel(platform)),
              selected: selected,
              onSelected: (v) {
                final current = ref.read(errorFilterProvider);
                if (v) {
                  ref.read(errorFilterProvider.notifier).state = {...current, platform};
                } else {
                  ref.read(errorFilterProvider.notifier).state = current.difference({platform});
                }
              },
              backgroundColor: _platformColor(platform).withValues(alpha: 0.1),
              selectedColor: _platformColor(platform).withValues(alpha: 0.3),
              labelStyle: TextStyle(fontSize: 11, color: _platformColor(platform)),
            ),
          );
        }),
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
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final entry = widget.entry;
    final severityColor = _severityColor(entry.severity);

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
              Text(
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
              IconButton(
                icon: const Icon(LucideIcons.camera, size: 16),
                onPressed: widget.onScreenshot,
                tooltip: 'Screenshot',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 16),
                onPressed: widget.onClose,
                tooltip: 'Close',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        // Tabs
        Container(
          decoration: BoxDecoration(
            color: isDark ? ColorTokens.darkSurface : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: 'Message'),
              Tab(text: 'Stack Trace'),
              Tab(text: 'Details'),
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
                child: SelectableText(
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
                      child: SelectableText(
                        entry.stackTrace!,
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    )
                  : const Center(
                      child: Text('No stack trace available'),
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
                      Text(
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
                        child: SelectableText(
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
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
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