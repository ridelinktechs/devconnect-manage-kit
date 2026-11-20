import 'package:flutter/material.dart';

import '../../../../../components/viewers/json_viewer.dart';
import '../../../../../core/theme/color_tokens.dart';
import '../../../../../models/round/protocol_entry.dart';
import '../shared/code_block.dart';
import '../shared/meta_chip.dart';
import '../shared/pill_tab.dart';

class GraphqlDetail extends StatefulWidget {
  final GraphqlEntry entry;
  const GraphqlDetail({super.key, required this.entry});

  @override
  State<GraphqlDetail> createState() => _GraphqlDetailState();
}

class _GraphqlDetailState extends State<GraphqlDetail> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = widget.entry;
    final tabs = const ['Variables', 'Response', 'Errors'];
    final showErrors = e.errors != null && e.errors!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.operation,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  MetaChip(
                    label: 'type',
                    value: e.type,
                    color: ColorTokens.primary,
                  ),
                  MetaChip(
                    label: 'latency',
                    value: '${e.latencyMs ?? '—'} ms',
                    color: const Color(0xFF74B9FF),
                  ),
                  MetaChip(
                    label: 'cache',
                    value: e.cacheHit ? 'hit' : 'miss',
                    color: e.cacheHit ? const Color(0xFF10B981) : Colors.grey,
                  ),
                  MetaChip(
                    label: 'status',
                    value: e.isComplete ? 'complete' : 'pending',
                    color: e.isComplete
                        ? const Color(0xFF10B981)
                        : const Color(0xFFFDAA5E),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                if (i != 2 || showErrors) ...[
                  PillTab(
                    label: tabs[i],
                    selected: _tab == i,
                    onTap: () => setState(() => _tab = i),
                  ),
                  const SizedBox(width: 4),
                ],
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final e = widget.entry;
    switch (_tab) {
      case 0:
        return e.variables.isEmpty
            ? const Center(child: Text('No variables'))
            : JsonPrettyViewer(data: e.variables);
      case 1:
        if (!e.isComplete) {
          return const Center(child: Text('Awaiting response...'));
        }
        // A transport failure (no GraphQL result at all).
        if (e.data == null && e.error != null) {
          return CodeBlock(text: e.error!);
        }
        return e.data == null
            ? const Center(child: Text('No data'))
            : JsonPrettyViewer(data: e.data!);
      case 2:
        return e.errors == null || e.errors!.isEmpty
            ? const Center(child: Text('No errors'))
            : ListView(
                children: [
                  for (final err in e.errors!)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            err['message']?.toString() ?? '(no message)',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (err['path'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'path: ${err['path']}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
    }
    return const SizedBox.shrink();
  }
}
