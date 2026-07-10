import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/inputs/search_field.dart';
import '../../../../components/misc/retention_hint.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/retention_provider.dart';
import '../../provider/network_providers.dart';
import 'clear_stale_btn.dart';
import 'icon_btn.dart';
import 'segment_group.dart';

/// Top toolbar of the Network Inspector page.
///
/// Four regions, left → right:
///   1. **Identity** — title, live event count
///   2. **Method filter** — GET / POST / PUT / PATCH / DELETE chips
///   3. **Source filter** — App / Library / System chips
///   4. **Search + Actions** — search field, auto-scroll, sort, clear-stale,
///      clear-all grouped in a rounded container.
class Toolbar extends ConsumerWidget {
  final ValueNotifier<int> count;
  final bool autoScroll;
  final VoidCallback onToggleAutoScroll;

  const Toolbar({
    super.key,
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
    final retentionPreset = ref.watch(retentionLimitProvider);
    final retentionLimit = retentionPreset.limit;
    final retentionLabel = retentionPreset.label;
    final capped = ref.watch(networkDisplayProvider);

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

          // ── Method segment group ──
          SegmentGroup(
            isDark: isDark,
            children: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'].map((m) {
              final isActive = methodFilter == m;
              final color = ColorTokens.httpMethodColor(m);
              return SegmentChip(
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
          SegmentGroup(
            isDark: isDark,
            children: [
              SegmentChip(
                label: 'App',
                isActive: sourceFilter.contains('app'),
                color: ColorTokens.primary,
                onTap: () => _toggleSource(ref, 'app'),
              ),
              SegmentChip(
                label: 'Library',
                isActive: sourceFilter.contains('library'),
                color: ColorTokens.warning,
                onTap: () => _toggleSource(ref, 'library'),
              ),
              SegmentChip(
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
              hintText: S.of(context).filterUrls,
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
                // ── Clear stale (only when there are pending > 10min) ──
                Consumer(
                  builder: (context, ref, _) {
                    final staleCount =
                        ref.watch(staleNetworkCountProvider);
                    if (staleCount == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: ClearStaleBtn(
                        count: staleCount,
                        onTap: () {
                          final removed = ref
                              .read(networkEntriesProvider.notifier)
                              .clearStale();
                          if (removed > 0 && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 2),
                                content: Text(
                                  'Cleared $removed stale request${removed == 1 ? '' : 's'} '
                                  '(pending > 10min)',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
                IconBtn(
                  icon: LucideIcons.trash2,
                  tooltip: S.of(context).clear,
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