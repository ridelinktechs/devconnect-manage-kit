import 'package:flutter/material.dart' hide FilterChip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/tab_visibility_provider.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../provider/all_events_provider.dart';
import 'filter_chip.dart';

/// Horizontal row of type-filter chips for the All Events page. Each chip
/// reflects the current count for its type and toggles the corresponding
/// filter set. Visibility of each chip is gated by the per-tab visibility
/// provider so the bar never shows chips for disabled source tabs.
class FilterBar extends ConsumerWidget {
  final List<UnifiedEvent> events;

  const FilterBar({super.key, required this.events});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeFilters = ref.watch(allEventsFilterProvider);
    final enabledTabs = ref.watch(tabVisibilityProvider);
    final errorsOnly = ref.watch(allEventsErrorsOnlyProvider);

    final logCount = events.where((e) => e.type == EventType.log).length;
    final netCount = events.where((e) => e.type == EventType.network).length;
    final stateCount = events.where((e) => e.type == EventType.state).length;
    final storeCount = events.where((e) => e.type == EventType.storage).length;
    final displayCount = events.where((e) => e.type == EventType.display).length;
    final asyncCount = events.where((e) => e.type == EventType.asyncOp).length;
    final errorCount = events.where((e) => e.level == 'error').length;

    // Only show filter chips for enabled tabs
    final chips = <Widget>[];
    if (enabledTabs.contains(TabKey.console)) {
      chips.add(FilterChip(
        label: 'LOG',
        count: logCount,
        icon: LucideIcons.terminal,
        color: ColorTokens.logInfo,
        isActive: activeFilters.contains(EventType.log),
        onTap: () => _toggle(ref, EventType.log),
      ));
    }
    if (enabledTabs.contains(TabKey.network)) {
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
      chips.add(FilterChip(
        label: 'API',
        count: netCount,
        icon: LucideIcons.globe,
        color: ColorTokens.success,
        isActive: activeFilters.contains(EventType.network),
        onTap: () => _toggle(ref, EventType.network),
      ));
    }
    if (enabledTabs.contains(TabKey.state)) {
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
      chips.add(FilterChip(
        label: 'STATE',
        count: stateCount,
        icon: LucideIcons.layers,
        color: ColorTokens.secondary,
        isActive: activeFilters.contains(EventType.state),
        onTap: () => _toggle(ref, EventType.state),
      ));
    }
    if (enabledTabs.contains(TabKey.storage)) {
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
      chips.add(FilterChip(
        label: 'STORE',
        count: storeCount,
        icon: LucideIcons.database,
        color: ColorTokens.warning,
        isActive: activeFilters.contains(EventType.storage),
        onTap: () => _toggle(ref, EventType.storage),
      ));
    }
    // Display events (always visible — no dedicated tab)
    if (displayCount > 0 || activeFilters.contains(EventType.display)) {
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
      chips.add(FilterChip(
        label: 'DISPLAY',
        count: displayCount,
        icon: LucideIcons.monitor,
        color: const Color(0xFF9B59B6),
        isActive: activeFilters.contains(EventType.display),
        onTap: () => _toggle(ref, EventType.display),
      ));
    }
    // Async operation events (always visible — no dedicated tab)
    if (asyncCount > 0 || activeFilters.contains(EventType.asyncOp)) {
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
      chips.add(FilterChip(
        label: 'ASYNC',
        count: asyncCount,
        icon: LucideIcons.zap,
        color: const Color(0xFFE67E22),
        isActive: activeFilters.contains(EventType.asyncOp),
        onTap: () => _toggle(ref, EventType.asyncOp),
      ));
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : ColorTokens.lightSurface,
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
          ...chips,
          if (errorCount > 0) ...[
            const SizedBox(width: 10),
            Container(
              width: 1,
              height: 18,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            const SizedBox(width: 10),
            FilterChip(
              label: 'ERRORS',
              count: errorCount,
              icon: LucideIcons.triangleAlert,
              color: ColorTokens.error,
              isActive: errorsOnly,
              onTap: () => ref
                  .read(allEventsErrorsOnlyProvider.notifier)
                  .update((v) => !v),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  void _toggle(WidgetRef ref, EventType type) {
    final current = ref.read(allEventsFilterProvider);
    if (current.contains(type)) {
      ref.read(allEventsFilterProvider.notifier).state =
          current.difference({type});
    } else {
      ref.read(allEventsFilterProvider.notifier).state = {...current, type};
    }
  }
}