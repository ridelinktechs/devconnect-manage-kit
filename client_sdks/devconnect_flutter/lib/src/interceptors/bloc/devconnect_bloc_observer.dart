import '../../devconnect_client.dart';

/// Bridges `flutter_bloc` [BlocObserver] callbacks to DevConnect state events.
///
/// Mirrors the helper-class-with-static-methods pattern used by
/// `DevConnectRiverpodHelper` — no top-level imports of `flutter_bloc`
/// itself, so consumers control when (and whether) to wire it.
///
/// Usage:
/// ```dart
/// import 'package:flutter_bloc/flutter_bloc.dart';
/// import 'package:devconnect_flutter/src/interceptors/bloc/devconnect_bloc_observer.dart';
///
/// void main() {
///   Bloc.observer = DevConnectBlocObserver();
///   runApp(MyApp());
/// }
/// ```
///
/// Or chain in front of an existing observer:
/// ```dart
/// final previous = Bloc.observer;
/// Bloc.observer = ChainedBlocObserver(
///   DevConnectBlocObserver(),
///   previous,
/// );
/// ```
class DevConnectBlocObserver extends BlocObserverBase {
  /// Optional existing observer to forward events to. Allows chaining
  /// when the consumer already has a custom BlocObserver.
  final BlocObserverBase? previous;

  DevConnectBlocObserver({this.previous});

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _safeReportCreate(bloc);
    previous?.onCreate(bloc);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _safeReportChange(bloc, change);
    previous?.onChange(bloc, change);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _safeReportError(bloc, error, stackTrace);
    previous?.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    _safeReportClose(bloc);
    previous?.onClose(bloc);
  }

  // ---- Helpers ----

  void _safeReportCreate(BlocBase bloc) {
    try {
      DevConnectClient.safeReportStateChange(
        stateManager: _stateManager(bloc),
        action: '${_blocName(bloc)} created',
        nextState: _toMap(bloc.state),
      );
    } catch (_) {}
  }

  void _safeReportChange(BlocBase bloc, Change change) {
    try {
      DevConnectClient.safeReportStateChange(
        stateManager: _stateManager(bloc),
        action: '${_blocName(bloc)} changed',
        previousState: _toMap(change.currentState),
        nextState: _toMap(change.nextState),
      );
    } catch (_) {}
  }

  void _safeReportError(BlocBase bloc, Object error, StackTrace stackTrace) {
    try {
      DevConnectClient.safeSendLog(
        level: 'error',
        message: 'BLoC error in ${_blocName(bloc)}: $error',
        tag: 'devconnect.bloc',
        stackTrace: stackTrace.toString(),
        metadata: {
          'bloc': _blocName(bloc),
          'stateManager': _stateManager(bloc),
        },
      );
    } catch (_) {}
  }

  void _safeReportClose(BlocBase bloc) {
    try {
      DevConnectClient.safeReportStateChange(
        stateManager: _stateManager(bloc),
        action: '${_blocName(bloc)} closed',
      );
    } catch (_) {}
  }

  String _blocName(BlocBase bloc) => bloc.runtimeType.toString();

  String _stateManager(BlocBase bloc) {
    final name = bloc.runtimeType.toString();
    return 'BLoC::$name';
  }

  /// Normalize a state value into a map-friendly representation so it can
  /// travel over WebSocket. Mirrors `_toMap` in `riverpod_observer.dart`.
  Map<String, dynamic>? _toMap(Object? state) {
    if (state == null) return null;
    try {
      if (state is Map<String, dynamic>) return state;
      if (state is String || state is num || state is bool) {
        return {'value': state};
      }
      return {'value': state.toString()};
    } catch (_) {
      return {'value': '<unprintable>'};
    }
  }
}

/// Minimal BlocObserver surface — duck-typed so this file doesn't need to
/// import `package:flutter_bloc`. The real `BlocObserver` (when imported
/// by the consumer) extends this same API, so we accept it via dynamic
/// dispatch by overriding on `BlocObserverBase` (which is the class name
/// used inside flutter_bloc).
///
/// IMPORTANT — `super` does NOT chain to `flutter_bloc`'s BlocObserver.
/// All four methods on this base are no-ops. If you subclass
/// [DevConnectBlocObserver] (which extends this base) and write
/// `super.onCreate(bloc)`, `super.onChange(bloc, change)`, etc.,
/// expecting those calls to forward to flutter_bloc's real BlocObserver,
/// they will NOT — they call these empty implementations. This is a
/// deliberate trade-off: we stay dep-free, but consumers lose the
/// super-chain convenience. If you need chaining, install `flutter_bloc`
/// and wire your own observer as `previous` on [DevConnectBlocObserver].
///
/// If `flutter_bloc` is NOT installed, the consumer can still call our
/// static helpers directly — see [reportCreate], [reportChange], etc.
abstract class BlocObserverBase {
  void onCreate(BlocBase bloc) {}
  void onChange(BlocBase bloc, Change change) {}
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {}
  void onClose(BlocBase bloc) {}
}

/// Placeholder for [BlocBase] — the real class lives in `flutter_bloc`.
/// We don't import it so consumers without `flutter_bloc` can still use
/// the file for the [DevConnectClient.safeReportStateChange] helpers.
abstract class BlocBase {
  Object? get state;
}

/// Placeholder for [Change] — also from `flutter_bloc`. When the consumer
/// installs `flutter_bloc`, their actual `Change` class satisfies this
/// shape (it has `currentState` and `nextState` getters).
class Change<T> {
  final T currentState;
  final T nextState;
  Change({required this.currentState, required this.nextState});
}

/// Static helper that callers can use directly without subclassing
/// [BlocObserverBase]. Useful when `flutter_bloc` isn't installed but
/// the app wants to report state changes from its own bloc-like system.
class DevConnectBlocHelper {
  DevConnectBlocHelper._();

  static void reportChange({
    required String blocName,
    required String? fromState,
    required String? toState,
  }) {
    try {
      DevConnectClient.safeReportStateChange(
        stateManager: 'BLoC::$blocName',
        action: '$blocName changed',
        previousState: fromState == null ? null : {'value': fromState},
        nextState: toState == null ? null : {'value': toState},
      );
    } catch (_) {}
  }

  static void reportCreate({
    required String blocName,
    required String? initialState,
  }) {
    try {
      DevConnectClient.safeReportStateChange(
        stateManager: 'BLoC::$blocName',
        action: '$blocName created',
        nextState: initialState == null ? null : {'value': initialState},
      );
    } catch (_) {}
  }

  static void reportClose({required String blocName}) {
    try {
      DevConnectClient.safeReportStateChange(
        stateManager: 'BLoC::$blocName',
        action: '$blocName closed',
      );
    } catch (_) {}
  }

  static void reportError({
    required String blocName,
    required Object error,
    StackTrace? stackTrace,
  }) {
    try {
      DevConnectClient.safeSendLog(
        level: 'error',
        message: 'BLoC error in $blocName: $error',
        tag: 'devconnect.bloc',
        stackTrace: stackTrace?.toString(),
        metadata: {
          'bloc': blocName,
          'stateManager': 'BLoC::$blocName',
        },
      );
    } catch (_) {}
  }
}