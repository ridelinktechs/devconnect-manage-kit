import 'package:flutter/material.dart';

import '../../../../../models/round/protocol_entry.dart';
import '../shared/code_block.dart';
import '../shared/meta_chip.dart';
import '../shared/pill_tab.dart';

class GrpcDetail extends StatefulWidget {
  final GrpcCallEntry entry;
  const GrpcDetail({super.key, required this.entry});

  @override
  State<GrpcDetail> createState() => _GrpcDetailState();
}

class _GrpcDetailState extends State<GrpcDetail> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = widget.entry;
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
                '${e.service}.${e.method}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  MetaChip(
                    label: 'latency',
                    value: '${e.latencyMs ?? '—'} ms',
                    color: const Color(0xFF74B9FF),
                  ),
                  MetaChip(
                    label: 'status',
                    value: e.status ?? '—',
                    color: e.status == 'ok'
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                  // The raw gRPC code and sizes, as Android reports them.
                  if (e.metadata?['statusCode'] case final String code)
                    MetaChip(label: 'code', value: code, color: Colors.grey),
                  if (e.metadata?['requestBytes'] case final num bytes)
                    MetaChip(
                      label: 'req',
                      value: '$bytes B',
                      color: const Color(0xFF00CEC9),
                    ),
                  if (e.metadata?['responseBytes'] case final num bytes)
                    MetaChip(
                      label: 'res',
                      value: '$bytes B',
                      color: const Color(0xFF00CEC9),
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
              PillTab(
                label: 'Request',
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              const SizedBox(width: 4),
              PillTab(
                label: 'Response',
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
              if (e.error != null) ...[
                const SizedBox(width: 4),
                PillTab(
                  label: 'Error',
                  selected: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _body(),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    final e = widget.entry;
    switch (_tab) {
      case 0:
        return CodeBlock(
          text: e.request.isNotEmpty ? e.request : _notCaptured('requestBytes'),
        );
      case 1:
        return CodeBlock(
          text:
              e.response ??
              (e.status == null
                  ? '(no response yet)'
                  : _notCaptured('responseBytes')),
        );
      case 2:
        return CodeBlock(text: e.error ?? '(no error)');
    }
    return const SizedBox.shrink();
  }

  /// The SDK reports message sizes, not bodies.
  String _notCaptured(String bytesKey) =>
      switch (widget.entry.metadata?[bytesKey]) {
        final num bytes => '($bytes bytes — message bodies are not captured)',
        _ => '(not captured)',
      };
}
