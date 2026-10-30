import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/color_tokens.dart';
import '../../../../../models/round/protocol_entry.dart';

class WsRow extends StatelessWidget {
  final WebsocketFrameEntry entry;
  final bool selected;
  final VoidCallback onTap;

  const WsRow({
    super.key,
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
            Text(
              '${entry.sizeBytes}B',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
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
