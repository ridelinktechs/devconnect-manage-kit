import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/code_generator.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/utils/code_highlighter.dart';
import '../../core/utils/lru_cache.dart';
import '../../core/utils/smooth_scroll_controller.dart';

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatAll() {
    try {
      return const JsonEncoder.withIndent('  ').convert(widget.data);
    } catch (_) {
      return widget.data?.toString() ?? 'null';
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final initiallyExpanded = widget.initiallyExpanded;
    if (data == null) {
      return Text('null', style: Theme.of(context).textTheme.labelMedium);
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // SelectionArea lets users drag across multiple rows to select/copy
    // many fields at once. Individual Text widgets become selectable as
    // part of a single unified selection scope.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar with "Copy All" button. Mirrors JsonPrettyViewer's header
        // so users always have a one-click way to copy the whole tree.
        _JsonViewerToolbar(
          isDark: isDark,
          onCopyAll: () {
            Clipboard.setData(ClipboardData(text: _formatAll()));
            showCopiedToast(context, label: 'Tree copied as JSON');
          },
        ),
        const SizedBox(height: 6),
        Flexible(
          child: SelectionArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _JsonNode(
                    keyName: null,
                    value: data,
                    depth: 0,
                    initiallyExpanded: initiallyExpanded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _JsonViewerToolbar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onCopyAll;

  const _JsonViewerToolbar({required this.isDark, required this.onCopyAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
          Icon(
            LucideIcons.listTree,
            size: 12,
            color: isDark ? const Color(0xFF7FD4E4) : const Color(0xFF0451A5),
          ),
          const SizedBox(width: 6),
          Text(
            'Tree',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: AppConstants.monoFontFamily,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const Spacer(),
          _MiniButton(
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

class _JsonNode extends StatefulWidget {
  final String? keyName;
  final dynamic value;
  final int depth;
  final bool initiallyExpanded;

  const _JsonNode({
    required this.keyName,
    required this.value,
    required this.depth,
    this.initiallyExpanded = false,
  });

  @override
  State<_JsonNode> createState() => _JsonNodeState();
}

class _JsonNodeState extends State<_JsonNode> {
  late bool _expanded;
  List<_JsonNode>? _cachedChildren;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded && widget.depth < 2;
  }

  @override
  void didUpdateWidget(_JsonNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Invalidate cache if value identity changes
    if (!identical(oldWidget.value, widget.value)) {
      _cachedChildren = null;
    }
  }

  List<_JsonNode> _buildChildren() {
    if (_cachedChildren != null) return _cachedChildren!;

    if (widget.value is Map) {
      _cachedChildren = (widget.value as Map).entries.map((e) {
        return _JsonNode(
          keyName: e.key.toString(),
          value: e.value,
          depth: widget.depth + 1,
        );
      }).toList();
    } else if (widget.value is List) {
      _cachedChildren = (widget.value as List).asMap().entries.map((e) {
        return _JsonNode(
          keyName: '${e.key}',
          value: e.value,
          depth: widget.depth + 1,
        );
      }).toList();
    } else {
      _cachedChildren = [];
    }
    return _cachedChildren!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indent = widget.depth * 16.0;

    if (widget.value is Map) {
      return _buildExpandable(
        '{${(widget.value as Map).length}}',
        indent,
        isDark,
      );
    }

    if (widget.value is List) {
      return _buildExpandable(
        '[${(widget.value as List).length}]',
        indent,
        isDark,
      );
    }

    // Primitive value
    Color valueColor;
    String displayValue;

    if (widget.value is String) {
      valueColor = isDark ? const Color(0xFF98C379) : const Color(0xFF50A14F);
      displayValue = '"${widget.value}"';
    } else if (widget.value is num) {
      valueColor = isDark ? const Color(0xFFD19A66) : const Color(0xFF986801);
      displayValue = '${widget.value}';
    } else if (widget.value is bool) {
      valueColor = isDark ? const Color(0xFF56B6C2) : const Color(0xFF0184BC);
      displayValue = '${widget.value}';
    } else {
      valueColor = Colors.grey;
      displayValue = 'null';
    }

    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.keyName != null)
              Text(
                '${widget.keyName}: ',
                style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFFE06C75)
                      : ColorTokens.primary,
                ),
              ),
            Flexible(
              child: Text(
                displayValue,
                style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
                  fontSize: 12,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandable(String badge, double indent, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: indent),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                // Only the chevron toggles expand. Excluded from the ambient
                // SelectionArea so the arrow character isn't dragged into the
                // copied text when users select across rows.
                SelectionContainer.disabled(
                  child: GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    behavior: HitTestBehavior.opaque,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Icon(
                        _expanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                if (widget.keyName != null)
                  Text(
                    '${widget.keyName}: ',
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFFE06C75)
                          : ColorTokens.primary,
                    ),
                  ),
                Text(
                  badge,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ..._buildChildren(),
      ],
    );
  }
}

/// Per-line highlight result from isolate.
class _HighlightResult {
  final String formatted;
  final int lineCount;
  /// Per-line tokens: lineTokens[i] = [text, colorInt, bold, text, colorInt, bold, ...]
  final List<List<Object>> lineTokens;

  _HighlightResult(this.formatted, this.lineCount, this.lineTokens);
}

/// Runs in isolate — per-line tokenization.
_HighlightResult _computeHighlight(List<dynamic> args) {
  final rawData = args[0];
  final isDark = args[1] as bool;

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

  final lines = formatted.split('\n');

  final dKey = isDark ? 0xFF9CDCFE : 0xFF0451A5;
  final dString = isDark ? 0xFFCE9178 : 0xFFA31515;
  final dNumber = isDark ? 0xFFB5CEA8 : 0xFF098658;
  final dBool = isDark ? 0xFF569CD6 : 0xFF0000FF;
  final dNull = isDark ? 0xFF569CD6 : 0xFF0000FF;
  final dBracket = isDark ? 0xFFFFD700 : 0xFF000000;
  final dPunct = isDark ? 0xFFD4D4D4 : 0xFF000000;
  final dPlain = isDark ? 0xFFD4D4D4 : 0xFF1F2328;

  final tokenPattern = RegExp(
    r'("(?:[^"\\]|\\.)*")\s*:'
    r'|("(?:[^"\\]|\\.)*")'
    r'|(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)'
    r'|(true|false)'
    r'|(null)'
    r'|([{}\[\]])'
    r'|([,:])',
  );

  final lineTokens = <List<Object>>[];

  for (final line in lines) {
    final tokens = <Object>[];
    int cursor = 0;

    for (final m in tokenPattern.allMatches(line)) {
      if (m.start > cursor) {
        tokens.addAll([line.substring(cursor, m.start), dPlain, 0]);
      }
      int color;
      int bold = 0;
      if (m.group(1) != null) { color = dKey; bold = 1; }
      else if (m.group(2) != null) { color = dString; }
      else if (m.group(3) != null) { color = dNumber; }
      else if (m.group(4) != null) { color = dBool; }
      else if (m.group(5) != null) { color = dNull; }
      else if (m.group(6) != null) { color = dBracket; }
      else { color = dPunct; }
      tokens.addAll([m.group(0)!, color, bold]);
      cursor = m.end;
    }
    if (cursor < line.length) {
      tokens.addAll([line.substring(cursor), dPlain, 0]);
    }
    lineTokens.add(tokens);
  }

  return _HighlightResult(formatted, lines.length, lineTokens);
}

/// Global cache keyed by data identity. Bounded to ~10 MB — old entries
/// are evicted in LRU order once the budget is exceeded.
final _highlightCache = LruCache<int, _HighlightResult>(
  maxBytes: 10 * 1024 * 1024,
  weightOf: (r) => r.formatted.length * 2 + // string chars ~2 bytes UTF-16
      r.lineTokens.length * 48, // per-line List overhead estimate
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

class JsonPrettyViewer extends StatefulWidget {
  final dynamic data;

  const JsonPrettyViewer({super.key, required this.data});

  @override
  State<JsonPrettyViewer> createState() => _JsonPrettyViewerState();
}

class _JsonPrettyViewerState extends State<JsonPrettyViewer> {
  static const double _lineHeight = 18.0;

  _HighlightResult? _result;
  bool _loading = true;
  bool? _lastIsDark;
  /// Per-line TextSpan cache — built lazily per visible line.
  final Map<int, List<TextSpan>> _lineSpanCache = {};
  final _scrollController = SmoothScrollController();
  /// The cache key for the entry currently displayed. Pinned so a cache
  /// pressure from other pages can't evict the value the user is looking at.
  int? _pinnedKey;

  @override
  void dispose() {
    if (_pinnedKey != null) {
      _highlightCache.unpin(_pinnedKey!);
    }
    _scrollController.dispose();
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
      _result = null;
      _lineSpanCache.clear();
      _startCompute();
    } else {
      // Same data — recompute if theme changed (handled in build) but
      // never show the spinner for an unchanged payload.
      _loading = _result == null;
    }
  }

  int get _cacheKey => identityHashCode(widget.data);

  void _startCompute() {
    final cached = _highlightCache.get(_cacheKey);
    if (cached != null) {
      _result = cached;
      _loading = false;
      // Mark the build dirty so the cached result is rendered without
      // sitting in the loading state for a frame.
      if (mounted) setState(() {});
      return;
    }

    _loading = true;
    final isDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;

    compute(_computeHighlight, [widget.data, isDark]).then((result) {
      if (!mounted) return;
      _highlightCache.put(_cacheKey, result);
      setState(() {
        _result = result;
        _loading = false;
      });
    }).catchError((e) {
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  List<TextSpan> _getLineSpans(int index) {
    if (_lineSpanCache.containsKey(index)) return _lineSpanCache[index]!;
    final tokens = _result!.lineTokens[index];
    final spans = <TextSpan>[];
    for (int i = 0; i < tokens.length; i += 3) {
      spans.add(TextSpan(
        text: tokens[i] as String,
        style: TextStyle(
          color: Color(tokens[i + 1] as int),
          fontWeight: (tokens[i + 2] as int) == 1
              ? FontWeight.w600
              : FontWeight.normal,
        ),
      ));
    }
    _lineSpanCache[index] = spans;
    return spans;
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
    await File(location.path).writeAsString(content);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_lastIsDark != null && _lastIsDark != isDark) {
      _lineSpanCache.clear();
      _result = null;
      _highlightCache.remove(_cacheKey);
      _startCompute();
    }
    _lastIsDark = isDark;

    final lineCount = _result?.lineCount ?? 0;
    final gutterWidth = '$lineCount'.length * 8.0 + 20;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252526) : const Color(0xFFF0F0F0),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
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
                Icon(LucideIcons.braces,
                    size: 12,
                    color: isDark
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF0451A5)),
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
                ],
                const Spacer(),
                if (!_loading) ...[
                  _MiniButton(
                    icon: LucideIcons.copy,
                    tooltip: 'Copy JSON',
                    isDark: isDark,
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: _result!.formatted));
                      showCopiedToast(context, label: 'JSON copied');
                    },
                  ),
                  const SizedBox(width: 4),
                  _MiniButton(
                    icon: LucideIcons.download,
                    tooltip: 'Save as file',
                    isDark: isDark,
                    onTap: () => _saveJsonFile(_result!.formatted),
                  ),
                ],
              ],
            ),
          ),
          // Content — virtualized per-line rendering
          if (_loading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: SelectionArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bounded = constraints.maxHeight.isFinite;
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: lineCount,
                      shrinkWrap: !bounded,
                      physics: bounded
                          ? null
                          : const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Line number gutter is excluded from selection
                              // so dragging across multiple lines doesn't pull
                              // the numbers into the copied text.
                              SelectionContainer.disabled(
                                child: SizedBox(
                                  width: gutterWidth,
                                  height: _lineHeight,
                                  child: Text(
                                    '${index + 1}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontFamily: AppConstants.monoFontFamily,
                                      fontSize: 11,
                                      height: 1.5,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                              SelectionContainer.disabled(
                                child: Container(
                                  width: 1,
                                  height: _lineHeight,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.06),
                                ),
                              ),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    style: const TextStyle(
                                      fontFamily: AppConstants.monoFontFamily,
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                    children: _getLineSpans(index),
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;

  const _MiniButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_MiniButton> createState() => _MiniButtonState();
}

class _MiniButtonState extends State<_MiniButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _hovered
                  ? (widget.isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.icon,
              size: 13,
              color: _hovered ? (widget.isDark ? Colors.white70 : Colors.black54) : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Segmented button used in detail panels for the Tree / JSON / Code
// toggle. Kept here so it can be reused across feature pages.
// ═══════════════════════════════════════════════════════════════════

enum ViewSegmentPosition { start, middle, end }

class ViewModeSegment extends StatelessWidget {
  final String label;
  final bool active;
  final ViewSegmentPosition position;
  final VoidCallback onTap;

  const ViewModeSegment({
    super.key,
    required this.label,
    required this.active,
    required this.position,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    BorderRadius radius;
    switch (position) {
      case ViewSegmentPosition.start:
        radius = const BorderRadius.only(
          topLeft: Radius.circular(5),
          bottomLeft: Radius.circular(5),
        );
        break;
      case ViewSegmentPosition.end:
        radius = const BorderRadius.only(
          topRight: Radius.circular(5),
          bottomRight: Radius.circular(5),
        );
        break;
      case ViewSegmentPosition.middle:
        radius = BorderRadius.zero;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: active
                ? ColorTokens.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: radius,
            border: Border.all(
              color: active
                  ? ColorTokens.primary.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: active ? ColorTokens.primary : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium 3-mode toggle (Tree / JSON / Code).
class ViewModeSwitcher extends StatelessWidget {
  final BodyViewMode current;
  final String codeLabel;
  final ValueChanged<BodyViewMode> onChanged;

  const ViewModeSwitcher({
    super.key,
    required this.current,
    required this.codeLabel,
    required this.onChanged,
  });

  Alignment _alignmentFor(BodyViewMode mode) {
    switch (mode) {
      case BodyViewMode.tree:
        return Alignment.centerLeft;
      case BodyViewMode.json:
        return Alignment.center;
      case BodyViewMode.code:
        return Alignment.centerRight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark
        ? const Color(0xFF1C2128).withValues(alpha: 0.6)
        : const Color(0xFFEEF0F2);
    final trackBorder = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final thumbColor = isDark ? const Color(0xFF30363D) : Colors.white;
    final thumbShadow = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      height: 30,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: trackBorder, width: 1),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: _alignmentFor(current),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 1 / 3,
              heightFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  decoration: BoxDecoration(
                    color: thumbColor,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: thumbShadow,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              _Segment(
                mode: BodyViewMode.tree,
                current: current,
                icon: LucideIcons.gitBranch,
                label: 'Tree',
                onTap: onChanged,
              ),
              _Segment(
                mode: BodyViewMode.json,
                current: current,
                icon: LucideIcons.braces,
                label: 'JSON',
                onTap: onChanged,
              ),
              _Segment(
                mode: BodyViewMode.code,
                current: current,
                icon: LucideIcons.code,
                label: codeLabel,
                onTap: onChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatefulWidget {
  final BodyViewMode mode;
  final BodyViewMode current;
  final IconData icon;
  final String label;
  final ValueChanged<BodyViewMode> onTap;

  const _Segment({
    required this.mode,
    required this.current,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = widget.mode == widget.current;
    final color = isActive
        ? ColorTokens.primary
        : (isDark ? Colors.white60 : Colors.black54);

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(widget.mode),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: _hovered && !isActive
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 11, color: color),
                  const SizedBox(width: 5),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: color,
                      fontFamily: AppConstants.monoFontFamily,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Code viewer — renders the generator's output as two stacked panels:
//   1. "Types" — a define-file-style block of named type declarations
//      (TypeScript `interface`, Dart `class`, Kotlin `data class`).
//   2. "Code"  — the typed initializer for a `body` variable.
// Both panels share a VSCode-style syntax highlighter and have their
// own Copy button.
// ═══════════════════════════════════════════════════════════════════

class CodeViewer extends StatelessWidget {
  final GeneratedCode generated;
  final CodeLang lang;
  final String languageLabel;

  const CodeViewer({
    super.key,
    required this.generated,
    required this.lang,
    required this.languageLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTypes =
        generated.types != null && generated.types!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasTypes) ...[
          _CodePanel(
            isDark: isDark,
            icon: LucideIcons.fileCode,
            title: 'Types',
            subtitle: languageLabel,
            code: generated.types!,
            lang: lang,
            copyLabel: 'Type definition copied',
          ),
          const SizedBox(height: 12),
        ],
        _CodePanel(
          isDark: isDark,
          icon: LucideIcons.code,
          title: 'Code',
          subtitle: languageLabel,
          code: generated.code,
          lang: lang,
          copyLabel: '$languageLabel code copied',
        ),
      ],
    );
  }
}

class _CodePanel extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final String code;
  final CodeLang lang;
  final String copyLabel;

  const _CodePanel({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.code,
    required this.lang,
    required this.copyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final lineCount = '\n'.allMatches(code).length + 1;
    final spans = CodeHighlighter.highlight(code, lang, isDark);

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF252526) : const Color(0xFFF0F0F0),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
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
                  icon,
                  size: 12,
                  color: isDark
                      ? const Color(0xFF7FD4E4)
                      : const Color(0xFF0451A5),
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppConstants.monoFontFamily,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '· $subtitle',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: AppConstants.monoFontFamily,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$lineCount lines',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: AppConstants.monoFontFamily,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),
                _MiniButton(
                  icon: LucideIcons.copy,
                  tooltip: 'Copy',
                  isDark: isDark,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    showCopiedToast(context, label: copyLabel);
                  },
                ),
              ],
            ),
          ),
          // Content — syntax-highlighted, selectable
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectionArea(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    height: 1.5,
                  ),
                  children: spans,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a loading spinner for 1 frame on mount, then builds the child.
///
/// Use with a [ValueKey] tied to a view mode so that switching modes
/// unmounts → remounts → defers → builds, preventing synchronous heavy
/// widget trees from blocking the tab-switch animation frame.
///
/// Example:
/// ```dart
/// DeferredBuilder(
///   key: ValueKey(currentMode),
///   builder: (_) => JsonViewer(data: parsed),
/// )
/// ```
class DeferredBuilder extends StatefulWidget {
  final WidgetBuilder builder;
  const DeferredBuilder({super.key, required this.builder});

  @override
  State<DeferredBuilder> createState() => _DeferredBuilderState();
}

class _DeferredBuilderState extends State<DeferredBuilder> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
        ),
      );
    }
    return widget.builder(context);
  }
}

/// Helper widget that ensures heavy JSON content never blocks tab transitions.
///
/// **How it works:**
/// 1. On mount (or when data changes), it immediately shows a loading spinner.
/// 2. After 1 frame (`addPostFrameCallback`), it parses the JSON (sync for
///    small payloads, isolate for large ones).
/// 3. After parsing completes, it waits 1 more frame before calling [builder]
///    so the spinner is visible and the parent layout has settled.
///
/// This guarantees the tab-switch animation completes smoothly before any
/// heavy widget tree (JsonViewer, JsonPrettyViewer, CodeViewer) is built.
class AsyncJsonParser extends StatefulWidget {
  final dynamic rawData;
  final Widget Function(BuildContext context, dynamic parsedData, bool isJson) builder;

  const AsyncJsonParser({
    super.key,
    required this.rawData,
    required this.builder,
  });

  @override
  State<AsyncJsonParser> createState() => _AsyncJsonParserState();
}

class _AsyncJsonParserState extends State<AsyncJsonParser> {
  dynamic _parsedData;
  bool _isJson = false;
  bool _ready = false; // true once we can call builder
  dynamic _lastRawData;

  @override
  void initState() {
    super.initState();
    _scheduleProcess();
  }

  @override
  void didUpdateWidget(AsyncJsonParser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.rawData, widget.rawData)) {
      _scheduleProcess();
    }
  }

  /// Defers processing by 1 frame so the current build (tab switch,
  /// navigation push, etc.) finishes and paints the loading spinner first.
  /// For data that needs no async work (null, Map, List, non-JSON strings,
  /// short JSON strings) we resolve synchronously and skip the spinner
  /// entirely — flashing a spinner on every click would clobber the selected
  /// tile's highlight and make the panel feel sluggish.
  void _scheduleProcess() {
    _lastRawData = widget.rawData;
    final raw = widget.rawData;

    // Fast path: data that can be resolved without an isolate.
    // We resolve synchronously and stay _ready=true so no spinner is shown.
    if (_tryResolveSync(raw)) {
      // _tryResolveSync already set _parsedData/_isJson and _ready=true.
      if (mounted) setState(() {});
      return;
    }

    // Slow path: large string needing isolate parsing. Show spinner.
    setState(() => _ready = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _processData();
    });
  }

  /// Tries to resolve [raw] synchronously. Returns true if it succeeded
  /// (caller should skip the spinner). Returns false if the data needs
  /// background isolate parsing.
  bool _tryResolveSync(dynamic raw) {
    if (raw == null) {
      _parsedData = null;
      _isJson = false;
      _ready = true;
      return true;
    }
    if (raw is Map || raw is List) {
      _parsedData = raw;
      _isJson = true;
      _ready = true;
      return true;
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty || (trimmed[0] != '{' && trimmed[0] != '[')) {
        _parsedData = raw;
        _isJson = false;
        _ready = true;
        return true;
      }
      if (trimmed.length < 10000) {
        dynamic parsed;
        try {
          parsed = jsonDecode(trimmed);
        } catch (_) {}
        _parsedData = parsed ?? raw;
        _isJson = parsed is Map || parsed is List;
        _ready = true;
        return true;
      }
    }
    // String ≥ 10k chars that LOOKS like JSON — defer to async path so
    // the slow-path in [_processData] gets a chance to run on an isolate.
    // Until the isolate finishes, mark as not-ready so callers see the
    // spinner rather than rendering the raw string as text.
    if (raw is String) {
      final t = raw.trim();
      if (t.length >= 10000 && (t.startsWith('{') || t.startsWith('['))) {
        return false; // let [_scheduleProcess] take the async path
      }
    }
    // Fallback for other types: resolve sync, no spinner.
    _parsedData = raw;
    _isJson = false;
    _ready = true;
    return true;
  }

  void _processData() {
    final raw = widget.rawData;
    if (!identical(raw, _lastRawData)) return; // stale

    // Should have been handled by the fast path; double-check.
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.length >= 10000 &&
          trimmed.isNotEmpty &&
          (trimmed[0] == '{' || trimmed[0] == '[')) {
        compute(_decodeJsonIsolate, trimmed).then((parsed) {
          if (!mounted || !identical(_lastRawData, raw)) return;
          _finalize(parsed ?? raw, parsed is Map || parsed is List);
        }).catchError((_) {
          if (!mounted || !identical(_lastRawData, raw)) return;
          _finalize(raw, false);
        });
        return;
      }
    }
    // Otherwise: resolve synchronously and flip ready.
    _tryResolveSync(raw);
    if (mounted) setState(() {});
  }

  /// Commits the parsed result and flips [_ready] after one more frame so
  /// the spinner has at least one paint cycle visible.
  void _finalize(dynamic data, bool isJson) {
    _parsedData = data;
    _isJson = isJson;
    // Post-frame so the spinner is visible for at least 1 frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _ready = true);
    });
  }

  static dynamic _decodeJsonIsolate(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
        ),
      );
    }
    return widget.builder(context, _parsedData, _isJson);
  }
}

