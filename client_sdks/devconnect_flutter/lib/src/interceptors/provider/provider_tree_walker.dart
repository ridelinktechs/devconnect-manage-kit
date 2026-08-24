import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../devconnect_client.dart';

/// Walks a Flutter widget tree to discover `Provider`-style inherited scopes
/// (`_InheritedProviderScope`, `InheritedProvider`, `ProviderScope`) and emits
/// state-change events when values change between walks.
///
/// Provider has no global hook (unlike BLoC's `Bloc.observer`). The walk
/// is driven by a [WidgetsBindingObserver] listening to app-lifecycle
/// `resume` events, plus a manual [refresh] API.
///
/// We avoid importing `package:provider/provider.dart` directly — that
/// would force a hard dep. Instead we walk the Element tree and duck-type
/// any InheritedWidget that exposes a `value` getter.
class DevConnectProviderWalker {
  static DevConnectProviderWalker? _instance;

  /// Singleton accessor. Use [install] once from your app entry point.
  static DevConnectProviderWalker get instance =>
      _instance ??= DevConnectProviderWalker._();

  DevConnectProviderWalker._();

  final _lifecycleObserver = _LifecycleObserver();
  Timer? _pollTimer;

  /// Snapshot of previous values, keyed by InheritedWidget identity.
  final Map<int, Map<String, dynamic>> _lastValues = {};

  /// Per-key throttle: last emit timestamp per identity hashCode.
  final Map<int, int> _lastEmitMs = {};

  /// Throttle window — at most one event per provider per this many ms.
  static const int _throttleMs = 250;

  /// Optional manual polling interval. Default off (only lifecycle-driven).
  Duration? pollInterval;

  bool _installed = false;

  /// Install the walker. Call from `main()` after `WidgetsFlutterBinding.ensureInitialized()`
  /// and after `DevConnectClient.init()` if you want events to actually go anywhere.
  void install({Duration? pollEvery}) {
    if (_installed) return;
    _installed = true;
    pollInterval = pollEvery;
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    if (pollEvery != null) {
      _pollTimer = Timer.periodic(pollEvery, (_) => refresh());
    }
  }

  /// Stop the walker and detach the lifecycle observer.
  void dispose() {
    if (!_installed) return;
    _installed = false;
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Walk the active widget tree and emit state-change events for any
  /// provider whose value changed since the last walk.
  ///
  /// Safe to call from anywhere — won't throw on a missing binding.
  Future<void> refresh() async {
    try {
      final rootElement = _findRootElement();
      if (rootElement == null) return;
      _walk(rootElement);
    } catch (_) {
      // Walking failed (probably no binding yet) — silently ignore.
    }
  }

  Element? _findRootElement() {
    // Prefer the render-view element when a binding is alive.
    final view = WidgetsBinding.instance.rootElement;
    if (view != null) return view;
    return null;
  }

  void _walk(Element element) {
    // Report the parent once BEFORE recursing into children. Putting the
    // report inside the visitChildren callback (as a previous version
    // did) caused the parent to be reported N times — once per child —
    // which flooded the desktop with duplicate state-change events.
    _maybeReportProvider(element);
    element.visitChildren(_walk);
  }

  void _maybeReportProvider(Element element) {
    final widget = element.widget;
    if (widget is! InheritedWidget) return;

    // We don't statically know the inherited widget's `value` getter —
    // it's an internal class on the `provider` package. Try a few well-
    // known shapes via dynamic dispatch.
    final dynamic dyn = element;
    Object? value;
    String? typeName;
    try {
      value = dyn.value;
      typeName = widget.runtimeType.toString();
    } catch (_) {
      return; // not a provider-style inherited widget
    }
    if (value == null) return;

    final key = identityHashCode(element);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final lastEmit = _lastEmitMs[key] ?? 0;
    if (nowMs - lastEmit < _throttleMs) return;

    final mappedValue = _toMap(value);
    final prev = _lastValues[key];
    if (_mapsEqual(prev, mappedValue)) return; // unchanged

    _lastValues[key] = mappedValue;
    _lastEmitMs[key] = nowMs;

    try {
      DevConnectClient.safeReportStateChange(
        stateManager: 'Provider::$typeName',
        action: '$typeName updated',
        previousState: prev,
        nextState: mappedValue,
      );
    } catch (_) {}
  }

  /// Convert an arbitrary provider value into a transport-friendly map.
  /// Mirrors `_toMap` in `riverpod_observer.dart`.
  Map<String, dynamic> _toMap(Object? value) {
    try {
      if (value is Map<String, dynamic>) return value;
      if (value is String || value is num || value is bool) {
        return {'value': value};
      }
      if (value is List) {
        return {
          'list': value.map((e) => _toMap(e)).toList(),
        };
      }
      // Don't try to serialize arbitrary models — toString() is plenty for a state-diff view.
      return {'value': value.toString()};
    } catch (_) {
      return {'value': '<unprintable>'};
    }
  }

  bool _mapsEqual(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k)) return false;
      if (a[k] != b[k]) return false;
    }
    return true;
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground — re-walk to catch any provider changes.
      unawaited(DevConnectProviderWalker.instance.refresh());
    }
  }
}

/// Public static helpers for consumers who want to push provider state
/// from their own code (e.g. when wrapping `ChangeNotifier.notifyListeners()`).
class DevConnectProviderHelper {
  DevConnectProviderHelper._();

  static void reportUpdate({
    required String providerName,
    required Object? previousValue,
    required Object? newValue,
  }) {
    try {
      DevConnectClient.safeReportStateChange(
        stateManager: 'Provider::$providerName',
        action: '$providerName updated',
        previousState: _safeMap(previousValue),
        nextState: _safeMap(newValue),
      );
    } catch (_) {}
  }

  static Map<String, dynamic>? _safeMap(Object? value) {
    if (value == null) return null;
    try {
      return {'value': value.toString()};
    } catch (_) {
      return {'value': '<unprintable>'};
    }
  }
}

void unawaited(Future<void> future) {
  // ignore: empty_catches
  future.then((_) {}, onError: (_) {});
}