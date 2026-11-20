import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/layout/segmented_tab_bar.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../provider/storage_providers.dart';
import '../../provider/storage_snapshot_providers.dart';

/// The Storage page's tabs as the segmented control the other pages use:
/// the history of operations and the stores' live contents, each with how
/// many it holds.
class StorageTabBar extends ConsumerWidget {
  const StorageTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = S.of(context);
    final operations = ref.watch(
      filteredStorageEntriesProvider.select((e) => e.length),
    );
    final device = ref.watch(storageTargetDeviceProvider)?.deviceId;
    final stores = ref.watch(
      storageSnapshotsProvider.select((s) => s[device] ?? const {}),
    );
    return SegmentedTabBar(
      controller: DefaultTabController.of(context),
      tabs: [
        SegmentedTab(
          icon: LucideIcons.history,
          label: loc.storageTabHistory,
          count: operations,
        ),
        SegmentedTab(
          icon: LucideIcons.keyRound,
          label: loc.storageTabKeyValue,
          count: stores.values.fold(0, (n, s) => n + s.entries.length),
        ),
      ],
    );
  }
}
