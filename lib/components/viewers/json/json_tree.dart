import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/chrome_palette.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/utils/color_values.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../misc/color_sample.dart';
import '../json_paths.dart';

/// What every node of one [JsonViewer] shares: the search (lowercased
/// [query], the [currentPath] match, the containers to [reveal]) and the
/// last expand / collapse all.
class JsonScope extends InheritedWidget {
  final String query;
  final String? currentPath;
  final Set<String> reveal;
  final int generation;
  final bool? expandAll;

  const JsonScope({
    super.key,
    required this.query,
    required this.currentPath,
    required this.reveal,
    required this.generation,
    required this.expandAll,
    required super.child,
  });

  static JsonScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<JsonScope>();

  @override
  bool updateShouldNotify(JsonScope old) =>
      query != old.query ||
      currentPath != old.currentPath ||
      generation != old.generation ||
      !identical(reveal, old.reveal);
}

class JsonNode extends StatefulWidget {
  /// Map key or list index; null for the root.
  final Object? keyName;
  final dynamic value;
  final String path;
  final int depth;
  final bool initiallyExpanded;

  const JsonNode({
    super.key,
    required this.keyName,
    required this.value,
    required this.path,
    required this.depth,
    this.initiallyExpanded = false,
  });

  @override
  State<JsonNode> createState() => _JsonNodeState();
}

class _JsonNodeState extends State<JsonNode> {
  /// Children are built a page at a time: a list of thousands would build
  /// thousands of rows at once.
  static const _page = 200;

  /// A string value longer than this shows only its start.
  static const _maxChars = 2000;

