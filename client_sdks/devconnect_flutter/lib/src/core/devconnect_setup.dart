import 'dart:io';

import '../devconnect.dart';
import '../devconnect_client.dart';
import '../interceptors/network/http_client_interceptor.dart';
import '../interceptors/network/mock_server_interceptor.dart' as mock_helper;
import '../plugins/app_benchmark.dart' as app_bench;
import '../plugins/error_monitor.dart' as error_monitor;
import '../plugins/memory_leak_detector.dart' as memory_detector;
import '../plugins/performance_monitor.dart' as perf_monitor;

/// Internal: start monitors → connect → runApp
Future<void> initAndRun({
  required bool autoPerformance,
  required bool autoMemoryLeak,
  required bool autoBenchmark,
  required bool autoError,
  required String appName,
  required String appVersion,
  required String? versionCode,
  required String? host,
  required int port,
  required bool auto_,
  required bool autoInterceptHttp,
  required Future<void> Function() runApp,
}) async {
  // Monitoring plugins (binding is already initialized)
  if (autoPerformance) perf_monitor.startPerformanceMonitor();
  if (autoMemoryLeak) memory_detector.startMemoryLeakDetector();
  if (autoBenchmark) app_bench.setupAppBenchmark();
  if (autoError) error_monitor.startErrorMonitor();

  await DevConnect.init(
    appName: appName,
    appVersion: appVersion,
    versionCode: versionCode,
    host: host,
    port: port,
    auto_: auto_,
    enabled: true,
    autoPerformance: false,
    autoMemoryLeak: false,
    autoBenchmark: false,
  );

  // Intercept ALL HTTP traffic globally
  if (autoInterceptHttp) {
    HttpOverrides.global = DevConnectHttpOverrides();
  }

  await runApp();
}

Future<void> doInit({
  required String appName,
  String appVersion = '1.0.0',
  String? versionCode,
  String? host,
  int port = 9090,
  String platform = 'flutter',
  bool auto_ = true,
  bool autoPerformance = true,
  bool autoMemoryLeak = true,
  bool autoBenchmark = true,
}) async {
  await DevConnectClient.init(
    host: host,
    port: port,
    appName: appName,
    appVersion: appVersion,
    versionCode: versionCode,
    auto_: auto_,
    deviceName: Platform.localHostname,
    platform: platform,
  );
  // Desktop mock rules (`server:mock_rules_update`) apply without app code.
  mock_helper.installMockServerInterceptor();

  // Auto-start monitoring plugins
  if (autoPerformance) perf_monitor.startPerformanceMonitor();
  if (autoMemoryLeak) memory_detector.startMemoryLeakDetector();
  if (autoBenchmark) app_bench.setupAppBenchmark();
}
