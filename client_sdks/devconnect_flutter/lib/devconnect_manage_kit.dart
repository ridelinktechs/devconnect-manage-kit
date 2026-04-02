/// DevConnect Flutter SDK - auto-intercepts network, state, storage, Firebase, OAuth2.
library;
///
/// ## Quick Start (1 line in main.dart):
/// ```dart
/// void main() async {
///   await DevConnect.init(appName: 'MyApp');
///   runApp(MyApp());
/// }
/// ```
///
/// ## With Dio auto-intercept:
/// ```dart
/// final dio = Dio();
/// dio.interceptors.add(DevConnect.dioInterceptor());
/// ```
///
/// ## With http package auto-intercept:
/// ```dart
/// final client = DevConnect.httpClient();
/// // or wrap existing: DevConnect.wrapHttpClient(existingClient);
/// ```
///
/// ## With Riverpod:
/// ```dart
/// ProviderScope(
///   observers: [DevConnect.riverpodObserver()],
///   child: MyApp(),
/// )
/// ```
///
/// ## With BLoC:
/// ```dart
/// Bloc.observer = DevConnect.blocObserver();
/// ```

export 'src/devconnect.dart';
export 'src/devconnect_client.dart';
export 'src/interceptors/dio_interceptor.dart';
export 'src/interceptors/getx_interceptor.dart';
export 'src/interceptors/http_client_interceptor.dart';
export 'src/interceptors/log_interceptor.dart';
export 'src/interceptors/loggy_interceptor.dart';
export 'src/interceptors/navigation_observer.dart';
export 'src/reporters/drift_reporter.dart';
export 'src/reporters/isar_reporter.dart';
export 'src/reporters/log_reporter.dart';
export 'src/reporters/mmkv_reporter.dart';
export 'src/reporters/secure_storage_reporter.dart';
export 'src/reporters/signals_observer.dart';
export 'src/reporters/storage_reporter.dart';
export 'src/wrappers/shared_preferences_wrapper.dart';
export 'src/wrappers/hive_box_wrapper.dart';
export 'src/wrappers/secure_storage_wrapper.dart';
export 'src/wrappers/mmkv_wrapper.dart';
export 'src/wrappers/sembast_wrapper.dart';
export 'src/wrappers/realm_wrapper.dart';
export 'src/wrappers/isar_wrapper.dart';
