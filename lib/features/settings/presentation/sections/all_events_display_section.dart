import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/retention_provider.dart';
import '../../../../l10n/app_localizations.dart';
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
          style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4),
        ),
        const SizedBox(height: 14),

        // Visible entries
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                S.of(context).maxItems,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ),
            Expanded(
              child: PresetDropdown(
                selected: preset,
                onSelected: (p) =>
                    ref.read(allEventsDisplayLimitProvider.notifier).set(p),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 100),
          child: Text(
            S.of(context).allEventsDisplayHelper,
            style: TextStyle(fontSize: 10, color: Colors.grey[600], height: 1.4),
          ),
        ),
      ],
    );
  }
}