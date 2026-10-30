import '../../devconnect_client.dart';

/// Observer for `signals` / `flutter_signals` package that reports
/// signal value changes as state changes to DevConnect.
///
/// Usage:
/// ```dart
/// final counter = signal(0);
/// final observer = DevConnect.signalsObserver();
///
/// // Report signal changes manually:
/// observer.reportChange('counter', previousValue: 0, newValue: 1);
///
/// // Or use the effect helper:
/// observer.observe('counter', counter);
/// ```
///
/// With flutter_signals effect:
/// ```dart
/// final obs = DevConnect.signalsObserver();
/// effect(() {
///   obs.reportChange('counter', newValue: counter.value);
/// });
/// ```
class DevConnectSignalsObserver {
  final Map<String, dynamic> _previousValues = {};

  /// Report a signal value change to DevConnect.
  ///
  /// [name] - A descriptive name for this signal (e.g., 'counter', 'user.name').
  /// [previousValue] - The previous value. If omitted, uses the last known value.
  /// [newValue] - The current value of the signal.
  void reportChange(
    String name, {
    dynamic previousValue,
    required dynamic newValue,
  }) {
    try {
      final prev = previousValue ?? _previousValues[name];
      _previousValues[name] = newValue;

      // Don't report if value hasn't changed
      if (prev == newValue) return;

      DevConnectClient.safeReportStateChange(
        stateManager: 'signals',
        action: 'signal:$name',
        previousState: prev != null ? {'value': _toSerializable(prev)} : null,
        nextState: {'value': _toSerializable(newValue)},
        diff: [
          {
            'path': name,
            'previousValue': _toSerializable(prev),
            'nextValue': _toSerializable(newValue),
          },
        ],
      );
    } catch (_) {}
  }

  /// Observe a signal by duck-typing. Calls `.listen()` on the signal
  /// and reports changes automatically.
  ///
  /// Returns a dispose function to stop observing.
  ///
  /// ```dart
  /// final counter = signal(0);
  /// final dispose = observer.observe('counter', counter);
  /// // later: dispose();
  /// ```
  dynamic Function() observe(String name, dynamic signal) {
    try {
      // Try to read initial value
      try {
        _previousValues[name] = signal.value;
      } catch (_) {}

      // Try to subscribe via .listen() (flutter_signals API)
      final unsub = signal.listen((dynamic newValue) {
        reportChange(name, newValue: newValue);
      });

      if (unsub is Function) {
        return () {
          try {
            unsub();
          } catch (_) {}
        };
      }
    } catch (_) {}

    return () {};
  }

  /// Report a computed signal value change.
  void reportComputed(
    String name, {
    required dynamic newValue,
  }) {
    try {
      final prev = _previousValues[name];
      _previousValues[name] = newValue;

      if (prev == newValue) return;

      DevConnectClient.safeReportStateChange(
        stateManager: 'signals',
        action: 'computed:$name',
        previousState: prev != null ? {'value': _toSerializable(prev)} : null,
        nextState: {'value': _toSerializable(newValue)},
      );
    } catch (_) {}
  }

  static dynamic _toSerializable(dynamic value) {
    if (value == null) return null;
    if (value is num || value is bool || value is String) return value;
    if (value is List) return value.map(_toSerializable).toList();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _toSerializable(v)));
    }
    return value.toString();
  }
}
