import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/collections/lru_cache.dart';
import '../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../core/utils/ui/toast_utils.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'json_mini_button.dart';
import 'json_search_field.dart';
import 'text_search.dart';

/// A document laid out for display: its text and where each line starts.
class _Formatted {
  final String text;
  final Int32List lineStarts;

  /// Per line, a generous count of the columns it fills: its length, plus
  /// one per non-ASCII unit and seven per tab.
  final Int32List cells;

  _Formatted(this.text, this.lineStarts, this.cells);

  int get lineCount => lineStarts.length;

  String line(int i) => text.substring(
    lineStarts[i],
    i + 1 < lineStarts.length ? lineStarts[i + 1] - 1 : text.length,
  );

  /// The line holding character [offset].
  int lineOf(int offset) {
    var lo = 0;
    var hi = lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (lineStarts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }
}

/// Runs in an isolate: [rawData] as indented JSON (or as its text), with
/// where each line starts.
_Formatted _format(dynamic rawData) {
  dynamic data = rawData;
  if (rawData is String) {
    try {
      data = jsonDecode(rawData);
    } catch (_) {
      data = rawData;
    }
  }

  String formatted;
  try {
    if (data is Map || data is List) {
      formatted = const JsonEncoder.withIndent('  ').convert(data);
    } else {
      formatted = data?.toString() ?? 'null';
    }
  } catch (e) {
    formatted = data?.toString() ?? 'null';
  }

  final starts = <int>[0];
  final cells = <int>[];
  for (
    var at = formatted.indexOf('\n');
    ;
    at = formatted.indexOf('\n', at + 1)
  ) {
    final end = at < 0 ? formatted.length : at;
    var count = end - starts.last;
    for (var k = starts.last; k < end; k++) {
      final unit = formatted.codeUnitAt(k);
      if (unit > 0x7F) {
        count++;
      } else if (unit == 0x09) {
        count += 7;
      }
    }
    cells.add(count);
    if (at < 0) break;
    starts.add(at + 1);
  }
  return _Formatted(
    formatted,
    Int32List.fromList(starts),
    Int32List.fromList(cells),
  );
}

final _tokenPattern = RegExp(
  r'("(?:[^"\\]|\\.)*")\s*:'
  r'|("(?:[^"\\]|\\.)*(?:"|$))'
  r'|(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)'
  r'|(true|false)'
  r'|(null)'
  r'|([{}\[\]])'
  r'|([,:])',
);

/// [line] as syntax-coloured spans.
List<TextSpan> _lineSpans(String line, bool isDark) {
  final key = Color(isDark ? 0xFF9CDCFE : 0xFF0451A5);
  final string = Color(isDark ? 0xFFCE9178 : 0xFFA31515);
  final number = Color(isDark ? 0xFFB5CEA8 : 0xFF098658);
  final literal = Color(isDark ? 0xFF569CD6 : 0xFF0000FF);
  final bracket = Color(isDark ? 0xFFFFD700 : 0xFF000000);
  final punct = Color(isDark ? 0xFFD4D4D4 : 0xFF000000);
  final plain = TextStyle(color: Color(isDark ? 0xFFD4D4D4 : 0xFF1F2328));

  final spans = <TextSpan>[];
  var cursor = 0;
  for (final m in _tokenPattern.allMatches(line)) {
    if (m.start > cursor) {
      spans.add(TextSpan(text: line.substring(cursor, m.start), style: plain));
    }
    final color = m.group(1) != null
        ? key
        : m.group(2) != null
        ? string
        : m.group(3) != null
        ? number
        : m.group(4) != null || m.group(5) != null
        ? literal
        : m.group(6) != null
        ? bracket
        : punct;
    spans.add(
      TextSpan(
        text: m.group(0),
        style: TextStyle(
          color: color,
          fontWeight: m.group(1) != null ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
    cursor = m.end;
  }
  if (cursor < line.length) {
    spans.add(TextSpan(text: line.substring(cursor), style: plain));
  }
  return spans;
}

/// Global cache keyed by data identity. Bounded to ~32 MB — old entries
/// are evicted in LRU order once the budget is exceeded.
final _highlightCache = LruCache<int, _Formatted>(
  maxBytes: 32 * 1024 * 1024,
  weightOf: (f) => f.text.length * 2 + f.lineStarts.lengthInBytes,
);

/// Background-time tracker. When the app is paused/hidden for longer than
/// [_idleClearThreshold], [_highlightCache] is cleared on resume so that
/// stale (and possibly stale-by-data-version) entries don't linger.
class HighlightCacheLifecycleObserver with WidgetsBindingObserver {
  static const Duration _idleClearThreshold = Duration(minutes: 20);
  static final HighlightCacheLifecycleObserver instance =
      HighlightCacheLifecycleObserver._();

  DateTime? _pausedAt;

  HighlightCacheLifecycleObserver._();

  void attach() {
    WidgetsBinding.instance.addObserver(this);
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Drops every cached highlight. Call when the data context changes
  /// (device switch, project switch, etc.) so stale values aren't reused.
  void clearCache() => _highlightCache.clear();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _pausedAt ??= DateTime.now();
        break;
      case AppLifecycleState.resumed:
        final pausedAt = _pausedAt;
        _pausedAt = null;
        if (pausedAt != null) {
          final elapsed = DateTime.now().difference(pausedAt);
          if (elapsed >= _idleClearThreshold) {
            _highlightCache.clear();
          }
        }
        break;
      case AppLifecycleState.inactive:
        // Transient state (e.g. incoming call, control center) — keep timer.
        break;
    }
  }
}

/// Height of one row of text; a long line wraps onto several.
const _lineHeight = 18.0;

/// A line longer than this shows only its start: finding where it wraps
/// lays all of it out. Copy and save still take all of it.
const _maxLineChars = 20000;

/// Without a bounded height (in a caller's scroll view, a screenshot) every
/// line is laid out at once, so lines are shown up to this many characters.
const _maxUnboundedChars = 300000;

/// The search stops counting here.
const _maxMatches = 100000;

/// The rows a document's lines take once wrapped. Each row is drawn on its
/// own, so a long line scrolling into view costs no more than a short one.
class _Rows {
  /// `first[i]` is line `i`'s first row; the last entry is the row count.
  final Int32List first;

  /// For each line that wraps, where in it each of its rows starts.
  final Map<int, Int32List> breaks;

  _Rows(this.first, this.breaks);

  int get count => first.last;

  /// The line row [row] belongs to.
  int lineOf(int row) {
    var lo = 0;
    var hi = first.length - 2;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (first[mid] <= row) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }
}

/// The part of [spans] (plain text, no children) from character [from] up
/// to [to], or to the end.
List<TextSpan> _slice(List<TextSpan> spans, int from, int? to) {
  final out = <TextSpan>[];
  var offset = 0;
  for (final span in spans) {
    final text = span.text ?? '';
    final end = offset + text.length;
    if (end > from && (to == null || offset < to)) {
      final a = math.max(from, offset) - offset;
      final b = (to == null ? end : math.min(to, end)) - offset;
      out.add(
        a == 0 && b == text.length
            ? span
            : TextSpan(text: text.substring(a, b), style: span.style),
      );
    }
    offset = end;
  }
  return out;
}

/// JSON (or any text) syntax-highlighted line by line, with line numbers,
/// copy, save and search (⌘F). Long lines wrap. Only the lines in view are
/// built, so a document of any size shows whole.
class JsonPrettyViewer extends StatefulWidget {
  final dynamic data;

  const JsonPrettyViewer({super.key, required this.data});

  @override
  State<JsonPrettyViewer> createState() => _JsonPrettyViewerState();
}

class _JsonPrettyViewerState extends State<JsonPrettyViewer> {
  _Formatted? _formatted;
  bool _loading = true;
  bool _saving = false;
  final _scrollController = SmoothScrollController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  /// The document lowercased, for the search.
  String? _lower;

  /// The rows the lines take once wrapped to [_rowsWidth].
  _Rows? _rows;
  double _rowsWidth = 0;

  /// The lines last built and what they were built from. A rebuild with the
  /// same inputs — the page redrawing for a new request, say — reuses them,
  /// so the visible lines aren't built again mid-scroll.
  Widget? _linesWidget;
  Object? _linesInputs;

  /// The style and scaler the lines were last built with.
  TextStyle _textStyle = const TextStyle();
  TextScaler _textScaler = TextScaler.noScaling;

  /// Where the search query shows up in the text.
  List<(int, int)> _matches = const [];
  int _current = 0;

  /// The cache key for the entry currently displayed. Pinned so a cache
  /// pressure from other pages can't evict the value the user is looking at.
  int? _pinnedKey;

  @override
  void dispose() {
    if (_pinnedKey != null) {
      _highlightCache.unpin(_pinnedKey!);
    }
    _scrollController.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pinnedKey = _cacheKey;
    _highlightCache.pin(_pinnedKey!);
    _startCompute();
  }

  @override
  void didUpdateWidget(JsonPrettyViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      // Unpin the previous entry so it becomes evictable again.
      if (_pinnedKey != null) {
        _highlightCache.unpin(_pinnedKey!);
      }
      _pinnedKey = _cacheKey;
      _highlightCache.pin(_pinnedKey!);
      _show(null);
      _startCompute();
    }
  }

  int get _cacheKey => identityHashCode(widget.data);

  void _startCompute() {
    final cached = _highlightCache.get(_cacheKey);
    if (cached != null) {
      _show(cached);
      // Mark the build dirty so the cached result is rendered without
      // sitting in the loading state for a frame.
      if (mounted) setState(() {});
      return;
    }

    _loading = true;
    compute(_format, widget.data)
        .then((formatted) {
          if (!mounted) return;
          _highlightCache.put(_cacheKey, formatted);
          setState(() => _show(formatted));
        })
        .catchError((e) {
          if (!mounted) return;
          setState(() => _loading = false);
        });
  }

  /// Shows [formatted] (none while it's being computed).
  void _show(_Formatted? formatted) {
    _formatted = formatted;
    _loading = formatted == null;
    _lower = null;
    _rows = null;
    _applySearch();
  }

  void _applySearch() {
    final formatted = _formatted;
    if (formatted == null) {
      _matches = const [];
      return;
    }
    if (_search.text.trim().isNotEmpty && _lower == null) {
      final lower = formatted.text.toLowerCase();
      // A few characters change length when lowercased; then match case.
      _lower = lower.length == formatted.text.length ? lower : formatted.text;
    }
    _matches = findMatches(
      formatted.text,
      _search.text,
      lower: _lower,
      limit: _maxMatches,
    );
    if (_current >= _matches.length) _current = 0;
  }

  void _onQuery(String query) {
    setState(() {
      _current = 0;
      _applySearch();
    });
    _reveal();
  }

  void _step(int delta) {
    final n = _matches.length;
    if (n == 0) return;
    setState(() => _current = ((_current + delta) % n + n) % n);
    _reveal();
  }

  double get _gutterWidth =>
      '${_formatted?.lineCount ?? 0}'.length * 8.0 + 16.0;

  /// The widest ASCII glyph as the lines draw it, in the keys' weight.
  double _cellWidth() {
    var widest = 0.0;
    for (final glyph in const ['W', 'M', '@', '%', 'm', 'w']) {
      final painter = TextPainter(
        text: TextSpan(
          text: glyph,
          style: _textStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
        textScaler: _textScaler,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    return widest;
  }

  /// Line [index] laid out [width] wide, as the lines draw it.
  TextPainter _layoutLine(int index, double width, bool isDark) => TextPainter(
    text: TextSpan(style: _textStyle, children: _lineContent(index, isDark)),
    textDirection: TextDirection.ltr,
    textScaler: _textScaler,
  )..layout(maxWidth: width);

  /// [_rows] for text [width] wide: a line that surely fits takes one row;
  /// a longer one is laid out to find where it wraps.
  _Rows _rowsFor(double width, bool isDark) {
    final cached = _rows;
    if (cached != null && _rowsWidth == width) return cached;
    final formatted = _formatted!;
    final oneRow = width / _cellWidth();
    final first = Int32List(formatted.lineCount + 1);
    final breaks = <int, Int32List>{};
    for (var i = 0; i < formatted.lineCount; i++) {
      var rows = 1;
      if (formatted.cells[i] > oneRow) {
        final painter = _layoutLine(i, width, isDark);
        final starts = <int>[];
        for (final metrics in painter.computeLineMetrics()) {
          final start = painter
              .getLineBoundary(
                painter.getPositionForOffset(Offset(0, metrics.baseline)),
              )
              .start;
          if (starts.isEmpty || start > starts.last) starts.add(start);
        }
        painter.dispose();
        if (starts.length > 1) {
          breaks[i] = Int32List.fromList(starts);
          rows = starts.length;
        }
      }
      first[i + 1] = first[i] + rows;
    }
    _rowsWidth = width;
    return _rows = _Rows(first, breaks);
  }

  /// Scrolls the current match into view.
  void _reveal() {
    final formatted = _formatted;
    if (formatted == null || _matches.isEmpty) return;
    final start = _matches[_current].$1;
    final line = formatted.lineOf(start);
    final column = math.min(start - formatted.lineStarts[line], _maxLineChars);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rows = _rows;
      if (!mounted || rows == null || !_scrollController.hasClients) {
        return;
      }
      var row = rows.first[line];
      final breaks = rows.breaks[line];
      for (var r = 1; breaks != null && r < breaks.length; r++) {
        if (breaks[r] > column) break;
        row++;
      }
      final y = 8 + row * _lineHeight;
      final v = _scrollController.position;
      if (y < v.pixels || y + _lineHeight > v.pixels + v.viewportDimension) {
        v.jumpTo((y - v.viewportDimension * 0.3).clamp(0, v.maxScrollExtent));
      }
    });
  }

  /// Index of the first match at or after character [offset].
  int _firstMatchFrom(int offset) {
    var lo = 0;
    var hi = _matches.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_matches[mid].$1 < offset) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Line [index] as highlighted spans, with the search matches marked
  /// and, when it's too long to show whole, how long it is.
  List<TextSpan> _lineContent(int index, bool isDark) {
    final formatted = _formatted!;
    final start = formatted.lineStarts[index];
    final whole = formatted.line(index);
    final cut = whole.length > _maxLineChars;
    final text = cut ? whole.substring(0, _maxLineChars) : whole;
    var spans = _lineSpans(text, isDark);
    final first = _firstMatchFrom(start);
    final hits = <(int, int)>[];
    for (
      var i = first;
      i < _matches.length && _matches[i].$1 < start + text.length;
      i++
    ) {
      hits.add((_matches[i].$1 - start, _matches[i].$2 - start));
    }
    if (hits.isNotEmpty) spans = markMatches(spans, hits, _current - first);
    return [
      ...spans,
      if (cut)
        TextSpan(
          text: '  ${S.of(context).jsonLongValue(whole.length)}',
          style: TextStyle(color: Colors.grey[500]),
        ),
    ];
  }

  /// The line-number gutter, showing [numbers].
  Widget _gutter(String numbers, double width, bool isDark) =>
      // Line number gutter is excluded from selection
      // so dragging across multiple lines doesn't pull
      // the numbers into the copied text.
      SelectionContainer.disabled(
        child: Container(
          width: width,
          padding: const EdgeInsets.only(right: 8),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          alignment: Alignment.topRight,
          child: Text(
            numbers,
            textAlign: TextAlign.right,
            style: _textStyle.copyWith(
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ),
      );

  /// Lines [from] to [to] (exclusive), wrapped, beside their numbers.
  Widget _block(int from, int to, double gutterWidth, bool isDark) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _gutter(
        [for (var i = from + 1; i <= to; i++) i].join('\n'),
        gutterWidth,
        isDark,
      ),
      Expanded(
        child: Text.rich(
          TextSpan(
            style: _textStyle,
            children: [
              for (var i = from; i < to; i++) ...[
                if (i > from) const TextSpan(text: '\n'),
                ..._lineContent(i, isDark),
              ],
            ],
          ),
        ),
      ),
    ],
  );

  /// [_buildLines], reused while nothing it reads has changed.
  Widget _lines(BoxConstraints constraints, bool isDark) {
    final inputs = (
      _formatted,
      constraints,
      isDark,
      _matches,
      _current,
      _textStyle,
      _textScaler,
      Localizations.localeOf(context),
    );
    final cached = _linesWidget;
    if (cached != null && inputs == _linesInputs) return cached;
    _linesInputs = inputs;
    return _linesWidget = _buildLines(constraints, isDark);
  }

  /// The lines, scrolled lazily when the height is bounded.
  Widget _buildLines(BoxConstraints constraints, bool isDark) {
    final formatted = _formatted!;
    final gutterWidth = _gutterWidth;
    final textWidth = math.max(
      1.0,
      constraints.maxWidth - gutterWidth - 8 - 16,
    );
    if (!constraints.hasBoundedHeight) {
      var shown = 0;
      var chars = 0;
      while (shown < formatted.lineCount && chars < _maxUnboundedChars) {
        chars += formatted.line(shown).length + 1;
        shown++;
      }
      final oneRow = textWidth / _cellWidth();
      final blocks = <Widget>[];
      var run = 0;
      for (var i = 0; i <= shown; i++) {
        if (i < shown && formatted.cells[i] <= oneRow) continue;
        for (final (from, to) in [(run, i), if (i < shown) (i, i + 1)]) {
          if (to > from) {
            blocks.add(
              IntrinsicHeight(child: _block(from, to, gutterWidth, isDark)),
            );
          }
        }
        run = i + 1;
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...blocks,
            if (shown < formatted.lineCount)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  S.of(context).jsonPrettyCut(shown, formatted.lineCount),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ),
          ],
        ),
      );
    }
    final rows = _rowsFor(textWidth, isDark);
    final wrapped = <int, List<TextSpan>>{};
    return Scrollbar(
      controller: _scrollController,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              sliver: SliverFixedExtentList(
                itemExtent: _lineHeight,
                delegate: SliverChildBuilderDelegate((_, r) {
                  final line = rows.lineOf(r);
                  final breaks = rows.breaks[line];
                  if (breaks == null) {
                    return _block(line, line + 1, gutterWidth, isDark);
                  }
                  final row = r - rows.first[line];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _gutter(
                        row == 0 ? '${line + 1}' : '',
                        gutterWidth,
                        isDark,
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: _textStyle,
                            children: _slice(
                              wrapped.putIfAbsent(
                                line,
                                () => _lineContent(line, isDark),
                              ),
                              breaks[row],
                              row + 1 < breaks.length ? breaks[row + 1] : null,
                            ),
                          ),
                          softWrap: false,
                        ),
                      ),
                    ],
                  );
                }, childCount: rows.count),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveJsonFile(String content) async {
    final fileName = 'data_${DateTime.now().millisecondsSinceEpoch}.json';
    final location = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: [
        const XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (location == null) return;
    if (mounted) setState(() => _saving = true);
    try {
      await File(location.path).writeAsString(content);
      if (!mounted) return;
      showSuccessToast(context, message: 'Saved JSON', subtitle: fileName);
    } catch (e) {
      if (!mounted) return;
      showErrorToast(context, message: 'Save failed', error: e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = DefaultTextStyle.of(context).style.merge(
      const TextStyle(
        fontFamily: AppConstants.monoFontFamily,
        fontSize: 12,
        height: 1.5,
      ),
    );
    final scaler = MediaQuery.textScalerOf(context);
    if (style != _textStyle || scaler != _textScaler) {
      _textStyle = style;
      _textScaler = scaler;
      _rows = null;
    }
    final lineCount = _formatted?.lineCount ?? 0;

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
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toolbar
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF252526)
                      : const Color(0xFFF0F0F0),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.braces,
                      size: 12,
                      color: isDark
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF0451A5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'JSON',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppConstants.monoFontFamily,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    if (!_loading) ...[
                      const SizedBox(width: 8),
                      Text(
                        '$lineCount lines',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: AppConstants.monoFontFamily,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 8),
                      JsonSearchField(
                        search: _search,
                        searchFocus: _searchFocus,
                        onQuery: _onQuery,
                        matchCount: _matches.length,
                        current: _current,
                        onStep: _step,
                        capped: _matches.length >= _maxMatches,
                        isDark: isDark,
                      ),
                    ] else
                      const Spacer(),
                    if (!_loading && _formatted != null) ...[
                      JsonMiniButton(
                        icon: LucideIcons.copy,
                        tooltip: 'Copy JSON',
                        isDark: isDark,
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: _formatted!.text),
                          );
                          showCopiedToast(context, label: 'JSON copied');
                        },
                      ),
                      const SizedBox(width: 4),
                      JsonMiniButton(
                        icon: LucideIcons.download,
                        tooltip: 'Save as file',
                        isDark: isDark,
                        loading: _saving,
                        onTap: _saving
                            ? () {}
                            : () => _saveJsonFile(_formatted!.text),
                      ),
                    ],
                  ],
                ),
              ),
              // Content — unified smooth scrollable view
              if (_loading || _formatted == null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: _loading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                )
              else
                Flexible(
                  child: SelectionArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) =>
                          _lines(constraints, isDark),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
