import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/utils/duration_format.dart';
import '../../../../components/feedback/empty_state.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../provider/database_providers.dart';

class DatabaseViewerPage extends ConsumerStatefulWidget {
  const DatabaseViewerPage({super.key});

  @override
  ConsumerState<DatabaseViewerPage> createState() => _DatabaseViewerPageState();
}

class _DatabaseViewerPageState extends ConsumerState<DatabaseViewerPage> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schemas = ref.watch(databaseSchemaProvider);
    final selectedTable = ref.watch(selectedTableProvider);
    final queryResult = ref.watch(queryResultProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Toolbar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
          ),
          child: Row(
            children: [
              Icon(LucideIcons.hardDrive, size: 16, color: ColorTokens.primary),
              const SizedBox(width: 8),
              Text('Database', style: theme.textTheme.titleMedium),
              const Spacer(),
            ],
          ),
        ),
        const Divider(height: 1),
        // Content
        Expanded(
          child: schemas.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.hardDrive,
                  title: 'No database connected',
                  subtitle:
                      'Connect a device with SQLite to browse tables and run queries',
                )
              : Row(
                  children: [
                    // Table list
                    SizedBox(
                      width: 220,
                      child: Container(
                        color: isDark
                            ? const Color(0xFF0D1117)
                            : const Color(0xFFF6F8FA),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'TABLES',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[500],
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                children: schemas.expand((schema) {
                                  return schema.tables.map((table) {
                                    final isSelected =
                                        selectedTable == table.name;
                                    return GestureDetector(
                                      onTap: () {
                                        ref
                                            .read(selectedTableProvider.notifier)
                                            .state = table.name;
                                      },
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          color: isSelected
                                              ? ColorTokens.selectedBg(
                                                  Theme.of(context).brightness == Brightness.dark)
                                              : null,
                                          child: Row(
                                            children: [
                                              Icon(
                                                LucideIcons.table2,
                                                size: 14,
                                                color: isSelected
                                                    ? ColorTokens.selectedAccent
                                                    : Colors.grey[500],
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  table.name,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                    color: isSelected
                                                        ? ColorTokens.selectedAccent
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${table.rowCount}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  });
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    VerticalDivider(width: 1, color: theme.dividerColor),
                    // Main content
                    Expanded(
                      child: Column(
                        children: [
                          // Query editor
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF161B22)
                                  : Colors.white,
                              border: Border(
                                bottom: BorderSide(color: theme.dividerColor),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _queryController,
                                    style: TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'SELECT * FROM table_name LIMIT 100',
                                      hintStyle: TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 13,
                                        color: Colors.grey[500],
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: theme.dividerColor,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                    maxLines: 2,
                                    minLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Execute query via WebSocket
                                  },
                                  icon: const Icon(LucideIcons.play, size: 14),
                                  label: const Text('Run'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorTokens.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Results
                          Expanded(
                            child: queryResult == null
                                ? const EmptyState(
                                    icon: LucideIcons.table2,
                                    title: 'Run a query to see results',
                                    subtitle:
                                        'Select a table or write a custom SQL query',
                                  )
                                : _QueryResultView(result: queryResult),
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

class _QueryResultView extends StatelessWidget {
  final QueryResult result;

  const _QueryResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (result.error != null) {
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
              Text(
                result.error!,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: ColorTokens.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Stats bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: isDark
              ? const Color(0xFF161B22)
              : const Color(0xFFF6F8FA),
          child: Row(
            children: [
              Text(
                '${result.rows.length} rows',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(width: 12),
              Text(
                formatDuration(result.executionTimeMs),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        // Data table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 32,
                columnSpacing: 24,
                headingTextStyle: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ColorTokens.primary,
                ),
                dataTextStyle: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
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
