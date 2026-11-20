import 'package:devconnect_manage_kit/devconnect_manage_kit.dart';
import 'package:devconnect_manage_kit/src/plugins/error_monitor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Messages of the errors reported so far.
List<Object?> _reported() => [
      for (final m in DevConnectClient.queuedMessages)
        if (m['type'] == 'client:error') (m['payload'] as Map)['message'],
    ];

void main() {
  FlutterExceptionHandler? flutterOnError;
  setUp(() {
    DevConnectClient.queuedMessages.clear();
    flutterOnError = FlutterError.onError;
  });
  tearDown(() {
    stopErrorMonitor();
    FlutterError.onError = flutterOnError;
  });

  test('reports errors, then hands them to the handlers already set', () {
    final flutterErrors = <FlutterErrorDetails>[];
    final asyncErrors = <Object>[];
    FlutterError.onError = flutterErrors.add;
    PlatformDispatcher.instance.onError = (error, stack) {
      asyncErrors.add(error);
      return true;
    };
    startErrorMonitor(const ErrorMonitorOptions(capturePlatformErrors: false));

    final details = FlutterErrorDetails(exception: StateError('build failed'));
    FlutterError.onError!(details);
    final error = StateError('request failed');
    expect(
        PlatformDispatcher.instance.onError!(error, StackTrace.empty), isTrue);

    expect(flutterErrors, [details]);
    expect(asyncErrors, [error]);
    expect(
        _reported(), ['Bad state: build failed', 'Bad state: request failed']);
  });

  test('without an app handler, an async error stays unhandled', () {
    PlatformDispatcher.instance.onError = null;
    startErrorMonitor(const ErrorMonitorOptions(capturePlatformErrors: false));

    expect(
      PlatformDispatcher.instance.onError!(StateError('x'), StackTrace.empty),
      isFalse,
    );
    expect(_reported(), ['Bad state: x']);
  });
}
