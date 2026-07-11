import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../utils/sdk_version.dart';
import 'app_version_provider.dart';

/// Latest published release of the DevConnect Manage Tool desktop app
/// itself (not the SDKs the user-facing tip covers). Fetched on
/// construction from GitHub Releases, then auto-refreshed every
/// [_ttl].
///
/// The currently-running version is sourced from [appVersionProvider]
/// (which reads `PackageInfo.fromPlatform()` — the binary's own
/// Info.plist, set from `pubspec.yaml` at build time). No Dart-side
/// version constants to drift.
class AppRelease {
  final String version;
  final String htmlUrl;
  final String? notes;

  const AppRelease({
    required this.version,
    required this.htmlUrl,
    this.notes,
  });
}

class AppReleaseState {
  /// Version of the running app, sourced from [appVersionProvider].
  /// Null until the platform channel has responded.
  final String? currentVersion;

  final AppRelease? release;
  final DateTime? fetchedAt;
  final String? error;

  const AppReleaseState({
    this.currentVersion,
    this.release,
    this.fetchedAt,
    this.error,
  });

  static const empty = AppReleaseState();

  /// True when we have both the running version and a published
  /// release, and the running version is older.
  bool get hasUpdate {
    final r = release;
    final cur = currentVersion;
    if (r == null || cur == null) return false;
    return compareSdkVersions(cur, r.version) < 0;
  }
}

/// Unoauthenticated GitHub REST endpoint for the most recent release.
/// 60 req/hr limit per IP — desktop app caches, so a single cold
/// start is one call.
const _releasesUrl =
    'https://api.github.com/repos/ridelinktechs/devconnect-manage-kit/releases/latest';

final appUpdateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppReleaseState>((ref) {
  final notifier = AppUpdateNotifier(ref);
  ref.onDispose(notifier._onDispose);
  return notifier;
});

class AppUpdateNotifier extends StateNotifier<AppReleaseState> {
  static const _ttl = Duration(minutes: 30);
  static const _timeout = Duration(seconds: 5);

  final Ref _ref;
  Timer? _refresh;

  AppUpdateNotifier(this._ref) : super(AppReleaseState.empty) {
    _refresh = Timer.periodic(_ttl, (_) => _refreshNow());
    // ignore: discarded_futures
    _bootstrap();
  }

  /// Manually re-fetch. UI surfaces this as a "Retry" affordance.
  Future<void> refresh() => _refreshNow();

  /// One-shot init: load the running version, then kick off the
  /// GitHub fetch. Order matters — `hasUpdate` needs both pieces.
  Future<void> _bootstrap() async {
    final cur = await _ref.read(appVersionProvider.future);
    if (!mounted) return;
    state = AppReleaseState(currentVersion: cur);
    await _refreshNow();
  }

  Future<void> _refreshNow() async {
    // Make sure we have the running version before checking
    // `hasUpdate`. Subsequent fetches after the first will already
    // have it cached in state.
    final cur = state.currentVersion ??
        await _ref.read(appVersionProvider.future);
    if (!mounted) return;

    try {
      final resp = await http
          .get(
            Uri.parse(_releasesUrl),
            headers: const {
              'Accept': 'application/vnd.github+json',
            },
          )
          .timeout(_timeout);
      if (!mounted) return;
      if (resp.statusCode != 200) {
        state = AppReleaseState(
          currentVersion: cur,
          fetchedAt: DateTime.now(),
          error: 'HTTP ${resp.statusCode}',
        );
        return;
      }
      final json = jsonDecode(resp.body);
      if (json is! Map<String, dynamic>) {
        state = AppReleaseState(
          currentVersion: cur,
          fetchedAt: DateTime.now(),
          error: 'unexpected payload',
        );
        return;
      }
      final tag = json['tag_name'];
      final url = json['html_url'];
      if (tag is! String || url is! String) {
        state = AppReleaseState(
          currentVersion: cur,
          fetchedAt: DateTime.now(),
          error: 'missing tag_name / html_url',
        );
        return;
      }
      // Strip leading "v" if the tag uses it (e.g. "v1.0.4" -> "1.0.4").
      final version = tag.startsWith('v') ? tag.substring(1) : tag;
      state = AppReleaseState(
        currentVersion: cur,
        release: AppRelease(
          version: version,
          htmlUrl: url,
          notes: json['body'] is String ? json['body'] as String : null,
        ),
        fetchedAt: DateTime.now(),
      );
    } on TimeoutException {
      if (!mounted) return;
      state = AppReleaseState(
        currentVersion: cur,
        fetchedAt: DateTime.now(),
        error: 'timeout',
      );
    } catch (e) {
      if (!mounted) return;
      state = AppReleaseState(
        currentVersion: cur,
        fetchedAt: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  void _onDispose() {
    _refresh?.cancel();
  }
}