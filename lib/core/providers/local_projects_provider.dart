import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/device_info.dart';
import '../../server/providers/server_providers.dart';
import 'sdk_versions_provider.dart';

/// A Metro / `flutter run` dev server running on this machine, with the
/// DevConnect SDK version actually installed in its project.
///
/// Released SDKs (RN ≤ 1.0.9, Flutter ≤ 1.0.6, Android ≤ 1.1.0) hardcode
/// `sdkVersion: '1.0.0'` in their handshake, so the number on disk is the
/// only one to trust for them.
class LocalProject {
  final SdkPlatform platform;

  /// The dev server's working directory.
  final String root;

  /// Null when the OS wouldn't let this app read [root] — on macOS, the
  /// user declined the Files & Folders prompt (Documents, Desktop, …).
  final String? sdkVersion;

  const LocalProject(this.platform, this.root, this.sdkVersion);

  bool get accessDenied => sdkVersion == null;
}

/// What released SDKs put in the handshake whatever their real version.
const _legacyHandshakeVersion = '1.0.0';

/// SDK version [device] runs, or null when unknown: read from its local
/// project when there is one (null if that folder is off limits), else
/// the handshake — unless it's the hardcoded [_legacyHandshakeVersion].
String? deviceSdkVersion(DeviceInfo device, List<LocalProject> projects) {
  final local = localProjectFor(device, projects);
  if (local != null) return local.sdkVersion;
  final reported = device.sdkVersion;
  return reported == _legacyHandshakeVersion ? null : reported;
}

/// Re-scans whenever devices connect or disconnect — the reload after
/// `yarn add` / `flutter pub upgrade` reconnects and picks up the change.
final localProjectsProvider = FutureProvider<List<LocalProject>>((ref) async {
  if (ref.watch(connectedDevicesProvider).isEmpty) return const [];
  return scanLocalProjects();
});

/// The local project [device] most likely runs from: the only dev server
/// of its platform, or — when several run — the one whose folder is named
/// like the app. Null when that's ambiguous.
LocalProject? localProjectFor(DeviceInfo device, List<LocalProject> projects) {
  final candidates = projects
      .where((p) => p.platform.handshakeId == device.platform)
      .toList();
  if (candidates.length == 1) return candidates.single;
  final app = _normalize(device.appName);
  return candidates
      .where((p) => _normalize(p.root.split('/').last) == app)
      .firstOrNull;
}

String _normalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Finds dev servers with `ps`, their folders with `lsof`, and reads the
/// installed SDK version in each. macOS/Linux only; any failure yields an
/// empty list so callers fall back to the handshake version.
Future<List<LocalProject>> scanLocalProjects() async {
  if (!Platform.isMacOS && !Platform.isLinux) return const [];
  try {
    final ps = await Process.run('ps', ['-axo', 'pid=,command=']);
    final servers = <String, SdkPlatform>{};
    for (final line in LineSplitter.split(ps.stdout as String)) {
      final m = RegExp(r'^\s*(\d+)\s+(.*)$').firstMatch(line);
      if (m == null) continue;
      final platform = devServerPlatform(m.group(2)!);
      if (platform != null) servers[m.group(1)!] = platform;
    }
    if (servers.isEmpty) return const [];

    // `-Fpn` prints `p<pid>`, then `n<path>` for that process's cwd.
    final lsof = await Process.run('lsof', [
      '-a',
      '-d',
      'cwd',
      '-p',
      servers.keys.join(','),
      '-Fpn',
    ]);
    final projects = <String, LocalProject>{};
    SdkPlatform? platform;
    for (final line in LineSplitter.split(lsof.stdout as String)) {
      if (line.startsWith('p')) {
        platform = servers[line.substring(1)];
      } else if (line.startsWith('n') && platform != null) {
        final root = line.substring(1);
        try {
          final version = installedSdkVersion(platform, root);
          if (version != null) {
            projects[root] = LocalProject(platform, root, version);
          }
        } on PathAccessException {
          projects[root] = LocalProject(platform, root, null);
        }
      }
    }
    return projects.values.toList();
  } catch (_) {
    return const [];
  }
}

/// Platform of a dev-server command line: Metro (`react-native start`,
/// `expo start`) or `flutter run` / `flutter attach`.
@visibleForTesting
SdkPlatform? devServerPlatform(String command) {
  if (RegExp(r'(react-native|expo)\S*\s+start\b').hasMatch(command)) {
    return SdkPlatform.reactNative;
  }
  if (RegExp(
    r'flutter_tools\.snapshot(\s+-\S+)*\s+(run|attach)\b',
  ).hasMatch(command)) {
    return SdkPlatform.flutter;
  }
  return null;
}

/// SDK version installed for the project at [dir], walking up the way
/// Node and pub resolve it (workspaces hoist node_modules and share one
/// pubspec.lock above the app folder).
///
/// Throws [PathAccessException] when the OS denies reading the folder.
@visibleForTesting
String? installedSdkVersion(SdkPlatform platform, String dir) {
  if (platform == SdkPlatform.android) return null; // no dev server to scan
  for (var d = Directory(dir); ; d = d.parent) {
    final version = platform == SdkPlatform.reactNative
        ? _npmVersion(
            File('${d.path}/node_modules/devconnect-manage-kit/package.json'),
          )
        : _pubLockVersion(File('${d.path}/pubspec.lock'));
    if (version != null || d.parent.path == d.path) return version;
  }
}

/// Contents of [f], or null when it doesn't exist. Reads straight away
/// rather than checking `existsSync` first: that reports a folder the OS
/// won't let us into as missing, hiding the [PathAccessException].
String? _read(File f) {
  try {
    return f.readAsStringSync();
  } on PathNotFoundException {
    return null;
  }
}

String? _npmVersion(File f) {
  final text = _read(f);
  if (text == null) return null;
  final json = jsonDecode(text);
  return json is Map ? json['version'] as String? : null;
}

String? _pubLockVersion(File f) {
  final text = _read(f);
  if (text == null) return null;
  return RegExp(
    r'^  devconnect_manage_kit:\r?\n(?:    .*\r?\n)*?    version: "([^"]+)"',
    multiLine: true,
  ).firstMatch(text)?.group(1);
}
