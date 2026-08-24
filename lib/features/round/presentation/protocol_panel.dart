import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/feedback/empty_state.dart';
import '../../../components/viewers/json_viewer.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../models/round/protocol_entry.dart';
import '../provider/round_providers.dart';

/// Round 3 — Protocol inspector (GraphQL + WebSocket + gRPC).
///
/// Implemented as a single tabbed panel with 3 sub-tabs at the top so a
/// QA can pivot between protocols without leaving the Network Inspector.
class ProtocolPanel extends ConsumerStatefulWidget {
  const ProtocolPanel({super.key});

  @override
  ConsumerState<ProtocolPanel> createState() => _ProtocolPanelState();
}

class _ProtocolPanelState extends ConsumerState<ProtocolPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
          ),
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: ColorTokens.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: ColorTokens.primary,
            indicatorWeight: 2,
            tabs: const [
              Tab(text: 'GraphQL'),
              Tab(text: 'WebSocket'),
              Tab(text: 'gRPC'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              _GraphqlTab(),
              _WebsocketTab(),
              _GrpcTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// GraphQL
// ============================================================

class _GraphqlTab extends ConsumerWidget {
  const _GraphqlTab();

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
              return _GraphqlRow(
                entry: entry,
                selected: isSel,
                onTap: () => ref
                    .read(selectedGraphqlIdProvider.notifier)
                    .state = entry.id,
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
              : _GraphqlDetail(entry: selected),
        ),
      ],
    );
  }
}

class _GraphqlRow extends StatelessWidget {
  final GraphqlEntry entry;
  final bool selected;
  final VoidCallback onTap;

