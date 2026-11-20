import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../components/feedback/empty_state.dart';
import '../../../provider/round_providers.dart';
import 'grpc_detail.dart';
import 'grpc_row.dart';

class GrpcTab extends ConsumerWidget {
  const GrpcTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(grpcDisplayProvider).items;
    final selectedId = ref.watch(selectedGrpcIdProvider);
    final selected = selectedId == null
        ? null
        : entries.where((e) => e.id == selectedId).firstOrNull;

    if (entries.isEmpty) {
      return EmptyState(
        icon: LucideIcons.server,
        title: 'No gRPC calls',
        subtitle:
            'gRPC calls from the Android SDK (client:grpc_call_start / _end) appear here.',
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 360,
          child: ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final entry = entries[i];
              final isSel = entry.id == selectedId;
              return GrpcRow(
                entry: entry,
                selected: isSel,
                onTap: () =>
                    ref.read(selectedGrpcIdProvider.notifier).set(entry.id),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selected == null
              ? EmptyState(
                  icon: LucideIcons.mousePointerClick,
                  title: 'Select a call',
                  subtitle: 'Pick a row to inspect request + response.',
                )
              : GrpcDetail(entry: selected),
        ),
      ],
    );
  }
}
