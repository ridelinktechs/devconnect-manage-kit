import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../provider/display_providers.dart';

/// Display Inspector.
///
/// Shows the stream of `client:display` events the SDK emits — typically
/// widget inspector snapshots, layout dumps, image previews. The model
/// (DisplayEntry) carries an optional `preview` (a short summary string)
/// and an optional `image` (base64 PNG). We render each entry as a
/// row + a drawer with the full JSON `value` and (when present) the
/// image preview.
class DisplayPage extends ConsumerStatefulWidget {
  const DisplayPage({super.key});

  @override
  ConsumerState<DisplayPage> createState() => _DisplayPageState();
}

class _DisplayPageState extends ConsumerState<DisplayPage> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(displayDisplayProvider).items;
    final total = ref.watch(displayTotalSeenProvider);
    final selected = _selectedId != null
        ? entries.where((e) => e.id == _selectedId).firstOrNull
        : null;

    if (_selectedId != null && selected == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedId = null);
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _Toolbar(
          count: entries.length,
          total: total,
          isDark: isDark,
          onClear: () {
            ref.read(displayEntriesProvider.notifier).clear();
            setState(() => _selectedId = null);
          },
        ),
        Expanded(
          child: entries.isEmpty
              ? EmptyState(
                  icon: LucideIcons.eye,
                  title: 'No display snapshots',
                  subtitle:
                      'client:display events appear here — widget inspector '
                      'snapshots, layout dumps, and image previews.',
                )
              : Row(
                  children: [
                    Expanded(
                      flex: selected != null ? 4 : 1,
                      child: ListView.builder(
                        itemCount: entries.length,
                        itemExtent: 48,
                        itemBuilder: (context, index) {
                          final entry = entries[entries.length - 1 - index];
                          final isSel = _selectedId == entry.id;
                          return _DisplayRow(
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
                        child: _DisplayDetail(
                          key: ValueKey(selected.id),
                          entry: selected,
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
          Icon(LucideIcons.eye, size: 15, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text(
            'Display snapshots',
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
              color: ColorTokens.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              total > count ? '$count / $total' : '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ColorTokens.primary,
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

class _DisplayRow extends StatelessWidget {
  final dynamic entry;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _DisplayRow({
    required this.entry,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm:ss.SSS')
        .format(DateTime.fromMillisecondsSinceEpoch(entry.timestamp));
    final hasImage = entry.image is String && (entry.image as String).isNotEmpty;
    final hasPreview =
        entry.preview is String && (entry.preview as String).isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? ColorTokens.primary.withValues(alpha: 0.1)
                  : ColorTokens.primary.withValues(alpha: 0.06))
              : null,
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            left: isSelected
                ? const BorderSide(color: ColorTokens.primary, width: 2)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasImage
                  ? LucideIcons.image
                  : (hasPreview
                      ? LucideIcons.scanLine
                      : LucideIcons.box),
              size: 14,
              color: isSelected ? ColorTokens.primary : Colors.grey[500],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name as String,
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
                  if (hasPreview)
                    Text(
                      entry.preview as String,
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

class _DisplayDetail extends StatelessWidget {
  final dynamic entry;
  final bool isDark;
  final VoidCallback onClose;
  const _DisplayDetail({
    super.key,
    required this.entry,
    required this.isDark,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS')
        .format(DateTime.fromMillisecondsSinceEpoch(entry.timestamp));
    final hasImage = entry.image is String && (entry.image as String).isNotEmpty;

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
                Icon(LucideIcons.eye, size: 14, color: ColorTokens.primary),
                const SizedBox(width: 8),
                Text(
                  entry.name as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ColorTokens.primary,
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
                  if (hasImage) ...[
                    Text(
                      'Image preview',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? ColorTokens.lightBackground
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 320),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.center,
                      child: Text(
                        '<image: ${(entry.image as String).length} bytes base64>',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (entry.preview is String &&
                      (entry.preview as String).isNotEmpty) ...[
                    Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? ColorTokens.lightBackground
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.preview as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Value',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? ColorTokens.lightBackground
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  JsonPrettyViewer(data: _normalize(entry.value)),
                  if (entry.metadata != null) ...[
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 8),
                    JsonPrettyViewer(data: _normalize(entry.metadata)),
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