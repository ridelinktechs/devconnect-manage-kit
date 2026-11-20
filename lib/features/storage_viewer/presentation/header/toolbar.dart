import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/inputs/search_field.dart';
import '../../../../components/misc/retention_hint.dart';
import '../../../../core/providers/retention_provider.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../settings/presentation/tips/page_guide_button.dart';
import '../../provider/storage_providers.dart';
import 'icon_btn.dart';
import 'storage_filter_row.dart';

/// The Storage page's title bar, laid out like the Console's and the State
/// Inspector's: title and operation count, a chip per operation and storage
/// type, the key filter and the action group. The history's controls show
/// only while its tab is open.
class Toolbar extends ConsumerWidget {
  final ValueNotifier<int> totalCount;

  /// The key filter's text, owned by the page so it survives tab switches.
  final TextEditingController searchController;
  final bool autoScroll;
  final VoidCallback onToggleAutoScroll;

  const Toolbar({
    super.key,
    required this.totalCount,
    required this.searchController,
    required this.autoScroll,
    required this.onToggleAutoScroll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tabs = DefaultTabController.of(context);
    final loc = S.of(context);
    final retention = ref.watch(retentionLimitProvider);
    final capped = ref.watch(storageDisplayProvider);
    final isTop = ref.watch(scrollDirectionProvider) == ScrollDirection.top;
    final rule = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: isDark ? ColorTokens.darkBackground : Colors.white,
      child: Row(
        children: [
          const Icon(
            LucideIcons.database,
            size: 16,
            color: ColorTokens.primary,
          ),
          const SizedBox(width: 8),
          Text(loc.storageTitle, style: theme.textTheme.titleMedium),
          const PageGuideButton(route: '/storage'),
          Expanded(
            child: ListenableBuilder(
              listenable: tabs,
              builder: (context, _) {
                if (tabs.index != 0) return const SizedBox.shrink();
                return Row(
                  children: [
                    const SizedBox(width: 8),
                    ValueListenableBuilder<int>(
                      valueListenable: totalCount,
                      builder: (_, count, _) => RetentionHint(
                        count: count,
                        total: capped.total,
                        limit: retention.limit,
                        limitLabel: retention.label,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: StorageFilterRow()),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 220,
                      child: SearchField(
                        controller: searchController,
                        hintText: loc.filterKeys,
                        onChanged: (v) =>
                            ref.read(storageSearchProvider.notifier).set(v),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                            tooltip: loc.autoScroll,
                            isActive: autoScroll,
                            onTap: onToggleAutoScroll,
                          ),
                          const SizedBox(width: 2),
                          IconBtn(
                            icon: isTop
                                ? LucideIcons.arrowUpNarrowWide
                                : LucideIcons.arrowDownNarrowWide,
                            tooltip: isTop ? loc.newestFirst : loc.oldestFirst,
                            isActive: isTop,
                            onTap: () => ref
                                .read(scrollDirectionProvider.notifier)
                                .set(
                                  isTop
                                      ? ScrollDirection.bottom
                                      : ScrollDirection.top,
                                ),
                          ),
                          const SizedBox(width: 2),
                          Container(width: 1, height: 18, color: rule),
                          const SizedBox(width: 2),
                          IconBtn(
                            icon: LucideIcons.trash2,
                            tooltip: loc.clearAll,
                            isDanger: true,
                            onTap: () => ref
                                .read(storageEntriesProvider.notifier)
                                .clear(),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