/// A widget that defers the initialization and rendering of a tab's child
/// until the tab controller actually selects it (making it active/visible).
class LazyTab extends StatefulWidget {
  final TabController? controller;
  final int index;
  final WidgetBuilder builder;

  const LazyTab({
    super.key,
    this.controller,
    required this.index,
    required this.builder,
  });

  @override
  State<LazyTab> createState() => _LazyTabState();
}

class _LazyTabState extends State<LazyTab> {
  bool _initialized = false;
  TabController? _controller;

  @override
  void initState() {
    super.initState();
    // We will resolve the controller in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = widget.controller ?? DefaultTabController.of(context);
    if (_controller != newController) {
      _controller?.removeListener(_handleTabChange);
      _controller = newController;
      _controller?.addListener(_handleTabChange);
      _checkVisibility();
    }
  }

  @override
  void didUpdateWidget(LazyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller?.removeListener(_handleTabChange);
      _controller = widget.controller ?? DefaultTabController.of(context);
      _controller?.addListener(_handleTabChange);
    }
    _checkVisibility();
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    if (!mounted) return;
    _checkVisibility();
  }

  void _checkVisibility() {
    final c = _controller;
    if (c != null && !_initialized && c.index == widget.index) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        alignment: Alignment.center,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
        ),
      );
    }
    return widget.builder(context);
  }
}



