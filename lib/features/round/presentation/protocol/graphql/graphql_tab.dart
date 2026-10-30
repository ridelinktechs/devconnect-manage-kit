import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../components/feedback/empty_state.dart';
import '../../../provider/round_providers.dart';
import 'graphql_detail.dart';
import 'graphql_row.dart';

class GraphqlTab extends ConsumerWidget {
  const GraphqlTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(graphqlDisplayProvider).items;
    final selectedId = ref.watch(selectedGraphqlIdProvider);
    final selected = selectedId == null
        ? null
        : entries.where((e) => e.id == selectedId).firstOrNull;

    if (entries.isEmpty) {
      return EmptyState(
        icon: LucideIcons.braces,
        title: 'No GraphQL operations',
        subtitle:
            'client:graphql_operation / client:graphql_response events appear here.',
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
              return GraphqlRow(
                entry: entry,
                selected: isSel,
                onTap: () =>
                    ref.read(selectedGraphqlIdProvider.notifier).set(entry.id),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selected == null
              ? EmptyState(
                  icon: LucideIcons.mousePointerClick,
                  title: 'Select an operation',
                  subtitle:
                      'Pick a row to inspect variables + response + errors.',
                )
              : GraphqlDetail(entry: selected),
        ),
      ],
    );
  }
}
