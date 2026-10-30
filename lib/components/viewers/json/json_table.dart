import 'package:flutter/material.dart';

import '../../../core/theme/chrome_palette.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../misc/color_sample.dart';
import '../json_paths.dart';
import 'json_tree.dart';

/// A list of objects as a grid: one column per key, first-seen order, `#`
/// being the row's index in the list. Scrolls both ways inside its own box
/// with both scrollbars in view; the lowercased [query] is marked.
class JsonTable extends StatefulWidget {
  final List rows;

  /// Indexes of the [rows] to show (the search's matches).
  final List<int> hits;
  final List<String> columns;
  final String query;

  const JsonTable({
    super.key,
    required this.rows,
    required this.hits,
    required this.columns,
    required this.query,
  });

  /// Past this, rows are left out (the grid isn't virtualised).
  static const maxRows = 500;

  /// Height when the parent leaves it unbounded (a scrolling detail panel).
  static const maxHeight = 420.0;

  @override
  State<JsonTable> createState() => _JsonTableState();
}

class _JsonTableState extends State<JsonTable> {
  final _horizontal = SmoothScrollController();
  final _vertical = SmoothScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  /// [row]'s cell in [column]: its text, the query marked, a sample before
  /// each color.
  Widget _cell(Map row, String column, TextStyle style) {
    final value = row[column];
    return Text.rich(
      TextSpan(
        children: withColorSamples(
          row.containsKey(column) ? jsonCellText(value) : '',
          value is String ? colorSamplesIn(value, key: column) : const [],
          (piece) => markQuery(piece, widget.query, style),
        ),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = TextStyle(fontSize: 10.5, color: Colors.grey[500]);
    final cellStyle = chromeMono(
      context,
      size: 11,
      color: isDark ? Colors.white70 : Colors.black87,
    );
    final grid = DataTable(
      headingRowHeight: 30,
      dataRowMinHeight: 26,
      dataRowMaxHeight: 26,
      columnSpacing: 20,
      horizontalMargin: 8,
      headingTextStyle: chromeMono(
        context,
        size: 11,
        color: isDark ? const Color(0xFFE06C75) : ColorTokens.primary,
        weight: FontWeight.w600,
      ),
      dataTextStyle: cellStyle,
      columns: [
        const DataColumn(label: Text('#')),
        for (final c in widget.columns) DataColumn(label: Text(c)),
      ],
      rows: [
        for (final i in widget.hits.take(JsonTable.maxRows))
          DataRow(
            cells: [
              DataCell(Text('$i', style: TextStyle(color: Colors.grey[500]))),
              for (final c in widget.columns)
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: _cell(widget.rows[i] as Map, c, cellStyle),
                  ),
                ),
            ],
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : JsonTable.maxHeight,
            ),
            // Both bars hang off the visible box: the vertical one on its
            // right edge, the horizontal one (depth 1: the inner scroll
            // view's) along its bottom, wherever the grid is scrolled.
            child: Scrollbar(
              controller: _vertical,
              thumbVisibility: true,
              child: Scrollbar(
                controller: _horizontal,
                thumbVisibility: true,
                notificationPredicate: (n) => n.depth == 1,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    controller: _vertical,
                    // Room below the last row for the horizontal bar…
                    padding: const EdgeInsets.only(bottom: 14),
                    child: SingleChildScrollView(
                      controller: _horizontal,
                      scrollDirection: Axis.horizontal,
                      // …and after the last column for the vertical one.
                      padding: const EdgeInsets.only(right: 14),
                      child: SelectionArea(child: grid),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.hits.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(S.of(context).jsonTableNoMatch, style: muted),
            )
          else if (widget.hits.length > JsonTable.maxRows)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                S.of(context).jsonTableTruncated(JsonTable.maxRows),
                style: muted,
              ),
            ),
        ],
      ),
    );
  }
}
