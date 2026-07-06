import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../header/section_title.dart';
import 'language_dropdown.dart';

/// Appearance card — theme (Dark / Light), scroll direction
/// (Top / Bottom), Language (popup), Smooth Scrolling (switch +
/// duration slider).
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final scrollDir = ref.watch(scrollDirectionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(icon: LucideIcons.palette, title: S.of(context).appearance),
        // Theme
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(S.of(context).theme,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ),
            Expanded(
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(LucideIcons.moon, size: 14),
                    label: Text(S.of(context).dark),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(LucideIcons.sun, size: 14),
                    label: Text(S.of(context).light),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (value) {
                  final mode = value.first;
                  if (mode == ThemeMode.dark) {
                    ref.read(themeModeProvider.notifier).setDark();
                  } else {
                    ref.read(themeModeProvider.notifier).setLight();
                  }
                },
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Scroll direction
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(S.of(context).autoScroll,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ),
            Expanded(
              child: SegmentedButton<ScrollDirection>(
                segments: [
                  ButtonSegment(
                    value: ScrollDirection.bottom,
                    icon: Icon(LucideIcons.arrowDownToLine, size: 14),
                    label: Text(S.of(context).bottom),
                  ),
                  ButtonSegment(
                    value: ScrollDirection.top,
                    icon: Icon(LucideIcons.arrowUpToLine, size: 14),
                    label: Text(S.of(context).top),
                  ),
                ],
                selected: {scrollDir},
                onSelectionChanged: (value) {
                  ref.read(scrollDirectionProvider.notifier).state = value.first;
                },
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Language
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(S.of(context).language,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ),
            Expanded(
              child: LanguageDropdown(
                selected: ref.watch(localeProvider),
                isDark: isDark,
                onSelect: (locale) {
                  ref.read(localeProvider.notifier).setLocale(locale);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Smooth scroll
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                S.of(context).smoothScrolling,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ),
            Switch.adaptive(
              value: ref.watch(smoothScrollEnabledProvider),
              onChanged: (v) =>
                  ref.read(smoothScrollEnabledProvider.notifier).set(v),
            ),
            const SizedBox(width: 8),
            Text(
              ref.watch(smoothScrollEnabledProvider)
                  ? S.of(context).on
                  : S.of(context).off,
              style: TextStyle(
                fontSize: 12,
                color: ref.watch(smoothScrollEnabledProvider)
                    ? ColorTokens.primary
                    : Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 100),
          child: Text(
            S.of(context).smoothScrollingDesc,
            style: TextStyle(fontSize: 10, color: Colors.grey[600], height: 1.4),
          ),
        ),
        if (ref.watch(smoothScrollEnabledProvider)) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  S.of(context).smoothScrollingDuration,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: ref.watch(smoothScrollDurationProvider).toDouble(),
                    min: 100,
                    max: 1000,
                    divisions: 18,
                    label: '${ref.watch(smoothScrollDurationProvider)}ms',
                    activeColor: ColorTokens.primary,
                    inactiveColor: isDark ? Colors.white12 : Colors.black12,
                    onChanged: (v) => ref
                        .read(smoothScrollDurationProvider.notifier)
                        .set(v.round()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                child: Text(
                  '${ref.watch(smoothScrollDurationProvider)}ms',
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorTokens.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 100),
            child: Text(
              S.of(context).smoothScrollingDurationDesc,
              style: TextStyle(fontSize: 10, color: Colors.grey[600], height: 1.4),
            ),
          ),
        ],
      ],
    );
  }
}