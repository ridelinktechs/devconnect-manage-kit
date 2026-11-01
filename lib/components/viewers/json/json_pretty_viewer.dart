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

  /// The line with the most characters, which sizes the horizontal scroll.
  final int longestLine;

  _Formatted(this.text, this.lineStarts, this.longestLine);

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
  var longest = 0;
  var longestLength = 0;
  for (
    var at = formatted.indexOf('\n');
    ;
    at = formatted.indexOf('\n', at + 1)
  ) {
    final length = (at < 0 ? formatted.length : at) - starts.last;
    if (length > longestLength) {
      longestLength = length;
      longest = starts.length - 1;
    }
    if (at < 0) break;
    starts.add(at + 1);
  }
  return _Formatted(formatted, Int32List.fromList(starts), longest);
}

final _tokenPattern = RegExp(
  r'("(?:[^"\\]|\\.)*")\s*:'
  r'|("(?:[^"\\]|\\.)*")'
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

/// Every line has this height: rows are laid out lazily, at fixed offsets.
const _lineHeight = 18.0;

/// A line longer than this shows only its start: one line can't be drawn
/// lazily. Copy and save still take all of it.
const _maxLineChars = 20000;

/// Without a bounded height (in a caller's scroll view, a screenshot) every
/// line is laid out at once, so lines are shown up to this many characters.
const _maxUnboundedChars = 300000;

/// The search stops counting here.
const _maxMatches = 100000;

/// JSON (or any text) syntax-highlighted line by line, with line numbers,
/// copy, save and search (⌘F). Only the lines in view are built, so a
/// document of any size shows whole.
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
  final _horizontalController = ScrollController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  /// The document lowercased, for the search.
  String? _lower;

  /// Width of the longest shown line, which the horizontal scroll spans.
  double? _longestWidth;

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
    _horizontalController.dispose();
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
    _longestWidth = null;
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

  /// Width of [text] as the lines draw it.
  double _widthOf(String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _textStyle),
      textDirection: TextDirection.ltr,
      textScaler: _textScaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  /// Scrolls the current match into view.
  void _reveal() {
    final formatted = _formatted;
    if (formatted == null || _matches.isEmpty) return;
    final start = _matches[_current].$1;
    final line = formatted.lineOf(start);
    final column = math.min(start - formatted.lineStarts[line], _maxLineChars);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        final v = _scrollController.position;
        final y = 8 + line * _lineHeight;
        if (y < v.pixels || y + _lineHeight > v.pixels + v.viewportDimension) {
          v.jumpTo((y - v.viewportDimension * 0.3).clamp(0, v.maxScrollExtent));
        }
      }
      if (_horizontalController.hasClients) {
        final h = _horizontalController.position;
        final x =
            _gutterWidth +
            8 +
            _widthOf(formatted.line(line).substring(0, column));
        if (x < h.pixels + 24 || x > h.pixels + h.viewportDimension - 48) {
          h.jumpTo((x - 48).clamp(0, h.maxScrollExtent));
        }
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

  /// The lines, scrolled lazily when the height is bounded.
  Widget _lines(BoxConstraints constraints, bool isDark) {
    final formatted = _formatted!;
    final gutterWidth = _gutterWidth;
    if (!constraints.hasBoundedHeight) {
      var shown = 0;
      var chars = 0;
      while (shown < formatted.lineCount && chars < _maxUnboundedChars) {
        chars += formatted.line(shown).length + 1;
        shown++;
      }
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _gutter(
                  [for (var i = 1; i <= shown; i++) i].join('\n'),
                  gutterWidth,
                  isDark,
                ),
                Text.rich(
                  TextSpan(
                    style: _textStyle,
                    children: [
                      for (var i = 0; i < shown; i++) ...[
                        if (i > 0) const TextSpan(text: '\n'),
                        ..._lineContent(i, isDark),
                      ],
                    ],
                  ),
                ),
              ],
            ),
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
    final longest = _longestWidth ??= _widthOf(
      formatted
          .line(formatted.longestLine)
          .substring(
            0,
            math.min(
              formatted.line(formatted.longestLine).length,
              _maxLineChars,
            ),
          ),
    );
    final width = math.max(
      gutterWidth + 8 + longest + 160,
      constraints.maxWidth,
    );
    return Scrollbar(
      controller: _scrollController,
      notificationPredicate: (n) => n.depth == 1,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemExtent: _lineHeight,
              itemCount: formatted.lineCount,
              itemBuilder: (_, i) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _gutter('${i + 1}', gutterWidth, isDark),
                  Text.rich(
                    TextSpan(
                      style: _textStyle,
                      children: _lineContent(i, isDark),
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ],
              ),
            ),
          ),
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
      _longestWidth = null;
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
