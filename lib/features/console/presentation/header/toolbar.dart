import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/inputs/search_field.dart';
import '../../../../components/misc/retention_hint.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/log/log_entry.dart';
import '../../../../core/providers/retention_provider.dart';
import '../../provider/console_providers.dart';
import '../shared/level_color.dart';
import 'icon_btn.dart';
import 'level_filter_chip.dart';

/// Top toolbar of the Console page — title + count pill, level
/// filter chips (DEBUG/INFO/WARN/ERROR), search field, action group
/// (auto-scroll, sort direction, clear).
class Toolbar extends ConsumerWidget {
  final ValueNotifier<int> entryCount;
  final bool autoScroll;
  final VoidCallback onToggleAutoScroll;
  final VoidCallback onClear;

  const Toolbar({
    super.key,
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
    final retentionPreset = ref.watch(retentionLimitProvider);
    final retentionLimit = retentionPreset.limit;
    final retentionLabel = retentionPreset.label;
    final capped = ref.watch(consoleDisplayProvider);

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
            builder: (_, count, _) {
              return RetentionHint(
                count: count,
                total: capped.total,
                limit: retentionLimit,
                limitLabel: retentionLabel,
              );
            },
          ),
          const SizedBox(width: 16),

          // Level filter chips
          ...LogLevel.values.map((level) {
            final isActive = activeFilters.contains(level);
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: LevelFilterChip(
                label: level.name.toUpperCase(),
                isActive: isActive,
                color: levelColor(level),
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