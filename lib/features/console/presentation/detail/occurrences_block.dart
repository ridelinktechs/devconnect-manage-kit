import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/log/log_entry.dart';
import '../shared/section_label.dart';

/// Every run of a folded log: when each one ran and how long after the one
/// before. Picking one shows its own time, metadata and stack trace in the
/// detail panel.
class OccurrencesBlock extends StatefulWidget {
  final List<LogEntry> occurrences;
  final String selectedId;
  final Color color;
  final ValueChanged<LogEntry> onSelect;

  const OccurrencesBlock({
    super.key,
    required this.occurrences,
    required this.selectedId,
    required this.color,
    required this.onSelect,
  });

  static const _rowHeight = 28.0;

  @override
  State<OccurrencesBlock> createState() => _OccurrencesBlockState();
}

class _OccurrencesBlockState extends State<OccurrencesBlock> {
  final _scroll = SmoothScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OccurrencesBlock(:occurrences, :selectedId, :color, :onSelect) =
        widget;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('HH:mm:ss.SSS');
    DateTime at(LogEntry e) => DateTime.fromMillisecondsSinceEpoch(e.timestamp);
    final first = at(occurrences.first);
    final last = at(occurrences.last);
    final mono = chromeMono(
      context,
      size: 11.5,
      color: isDark ? Colors.white70 : Colors.black87,
    );
    final muted = chromeMono(context, size: 11, color: Colors.grey.shade500);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SectionLabel(
              label:
                  '${S.of(context).consoleOccurrences} · ${occurrences.length}',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${time.format(first)} → ${time.format(last)} '
                '(${formatGap(last.difference(first))})',
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: math.min(occurrences.length, 8) * OccurrencesBlock._rowHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: ListView.builder(
            controller: _scroll,
            itemCount: occurrences.length,
            itemExtent: OccurrencesBlock._rowHeight,
            itemBuilder: (context, i) {
              final e = occurrences[i];
              final selected = e.id == selectedId;
              return Material(
                color: selected
                    ? color.withValues(alpha: 0.16)
                    : Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(e),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text('#${i + 1}', style: muted),
                        ),
                        Text(
                          time.format(at(e)),
                          style: mono.copyWith(
                            fontWeight: selected ? FontWeight.w700 : null,
                          ),
                        ),
                        const Spacer(),
                        if (i > 0)
                          Text(
                            '+${formatGap(at(e).difference(at(occurrences[i - 1])))}',
                            style: muted,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// [d] the short way: `520ms`, `1.52s`, `2m 05s`.
String formatGap(Duration d) {
  if (d.inMilliseconds < 1000) return '${d.inMilliseconds}ms';
  if (d.inSeconds < 60) {
    return '${(d.inMilliseconds / 1000).toStringAsFixed(2)}s';
  }
  return '${d.inMinutes}m ${(d.inSeconds % 60).toString().padLeft(2, '0')}s';
}
