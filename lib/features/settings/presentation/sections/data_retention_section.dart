import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/retention_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../header/section_title.dart';
import '../shared/preset_dropdown.dart';

/// Hard data-retention cap. When the per-feature list exceeds this
/// limit, the oldest entries are dropped FIFO. Async ops keep their
/// pending `start` rows in preference to resolved/rejected ones.
///
/// This is destructive — it actually mutates the underlying state, so
/// the related setting (`All Events Display Limit`) is view-only.
class DataRetentionSection extends ConsumerWidget {
  const DataRetentionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(retentionLimitProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          icon: LucideIcons.database,
          title: S.of(context).dataRetention,
        ),
        Text(
          S.of(context).dataRetentionDesc,
          style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4),
        ),
        const SizedBox(height: 14),

        // Max items per list
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
                    ref.read(retentionLimitProvider.notifier).set(p),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 100),
          child: Text(
            S.of(context).dataRetentionHelper,
            style: TextStyle(fontSize: 10, color: Colors.grey[600], height: 1.4),
          ),
        ),
      ],
    );
  }
}