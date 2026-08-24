import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../display/provider/display_providers.dart' as dp show asyncOperationEntriesProvider, asyncOpDisplayProvider, asyncOpTotalSeenProvider;
import '../../../../models/display/display_entry.dart';

/// Async Ops Inspector.
///
/// Surfaces the `client:async:operation` events the SDK emits — saga
/// hops, async tasks, background jobs. Groups them by `sagaName` so
/// the user can see the full timeline of a single saga in one view.
/// Standalone (no saga) operations get their own group.
class AsyncOpsPage extends ConsumerStatefulWidget {
  const AsyncOpsPage({super.key});

  @override
  ConsumerState<AsyncOpsPage> createState() => _AsyncOpsPageState();
}

class _AsyncOpsPageState extends ConsumerState<AsyncOpsPage> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(dp.asyncOpDisplayProvider).items;
    final total = ref.watch(dp.asyncOpTotalSeenProvider);
    final selected = _selectedId != null
        ? entries.where((e) => e.id == _selectedId).firstOrNull
        : null;

    if (_selectedId != null && selected == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedId = null);
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group by sagaName. Entries with the same saga land in the same
    // group so the panel can render the saga timeline. Standalone
    // entries (no saga) get a synthetic '(standalone)' bucket.
    final groups = _groupBySaga(entries);

    return Column(
      children: [
        _Toolbar(
          count: entries.length,
          total: total,
          isDark: isDark,
          onClear: () {
            ref.read(dp.asyncOperationEntriesProvider.notifier).clear();
            setState(() => _selectedId = null);
          },
        ),
        Expanded(
          child: entries.isEmpty
              ? EmptyState(
                  icon: LucideIcons.workflow,
                  title: 'No async operations',
                  subtitle:
                      'client:async:operation events appear here — saga hops, '
                      'async tasks, and background jobs from the SDK.',
                )
              : Row(
                  children: [
                    Expanded(
                      flex: selected != null ? 4 : 1,
                      child: ListView.builder(
                        itemCount: entries.length,
                        itemExtent: 52,
                        itemBuilder: (context, index) {
                          final entry = entries[entries.length - 1 - index];
                          final isSel = _selectedId == entry.id;
                          return _AsyncOpRow(
                            entry: entry,
                            isSelected: isSel,
                            isDark: isDark,
                            onTap: () => setState(() => _selectedId =
                                isSel ? null : entry.id),
                          );
                        },
                      ),
                    ),
                    if (selected != null) ...[
                      VerticalDivider(
                        width: 1,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                      Expanded(
                        flex: 6,
                        child: _AsyncOpDetail(
                          key: ValueKey(selected.id),
                          entry: selected,
                          sagaGroup: groups[selected.sagaName ?? '']
                              ?? const <AsyncOperationEntry>[],
                          isDark: isDark,
                          onClose: () => setState(() => _selectedId = null),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Map<String, List<AsyncOperationEntry>> _groupBySaga(
      List<AsyncOperationEntry> entries) {
    final map = <String, List<AsyncOperationEntry>>{};
    for (final e in entries) {
      final key = e.sagaName ?? '';
      (map[key] ??= <AsyncOperationEntry>[]).add(e);
    }
    return map;
  }
}

class _Toolbar extends ConsumerWidget {
  final int count;
  final int total;
  final bool isDark;
  final VoidCallback onClear;
  const _Toolbar({
    required this.count,
    required this.total,
    required this.isDark,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.workflow, size: 15, color: const Color(0xFF8B5CF6)),
          const SizedBox(width: 8),
          Text(
            'Async operations',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              total > count ? '$count / $total' : '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(LucideIcons.trash2,
                size: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600]),
            onPressed: onClear,
            tooltip: 'Clear all',
            splashRadius: 14,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _AsyncOpRow extends StatelessWidget {
  final AsyncOperationEntry entry;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _AsyncOpRow({
    required this.entry,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  Color _statusColor() {
    switch (entry.status) {
      case AsyncOperationStatus.resolve:
        return const Color(0xFF10B981);
      case AsyncOperationStatus.reject:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFFDAA5E);
    }
  }

  String _typeLabel() {
    switch (entry.operationType) {
      case AsyncOperationType.sagaTake:
        return 'take';
      case AsyncOperationType.sagaPut:
        return 'put';
      case AsyncOperationType.sagaCall:
        return 'call';
      case AsyncOperationType.sagaFork:
        return 'fork';
      case AsyncOperationType.sagaAll:
        return 'all';
      case AsyncOperationType.sagaRace:
        return 'race';
      case AsyncOperationType.sagaSelect:
        return 'select';
      case AsyncOperationType.sagaDelay:
        return 'delay';
      case AsyncOperationType.asyncTask:
        return 'async';
      case AsyncOperationType.backgroundJob:
        return 'job';
      default:
        return 'op';
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm:ss.SSS')
        .format(DateTime.fromMillisecondsSinceEpoch(entry.timestamp));
    final statusColor = _statusColor();
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                  : const Color(0xFF8B5CF6).withValues(alpha: 0.06))
              : null,
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            left: isSelected
                ? const BorderSide(color: Color(0xFF8B5CF6), width: 2)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _typeLabel(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description.isEmpty
                        ? '(no description)'
                        : entry.description,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? ColorTokens.lightBackground
                          : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.sagaName != null)
                    Text(
                      entry.sagaName!,
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
            if (entry.duration != null)
              Text(
                '${entry.duration}ms',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AsyncOpDetail extends StatelessWidget {
  final AsyncOperationEntry entry;
  final List<AsyncOperationEntry> sagaGroup;
  final bool isDark;
  final VoidCallback onClose;
  const _AsyncOpDetail({
    super.key,
    required this.entry,
    required this.sagaGroup,
    required this.isDark,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS')
        .format(DateTime.fromMillisecondsSinceEpoch(entry.timestamp));
    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? ColorTokens.darkBackground : Colors.white,
            ),
            child: Row(
              children: [
                Icon(LucideIcons.workflow,
                    size: 14, color: const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                Text(
                  entry.description.isEmpty
                      ? '(no description)'
                      : entry.description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const Spacer(),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(LucideIcons.x,
                      size: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[600]),
                  onPressed: onClose,
                  splashRadius: 14,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetaRow(label: 'type', value: entry.operationType.name),
                  _MetaRow(label: 'status', value: entry.status.name),
                  if (entry.sagaName != null)
                    _MetaRow(label: 'saga', value: entry.sagaName!),
                  if (entry.duration != null)
                    _MetaRow(label: 'duration', value: '${entry.duration} ms'),
                  if (entry.error != null)
                    _MetaRow(label: 'error', value: entry.error!,
                        valueColor: const Color(0xFFEF4444)),
                  const SizedBox(height: 12),
                  if (entry.result != null) ...[
                    Text(
                      'Result',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? ColorTokens.lightBackground
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    JsonPrettyViewer(data: _normalize(entry.result)),
                    const SizedBox(height: 12),
                  ],
                  if (entry.metadata != null) ...[
                    Text(
                      'Metadata',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? ColorTokens.lightBackground
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    JsonPrettyViewer(data: _normalize(entry.metadata)),
                    const SizedBox(height: 12),
                  ],
                  if (sagaGroup.length > 1) ...[
                    Text(
                      'Saga timeline (${sagaGroup.length} ops)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? ColorTokens.lightBackground
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...sagaGroup.map((e) => _SagaRow(
                          entry: e,
                          highlight: e.id == entry.id,
                          isDark: isDark,
                        )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _normalize(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.cast<String, dynamic>();
    return {'value': v};
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _MetaRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
                color: valueColor ??
                    (isDark
                        ? ColorTokens.lightBackground
                        : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SagaRow extends StatelessWidget {
  final AsyncOperationEntry entry;
  final bool highlight;
  final bool isDark;
  const _SagaRow({
    required this.entry,
    required this.highlight,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final t = DateFormat('HH:mm:ss.SSS')
        .format(DateTime.fromMillisecondsSinceEpoch(entry.timestamp));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
            : (isDark
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.black.withValues(alpha: 0.02)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            entry.status.name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: entry.status == AsyncOperationStatus.resolve
                  ? const Color(0xFF10B981)
                  : entry.status == AsyncOperationStatus.reject
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFFDAA5E),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.description.isEmpty
                  ? entry.operationType.name
                  : entry.description,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? ColorTokens.lightBackground
                    : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            t,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}