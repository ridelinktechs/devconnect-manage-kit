import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../components/inputs/search_field.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../provider/storage_providers.dart';

class StorageViewerPage extends ConsumerStatefulWidget {
  const StorageViewerPage({super.key});

  @override
  ConsumerState<StorageViewerPage> createState() => _StorageViewerPageState();
}

class _StorageViewerPageState extends ConsumerState<StorageViewerPage> {
  static const _pageSize = 50;

  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  int _maxVisible = 50;
  bool _loadingMore = false;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_autoScroll &&
        !_loadingMore &&
        _scrollController.position.pixels < 50) {
      _loadMore();
    }
  }

  void _loadMore() {
    final entries = ref.read(filteredStorageEntriesProvider);
    if (_maxVisible >= entries.length) return;

    _loadingMore = true;
    final oldMaxExtent = _scrollController.position.maxScrollExtent;

    setState(() {
      _maxVisible = (_maxVisible + _pageSize).clamp(0, entries.length);
    });

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final newMaxExtent = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(
          _scrollController.offset + (newMaxExtent - oldMaxExtent),
        );
      }
      _loadingMore = false;
    });
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleAutoScroll() {
    setState(() {
      _autoScroll = !_autoScroll;
      if (_autoScroll) {
        _maxVisible = _pageSize;
        _scrollToBottom();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(filteredStorageEntriesProvider);
    final selected = ref.watch(selectedStorageEntryProvider);
    final theme = Theme.of(context);

    final startIndex = (entries.length - _maxVisible).clamp(0, entries.length);
    final visibleEntries = entries.sublist(startIndex);
    final hasMore = startIndex > 0;

    // Auto-scroll when new items arrive and autoScroll is enabled
    if (_autoScroll && entries.length > _previousCount && entries.isNotEmpty) {
      _scrollToBottom();
    }
    _previousCount = entries.length;

    return Column(
      children: [
        _Toolbar(
          totalCount: entries.length,
          visibleCount: visibleEntries.length,
          autoScroll: _autoScroll,
          onToggleAutoScroll: _toggleAutoScroll,
        ),
        const Divider(height: 1),
        Expanded(
          child: entries.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.database,
                  title: 'No storage data',
                  subtitle:
                      'SharedPreferences, AsyncStorage, and Hive entries appear here',
                )
              : Row(
                  children: [
                    // Key list
                    SizedBox(
                      width: selected != null ? 320 : 400,
                      child: Column(
                        children: [
                          if (hasMore && !_autoScroll)
                            GestureDetector(
                              onTap: _loadMore,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  color: ColorTokens.primary
                                      .withValues(alpha: 0.05),
                                  child: Center(
                                    child: Text(
                                      '${entries.length - visibleEntries.length} older entries — tap to load more',
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
                              itemCount: visibleEntries.length,
                              itemExtent: 52,
                              itemBuilder: (context, index) {
                                final entry = visibleEntries[index];
                                final isSelected = selected?.id == entry.id;
                                return _StorageEntryTile(
                                  key: ValueKey(entry.id),
                                  entry: entry,
                                  isSelected: isSelected,
                                  onTap: () {
                                    ref
                                        .read(selectedStorageEntryProvider
                                            .notifier)
                                        .state = isSelected ? null : entry;
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected != null) ...[
                      VerticalDivider(width: 1, color: theme.dividerColor),
                      Expanded(
                        child: _StorageDetailPanel(entry: selected),
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
  final int totalCount;
  final int visibleCount;
  final bool autoScroll;
  final VoidCallback onToggleAutoScroll;

  const _Toolbar({
    required this.totalCount,
    required this.visibleCount,
    required this.autoScroll,
    required this.onToggleAutoScroll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final countText = visibleCount != totalCount
        ? '$visibleCount / $totalCount'
        : '$totalCount';

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.database, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text('Storage', style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          Text('$countText keys', style: theme.textTheme.bodySmall),
          const Spacer(),
          GestureDetector(
            onTap: onToggleAutoScroll,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: autoScroll
                      ? ColorTokens.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: autoScroll
                        ? ColorTokens.primary.withValues(alpha: 0.4)
                        : Colors.grey.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.arrowDownToLine,
                        size: 11,
                        color:
                            autoScroll ? ColorTokens.primary : Colors.grey),
                    const SizedBox(width: 4),
                    Text('AUTO',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: autoScroll
                                ? ColorTokens.primary
                                : Colors.grey,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 200,
            child: SearchField(
              hintText: 'Filter keys...',
              onChanged: (v) =>
                  ref.read(storageSearchProvider.notifier).state = v,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ref.read(storageEntriesProvider.notifier).clear(),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Icon(LucideIcons.trash2, size: 14, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageEntryTile extends StatelessWidget {
  final StorageEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const _StorageEntryTile({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color typeColor;
    String typeLabel;
    switch (entry.storageType) {
      case StorageType.asyncStorage:
        typeColor = const Color(0xFF61DAFB);
        typeLabel = 'AS';
        break;
      case StorageType.sharedPreferences:
        typeColor = const Color(0xFF3DDC84);
        typeLabel = 'SP';
        break;
      case StorageType.hive:
        typeColor = const Color(0xFFFFC107);
        typeLabel = 'HV';
        break;
      case StorageType.sqlite:
        typeColor = const Color(0xFF003B57);
        typeLabel = 'SQL';
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorTokens.primary.withValues(alpha: 0.08)
                : null,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.3),
                width: 0.5,
              ),
              left: isSelected
                  ? const BorderSide(color: ColorTokens.primary, width: 2)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Center(
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: typeColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _valuePreview(entry.value),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _opColor(entry.operation).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  entry.operation.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: _opColor(entry.operation),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _valuePreview(dynamic value) {
    if (value == null) return 'null';
    final str = value.toString();
    return str.length > 50 ? '${str.substring(0, 50)}...' : str;
  }

  Color _opColor(String op) {
    switch (op.toLowerCase()) {
      case 'write':
        return ColorTokens.success;
      case 'delete':
      case 'clear':
        return ColorTokens.error;
      default:
        return ColorTokens.info;
    }
  }
}

class _StorageDetailPanel extends StatelessWidget {
  final StorageEntry entry;

  const _StorageDetailPanel({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    return Container(
      color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Key', style: theme.textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 14),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: entry.value?.toString() ?? ''),
                    );
                  },
                  tooltip: 'Copy value',
                  splashRadius: 14,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              entry.key,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ColorTokens.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text('Value', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            if (entry.value is Map || entry.value is List)
              JsonViewer(data: entry.value, initiallyExpanded: true)
            else
              JsonPrettyViewer(data: entry.value),
            const SizedBox(height: 16),
            Text('Metadata', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            _MetaRow('Type', entry.storageType.name),
            _MetaRow('Operation', entry.operation),
            _MetaRow('Timestamp', time),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12),
          ),
        ],
      ),
    );
  }
}
