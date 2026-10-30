import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/color_tokens.dart';
import '../../../../../models/round/protocol_entry.dart';

class GrpcRow extends StatelessWidget {
  final GrpcCallEntry entry;
  final bool selected;
  final VoidCallback onTap;

  const GrpcRow({
    super.key,
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
                DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
              ),
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
