import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/color_tokens.dart';
import '../../../../../models/round/protocol_entry.dart';

class GraphqlRow extends StatelessWidget {
  final GraphqlEntry entry;
  final bool selected;
  final VoidCallback onTap;

  const GraphqlRow({
    super.key,
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              Icon(LucideIcons.database, size: 12, color: Colors.grey[500]),
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
                    isComplete ? '${entry.latencyMs ?? '?'} ms' : 'pending...',
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