  late bool _expanded = widget.initiallyExpanded && widget.depth < 2;
  int _shown = _page;
  List<JsonNode>? _cachedChildren;
  int _generation = 0;
  String _query = '';
  bool _wasCurrent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = JsonScope.of(context);
    if (scope == null) return;
    if (scope.generation != _generation) {
      _generation = scope.generation;
      if (scope.expandAll case final all?) _expanded = all;
    }
    if (scope.query != _query) {
      _query = scope.query;
      if (scope.reveal.contains(widget.path)) _expanded = true;
    }
    final at = _childOnPath(scope.currentPath);
    if (at != null && at >= _shown) {
      _shown = (at ~/ _page + 1) * _page;
      _cachedChildren = null;
    }
  }

  /// Index of the child that [path] (the current search match) is in or
  /// under, when it's one of this node's.
  int? _childOnPath(String? path) {
    final own = widget.path;
    if (path == null || path.length <= own.length || !path.startsWith(own)) {
      return null;
    }
    final value = widget.value;
    if (value is List) {
      final index = RegExp(
        r'^\[(\d+)\]',
      ).firstMatch(path.substring(own.length));
      return index == null ? null : int.parse(index.group(1)!);
    }
    if (value is! Map) return null;
    var i = 0;
    for (final key in value.keys) {
      final child = jsonChildPath(own, key);
      if (path == child ||
          path.startsWith('$child.') ||
          path.startsWith('$child[')) {
        return i;
      }
      i++;
    }
    return null;
  }

  @override
  void didUpdateWidget(JsonNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Invalidate cache if value identity changes
    if (!identical(oldWidget.value, widget.value)) {
      _cachedChildren = null;
    }
  }

  List<JsonNode> _buildChildren() {
    if (_cachedChildren != null) return _cachedChildren!;
    final value = widget.value;
    final Iterable<(Object?, Object?)> entries = value is Map
        ? value.entries.map((e) => (e.key, e.value))
        : value is List
        ? value.indexed
        : const [];
    return _cachedChildren = [
      for (final (key, child) in entries.take(_shown))
        JsonNode(
          keyName: key,
          value: child,
          path: jsonChildPath(widget.path, key),
          depth: widget.depth + 1,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scope = JsonScope.of(context);
    final query = scope?.query ?? '';
    final current = query.isNotEmpty && scope?.currentPath == widget.path;
    if (current && !_wasCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.3,
            duration: const Duration(milliseconds: 150),
          );
        }
      });
    }
    _wasCurrent = current;

    final value = widget.value;
    final container = value is Map || value is List;
    final cut = value is String && value.length > _maxChars
        ? value.substring(0, _maxChars)
        : null;
    final (String text, Color color) = switch (value) {
      Map() => ('{${value.length}}', Colors.grey[500]!),
      List() => ('[${value.length}]', Colors.grey[500]!),
      String() => (
        cut == null ? '"$value"' : '"$cut…"',
        isDark ? const Color(0xFF98C379) : const Color(0xFF50A14F),
      ),
      num() => (
        '$value',
        isDark ? const Color(0xFFD19A66) : const Color(0xFF986801),
      ),
      bool() => (
        '$value',
        isDark ? const Color(0xFF56B6C2) : const Color(0xFF0184BC),
      ),
      _ => ('null', Colors.grey),
    };
    final row = _JsonRow(
      indent: widget.depth * 16.0,
      expanded: container ? _expanded : null,
      onToggle: () => setState(() => _expanded = !_expanded),
      keyText: widget.keyName?.toString(),
      valueText: text,
      valueColor: color,
      valueSamples: value is String
          ? _colorSamples(cut ?? value, widget.keyName)
          : const [],
      note: cut == null
          ? null
          : S.of(context).jsonLongValue((value as String).length),
      // Containers only match on their key.
      query: query,
      valueSearchable: !container,
      current: current,
      path: widget.path,
      copyValue: () => _copyValue(value),
      isDark: isDark,
    );
    if (!container || !_expanded) return row;
    final more =
        (value is Map ? value.length : (value as List).length) - _shown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        ..._buildChildren(),
        if (more > 0)
          _ShowMore(
            indent: (widget.depth + 1) * 16.0 + 16,
            count: more < _page ? more : _page,
            remaining: more,
            onTap: () => setState(() {
              _shown += _page;
              _cachedChildren = null;
            }),
          ),
      ],
    );
  }

  /// Where [value]'s colors get a sample in its quoted text: before the
  /// quotes when all of it is one color.
  static List<(int, Color)> _colorSamples(String value, Object? key) {
    final found = findColors(value, key: key?.toString());
    final whole =
        found.length == 1 &&
        found.single.end - found.single.start == value.trim().length;
    return [for (final c in found) (whole ? 0 : c.start + 1, c.color)];
  }

  static String _copyValue(Object? value) {
    if (value is String) return value;
    if (value is! Map && value is! List) return '$value';
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return '$value';
    }
  }
}

/// One tree line: chevron (containers), key, value, search highlights, and
/// copy-key / copy-value / copy-path buttons on hover.
class _JsonRow extends StatefulWidget {
  final double indent;

  /// Null for a leaf.
  final bool? expanded;
  final VoidCallback onToggle;
  final String? keyText;
  final String valueText;
  final Color valueColor;

  /// Color samples to show in [valueText], at these offsets.
  final List<(int, Color)> valueSamples;

  /// Muted text after the value, such as how long a cut one really is.
  final String? note;
  final String query;
  final bool valueSearchable;
  final bool current;
  final String path;
  final String Function() copyValue;
  final bool isDark;

  const _JsonRow({
    required this.indent,
    required this.expanded,
    required this.onToggle,
    required this.keyText,
    required this.valueText,
    required this.valueColor,
    required this.valueSamples,
    this.note,
    required this.query,
    required this.valueSearchable,
    required this.current,
    required this.path,
    required this.copyValue,
    required this.isDark,
  });

  @override
  State<_JsonRow> createState() => _JsonRowState();
}

class _JsonRowState extends State<_JsonRow> {
  bool _hovered = false;

