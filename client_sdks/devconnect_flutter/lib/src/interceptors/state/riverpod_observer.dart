import '../../devconnect_client.dart';

/// Riverpod ProviderObserver that reports state changes to DevConnect.
///
/// Usage:
/// ```dart
/// ProviderScope(
///   observers: [DevConnectRiverpodObserver()],
///   child: MyApp(),
/// )
/// ```
///
/// Note: This file uses dynamic types to avoid depending on flutter_riverpod.
/// The observer should be used by extending ProviderObserver in your app:
///
/// ```dart
/// import 'package:flutter_riverpod/flutter_riverpod.dart';
///
/// class DevConnectObserver extends ProviderObserver {
///   @override
///   void didUpdateProvider(
///     ProviderBase provider,
///     Object? previousValue,
///     Object? newValue,
///     ProviderContainer container,
///   ) {
///     DevConnectClient.instance.reportStateChange(
///       stateManager: 'riverpod',
///       action: '${provider.name ?? provider.runtimeType.toString()} updated',
///       previousState: _toMap(previousValue),
///       nextState: _toMap(newValue),
///     );
///   }
///
///   Map<String, dynamic> _toMap(Object? value) {
///     if (value is Map<String, dynamic>) return value;
///     return {'value': value.toString()};
///   }
/// }
/// ```
class DevConnectRiverpodHelper {
  static void reportUpdate({
    required String providerName,
    Object? previousValue,
    Object? newValue,
  }) {
    try {
      DevConnectClient.safeReportStateChange(
        stateManager: 'riverpod',
        action: '$providerName updated',
        previousState: _toMap(previousValue),
        nextState: _toMap(newValue),
      );
    } catch (_) {}
  }

  static Map<String, dynamic> _toMap(Object? value) {
    if (value == null) return {'value': 'null'};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return {'value': value.toString()};
  }
}
