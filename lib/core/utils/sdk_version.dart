/// Compare two semver-ish strings like `1.2.3` < `1.2.10`.
///
/// Returns negative if [a] < [b], zero if equal, positive if [a] > [b].
/// Missing components default to `0` (so `1.2` is treated as `1.2.0`).
/// Pre-release tags (`1.2.3-beta.1`) are ignored — fine for the SDKs we
/// ship, where every release is a stable `MAJOR.MINOR.PATCH`.
///
/// Non-numeric components (e.g. `1.x.0`) are treated as `0` instead of
/// throwing — we don't want a malformed registry payload to crash the
/// "Update available" badge.
int compareSdkVersions(String a, String b) {
  final pa = a.split('.');
  final pb = b.split('.');
  final length = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < length; i++) {
    final ai = i < pa.length ? int.tryParse(pa[i]) ?? 0 : 0;
    final bi = i < pb.length ? int.tryParse(pb[i]) ?? 0 : 0;
    if (ai != bi) return ai - bi;
  }
  return 0;
}