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
/// class AppBlocObserver extends BlocObserver {
///   @override
///   void onChange(BlocBase bloc, Change change) {
///     super.onChange(bloc, change);
///     DevConnect.reportBlocChange(
///       blocName: bloc.runtimeType.toString(),
///       fromState: change.currentState.toString(),
///       toState: change.nextState.toString(),
///     );
///   }
/// }
///
/// Bloc.observer = AppBlocObserver();
/// ```

export 'src/devconnect.dart';
export 'src/devconnect_client.dart';
export 'src/storage_adapter.dart';
export 'src/interceptors/network/dio_interceptor.dart';
export 'src/interceptors/network/getx_interceptor.dart';
export 'src/interceptors/network/http_client_interceptor.dart';
export 'src/interceptors/logging/log_interceptor.dart';
export 'src/interceptors/logging/loggy_interceptor.dart';
export 'src/interceptors/navigation/navigation_observer.dart';
export 'src/interceptors/network/websocket/devconnect_websocket.dart';
export 'src/reporters/storage/drift_reporter.dart';
export 'src/reporters/storage/isar_reporter.dart';
export 'src/reporters/logging/log_reporter.dart';
export 'src/reporters/storage/mmkv_reporter.dart';
export 'src/reporters/storage/secure_storage_reporter.dart';
export 'src/reporters/state/signals_observer.dart';
export 'src/reporters/storage/storage_reporter.dart';
export 'src/wrappers/key_value/shared_preferences_wrapper.dart';
export 'src/wrappers/key_value/shared_preferences_async_wrapper.dart';
export 'src/wrappers/key_value/shared_preferences_cached_wrapper.dart';
export 'src/wrappers/key_value/hive_box_wrapper.dart';
export 'src/wrappers/key_value/secure_storage_wrapper.dart';
export 'src/wrappers/key_value/mmkv_wrapper.dart';
export 'src/wrappers/database/sembast_wrapper.dart';
export 'src/wrappers/database/realm_wrapper.dart';
export 'src/wrappers/database/isar_wrapper.dart';
