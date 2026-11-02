import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../controls/bubble_slider.dart';
import '../controls/segmented_picker.dart';
import '../controls/settings_row.dart';
import '../controls/stretch_switch.dart';
import '../header/section_title.dart';

/// Detail View card — picks between tree/json/code for response body
/// rendering, plus the tab animation toggle + duration slider.
class DetailViewSection extends ConsumerWidget {
  const DetailViewSection({super.key});

  String _modeDescription(WidgetRef ref, BodyViewMode mode) {
    switch (mode) {
      case BodyViewMode.tree:
        return S.of(ref.context).treeModeDesc;
      case BodyViewMode.json:
        return S.of(ref.context).jsonModeDesc;
      case BodyViewMode.code:
        return S.of(ref.context).codeModeDesc;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(bodyViewModeProvider);
    final animEnabled = ref.watch(tabAnimationEnabledProvider);
    final animMs = ref.watch(tabAnimationDurationProvider);
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(icon: LucideIcons.panelRight, title: s.detailView),
        Text(
          s.detailViewDesc,
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            color: ChromePalette.of(context).textMuted,
          ),
        ),
        const SizedBox(height: 10),
        SettingsRow(
          first: true,
          title: s.bodyView,
          description: _modeDescription(ref, viewMode),
          control: SegmentedPicker<BodyViewMode>(
            segments: [
              (
                value: BodyViewMode.tree,
                label: s.tree,
                icon: LucideIcons.listTree,
              ),
              (
                value: BodyViewMode.json,
                label: s.json,
                icon: LucideIcons.braces,
              ),
              (value: BodyViewMode.code, label: s.code, icon: LucideIcons.code),
            ],
            value: viewMode,
            onChanged: (v) => ref.read(bodyViewModeProvider.notifier).set(v),
          ),
        ),
        SettingsRow(
          title: s.tabAnimation,
          control: Align(
            alignment: Alignment.centerRight,
            child: StretchSwitch(
              value: animEnabled,
              label: s.tabAnimation,
              onChanged: (v) =>
                  ref.read(tabAnimationEnabledProvider.notifier).set(v),
            ),
          ),
        ),
        SettingsRow(
          title: s.duration,
          control: BubbleSlider(
            value: animMs,
            min: 0,
            max: 1000,
            step: 50,
            ticks: const [0, 250, 500, 750, 1000],
            format: (v) => '${v}ms',
            label: s.duration,
            onChanged: animEnabled
                ? (v) => ref.read(tabAnimationDurationProvider.notifier).set(v)
                : null,
          ),
        ),
      ],
    );
  }
}