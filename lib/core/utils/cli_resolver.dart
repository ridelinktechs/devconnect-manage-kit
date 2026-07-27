import 'dart:io';

/// Cached lookups so we don't re-shell `which` on every Run click.
/// Cleared on app restart (process-lifetime cache only).
final Map<String, String?> _resolved = {};

/// Resolve the absolute path to an AI-client CLI binary.
///
/// Order:
/// 1. `Process.run('which', [name])` (POSIX) / `where` (Windows).
/// 2. Platform-specific fallback dirs (Homebrew, /usr/local/bin, ~/.local/bin, ...).
/// 3. Returns null if not found anywhere.
Future<String?> resolveCliBinary(String name) async {
  if (Platform.isWindows) return null;
  if (_resolved.containsKey(name)) return _resolved[name];

  // 1. which
  try {
    final r = await Process.run('which', [name])
        .timeout(const Duration(seconds: 2));
    if (r.exitCode == 0) {
      final p = r.stdout.toString().trim();
      if (p.isNotEmpty) {
        final cached = p.split('\n').first.trim();
        if (await File(cached).exists()) {
          _resolved[name] = cached;
          return cached;
        }
      }
    }
  } catch (_) {}

  // 2. fallback dirs
  final home = Platform.environment['HOME'] ?? '';
  final candidates = Platform.isMacOS
      ? <String>[
          '/opt/homebrew/bin/$name',
          '/usr/local/bin/$name',
          '$home/.local/bin/$name',
        ]
      : <String>[
          '$home/.local/bin/$name',
          '/usr/local/bin/$name',
          '/usr/bin/$name',
        ];
  for (final c in candidates) {
    if (await File(c).exists()) {
      _resolved[name] = c;
      return c;
    }
  }

  _resolved[name] = null;
  return null;
}

/// Augment the parent process PATH with common install dirs so that
/// GUI-launched processes (macOS .app bundle) can find homebrew-installed
/// CLIs. Returns a new env map suitable for `Process.run(env: ...)`.
///
/// ponytail: GUI macOS apps inherit only /usr/bin:/bin:/usr/sbin:/sbin —
/// homebrew / pipx / cargo / pub-cache bins are invisible without this.
Map<String, String> augmentedEnv() {
  final home = Platform.environment['HOME'] ?? '';
  final extra = [
    if (!Platform.isWindows) '/opt/homebrew/bin',
    if (!Platform.isWindows) '/usr/local/bin',
    if (!Platform.isWindows) '$home/.local/bin',
    if (!Platform.isWindows) '$home/.pub-cache/bin',
    if (!Platform.isWindows) '$home/.cargo/bin',
  ].join(':');
  return {
    ...Platform.environment,
    'PATH': '${Platform.environment['PATH'] ?? ''}:$extra',
  };
}
