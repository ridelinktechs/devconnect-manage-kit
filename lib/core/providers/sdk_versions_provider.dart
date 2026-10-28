import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Client SDKs DevConnect Manage Tool supports.
enum SdkPlatform {
  flutter('flutter'),
  reactNative('react_native'),
  android('android');

  /// `deviceInfo.platform` value the SDK sends in `client:handshake`.
  final String handshakeId;
  const SdkPlatform(this.handshakeId);
}

/// Latest published versions for the SDKs DevConnect Manage Tool
/// supports. Fetched on construction from pub.dev (Flutter), npm
/// (React Native) and Maven Central (Android), then auto-refreshed
/// every [SdkVersionsNotifier._ttl].
///
/// Designed to be fault-tolerant: a network failure, timeout, or
/// malformed payload on one registry leaves that platform's value
/// null and records an error. The UI shows a retry chip for that
/// platform — no crash, no endless spinner.
class SdkLatestVersions {
  final String? flutter;
  final String? reactNative;
  final String? android;
  final DateTime? fetchedAt;
  final String? flutterError;
  final String? reactNativeError;
  final String? androidError;

  const SdkLatestVersions({
    this.flutter,
    this.reactNative,
    this.android,
    this.fetchedAt,
    this.flutterError,
    this.reactNativeError,
    this.androidError,
  });

  static const empty = SdkLatestVersions();

  String? latestFor(SdkPlatform p) => switch (p) {
        SdkPlatform.flutter => flutter,
        SdkPlatform.reactNative => reactNative,
        SdkPlatform.android => android,
      };

  String? errorFor(SdkPlatform p) => switch (p) {
        SdkPlatform.flutter => flutterError,
        SdkPlatform.reactNative => reactNativeError,
        SdkPlatform.android => androidError,
      };

  /// Per-platform fetch state — used by the UI to decide between the
  /// loading shimmer, the offline retry, and the loaded (or up-to-date)
  /// pill.
  ///
  /// - [SdkVersionFetch.loaded] when we have a parsed version
  /// - [SdkVersionFetch.error] when the latest fetch failed
  /// - [SdkVersionFetch.loading] when we haven't heard back yet (first
  ///   fetch, or right after a manual retry)
  SdkVersionFetch fetchStateFor(SdkPlatform p) {
    if (latestFor(p) != null) return SdkVersionFetch.loaded;
    if (errorFor(p) != null) return SdkVersionFetch.error;
    return SdkVersionFetch.loading;
  }
}

enum SdkVersionFetch { loading, loaded, error }

final sdkLatestVersionsProvider =
    NotifierProvider<SdkVersionsNotifier, SdkLatestVersions>(
        SdkVersionsNotifier.new);

class SdkVersionsNotifier extends Notifier<SdkLatestVersions> {
  /// Refresh cadence. Desktop apps stay open for hours; refreshing
  /// every 30 min keeps the "Latest" pill current without spamming
  /// the registries.
  static const _ttl = Duration(minutes: 30);

  /// Per-request timeout. The registries are all fast — 5 s is
  /// generous and prevents the panel from sitting on a stale "loading"
  /// state if the user's network is wedged.
  static const _timeout = Duration(seconds: 5);

  /// Endpoints. The npm `/latest` shortcut returns only the latest
  /// release (small payload). pub.dev's `/api/packages/<name>` is the
  /// canonical metadata endpoint and includes a `latest` block. Maven
  /// Central's `maven-metadata.xml` names the newest release in
  /// `<release>`.
  static const _npmUrl =
      'https://registry.npmjs.org/devconnect-manage-kit/latest';
  static const _pubUrl =
      'https://pub.dev/api/packages/devconnect_manage_kit';
  static const _mavenUrl =
      'https://repo1.maven.org/maven2/io/github/buivietphi/devconnect-android/maven-metadata.xml';

  Timer? _refresh;
  // Guard against concurrent fetches — Rapid Retry clicks would
  // otherwise stack parallel HTTP requests and the second one's
  // state assignment would race the first.
  bool _inFlight = false;

  @override
  SdkLatestVersions build() {
    // Microtask, not a direct call: _refreshNow reads `state`, which
    // throws until build() has returned the initial value.
    Future.microtask(_refreshNow);
    _refresh = Timer.periodic(_ttl, (_) => _refreshNow());
    ref.onDispose(_onDispose);
    return SdkLatestVersions.empty;
  }

  /// Manually re-fetch. UI surfaces this as a "Retry" affordance when
  /// a previous fetch errored out (offline / timeout / 5xx).
  Future<void> refresh() => _refreshNow();

  Future<void> _refreshNow() async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      // Reset the per-platform error flags so the UI transitions from
      // "Live check unavailable" back to the spinner immediately on
      // retry, instead of waiting up to 5s for the new fetch to land.
      // Keep the previous values so the pill doesn't briefly read
      // "missing" — once the fetch finishes the new values overwrite.
      state = SdkLatestVersions(
        flutter: state.flutter,
        reactNative: state.reactNative,
        android: state.android,
      );
      // Each fetch catches its own errors, so a failure on one
      // registry doesn't poison the others.
      final [pub, npm, maven] =
          await Future.wait([_fetchPub(), _fetchNpm(), _fetchMaven()]);
      if (!ref.mounted) return;
      state = SdkLatestVersions(
        flutter: pub.value,
        reactNative: npm.value,
        android: maven.value,
        fetchedAt: DateTime.now(),
        flutterError: pub.error,
        reactNativeError: npm.error,
        androidError: maven.error,
      );
    } finally {
      _inFlight = false;
    }
  }

  Future<_Result> _fetchPub() => _fetch(_pubUrl, (body) {
        final latest = (jsonDecode(body) as Map)['latest'];
        return latest is Map ? latest['version'] as String? : null;
      });

  Future<_Result> _fetchNpm() => _fetch(
      _npmUrl, (body) => (jsonDecode(body) as Map)['version'] as String?);

  Future<_Result> _fetchMaven() => _fetch(
      _mavenUrl,
      (body) =>
          RegExp(r'<release>([^<]+)</release>').firstMatch(body)?.group(1));

  /// GETs [url] and pulls the version out of the body with [parse].
  /// Any failure (timeout, non-200, unexpected payload) becomes an
  /// error result instead of throwing.
  Future<_Result> _fetch(
      String url, String? Function(String body) parse) async {
    try {
      final resp = await http.get(Uri.parse(url)).timeout(_timeout);
      if (resp.statusCode != 200) {
        return _Result.error('HTTP ${resp.statusCode}');
      }
      final version = parse(resp.body);
      if (version != null && version.isNotEmpty) return _Result.ok(version);
      return _Result.error('no version in payload');
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
