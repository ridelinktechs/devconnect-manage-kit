import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/inputs/search_field.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../settings/presentation/shared/focus_ring.dart';
import '../shared/db_look.dart';

/// The databases an app registered and their tables with row counts, under
/// a filter, like a database client's sidebar. Picking a table previews it.
class TableSidebar extends StatefulWidget {
  final List<DatabaseSchema> schemas;

  /// The picked (database, table).
  final (String, String)? picked;
  final void Function(String database, String table) onPick;

  const TableSidebar({
    super.key,
    required this.schemas,
    required this.picked,
    required this.onPick,
  });

  @override
  State<TableSidebar> createState() => _TableSidebarState();
}

class _TableSidebarState extends State<TableSidebar> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final loc = S.of(context);
    final filter = _filter.toLowerCase();
    final empty = widget.schemas.every((s) => s.tables.isEmpty);
    return ColoredBox(
      color: p.isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!empty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
              child: SearchField(
                hintText: loc.dbFilterTables,
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
          Expanded(
            child: empty
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      loc.dbNoDatabases,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: p.textMuted,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 10),
                    children: [
                      for (final schema in widget.schemas)
                        if (schema.tables.where(
                              (t) => t.name.toLowerCase().contains(filter),
                            )
                            case final tables when tables.isNotEmpty) ...[
                          _GroupHeader(name: schema.name, count: tables.length),
                          for (final table in tables)
                            _TableRow(
                              table: table,
                              selected:
                                  widget.picked == (schema.name, table.name),
                              onTap: () =>
                                  widget.onPick(schema.name, table.name),
                            ),
                        ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// A database's name over its tables, with how many show.
class _GroupHeader extends StatelessWidget {
  final String name;
  final int count;

  const _GroupHeader({required this.name, required this.count});

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        children: [
          Icon(LucideIcons.database, size: 12, color: p.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: p.textMuted,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              color: p.textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// One table: its name and row count, tinted blue when picked.
class _TableRow extends StatefulWidget {
  final DatabaseTable table;
  final bool selected;
  final VoidCallback onTap;

  const _TableRow({
    required this.table,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final selected = widget.selected;
    final fill = selected
        ? dbSelection(p.isDark).withValues(alpha: p.isDark ? 0.22 : 0.12)
        : (_hover ? p.hover : Colors.transparent);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: FocusRing(
        onTap: widget.onTap,
        radius: 6,
        selected: selected,
        label: widget.table.name,
        onHover: (v) => setState(() => _hover = v),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.table2,
                size: 13,
                color: selected ? p.text : p.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.table.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: p.text,
                  ),
                ),
              ),
              Text(
                NumberFormat.decimalPattern().format(widget.table.rowCount),
                style: TextStyle(
                  fontSize: 11,
                  color: p.textMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
