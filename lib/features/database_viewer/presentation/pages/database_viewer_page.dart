import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../components/feedback/empty_state_with_pulse.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/format/duration_format.dart';
import '../../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/device_info.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../../server/providers/server_providers.dart';
import '../../../settings/presentation/tips/page_guide_button.dart';
import '../../provider/database_providers.dart';

/// Browses and queries the SQLite databases an app registered with
/// `DevConnect.registerDatabase`: tables (with row counts) on the left, a
/// SQL editor and the result grid on the right. Picking a table runs a
/// preview query.
class DatabaseViewerPage extends ConsumerStatefulWidget {
  const DatabaseViewerPage({super.key});

  @override
  ConsumerState<DatabaseViewerPage> createState() => _DatabaseViewerPageState();
}

class _DatabaseViewerPageState extends ConsumerState<DatabaseViewerPage> {
  final _sql = TextEditingController();

  /// The picked (database, table).
  (String, String)? _picked;

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

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final devices = ref.watch(connectedDevicesProvider);
    final selectedId = ref.watch(selectedDeviceProvider);
    // The selected device, else the only one connected.
    final target =
        devices.where((d) => d.deviceId == selectedId).firstOrNull ??
        (devices.length == 1 ? devices.single : null);
    final schemas = target == null
        ? null
        : ref.watch(databaseSchemasProvider)[target.deviceId];
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
    final divider = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);

    return Column(
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            border: Border(bottom: BorderSide(color: divider)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.hardDrive, size: 15, color: ColorTokens.primary),
              const SizedBox(width: 8),
              Text(
                loc.database,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const PageGuideButton(route: '/database'),
              const SizedBox(width: 10),
              Expanded(
                child: target == null
                    ? const SizedBox.shrink()
                    : Text(
                        '${target.appName} · ${target.deviceName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey[500],
                        ),
                      ),
              ),
              if (target != null)
                IconButton(
                  icon: const Icon(LucideIcons.refreshCw, size: 14),
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
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
              ? EmptyStateWithPulse(
                  icon: LucideIcons.hardDrive,
                  title: loc.database,
                  subtitle: devices.isEmpty
                      ? loc.dbNoDevice
                      : loc.dbSelectDevice,
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 240,
                      child: _TableList(
                        schemas: schemas ?? const [],
                        picked: _picked,
                        isDark: isDark,
                        onPick: (database, table) => _pickTable(
                          target,
                          schemas ?? const [],
                          database,
                          table,
                        ),
                      ),
                    ),
                    VerticalDivider(width: 1, color: divider),
                    Expanded(
                      child: Column(
                        children: [
                          _SqlEditor(
                            controller: _sql,
                            running: query != null && query.result == null,
                            isDark: isDark,
                            divider: divider,
                            onRun: () => _run(target, schemas ?? const []),
                          ),
                          Expanded(
                            child: switch (query) {
                              null => EmptyState(
                                icon: LucideIcons.table2,
                                title: loc.dbRunHint,
                                subtitle: loc.dbRunHintSubtitle,
                              ),
                              DatabaseQuery(result: null) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              DatabaseQuery(:final result?) => _QueryResultView(
                                result: result,
                              ),
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TableList extends StatelessWidget {
  final List<DatabaseSchema> schemas;
  final (String, String)? picked;
  final bool isDark;
  final void Function(String database, String table) onPick;

  const _TableList({
    required this.schemas,
    required this.picked,
    required this.isDark,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final muted = Colors.grey[500];
    final header = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: muted,
      letterSpacing: 1,
    );
    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: schemas.every((s) => s.tables.isEmpty)
          ? Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                loc.dbNoDatabases,
                style: TextStyle(fontSize: 12, height: 1.5, color: muted),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                for (final schema in schemas) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                    child: Text(
                      schemas.length > 1
                          ? schema.name.toUpperCase()
                          : loc.dbTables.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: header,
                    ),
                  ),
                  for (final table in schema.tables)
                    _TableTile(
                      table: table,
                      selected: picked == (schema.name, table.name),
                      isDark: isDark,
                      onTap: () => onPick(schema.name, table.name),
                    ),
                ],
              ],
            ),
    );
  }
}

class _TableTile extends StatelessWidget {
  final DatabaseTable table;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _TableTile({
    required this.table,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: selected ? ColorTokens.selectedBg(isDark) : null,
        child: Row(
          children: [
            Icon(
              LucideIcons.table2,
              size: 14,
              color: selected ? ColorTokens.selectedAccent : Colors.grey[500],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                table.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? ColorTokens.selectedAccent : null,
                ),
              ),
            ),
            Text(
              '${table.rowCount}',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SqlEditor extends StatelessWidget {
  final TextEditingController controller;
  final bool running;
  final bool isDark;
  final Color divider;
  final VoidCallback onRun;

  const _SqlEditor({
    required this.controller,
    required this.running,
    required this.isDark,
    required this.divider,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
        border: Border(bottom: BorderSide(color: divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: chromeMono(
                context,
                size: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'SELECT * FROM table_name LIMIT 100',
                hintStyle: chromeMono(
                  context,
                  size: 13,
                  color: Colors.grey[500]!,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: divider),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              maxLines: 3,
              minLines: 1,
              onSubmitted: (_) => onRun(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: FilledButton.icon(
              onPressed: running ? null : onRun,
              icon: running
                  ? const SizedBox.square(
                      dimension: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : const Icon(LucideIcons.play, size: 14),
              label: Text(S.of(context).dbRun),
              style: FilledButton.styleFrom(
                backgroundColor: ColorTokens.primary,
                foregroundColor: Colors.white,
                textStyle: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueryResultView extends StatefulWidget {
  final QueryResult result;

  const _QueryResultView({required this.result});

  @override
  State<_QueryResultView> createState() => _QueryResultViewState();
}

class _QueryResultViewState extends State<_QueryResultView> {
  final _verticalScrollController = SmoothScrollController();
  final _horizontalScrollController = SmoothScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final result = widget.result;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (result.error case final error?) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorTokens.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColorTokens.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.circleAlert, color: ColorTokens.error, size: 24),
              const SizedBox(height: 8),
              SelectableText(
                error,
                style: chromeMono(context, size: 12, color: ColorTokens.error),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final stats = TextStyle(fontSize: 11, color: Colors.grey[500]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: isDark ? ColorTokens.darkBackground : ColorTokens.lightSurface,
          child: Row(
            children: [
              Text(loc.dbRows(result.rows.length), style: stats),
              if (result.truncated) ...[
                const SizedBox(width: 8),
                Text(
                  loc.dbTruncated(result.rows.length),
                  style: stats.copyWith(color: ColorTokens.warning),
                ),
              ],
              const SizedBox(width: 12),
              Text(
                formatDuration(result.executionTimeMs),
                style: chromeMono(context, size: 11, color: Colors.grey[500]!),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 32,
                columnSpacing: 24,
                headingTextStyle: chromeMono(
                  context,
                  size: 11,
                  color: ColorTokens.primary,
                  weight: FontWeight.w700,
                ),
                dataTextStyle: chromeMono(
                  context,
                  size: 11,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                columns: result.columns
                    .map((c) => DataColumn(label: Text(c)))
                    .toList(),
                rows: result.rows.map((row) {
                  return DataRow(
                    cells: result.columns.map((col) {
                      return DataCell(
                        Text(
                          row[col]?.toString() ?? 'NULL',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
