import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/chrome_palette.dart';
import '../../core/utils/save_file.dart';
import '../../core/utils/smooth_scroll_controller.dart';
import '../../core/utils/toast_utils.dart';
import '../../l10n/app_localizations.dart';
import 'json/json_mini_button.dart';
import 'json/json_table.dart';
import 'json/json_tree.dart';
import 'json_paths.dart';

export 'json/code_viewer.dart';
export 'json/json_pretty_viewer.dart';
export 'json/lazy_views.dart';
export 'json/view_mode_switcher.dart';

/// JSON tree: expand / collapse all, search (⌘F; Enter / ⇧Enter step
/// through matches, which get revealed and highlighted), copy a row's key,
/// value or path on hover, and a table view for a list of objects (the
/// search filters its rows; it downloads as CSV).
class JsonViewer extends StatefulWidget {
  final dynamic data;
  final bool initiallyExpanded;

  const JsonViewer({
    super.key,
    required this.data,
    this.initiallyExpanded = true,
  });

  @override
  State<JsonViewer> createState() => _JsonViewerState();
}

class _JsonViewerState extends State<JsonViewer> {
  final _scrollController = SmoothScrollController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  /// Bumped by expand / collapse all; every node then adopts [_expandAll].
  int _generation = 0;
  bool? _expandAll;
  bool _table = false;
  ({List<String> matches, Set<String> ancestors}) _found = (
    matches: const [],
    ancestors: const {},
  );
  int _current = 0;

