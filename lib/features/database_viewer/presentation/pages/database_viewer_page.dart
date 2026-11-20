import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/device_info.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../../server/providers/server_providers.dart';
import '../../../settings/presentation/tips/page_guide_button.dart';
import '../../provider/database_providers.dart';
import '../editor/sql_editor.dart';
import '../grid/query_status_bar.dart';
import '../grid/result_grid.dart';
import '../header/table_bar.dart';
import '../shared/db_look.dart';
import '../shared/quiet_state.dart';
import '../sidebar/table_sidebar.dart';

/// Browses and queries the SQLite databases an app registered with
/// `DevConnect.registerDatabase`, laid out like a desktop database client:
/// the databases and their tables on the left; on the right the picked
/// table's bar, then the SQL editor, the result grid and its status bar, or
/// the table's structure. Picking a table runs a preview query.
class DatabaseViewerPage extends ConsumerStatefulWidget {
  const DatabaseViewerPage({super.key});

  @override
  ConsumerState<DatabaseViewerPage> createState() => _DatabaseViewerPageState();
}

class _DatabaseViewerPageState extends ConsumerState<DatabaseViewerPage> {
  final _sql = TextEditingController();

  /// The picked (database, table).
  (String, String)? _picked;

  /// Whether the picked table shows its structure rather than its data.
  bool _structure = false;

  /// Devices already asked for their schema, so rebuilds don't re-ask.
  final _asked = <String>{};

  @override
  void dispose() {
    _sql.dispose();
    super.dispose();
  }

  void _run(DeviceInfo device, List<DatabaseSchema> schemas) {
    final sql = _sql.text.trim();
    if (sql.isEmpty) return;
    ref
        .read(databaseQueryProvider.notifier)
        .run(
          device.deviceId,
          _picked?.$1 ?? schemas.firstOrNull?.name ?? '',
          sql,
          noResponse: S.of(context).dbNoResponse,
        );
  }

  void _pickTable(
    DeviceInfo device,
    List<DatabaseSchema> schemas,
    String database,
    String table,
  ) {
    setState(() {
      _picked = (database, table);
      _sql.text = 'SELECT * FROM "${table.replaceAll('"', '""')}" LIMIT 50;';
    });
    _run(device, schemas);
  }

