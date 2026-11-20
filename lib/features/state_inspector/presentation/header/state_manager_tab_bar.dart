import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/layout/segmented_tab_bar.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../round/provider/round_providers.dart';
import '../../provider/state_providers.dart';
import '../../provider/state_tools_providers.dart';

/// The State Inspector's tabs as the segmented control the Network page
/// uses — Timeline, State Managers and State Tools — each with what it
/// holds.
class StateManagerTabBar extends ConsumerWidget {
  const StateManagerTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final changes = ref.watch(
      filteredStateChangesProvider.select((e) => e.length),
    );
    final managers = ref.watch(
      filteredStateRoundProvider.select((e) => e.length),
    );
    final snapshots = ref.watch(stateSnapshotsProvider.select((s) => s.length));
    return SegmentedTabBar(
      controller: DefaultTabController.of(context),
      tabs: [
        SegmentedTab(
          icon: LucideIcons.history,
          label: 'Timeline',
          count: changes,
          tooltip: 'Changes from every state library, with their actions',
        ),
        SegmentedTab(
          icon: LucideIcons.boxes,
          label: 'State Managers',
          count: managers,
          tooltip: 'BLoC, Provider, React Query and Apollo updates',
        ),
        SegmentedTab(
          icon: LucideIcons.wrench,
          label: S.of(context).stateToolsTab,
          count: snapshots,
        ),
      ],
    );
  }
}
