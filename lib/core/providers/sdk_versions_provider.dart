import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Latest published versions for the SDKs DevConnect Manage Tool
/// supports. Fetched on construction from npm (React Native) and
/// pub.dev (Flutter), then auto-refreshed every [_ttl].
///
/// Designed to be fault-tolerant: a network failure, timeout, or
/// malformed payload on one registry leaves that platform's [value]
/// null and records an [error]. The UI falls back to showing only the
/// hardcoded installed versions in that case — no crash, no spinner.
///
/// Android (`com.devconnect:devconnect`) is intentionally NOT fetched
/// here — there's no Maven Central fetch wired into this provider.
class SdkLatestVersions {
  final String? flutter;
  final String? reactNative;
  final DateTime? fetchedAt;
  final String? flutterError;
  final String? reactNativeError;

  const SdkLatestVersions({
    this.flutter,
    this.reactNative,
    this.fetchedAt,
    this.flutterError,
    this.reactNativeError,
  });

  static const empty = SdkLatestVersions();

  bool get hasAny => flutter != null || reactNative != null;

  String? latestFor(bool isFlutter) => isFlutter ? flutter : reactNative;
  String? errorFor(bool isFlutter) => isFlutter ? flutterError : reactNativeError;

  /// Per-platform fetch state — used by the UI to decide between the
  /// loading shimmer, the offline retry, and the loaded (or up-to-date)
  /// pill.
  ///
  /// - [SdkVersionFetch.loaded] when we have a parsed version
  /// - [SdkVersionFetch.error] when the latest fetch failed
  /// - [SdkVersionFetch.loading] when we haven't heard back yet (first
  ///   fetch, or right after a manual retry)
  SdkVersionFetch fetchStateFor(bool isFlutter) {
    final value = isFlutter ? flutter : reactNative;
    final err = isFlutter ? flutterError : reactNativeError;
    if (value != null) return SdkVersionFetch.loaded;
    if (err != null) return SdkVersionFetch.error;
    return SdkVersionFetch.loading;
  }
}

enum SdkVersionFetch { loading, loaded, error }

final sdkLatestVersionsProvider =
    StateNotifierProvider<SdkVersionsNotifier, SdkLatestVersions>((ref) {
  final notifier = SdkVersionsNotifier();
  ref.onDispose(notifier._onDispose);
  return notifier;
});

class SdkVersionsNotifier extends StateNotifier<SdkLatestVersions> {
  /// Refresh cadence. Desktop apps stay open for hours; refreshing
  /// every 30 min keeps the "Latest" pill current without spamming
  /// the registries.
  static const _ttl = Duration(minutes: 30);

  /// Per-request timeout. npm and pub.dev are both fast — 5 s is
  /// generous and prevents the panel from sitting on a stale "loading"
  /// state if the user's network is wedged.
  static const _timeout = Duration(seconds: 5);

  /// Endpoints. The npm `/latest` shortcut returns only the latest
  /// release (small payload). pub.dev's `/api/packages/<name>` is the
  /// canonical metadata endpoint and includes a `latest` block.
  static const _npmUrl =
      'https://registry.npmjs.org/devconnect-manage-kit/latest';
  static const _pubUrl =
      'https://pub.dev/api/packages/devconnect_manage_kit';

  Timer? _refresh;
  // Guard against concurrent fetches — Rapid Retry clicks would
  // otherwise stack parallel HTTP requests and the second one's
  // state assignment would race the first.
  bool _inFlight = false;

  SdkVersionsNotifier() : super(SdkLatestVersions.empty) {
    // Kick off the first fetch asynchronously so the StateNotifier
    // constructor returns immediately (Riverpod expects sync init).
    // ignore: discarded_futures
    _refreshNow();
    _refresh = Timer.periodic(_ttl, (_) => _refreshNow());
  }

  /// Manually re-fetch. UI surfaces this as a "Retry" affordance when
  /// a previous fetch errored out (offline / timeout / 5xx).
  Future<void> refresh() => _refreshNow();

  Future<void> _refreshNow() async {
    if (_inFlight) return;
    _inFlight = true;
    // Reset the per-platform error flags so the UI transitions from
    // "Live check unavailable" back to the spinner immediately on
    // retry, instead of waiting up to 5s for the new fetch to land.
    // Keep the previous values so the pill doesn't briefly read
    // "missing" — once the fetch finishes the new values overwrite.
    state = SdkLatestVersions(
      flutter: state.flutter,
      reactNative: state.reactNative,
      flutterError: null,
      reactNativeError: null,
    );
    try {
      // Run both fetches in parallel. Each is wrapped in its own
      // try/catch so a failure on one platform doesn't poison the other.
      final results = await Future.wait([_fetchNpm(), _fetchPub()]);
      // Guard against "use after dispose": the widget tree holding us
      // could tear down (user closes the panel mid-fetch). Without this
      // check, the `state =` below would throw "Bad state: Cannot use a
      // StateNotifier after its dispose()".
      if (!mounted) return;
      final npm = results[0]; // _fetchNpm() -> reactNative
      final pub = results[1]; // _fetchPub() -> flutter
      state = SdkLatestVersions(
        flutter: pub.value,
        reactNative: npm.value,
        fetchedAt: DateTime.now(),
        flutterError: pub.error,
        reactNativeError: npm.error,
      );
    } finally {
      _inFlight = false;
    }
  }

  Future<_Result> _fetchNpm() async {
    try {
      final resp =
          await http.get(Uri.parse(_npmUrl)).timeout(_timeout);
      if (resp.statusCode != 200) {
        return _Result.error('HTTP ${resp.statusCode}');
      }
      final json = jsonDecode(resp.body);
      final version = json is Map<String, dynamic> ? json['version'] : null;
      if (version is String && version.isNotEmpty) return _Result.ok(version);
      return _Result.error('missing "version" field');
    } on TimeoutException {
      return _Result.error('timeout');
    } catch (e) {
      return _Result.error(e.toString());
    }
  }

  Future<_Result> _fetchPub() async {
    try {
      final resp =
          await http.get(Uri.parse(_pubUrl)).timeout(_timeout);
      if (resp.statusCode != 200) {
        return _Result.error('HTTP ${resp.statusCode}');
      }
      final json = jsonDecode(resp.body);
      final latest = json is Map<String, dynamic> ? json['latest'] : null;
      final version = latest is Map<String, dynamic> ? latest['version'] : null;
      if (version is String && version.isNotEmpty) return _Result.ok(version);
      return _Result.error('missing "latest.version" field');
    } on TimeoutException {
      return _Result.error('timeout');
    } catch (e) {
      return _Result.error(e.toString());
    }
  }

  void _onDispose() {
    _refresh?.cancel();
  }
}

class _Result {
  final String? value;
  final String? error;
  const _Result.ok(this.value) : error = null;
  const _Result.error(this.error) : value = null;
}