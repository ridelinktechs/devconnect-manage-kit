/// Compare two semver-ish strings like `1.2.3` < `1.2.10`.
///
/// Returns negative if [a] < [b], zero if equal, positive if [a] > [b].
/// Missing components default to `0` (so `1.2` is treated as `1.2.0`).
/// Pre-release tags are stripped from each component before parsing:
/// `1.2.3-beta.1` and `1.2.3` both reduce to `1.2.3` for comparison
/// purposes. Pre-release ordering (alpha vs beta vs rc) is NOT
/// respected — fine for the SDKs we ship, where every release is a
/// stable `MAJOR.MINOR.PATCH`.
///
/// Non-numeric components (e.g. `1.x.0`) are treated as `0` instead of
/// throwing — we don't want a malformed registry payload to crash the
/// "Update available" badge.
int compareSdkVersions(String a, String b) {
  final pa = a.split('.');
  final pb = b.split('.');
  final length = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < length; i++) {
    final ai = i < pa.length ? _componentInt(pa[i]) : 0;
    final bi = i < pb.length ? _componentInt(pb[i]) : 0;
    if (ai != bi) return ai - bi;
  }
  return 0;
}

/// Parses the leading numeric portion of a single version component.
/// `3-beta.1` → 3, `12rc2` → 12, `` → 0, `x` → 0. Without this,
/// `int.tryParse('3-beta')` returns null and we'd silently treat
/// pre-release builds as the same version as the stable release —
/// e.g. `1.0.0-beta` would compare equal to `1.0.0` instead of
/// being treated as the same major/minor/patch.
int _componentInt(String s) {
  final match = RegExp(r'^\d+').firstMatch(s);
  return match != null ? int.parse(match.group(0)!) : 0;
}