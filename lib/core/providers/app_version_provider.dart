import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Single source of truth for the desktop app's own version.
///
/// Reads from `PackageInfo.fromPlatform()` — that returns the version
/// baked into the compiled binary's Info.plist (macOS), which Flutter
/// sets from `pubspec.yaml` during `flutter build`. So bumping
/// `pubspec.yaml` is the only thing required to "ship" a new version;
/// no Dart constants to update.
///
/// Returns `AsyncValue<String>` so callers can render a loading state
/// while the platform channel roundtrip is in flight. Resolved value
/// is cached by Riverpod for the lifetime of the provider scope.
final appVersionProvider = FutureProvider<String>((_) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});