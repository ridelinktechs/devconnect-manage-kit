/// Detects whether [body] is one of the binary-payload placeholder strings
/// that the upstream SDK emits when it suppresses a large / non-UTF8
/// response. Returns `(type, sizeBytes)` — both `null` when the body is
/// real data.
///
/// Three placeholder formats are recognized:
/// - `&lt;blob N bytes&gt;` / `&lt;arraybuffer N bytes&gt;` → type `blob` / `arraybuffer`
/// - `&lt;blob: N bytes&gt;` → type `blob`
/// - `N bytes` (bare) → type `blob`
///
/// Used by [BodyTab] and [RequestDetailPanel] so both views share one
/// definition of "is this body blob-shaped?".
(String?, int?) detectBlobPayload(dynamic body) {
  if (body is String) {
    final t = body.trim();
    final m = RegExp(r'^<\s*(blob|arraybuffer)\s+(\d+)\s*bytes\s*>\s*$',
            caseSensitive: false)
        .firstMatch(t);
    if (m != null) return (m.group(1), int.tryParse(m.group(2)!));
    final m2 =
        RegExp(r'^<blob:\s*(\d+)\s*bytes>\s*$', caseSensitive: false)
            .firstMatch(t);
    if (m2 != null) return ('blob', int.tryParse(m2.group(1)!));
    final m3 = RegExp(r'^(\d+)\s*bytes$', caseSensitive: false).firstMatch(t);
    if (m3 != null) return ('blob', int.tryParse(m3.group(1)!));
  }
  return (null, null);
}