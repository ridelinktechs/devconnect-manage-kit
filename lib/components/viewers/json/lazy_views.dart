import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';

/// Shows a loading spinner for 1 frame on mount, then builds the child —
/// at once when tab animations are off, as there is no switch to keep smooth.
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
class DeferredBuilder extends ConsumerStatefulWidget {
  final WidgetBuilder builder;
  const DeferredBuilder({super.key, required this.builder});

  @override
  ConsumerState<DeferredBuilder> createState() => _DeferredBuilderState();
}

class _DeferredBuilderState extends ConsumerState<DeferredBuilder> {
  late bool _ready = !ref.read(tabAnimationEnabledProvider);

  @override
  void initState() {
    super.initState();
    if (_ready) return;
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
  final Widget Function(BuildContext context, dynamic parsedData, bool isJson)
  builder;

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
      // Normalise empty / whitespace-only strings to `null` so consumers
      // can treat them uniformly as "no data" (renders an EmptyState)
      // instead of falling through to a blank JSON viewer.
      if (trimmed.isEmpty) {
        _parsedData = null;
        _isJson = false;
        _ready = true;
        return true;
      }
      if (trimmed[0] != '{' && trimmed[0] != '[') {
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
        compute(_decodeJsonIsolate, trimmed)
            .then((parsed) {
              if (!mounted || !identical(_lastRawData, raw)) return;
              _finalize(parsed ?? raw, parsed is Map || parsed is List);
            })
            .catchError((_) {
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
