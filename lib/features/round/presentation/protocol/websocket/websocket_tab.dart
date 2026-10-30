import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../components/feedback/empty_state.dart';
import '../../../provider/round_providers.dart';
import 'ws_detail.dart';
import 'ws_row.dart';

class WebsocketTab extends ConsumerWidget {
  const WebsocketTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(websocketDisplayProvider).items;
    final selectedId = ref.watch(selectedWebsocketIdProvider);
    final selected = selectedId == null
        ? null
        : entries.where((e) => e.id == selectedId).firstOrNull;

    if (entries.isEmpty) {
      return EmptyState(
        icon: LucideIcons.radio,
        title: 'No WebSocket frames',
        subtitle:
            'client:ws_open / ws_frame / ws_close events appear here: connections and every frame sent or received.',
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
              return WsRow(
                entry: entry,
                selected: isSel,
                onTap: () => ref
                    .read(selectedWebsocketIdProvider.notifier)
                    .set(entry.id),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selected == null
              ? EmptyState(
                  icon: LucideIcons.mousePointerClick,
                  title: 'Select a frame',
                  subtitle: 'Pick a row to inspect the raw payload.',
                )
              : WsDetail(entry: selected),
        ),
      ],
    );
  }
}
