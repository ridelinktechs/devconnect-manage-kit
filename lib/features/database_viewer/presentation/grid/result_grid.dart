import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/ui/toast_utils.dart';
import '../../../../models/storage/storage_entry.dart';
import '../shared/db_look.dart';

const _rowHeight = 26.0;
const _headerHeight = 30.0;
const _cellPad = 10.0;

/// [value] as one line of a cell.
String _cellText(Object? value) => switch (value) {
  null => 'NULL',
  String() => value.replaceAll('\n', '↵'),
  Map() || List() => jsonEncode(value),
  _ => '$value',
};

/// A query's rows as a data grid, the way database clients show them: a
/// header that stays on top with each column's name and, when the schema
/// knows it, its type and key; a row-number gutter; cells in mono, numbers
/// on the right and NULL set apart. Clicking a cell picks it; double-clicking
/// copies its value.
class ResultGrid extends StatefulWidget {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;

  /// The schema's columns by name, for types and keys.
  final Map<String, DatabaseColumn> schema;

  const ResultGrid({
    super.key,
    required this.columns,
    required this.rows,
    this.schema = const {},
  });

  @override
  State<ResultGrid> createState() => _ResultGridState();
}

class _ResultGridState extends State<ResultGrid> {
  final _h = ScrollController();
  final _v = ScrollController();

  /// The picked cell, as (row, column).
  (int, int)? _picked;
  int? _hover;
  List<double>? _widths;

  @override
  void dispose() {
    _h.dispose();
    _v.dispose();
    super.dispose();
  }

  /// Each column as wide as its header or its longest value in the first
  /// rows, within limits.
  List<double> _measure(TextStyle mono, TextStyle head, TextStyle type) {
    final probe = TextPainter(
      text: TextSpan(text: '0' * 10, style: mono),
      textDirection: TextDirection.ltr,
    )..layout();
    final advance = probe.width / 10;
    probe.dispose();
    final sample = widget.rows.take(200).toList();
    return [
      for (final name in widget.columns)
        _width(name, sample, advance, head, type),
    ];
  }

  double _width(
    String name,
    List<Map<String, dynamic>> sample,
    double advance,
    TextStyle head,
    TextStyle type,
  ) {
    var chars = 0;
    for (final row in sample) {
      chars = math.max(chars, _cellText(row[name]).length);
    }
    final column = widget.schema[name];
    final header = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(text: name, style: head),
          if (column != null) TextSpan(text: '  ${column.type}', style: type),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final key = column?.isPrimaryKey == true ? 15.0 : 0.0;
    final width = math.max((chars + 1) * advance, header.width + key + 4);
    header.dispose();
    return (width + 2 * _cellPad).clamp(72.0, 360.0);
  }

  void _copy(Object? value) {
    Clipboard.setData(
      ClipboardData(text: value is String ? value : _cellText(value)),
    );
    showCopiedToast(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final blue = dbSelection(p.isDark);
    final mono = chromeMono(context, size: 12, color: p.text);
    final head = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: p.text,
    );
    final type = chromeMono(context, size: 10.5, color: p.textMuted);
    final widths = _widths ??= _measure(mono, head, type);
    final gutter = math.max(40.0, '${widget.rows.length}'.length * 8.0 + 22);
    final total = gutter + widths.fold(0.0, (a, b) => a + b);
    final line = p.border.withValues(alpha: p.isDark ? 0.55 : 0.7);
    final stripe = p.isDark
        ? Colors.white.withValues(alpha: 0.025)
        : Colors.black.withValues(alpha: 0.025);
    final number = chromeMono(
      context,
      size: 11,
      color: p.textMuted,
    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final noBars = ScrollConfiguration.of(context).copyWith(scrollbars: false);

    Widget cell(int i, int j, Object? value) {
      final isNum = value is num;
      return Listener(
        onPointerDown: (_) => setState(() => _picked = (i, j)),
        child: GestureDetector(
          onDoubleTap: () => _copy(value),
          child: Container(
            width: widths[j],
            padding: const EdgeInsets.symmetric(horizontal: _cellPad),
            alignment: isNum ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: line.withValues(alpha: 0.5)),
              ),
            ),
            foregroundDecoration: _picked == (i, j)
                ? BoxDecoration(border: Border.all(color: blue, width: 1.5))
                : null,
            child: Text(
              _cellText(value),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: value == null
                  ? mono.copyWith(
                      color: p.textMuted,
                      fontStyle: FontStyle.italic,
                    )
                  : mono,
            ),
          ),
        ),
      );
    }

    Widget row(int i) {
      final values = widget.rows[i];
      final fill = _picked?.$1 == i
          ? blue.withValues(alpha: p.isDark ? 0.16 : 0.08)
          : _hover == i
          ? p.hover
          : (i.isOdd ? stripe : Colors.transparent);
      return MouseRegion(
        onEnter: (_) => setState(() => _hover = i),
        onExit: (_) {
          if (_hover == i) setState(() => _hover = null);
        },
        child: ColoredBox(
          color: fill,
          child: Row(
            children: [
              Container(
                width: gutter,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: line)),
                ),
                child: Text('${i + 1}', style: number),
              ),
              for (final (j, name) in widget.columns.indexed)
                cell(i, j, values[name]),
            ],
          ),
        ),
      );
    }

    final header = Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        color: p.isDark ? ColorTokens.darkBackground : ColorTokens.lightSurface,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          Container(
            width: gutter,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: line)),
            ),
          ),
          for (final (j, name) in widget.columns.indexed)
            _HeaderCell(
              width: widths[j],
              name: name,
              column: widget.schema[name],
              line: line,
              head: head,
              type: type,
            ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) => Scrollbar(
        controller: _v,
        notificationPredicate: (n) => n.depth == 1,
        child: Scrollbar(
          controller: _h,
          child: ScrollConfiguration(
            behavior: noBars,
            child: SingleChildScrollView(
              controller: _h,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(total, constraints.maxWidth),
                child: Column(
                  children: [
                    header,
                    Expanded(
                      child: ListView.builder(
                        controller: _v,
                        itemExtent: _rowHeight,
                        itemCount: widget.rows.length,
                        itemBuilder: (context, i) => row(i),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A column's name in the header, its type after it in mono and a gold key
/// before it when it's the primary key.
class _HeaderCell extends StatelessWidget {
  final double width;
  final String name;
  final DatabaseColumn? column;
  final Color line;
  final TextStyle head;
  final TextStyle type;

  const _HeaderCell({
    required this.width,
    required this.name,
    required this.column,
    required this.line,
    required this.head,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final column = this.column;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: _cellPad),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: line)),
      ),
      child: Row(
        children: [
          if (column?.isPrimaryKey == true) ...[
            const Icon(LucideIcons.keyRound, size: 11, color: dbKeyGold),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: name, style: head),
                  if (column != null)
                    TextSpan(text: '  ${column.type}', style: type),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
