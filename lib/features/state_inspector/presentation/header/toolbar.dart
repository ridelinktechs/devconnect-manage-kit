import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/inputs/search_field.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/retention_provider.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../provider/state_providers.dart';
import 'icon_btn.dart';

/// Redux tab toolbar: title, change count, action filter and action group.
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
    final scrollDir = ref.watch(scrollDirectionProvider);
    final isTop = scrollDir == ScrollDirection.top;

    final retentionPreset = ref.watch(retentionLimitProvider);
    final retentionLimit = retentionPreset.limit;
    final retentionLabel = retentionPreset.label;
    final capped = ref.watch(stateChangesDisplayProvider);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.layers, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text('State Inspector', style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: totalCount,
            builder: (_, c, __) {
              final isTrimmed = retentionLimit != null && capped.total > c;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    retentionLimit == null
                        ? '$c changes'
                        : '$c / $retentionLabel changes',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (isTrimmed)
                    Text(
                      'Showing $c of ${capped.total}',
                      style: TextStyle(
                        fontSize: 9,
                        fontFamily: AppConstants.monoFontFamily,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                      ),
                    ),
                ],
              );
            },
          ),
          const Spacer(),
          SizedBox(
            width: 200,
            child: SearchField(
              hintText: S.of(context).filterActions,
              onChanged: (v) => ref.read(stateSearchProvider.notifier).set(v),
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
                IconBtn(
                  icon: isTop
                      ? LucideIcons.arrowUpNarrowWide
                      : LucideIcons.arrowDownNarrowWide,
                  tooltip: isTop
                      ? S.of(context).newestAtTop
                      : S.of(context).newestAtBottom,
                  isActive: isTop,
                  onTap: () => ref
                      .read(scrollDirectionProvider.notifier)
                      .set(
                        isTop ? ScrollDirection.bottom : ScrollDirection.top,
                      ),
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
                  onTap: () => ref.read(stateChangesProvider.notifier).clear(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
