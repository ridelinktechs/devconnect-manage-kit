import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../controls/bubble_slider.dart';
import '../controls/segmented_picker.dart';
import '../controls/settings_row.dart';
import '../controls/stretch_switch.dart';
import '../header/section_title.dart';
import 'language_dropdown.dart';

/// Appearance card — theme (Dark / Light), Language (popup), scroll
/// direction (Top / Bottom), Smooth Scrolling (switch + duration slider).
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final scrollDir = ref.watch(scrollDirectionProvider);
    final smooth = ref.watch(smoothScrollEnabledProvider);
    final smoothMs = ref.watch(smoothScrollDurationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final durationRow = SettingsRow(
      title: s.smoothScrollingDuration,
      description: s.smoothScrollingDurationDesc,
      control: BubbleSlider(
        value: smoothMs,
        min: 100,
        max: 1000,
        step: 50,
        ticks: const [100, 400, 700, 1000],
        format: (v) => '${v}ms',
        label: s.smoothScrollingDuration,
        onChanged: (v) =>
            ref.read(smoothScrollDurationProvider.notifier).set(v),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(icon: LucideIcons.palette, title: s.appearance),
        SettingsRow(
          first: true,
          title: s.theme,
          control: SegmentedPicker<ThemeMode>(
            segments: [
              (value: ThemeMode.dark, label: s.dark, icon: LucideIcons.moon),
              (value: ThemeMode.light, label: s.light, icon: LucideIcons.sun),
            ],
            value: themeMode,
            onChanged: (mode) {
              if (mode == ThemeMode.dark) {
                ref.read(themeModeProvider.notifier).setDark();
              } else {
                ref.read(themeModeProvider.notifier).setLight();
              }
            },
          ),
        ),
        SettingsRow(
          title: s.language,
          control: LanguageDropdown(
            selected: ref.watch(localeProvider),
            isDark: isDark,
            onSelect: (locale) {
              ref.read(localeProvider.notifier).setLocale(locale);
            },
          ),
        ),
        SettingsRow(
          title: s.autoScroll,
          control: SegmentedPicker<ScrollDirection>(
            segments: [
              (
                value: ScrollDirection.bottom,
                label: s.bottom,
                icon: LucideIcons.arrowDownToLine,
              ),
              (
                value: ScrollDirection.top,
                label: s.top,
                icon: LucideIcons.arrowUpToLine,
              ),
            ],
            value: scrollDir,
            onChanged: (v) => ref.read(scrollDirectionProvider.notifier).set(v),
          ),
        ),
        SettingsRow(
          title: s.smoothScrolling,
          description: s.smoothScrollingDesc,
          control: Align(
            alignment: Alignment.centerRight,
            child: StretchSwitch(
              value: smooth,
              label: s.smoothScrolling,
              onChanged: (v) =>
                  ref.read(smoothScrollEnabledProvider.notifier).set(v),
            ),
          ),
        ),
        if (MediaQuery.disableAnimationsOf(context))
          smooth ? durationRow : const SizedBox.shrink()
        else
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: const Cubic(0.2, 0.8, 0.2, 1),
            alignment: Alignment.topCenter,
            child: smooth
                ? durationRow
                : const SizedBox(width: double.infinity),
          ),
      ],
    );
  }
}