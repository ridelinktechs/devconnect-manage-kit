import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/layout/segmented_tab_bar.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../provider/round_providers.dart';

/// GraphQL / WebSocket / gRPC, each with how many items it holds.
class ProtocolTabs extends ConsumerWidget {
  final TabController controller;
  const ProtocolTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = S.of(context);
    return SegmentedTabBar(
      controller: controller,
      secondary: true,
      tabs: [
        SegmentedTab(
          icon: LucideIcons.braces,
          label: 'GraphQL',
          count: ref.watch(
            graphqlDisplayProvider.select((d) => d.items.length),
          ),
          tooltip: loc.protocolGraphqlHint,
        ),
        SegmentedTab(
          icon: LucideIcons.radio,
          label: 'WebSocket',
          count: ref.watch(
            websocketDisplayProvider.select((d) => d.items.length),
          ),
          tooltip: loc.protocolWebsocketHint,
        ),
        SegmentedTab(
          icon: LucideIcons.server,
          label: 'gRPC',
          count: ref.watch(grpcDisplayProvider.select((d) => d.items.length)),
          tooltip: loc.protocolGrpcHint,
        ),
      ],
    );
  }
}
