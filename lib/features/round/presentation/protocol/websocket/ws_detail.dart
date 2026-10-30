import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/utils/ui/toast_utils.dart';
import '../../../../../models/round/protocol_entry.dart';
import '../shared/meta_chip.dart';
import 'icon_text_btn.dart';

class WsDetail extends StatelessWidget {
  final WebsocketFrameEntry entry;
  const WsDetail({super.key, required this.entry});

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
              Text(
                entry.url.isEmpty ? '(no url)' : entry.url,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconTextBtn(
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
              MetaChip(
                label: 'dir',
                value: entry.direction,
                color: const Color(0xFF00CEC9),
              ),
              const SizedBox(width: 6),
              MetaChip(
                label: 'size',
                value: '${entry.sizeBytes} B',
                color: const Color(0xFF74B9FF),
              ),
              if (entry.closeCode != null) ...[
                const SizedBox(width: 6),
                MetaChip(
                  label: 'code',
                  value: '${entry.closeCode}',
                  color: const Color(0xFFFDAA5E),
                ),
              ],
              const SizedBox(width: 6),
              MetaChip(
                label: 'at',
                value: DateFormat(
                  'HH:mm:ss.SSS',
                ).format(DateTime.fromMillisecondsSinceEpoch(entry.timestamp)),
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
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  // A close shows its reason; a frame, its payload.
                  _prettyOrRaw(
                    entry.payload.isEmpty
                        ? entry.closeReason ?? ''
                        : entry.payload,
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
