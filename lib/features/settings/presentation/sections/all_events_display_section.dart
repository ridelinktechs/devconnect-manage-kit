import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/retention_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../controls/settings_row.dart';
import '../header/section_title.dart';
import '../shared/preset_dropdown.dart';

/// View-only filter for the All Events page. Caps the rendered list
/// to the N most-recent entries but never mutates the underlying
/// providers — flipping the setting back to Unlimited restores every
/// entry.
///
/// Distinct from `DataRetentionSection` (which is destructive).
class AllEventsDisplaySection extends ConsumerWidget {
  const AllEventsDisplaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(allEventsDisplayLimitProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          icon: LucideIcons.list,
          title: S.of(context).allEventsDisplay,
        ),
        Text(
          S.of(context).allEventsDisplayDesc,
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            color: ChromePalette.of(context).textMuted,
          ),
        ),
        const SizedBox(height: 10),
        SettingsRow(
          first: true,
          title: S.of(context).maxItems,
          description: S.of(context).allEventsDisplayHelper,
          control: PresetDropdown(
            selected: preset,
            onSelected: (p) => ref.read(allEventsDisplayLimitProvider.notifier).set(p),
          ),
        ),
      ],
    );
  }
}