  /// The picked table in [schemas], once they list it.
  DatabaseTable? _table(List<DatabaseSchema> schemas) {
    final (database, table) = _picked ?? ('', '');
    return schemas
        .where((s) => s.name == database)
        .firstOrNull
        ?.tables
        .where((t) => t.name == table)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final p = ChromePalette.of(context);
    final devices = ref.watch(connectedDevicesProvider);
    final selectedId = ref.watch(selectedDeviceProvider);
    // The selected device, else the only one connected.
    final target =
        devices.where((d) => d.deviceId == selectedId).firstOrNull ??
        (devices.length == 1 ? devices.single : null);
    final schemas = target == null
        ? const <DatabaseSchema>[]
        : ref.watch(databaseSchemasProvider)[target.deviceId] ?? const [];
    final query = target == null
        ? null
        : ref.watch(databaseQueryProvider)[target.deviceId];
    if (target != null && _asked.add(target.deviceId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(databaseSchemasProvider.notifier).request(target.deviceId);
        }
      });
    }
    final table = _table(schemas);

    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.only(left: 16, right: 8),
          decoration: BoxDecoration(
            color: p.isDark ? ColorTokens.darkBackground : Colors.white,
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.hardDrive,
                size: 16,
                color: ColorTokens.primary,
              ),
              const SizedBox(width: 8),
              Text(
                loc.database,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const PageGuideButton(route: '/database'),
              const SizedBox(width: 12),
              Expanded(
                child: target == null
                    ? const SizedBox.shrink()
                    : Text(
                        '${target.appName} · ${target.deviceName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: p.textMuted),
                      ),
              ),
              if (target != null)
                IconButton(
                  icon: const Icon(LucideIcons.refreshCw, size: 14),
                  color: p.textMuted,
                  visualDensity: VisualDensity.compact,
                  tooltip: loc.dbRefresh,
                  onPressed: () => ref
                      .read(databaseSchemasProvider.notifier)
                      .request(target.deviceId),
                ),
            ],
          ),
        ),
        Expanded(
          child: target == null
              ? QuietState(
                  title: loc.database,
                  subtitle: devices.isEmpty
                      ? loc.dbNoDevice
                      : loc.dbSelectDevice,
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 248,
                      child: TableSidebar(
                        schemas: schemas,
                        picked: _picked,
                        onPick: (database, name) =>
                            _pickTable(target, schemas, database, name),
                      ),
                    ),
                    VerticalDivider(width: 1, thickness: 1, color: p.border),
                    Expanded(
                      child: ColoredBox(
                        color: p.isDark
                            ? ColorTokens.darkSurface
                            : Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (table != null)
                              TableBar(
                                table: table,
                                structure: _structure,
                                onStructure: (v) =>
                                    setState(() => _structure = v),
                              ),
                            if (table != null && _structure)
                              Expanded(child: _structureOf(table))
                            else ...[
                              SqlEditor(
                                controller: _sql,
                                running: query != null && query.result == null,
                                onRun: () => _run(target, schemas),
                              ),
                              Divider(height: 1, thickness: 1, color: p.border),
                              Expanded(child: _results(query, table)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  /// [table]'s columns as a grid: name, type, key and nullability.
  Widget _structureOf(DatabaseTable table) {
    if (table.columns.isEmpty) return QuietState(title: S.of(context).noData);
    return ResultGrid(
      key: ValueKey('structure ${table.name}'),
      columns: const ['column', 'type', 'primary_key', 'nullable'],
      rows: [
        for (final c in table.columns)
          {
            'column': c.name,
            'type': c.type,
            'primary_key': c.isPrimaryKey ? 'YES' : '',
            'nullable': c.isNullable ? 'YES' : 'NO',
          },
      ],
    );
  }

  /// The last query's outcome: a hint before any, a thin bar while it runs,
  /// its error, or its rows with the status bar.
  Widget _results(DatabaseQuery? query, DatabaseTable? table) {
    final loc = S.of(context);
    final p = ChromePalette.of(context);
    return switch (query) {
      null => QuietState(title: loc.dbRunHint, subtitle: loc.dbRunHintSubtitle),
      DatabaseQuery(result: null) => Align(
        alignment: Alignment.topCenter,
        child: LinearProgressIndicator(
          minHeight: 2,
          color: dbSelection(p.isDark),
          backgroundColor: Colors.transparent,
        ),
      ),
      DatabaseQuery(result: QueryResult(:final error?)) => _ErrorNote(
        error: error,
      ),
      DatabaseQuery(:final sql, :final database, result: final result?) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: result.columns.isEmpty
                  ? QuietState(title: loc.dbRows(0))
                  : ResultGrid(
                      key: ObjectKey(result),
                      columns: result.columns,
                      rows: result.rows,
                      schema: table != null && sql.contains(table.name)
                          ? {for (final c in table.columns) c.name: c}
                          : const {},
                    ),
            ),
            QueryStatusBar(
              rows: result.rows.length,
              truncated: result.truncated,
              ms: result.executionTimeMs,
              database: database,
            ),
          ],
        ),
    };
  }
}

/// A failed query's error as a callout at the top of the results, in mono
/// so it reads like the database said it.
class _ErrorNote extends StatelessWidget {
  final String error;

  const _ErrorNote({required this.error});

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            ColorTokens.error.withValues(alpha: 0.08),
            p.isDark ? ColorTokens.darkSurface : Colors.white,
          ),
          border: const Border(
            left: BorderSide(color: ColorTokens.error, width: 2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                LucideIcons.circleAlert,
                size: 14,
                color: ColorTokens.error,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: SelectableText(
                error,
                style: chromeMono(context, size: 12, color: p.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
