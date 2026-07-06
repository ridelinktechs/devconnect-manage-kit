import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/inputs/search_field.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/log/error_event.dart';
import '../../provider/error_providers.dart';
import '../shared/count_up.dart';
import '../shared/error_tokens.dart' show platformColor, platformLabel;
import '../shared/pulsing_dot.dart';
import 'info_bar.dart';
import 'icon_btn.dart';
import 'platform_filter_chip.dart';

/// Top toolbar of the Error Inspector page.
///
/// Two stacked regions, top → bottom:
///
/// 1. **Header bar** — title, error count (with pulsing red dot when
///    count > 0), platform filter chips, search field, action group
///    (auto-scroll, sort, clear).
/// 2. **Info bar** — "Total / Fatal" + per-platform count cells.
///
/// Anti-card-overuse: both regions use just `border-b` dividers, no
/// background containers (matches the rest of the app).
class Toolbar extends ConsumerWidget {
  final ValueNotifier<int> entryCount;
  final TextEditingController searchController;
  final bool autoScroll;
  final VoidCallback onToggleAutoScroll;

  const Toolbar({
    super.key,
    required this.entryCount,
    required this.searchController,
    required this.autoScroll,
    required this.onToggleAutoScroll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeFilters = ref.watch(errorFilterProvider);

    return Column(
      children: [
        // ── Header bar ────────────────────────────────────────────────────
        Container(
          height: 56,
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: Row(
            children: [
              // Title — display weight, tight tracking
              Icon(LucideIcons.alertTriangle, size: 16, color: ColorTokens.logError),
              const SizedBox(width: 10),
              Text(
                S.of(context).errors,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark
                      ? ColorTokens.lightBackground
                      : ColorTokens.darkNeutral,
                ),
              ),
              const SizedBox(width: 10),
              // Count pill with pulsing red dot when errors > 0
              ValueListenableBuilder<int>(
                valueListenable: entryCount,
                builder: (context, count, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (count > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: PulsingDot(
                            color: ColorTokens.logError,
                            size: 7,
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: count > 0
                              ? ColorTokens.logError.withValues(alpha: 0.12)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CountUp(
                          value: count,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppConstants.monoFontFamily,
                            color: count > 0
                                ? ColorTokens.logError
                                : (isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(width: 16),

              // Platform filter chips — compact, color-tinted
              ...ErrorPlatform.values.map((platform) {
                final isActive = activeFilters.contains(platform);
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: PlatformFilterChip(
                    label: platformLabel(platform),
                    isActive: isActive,
                    color: platformColor(platform),
                    onTap: () {
                      final current = ref.read(errorFilterProvider);
                      if (isActive) {
                        ref.read(errorFilterProvider.notifier).state =
                            current.difference({platform});
                      } else {
                        ref.read(errorFilterProvider.notifier).state = {
                          ...current,
                          platform,
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
                  hintText: S.of(context).searchErrors,
                  controller: searchController,
                  onClear: () {
                    searchController.clear();
                    ref.read(errorSearchProvider.notifier).state = '';
                  },
                  onChanged: (v) => ref.read(errorSearchProvider.notifier).state = v,
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
                      tooltip: autoScroll
                          ? S.of(context).autoScroll
                          : S.of(context).stop,
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
                          tooltip: isTop
                              ? S.of(context).newestFirst
                              : S.of(context).oldestFirst,
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
                    IconBtn(
                      icon: LucideIcons.trash2,
                      tooltip: S.of(context).clearErrors,
                      isDanger: true,
                      onTap: () => ref.read(errorEntriesProvider.notifier).clear(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Unified info bar ─────────────────────────────────────────────
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: ref.watch(errorCountProvider) > 0
                ? ColorTokens.logError.withValues(alpha: 0.04)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
          ),
          child: const InfoBar(),
        ),
      ],
    );
  }
}