  @override
  void didUpdateWidget(JsonViewer old) {
    super.didUpdateWidget(old);
    if (!identical(old.data, widget.data) && _search.text.isNotEmpty) {
      _found = jsonSearch(widget.data, _search.text);
      _current = 0;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  String _formatAll() {
    try {
      return const JsonEncoder.withIndent('  ').convert(widget.data);
    } catch (_) {
      return widget.data?.toString() ?? 'null';
    }
  }

  void _setAll(bool expanded) => setState(() {
    _expandAll = expanded;
    _generation++;
  });

  void _onQuery(String query) => setState(() {
    _found = jsonSearch(widget.data, query);
    _current = 0;
  });

  void _step(int delta) {
    final n = _found.matches.length;
    if (n == 0) return;
    setState(() => _current = ((_current + delta) % n + n) % n);
  }

  Future<void> _exportCsv(List rows, List<int> hits, List<String> columns) =>
      saveTextFile(
        context,
        suggestedName: exportFileName('table', 'csv'),
        typeLabel: 'CSV',
        extension: 'csv',
        // A byte-order mark first, so Excel reads the file as UTF-8.
        content:
            String.fromCharCode(0xFEFF) +
            jsonTableCsv([for (final i in hits) rows[i] as Map], columns),
      );

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data == null) {
      return Text('null', style: Theme.of(context).textTheme.labelMedium);
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final columns = jsonTableColumns(data);
    final table = _table && columns != null;
    final matches = _found.matches;
    final query = _search.text.trim();
    // Rows of the table the search keeps (all of them without one).
    final hits = table ? jsonTableFilter(data as List, query) : const <int>[];
    return CallbackShortcuts(
      bindings: {
        SingleActivator(
          LogicalKeyboardKey.keyF,
          meta: Platform.isMacOS,
          control: !Platform.isMacOS,
        ): () =>
            _searchFocus.requestFocus(),
      },
      child: Focus(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _JsonViewerToolbar(
              isDark: isDark,
              tableAvailable: columns != null,
              table: table,
              onTable: (v) => setState(() => _table = v),
              search: _search,
              searchFocus: _searchFocus,
              onQuery: _onQuery,
              matchCount: matches.length,
              current: _current,
              onStep: _step,
              tableCount: table && query.isNotEmpty
                  ? '${hits.length}/${(data as List).length}'
                  : null,
              onExportCsv: table
                  ? () => _exportCsv(data as List, hits, columns)
                  : null,
              onExpandAll: () => _setAll(true),
              onCollapseAll: () => _setAll(false),
              onCopyAll: () {
                Clipboard.setData(ClipboardData(text: _formatAll()));
                showCopiedToast(context, label: 'Tree copied as JSON');
              },
            ),
            const SizedBox(height: 6),
            Flexible(
              child: table
                  ? JsonTable(
                      rows: data as List,
                      hits: hits,
                      columns: columns,
                      query: query.toLowerCase(),
                    )
                  : SelectionArea(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            JsonScope(
                              query: _search.text.trim().toLowerCase(),
                              currentPath: matches.isEmpty
                                  ? null
                                  : matches[_current],
                              reveal: _found.ancestors,
                              generation: _generation,
                              expandAll: _expandAll,
                              child: JsonNode(
                                keyName: null,
                                value: data,
                                path: '',
                                depth: 0,
                                initiallyExpanded: widget.initiallyExpanded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JsonViewerToolbar extends StatelessWidget {
  final bool isDark;
  final bool tableAvailable;
  final bool table;
  final ValueChanged<bool> onTable;
  final TextEditingController search;
  final FocusNode searchFocus;
  final ValueChanged<String> onQuery;
  final int matchCount;
  final int current;
  final ValueChanged<int> onStep;

  /// Table mode: `shown/total` rows while searching.
  final String? tableCount;
  final VoidCallback? onExportCsv;
  final VoidCallback onExpandAll;
  final VoidCallback onCollapseAll;
  final VoidCallback onCopyAll;

  const _JsonViewerToolbar({
    required this.isDark,
    required this.tableAvailable,
    required this.table,
    required this.onTable,
    required this.search,
    required this.searchFocus,
    required this.onQuery,
    required this.matchCount,
    required this.current,
    required this.onStep,
    required this.tableCount,
    required this.onExportCsv,
    required this.onExpandAll,
    required this.onCollapseAll,
    required this.onCopyAll,
  });

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final muted = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final accent = isDark ? const Color(0xFF7FD4E4) : const Color(0xFF0451A5);
    Widget mode(
      String label,
      IconData icon,
      bool selected,
      VoidCallback onTap,
    ) => GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: selected
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06))
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: selected ? accent : muted),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: selected ? accent : muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final hasQuery = search.text.trim().isNotEmpty;
    return Container(
      height: 32,
      padding: const EdgeInsets.only(left: 8, right: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252526) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          mode(
            loc.jsonTreeView,
            LucideIcons.listTree,
            !table,
            () => onTable(false),
          ),
          if (tableAvailable) ...[
            const SizedBox(width: 2),
            mode(
              loc.jsonTableView,
              LucideIcons.table2,
              table,
              () => onTable(true),
            ),
          ],
          const SizedBox(width: 8),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(
                    LogicalKeyboardKey.enter,
                    shift: true,
                  ): () =>
                      onStep(-1),
                  const SingleActivator(LogicalKeyboardKey.escape): () {
                    search.clear();
                    onQuery('');
                  },
                },
                child: TextField(
                  controller: search,
                  focusNode: searchFocus,
                  onChanged: onQuery,
                  onSubmitted: (_) {
                    onStep(1);
                    searchFocus.requestFocus();
                  },
                  style: chromeMono(
                    context,
                    size: 11,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: loc.jsonSearchHint,
                    hintStyle: TextStyle(fontSize: 11, color: muted),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 12,
                      color: muted,
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 24),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ),
          ),
          if (hasQuery && table)
            Text(tableCount ?? '', style: TextStyle(fontSize: 10, color: muted))
          else if (hasQuery) ...[
            Text(
              matchCount == 0 ? '0' : '${current + 1}/$matchCount',
              style: TextStyle(fontSize: 10, color: muted),
            ),
            JsonMiniButton(
              icon: LucideIcons.chevronUp,
              tooltip: '${loc.jsonPrevMatch} (⇧↵)',
              isDark: isDark,
              onTap: () => onStep(-1),
            ),
            JsonMiniButton(
              icon: LucideIcons.chevronDown,
              tooltip: '${loc.jsonNextMatch} (↵)',
              isDark: isDark,
              onTap: () => onStep(1),
            ),
          ],
          const Spacer(),
          if (!table) ...[
            JsonMiniButton(
              icon: LucideIcons.chevronsUpDown,
              tooltip: loc.jsonExpandAll,
              isDark: isDark,
              onTap: onExpandAll,
            ),
            JsonMiniButton(
              icon: LucideIcons.chevronsDownUp,
              tooltip: loc.jsonCollapseAll,
              isDark: isDark,
              onTap: onCollapseAll,
            ),
          ],
          if (onExportCsv != null)
            JsonMiniButton(
              icon: LucideIcons.download,
              tooltip: loc.jsonExportCsv,
              isDark: isDark,
              onTap: onExportCsv!,
            ),
          JsonMiniButton(
            icon: LucideIcons.copy,
            tooltip: 'Copy entire tree as JSON',
            isDark: isDark,
            onTap: onCopyAll,
          ),
        ],
      ),
    );
  }
}
