import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../settings/presentation/shared/focus_ring.dart';

/// The picked table's bar: its name, how many columns and rows it has, and
/// the switch between its data and its structure.
class TableBar extends StatelessWidget {
  final DatabaseTable table;
  final bool structure;
  final ValueChanged<bool> onStructure;

  const TableBar({
    super.key,
    required this.table,
    required this.structure,
    required this.onStructure,
  });

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final loc = S.of(context);
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: p.isDark ? ColorTokens.darkBackground : Colors.white,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.table2, size: 13, color: p.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    table.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: chromeMono(
                      context,
                      size: 12.5,
                      color: p.text,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${loc.dbColumnCount(table.columns.length)}  ·  '
                  '${loc.dbRows(table.rowCount)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: p.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Switch(
            labels: [loc.dbData, loc.dbStructure],
            index: structure ? 1 : 0,
            onSelect: (i) => onStructure(i == 1),
          ),
        ],
      ),
    );
  }
}

/// A two-way switch as a quiet segmented control: the picked side raised,
/// the other plain.
class _Switch extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onSelect;

  const _Switch({
    required this.labels,
    required this.index,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, label) in labels.indexed)
            FocusRing(
              onTap: () => onSelect(i),
              radius: 5,
              selected: i == index,
              label: label,
              child: Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == index
                      ? (p.isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: i == index && !p.isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: i == index ? FontWeight.w600 : FontWeight.w500,
                    color: i == index ? p.text : p.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