  const _GraphqlRow({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  static final _time = DateFormat('HH:mm:ss.SSS');

  Color _typeColor() {
    switch (entry.type) {
      case 'mutation':
        return const Color(0xFFFDAA5E);
      case 'subscription':
        return const Color(0xFFFD79A8);
      default:
        return const Color(0xFF00CEC9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tcolor = _typeColor();
    final isComplete = entry.isComplete;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 28,
              color: selected ? ColorTokens.primary : Colors.transparent,
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tcolor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.type.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tcolor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
            if (entry.cacheHit) ...[
              const SizedBox(width: 4),
              Icon(LucideIcons.database,
                  size: 12, color: Colors.grey[500]),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.operation,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    isComplete
                        ? '${entry.latencyMs ?? '?'} ms'
                        : 'pending...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _time.format(
                  DateTime.fromMillisecondsSinceEpoch(entry.timestamp)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphqlDetail extends StatefulWidget {
  final GraphqlEntry entry;
  const _GraphqlDetail({required this.entry});

  @override
  State<_GraphqlDetail> createState() => _GraphqlDetailState();
}

class _GraphqlDetailState extends State<_GraphqlDetail> {
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
                  color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.operation,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  _MetaChip(
                      label: 'type', value: e.type, color: ColorTokens.primary),
                  _MetaChip(
                      label: 'latency',
                      value: '${e.latencyMs ?? '—'} ms',
                      color: const Color(0xFF74B9FF)),
                  _MetaChip(
                      label: 'cache',
                      value: e.cacheHit ? 'hit' : 'miss',
                      color: e.cacheHit
                          ? const Color(0xFF10B981)
                          : Colors.grey),
                  _MetaChip(
                      label: 'status',
                      value: e.isComplete ? 'complete' : 'pending',
                      color: e.isComplete
                          ? const Color(0xFF10B981)
                          : const Color(0xFFFDAA5E)),
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
                  _PillTab(
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
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(err['message']?.toString() ?? '(no message)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          if (err['path'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                  'path: ${err['path']}',
                                  style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11)),
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

class _MetaChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetaChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label:',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ============================================================
// WebSocket
// ============================================================

class _WebsocketTab extends ConsumerWidget {
  const _WebsocketTab();

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
            'client:websocket_frame events appear here. Sent and received.',
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
              return _WsRow(
                entry: entry,
                selected: isSel,
                onTap: () => ref
                    .read(selectedWebsocketIdProvider.notifier)
                    .state = entry.id,
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
              : _WsDetail(entry: selected),
        ),
      ],
    );
  }
}

class _WsRow extends StatelessWidget {
  final WebsocketFrameEntry entry;
  final bool selected;
  final VoidCallback onTap;

  const _WsRow({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  static final _time = DateFormat('HH:mm:ss.SSS');

  Color _dirColor() {
    switch (entry.direction) {
      case 'received':
        return const Color(0xFF00CEC9);
      case 'open':
        return const Color(0xFF10B981);
      case 'close':
        return const Color(0xFFFDAA5E);
      case 'error':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF74B9FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dcolor = _dirColor();
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 24,
              color: selected ? ColorTokens.primary : Colors.transparent,
            ),
            const SizedBox(width: 8),
            Icon(
              entry.direction == 'sent'
                  ? LucideIcons.arrowUp
                  : entry.direction == 'received'
                      ? LucideIcons.arrowDown
                      : LucideIcons.zap,
              size: 14,
              color: dcolor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.url.isEmpty ? '(no url)' : entry.url,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Text('${entry.sizeBytes}B',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
            const SizedBox(width: 8),
            Text(
              _time.format(
                  DateTime.fromMillisecondsSinceEpoch(entry.timestamp)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WsDetail extends StatelessWidget {
  final WebsocketFrameEntry entry;
  const _WsDetail({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(entry.url.isEmpty ? '(no url)' : entry.url,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              _IconTextBtn(
                icon: LucideIcons.copy,
                label: 'Copy',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: entry.payload));
                  showCopiedToast(context, label: 'Frame copied');
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _MetaChip(
                label: 'dir',
                value: entry.direction,
                color: const Color(0xFF00CEC9),
              ),
              const SizedBox(width: 6),
              _MetaChip(
                label: 'size',
                value: '${entry.sizeBytes} B',
                color: const Color(0xFF74B9FF),
              ),
              const SizedBox(width: 6),
              _MetaChip(
                label: 'at',
                value: DateFormat('HH:mm:ss.SSS').format(
                    DateTime.fromMillisecondsSinceEpoch(entry.timestamp)),
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.5)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _prettyOrRaw(entry.payload),
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _prettyOrRaw(String raw) {
    if (raw.isEmpty) return '(empty)';
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }
}

// ============================================================
// gRPC
// ============================================================

class _GrpcTab extends ConsumerWidget {
  const _GrpcTab();

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
            'Unary and streaming gRPC calls (client:grpc_call) appear here.',
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
              return _GrpcRow(
                entry: entry,
                selected: isSel,
                onTap: () => ref
                    .read(selectedGrpcIdProvider.notifier)
                    .state = entry.id,
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
              : _GrpcDetail(entry: selected),
        ),
      ],
    );
  }
}

class _GrpcRow extends StatelessWidget {
  final GrpcCallEntry entry;
  final bool selected;
  final VoidCallback onTap;

  const _GrpcRow({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  static final _time = DateFormat('HH:mm:ss.SSS');

  Color _statusColor() {
    switch (entry.status) {
      case 'ok':
        return const Color(0xFF10B981);
      case 'error':
        return const Color(0xFFEF4444);
      case 'cancelled':
        return const Color(0xFFFDAA5E);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scolor = _statusColor();
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 28,
              color: selected ? ColorTokens.primary : Colors.transparent,
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.server, size: 14, color: scolor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${entry.service}.${entry.method}',
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    entry.latencyMs != null
                        ? '${entry.latencyMs} ms · ${entry.status ?? '—'}'
                        : 'pending...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _time.format(
                  DateTime.fromMillisecondsSinceEpoch(entry.timestamp)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrpcDetail extends StatefulWidget {
  final GrpcCallEntry entry;
  const _GrpcDetail({required this.entry});

  @override
  State<_GrpcDetail> createState() => _GrpcDetailState();
}

class _GrpcDetailState extends State<_GrpcDetail> {
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
                  color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${e.service}.${e.method}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  _MetaChip(
                      label: 'latency',
                      value: '${e.latencyMs ?? '—'} ms',
                      color: const Color(0xFF74B9FF)),
                  _MetaChip(
                      label: 'status',
                      value: e.status ?? '—',
                      color: e.status == 'ok'
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444)),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _PillTab(
                  label: 'Request',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0)),
              const SizedBox(width: 4),
              _PillTab(
                  label: 'Response',
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1)),
              if (e.error != null) ...[
                const SizedBox(width: 4),
                _PillTab(
                    label: 'Error',
                    selected: _tab == 2,
                    onTap: () => setState(() => _tab = 2)),
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
        return _CodeBlock(text: e.request);
      case 1:
        return _CodeBlock(text: e.response ?? '(no response yet)');
      case 2:
        return _CodeBlock(text: e.error ?? '(no error)');
    }
    return const SizedBox.shrink();
  }
}

class _CodeBlock extends StatelessWidget {
  final String text;
  const _CodeBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pretty = _tryPretty(text);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          pretty,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }

  String _tryPretty(String raw) {
    if (raw.isEmpty) return '(empty)';
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }
}

// ============================================================
// Shared widgets
// ============================================================

class _PillTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PillTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? ColorTokens.primary.withValues(alpha: 0.18)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected
                  ? ColorTokens.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconTextBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _IconTextBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}
