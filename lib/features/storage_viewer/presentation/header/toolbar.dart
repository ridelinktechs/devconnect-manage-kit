import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/inputs/search_field.dart';
import '../../../../components/misc/retention_hint.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../../core/providers/retention_provider.dart';
import '../../provider/storage_providers.dart';
import '../shared/storage_tokens.dart';
import 'icon_btn.dart';
import 'segment_chip.dart';
import 'segment_group.dart';

/// Top toolbar of the Storage Viewer page — title + count pill,
/// op-filter group (read/write/delete), scrollable type-filter
/// group (AS/SP/HV/SQL/RLM/MKV/OBX/SQF/ENC), search field, and the
/// action group (auto-scroll, sort direction, clear).
class Toolbar extends ConsumerWidget {
  final ValueNotifier<int> totalCount;
  final bool autoScroll;
  final VoidCallback onToggleAutoScroll;

  const Toolbar({
    super.key,
    required this.totalCount,
    required this.autoScroll,
    required this.onToggleAutoScroll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final opFilter = ref.watch(storageOperationFilterProvider);
    final typeFilter = ref.watch(storageTypeFilterProvider);
    final retentionPreset = ref.watch(retentionLimitProvider);
    final retentionLimit = retentionPreset.limit;
    final retentionLabel = retentionPreset.label;
    final capped = ref.watch(storageDisplayProvider);

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
          // Title + count pill
          Icon(LucideIcons.database, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text('Storage', style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: totalCount,
            builder: (_, c, _) {
              return RetentionHint(
                count: c,
                total: capped.total,
                limit: retentionLimit,
                limitLabel: retentionLabel,
              );
            },
          ),
          const SizedBox(width: 16),

          // ── Operation segment group ──
          SegmentGroup(isDark: isDark, children: [
            SegmentChip(label: S.of(context).read, isActive: opFilter == 'read', color: ColorTokens.info, isMono: true, onTap: () => ref.read(storageOperationFilterProvider.notifier).state = opFilter == 'read' ? null : 'read'),
            SegmentChip(label: S.of(context).write, isActive: opFilter == 'write', color: ColorTokens.success, isMono: true, onTap: () => ref.read(storageOperationFilterProvider.notifier).state = opFilter == 'write' ? null : 'write'),
            SegmentChip(label: S.of(context).delete, isActive: opFilter == 'delete', color: ColorTokens.error, isMono: true, onTap: () => ref.read(storageOperationFilterProvider.notifier).state = opFilter == 'delete' ? null : 'delete'),
          ]),
          const SizedBox(width: 10),

          // ── Type segment group ──
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentGroup(isDark: isDark, children: [
                SegmentChip(label: 'AS', isActive: typeFilter.contains(StorageType.asyncStorage), color: storageTypeColor(StorageType.asyncStorage), isMono: true, onTap: () => _toggleType(ref, StorageType.asyncStorage)),
                SegmentChip(label: 'SP', isActive: typeFilter.contains(StorageType.sharedPreferences), color: storageTypeColor(StorageType.sharedPreferences), isMono: true, onTap: () => _toggleType(ref, StorageType.sharedPreferences)),
                SegmentChip(label: 'HV', isActive: typeFilter.contains(StorageType.hive), color: storageTypeColor(StorageType.hive), isMono: true, onTap: () => _toggleType(ref, StorageType.hive)),
                SegmentChip(label: 'SQL', isActive: typeFilter.contains(StorageType.sqlite), color: storageTypeColor(StorageType.sqlite), isMono: true, onTap: () => _toggleType(ref, StorageType.sqlite)),
                SegmentChip(label: 'RLM', isActive: typeFilter.contains(StorageType.realm), color: storageTypeColor(StorageType.realm), isMono: true, onTap: () => _toggleType(ref, StorageType.realm)),
                SegmentChip(label: 'MKV', isActive: typeFilter.contains(StorageType.mmkv), color: storageTypeColor(StorageType.mmkv), isMono: true, onTap: () => _toggleType(ref, StorageType.mmkv)),
                SegmentChip(label: 'OBX', isActive: typeFilter.contains(StorageType.objectbox), color: storageTypeColor(StorageType.objectbox), isMono: true, onTap: () => _toggleType(ref, StorageType.objectbox)),
                SegmentChip(label: 'SQF', isActive: typeFilter.contains(StorageType.sqflite), color: storageTypeColor(StorageType.sqflite), isMono: true, onTap: () => _toggleType(ref, StorageType.sqflite)),
                SegmentChip(label: 'ENC', isActive: typeFilter.contains(StorageType.encryptedStorage), color: storageTypeColor(StorageType.encryptedStorage), isMono: true, onTap: () => _toggleType(ref, StorageType.encryptedStorage)),
              ]),
            ),
          ),

          const Spacer(),

          // Search field
          SizedBox(
            width: 200,
            child: SearchField(
              hintText: S.of(context).filterKeys,
              onChanged: (v) =>
                  ref.read(storageSearchProvider.notifier).state = v,
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
                IconBtn(
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
                    return IconBtn(
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
                IconBtn(
                  icon: LucideIcons.trash2,
                  tooltip: S.of(context).clearAll,
                  isDanger: true,
                  onTap: () =>
                      ref.read(storageEntriesProvider.notifier).clear(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleType(WidgetRef ref, StorageType type) {
    final current = ref.read(storageTypeFilterProvider);
    if (current.contains(type)) {
      ref.read(storageTypeFilterProvider.notifier).state =
          current.difference({type});
    } else {
      ref.read(storageTypeFilterProvider.notifier).state = {...current, type};
    }
  }
}