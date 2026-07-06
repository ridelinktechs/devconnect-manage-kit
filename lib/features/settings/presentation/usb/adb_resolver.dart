import 'dart:io';

/// Resolve the full path to adb binary.
/// Checks common SDK locations and user's shell PATH.
Future<String?> resolveAdbPath() async {
  final isWindows = Platform.isWindows;
  final adbName = isWindows ? 'adb.exe' : 'adb';

  // 1. Check ANDROID_HOME / ANDROID_SDK_ROOT first
  final androidHome = Platform.environment['ANDROID_HOME'] ??
      Platform.environment['ANDROID_SDK_ROOT'];
  final candidates = <String>[];
  if (androidHome != null) {
    candidates.add('$androidHome/platform-tools/$adbName');
  }

  if (isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    candidates.addAll([
      '$localAppData\\Android\\Sdk\\platform-tools\\adb.exe',
      '$userProfile\\AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe',
      'C:\\Android\\sdk\\platform-tools\\adb.exe',
    ]);
  } else {
    final home = Platform.environment['HOME'] ?? '';
    candidates.addAll([
      '$home/Library/Android/sdk/platform-tools/adb', // macOS
      '$home/Android/Sdk/platform-tools/adb', // Linux
      '/usr/local/bin/adb',
      '/opt/homebrew/bin/adb',
    ]);
  }

  for (final path in candidates) {
    if (await File(path).exists()) return path;
  }

  // 2. Try resolving via shell
  try {
    final result = isWindows
        ? await Process.run('where', ['adb'])
        : await Process.run('/bin/sh', ['-lc', 'which adb']);
    final path = result.stdout.toString().trim().split('\n').first;
    if (result.exitCode == 0 && path.isNotEmpty && await File(path).exists()) {
      return path;
    }
  } catch (_) {}

  return null;
}