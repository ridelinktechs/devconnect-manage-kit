import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/lru_cache.dart';
import '../../../core/utils/smooth_scroll_controller.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../l10n/app_localizations.dart';
import 'json_mini_button.dart';

/// Per-line highlight result from isolate.
class _HighlightResult {
  final String formatted;
  final int lineCount;

  /// Per-line tokens: lineTokens[i] = [text, colorInt, bold, text, colorInt, bold, ...]
  final List<List<Object>> lineTokens;

  _HighlightResult(this.formatted, this.lineCount, this.lineTokens);
}

/// Runs in isolate — per-line tokenization.
/// Text past this many characters isn't highlighted or shown: laid out as
/// one paragraph, megabytes of it would hang the UI. Copy and save still
/// take all of it.
const _maxShownChars = 300000;

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

  var left = _maxShownChars;
  for (final whole in lines) {
    if (left <= 0) break;
    final line = whole.length > left ? whole.substring(0, left) : whole;
    left -= line.length + 1;
    final tokens = <Object>[];
    int cursor = 0;

    for (final m in tokenPattern.allMatches(line)) {
      if (m.start > cursor) {
        tokens.addAll([line.substring(cursor, m.start), dPlain, 0]);
      }
      int color;
      int bold = 0;
      if (m.group(1) != null) {
        color = dKey;
        bold = 1;
      } else if (m.group(2) != null) {
        color = dString;
      } else if (m.group(3) != null) {
        color = dNumber;
      } else if (m.group(4) != null) {
        color = dBool;
      } else if (m.group(5) != null) {
        color = dNull;
      } else if (m.group(6) != null) {
        color = dBracket;
      } else {
        color = dPunct;
      }
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
  weightOf: (r) =>
      r.formatted.length * 2 + // string chars ~2 bytes UTF-16
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
  _HighlightResult? _result;
  List<TextSpan>? _cachedSpans;
  String? _lineNumbersText;
  bool _loading = true;
  bool _saving = false;
  bool? _lastIsDark;
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
      _cachedSpans = null;
      _lineNumbersText = null;
      _startCompute();
    } else {
      // Same data — recompute if theme changed (handled in build) but
      // never show the spinner for an unchanged payload.
      _loading = _result == null;
    }
  }

  int get _cacheKey => identityHashCode(widget.data);

  void _updateSpans() {
    if (_result == null) {
      _cachedSpans = null;
      _lineNumbersText = null;
      return;
    }
    _lineNumbersText = List.generate(
      _result!.lineTokens.length,
      (i) => '${i + 1}',
    ).join('\n');
    _cachedSpans = _buildAllSpans(_result!);
  }

  List<TextSpan> _buildAllSpans(_HighlightResult result) {
    final spans = <TextSpan>[];
    for (int lineIdx = 0; lineIdx < result.lineTokens.length; lineIdx++) {
      final tokens = result.lineTokens[lineIdx];
      for (int i = 0; i < tokens.length; i += 3) {
        spans.add(
          TextSpan(
            text: tokens[i] as String,
            style: TextStyle(
              color: Color(tokens[i + 1] as int),
              fontWeight: (tokens[i + 2] as int) == 1
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        );
      }
      if (lineIdx < result.lineTokens.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    return spans;
  }

  void _startCompute() {
    final cached = _highlightCache.get(_cacheKey);
    if (cached != null) {
      _result = cached;
      _updateSpans();
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

    compute(_computeHighlight, [widget.data, isDark])
        .then((result) {
          if (!mounted) return;
          _highlightCache.put(_cacheKey, result);
          setState(() {
            _result = result;
            _updateSpans();
            _loading = false;
          });
        })
        .catchError((e) {
          if (!mounted) return;
          setState(() => _loading = false);
        });
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

    if (_lastIsDark != null && _lastIsDark != isDark) {
      _cachedSpans = null;
      _lineNumbersText = null;
      _result = null;
      _highlightCache.remove(_cacheKey);
      _startCompute();
    }
    _lastIsDark = isDark;

    final lineCount = _result?.lineCount ?? 0;
    final gutterWidth = '$lineCount'.length * 8.0 + 16.0;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252526) : const Color(0xFFF0F0F0),
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
                ],
                const Spacer(),
                if (!_loading) ...[
                  JsonMiniButton(
                    icon: LucideIcons.copy,
                    tooltip: 'Copy JSON',
                    isDark: isDark,
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: _result!.formatted),
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
                        : () => _saveJsonFile(_result!.formatted),
                  ),
                ],
              ],
            ),
          ),
          // Content — unified smooth scrollable view
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
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Line number gutter is excluded from selection
                        // so dragging across multiple lines doesn't pull
                        // the numbers into the copied text.
                        SelectionContainer.disabled(
                          child: Container(
                            width: gutterWidth,
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
                              _lineNumbersText ?? '',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: AppConstants.monoFontFamily,
                                fontSize: 12,
                                height: 1.5,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontFamily: AppConstants.monoFontFamily,
                              fontSize: 12,
                              height: 1.5,
                            ),
                            children: _cachedSpans ?? const [],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!_loading &&
              _result != null &&
              _result!.lineTokens.length < _result!.lineCount)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Text(
                S
                    .of(context)
                    .jsonPrettyCut(
                      _result!.lineTokens.length,
                      _result!.lineCount,
                    ),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }
}
