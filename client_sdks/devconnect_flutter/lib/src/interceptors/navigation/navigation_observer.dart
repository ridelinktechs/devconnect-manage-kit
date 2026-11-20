import 'package:flutter/widgets.dart';

import '../../devconnect_client.dart';

/// NavigatorObserver that tracks screen navigation and reports to DevConnect.
///
/// Usage:
/// ```dart
/// MaterialApp(
///   navigatorObservers: [DevConnect.navigationObserver()],
/// )
/// ```
///
/// Or with GoRouter:
/// ```dart
/// GoRouter(
///   observers: [DevConnect.navigationObserver()],
/// )
/// ```
class DevConnectNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _reportNavigation('push', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _reportNavigation('pop', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _reportNavigation('replace', newRoute, oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _reportNavigation('remove', route, previousRoute);
  }

  void _reportNavigation(
    String action,
    Route<dynamic>? currentRoute,
    Route<dynamic>? previousRoute,
  ) {
    try {
      final currentName = currentRoute?.settings.name ?? 'unknown';
      final previousName = previousRoute?.settings.name;

      DevConnectClient.safeLog(
        '$action: $currentName${previousName != null ? ' (from: $previousName)' : ''}',
        tag: 'Navigation',
        metadata: {
          'action': action,
          'route': currentName,
          if (previousName != null) 'previousRoute': previousName,
          if (currentRoute?.settings.arguments != null)
            'arguments': currentRoute!.settings.arguments.toString(),
        },
      );
    } catch (_) {}
  }
}