  /// [text] with every occurrence of the query marked.
  InlineSpan _marked(String text, TextStyle style) =>
      markQuery(text, widget.query, style, current: widget.current);

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    showCopiedToast(context, label: label);
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final isDark = widget.isDark;
    final keyStyle = chromeMono(
      context,
      size: 12,
      color: isDark ? const Color(0xFFE06C75) : ColorTokens.primary,
      weight: FontWeight.w400,
    );
    final valueStyle = chromeMono(
      context,
      size: widget.expanded == null ? 12 : 11,
      color: widget.valueColor,
      weight: FontWeight.w400,
    );
    final keyText = widget.keyText;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: EdgeInsets.only(left: widget.indent, top: 1, bottom: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Only the chevron toggles expand. Excluded from the ambient
            // SelectionArea so the arrow isn't dragged into copied text.
            SelectionContainer.disabled(
              child: widget.expanded == null
                  ? const SizedBox(width: 16)
                  : GestureDetector(
                      onTap: widget.onToggle,
                      behavior: HitTestBehavior.opaque,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Icon(
                          widget.expanded!
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    if (keyText != null) ...[
                      _marked(keyText, keyStyle),
                      TextSpan(text: ': ', style: keyStyle),
                    ],
                    widget.valueSearchable
                        ? TextSpan(
                            children: withColorSamples(
                              widget.valueText,
                              widget.valueSamples,
                              (piece) => _marked(piece, valueStyle),
                            ),
                          )
                        : TextSpan(text: widget.valueText, style: valueStyle),
                    if (widget.note case final note?)
                      TextSpan(
                        text: '  $note',
                        style: valueStyle.copyWith(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
            if (_hovered)
              SelectionContainer.disabled(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 6),
                    if (keyText != null)
                      _RowAction(
                        icon: LucideIcons.key,
                        tooltip: loc.jsonCopyKey,
                        onTap: () => _copy(keyText, loc.jsonKeyCopied),
                      ),
                    _RowAction(
                      icon: LucideIcons.copy,
                      tooltip: loc.jsonCopyValue,
                      onTap: () =>
                          _copy(widget.copyValue(), loc.jsonValueCopied),
                    ),
                    if (widget.path.isNotEmpty)
                      _RowAction(
                        icon: LucideIcons.route,
                        tooltip: '${loc.jsonCopyPath}: ${widget.path}',
                        onTap: () => _copy(widget.path, loc.jsonPathCopied),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The line after a container's shown children: shows [count] more.
class _ShowMore extends StatelessWidget {
  final double indent;
  final int count;
  final int remaining;
  final VoidCallback onTap;

  const _ShowMore({
    required this.indent,
    required this.count,
    required this.remaining,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SelectionContainer.disabled(
      child: Padding(
        padding: EdgeInsets.only(left: indent, top: 2, bottom: 2),
        child: GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Text(
              S.of(context).jsonShowMore(count, remaining),
              style: chromeMono(
                context,
                size: 11,
                color: ColorTokens.primary,
                weight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RowAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: Icon(icon, size: 12, color: Colors.grey[500]),
        ),
      ),
    );
  }
}

/// [text] with every occurrence of the lowercased [query] marked, strongly
/// for the [current] search match.
InlineSpan markQuery(
  String text,
  String query,
  TextStyle style, {
  bool current = false,
}) {
  if (query.isEmpty) return TextSpan(text: text, style: style);
  final mark = style.copyWith(
    color: current ? const Color(0xFF1F2328) : null,
    backgroundColor: current
        ? const Color(0xFFFBBF24)
        : const Color(0x59FBBF24),
  );
  final spans = <TextSpan>[];
  final lower = text.toLowerCase();
  var start = 0;
  for (
    var i = lower.indexOf(query);
    i >= 0;
    i = lower.indexOf(query, i + query.length)
  ) {
    if (i > start) spans.add(TextSpan(text: text.substring(start, i)));
    spans.add(TextSpan(text: text.substring(i, i + query.length), style: mark));
    start = i + query.length;
  }
  if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
  return TextSpan(style: style, children: spans);
}
