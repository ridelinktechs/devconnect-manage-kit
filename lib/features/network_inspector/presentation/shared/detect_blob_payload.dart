/// Detects whether [body] is one of the binary-payload placeholder strings
/// the SDKs send instead of a binary body, or a picture they send as a
/// `data:` URL. Returns `(type, sizeBytes)` — both `null` when the body is
/// real data.
///
/// Recognized formats:
/// - `&lt;N bytes&gt;`, `&lt;blob N bytes&gt;` / `&lt;arraybuffer N bytes&gt;`,
///   `&lt;blob: N bytes&gt;`, `&lt;binary, N bytes&gt;`, `&lt;large, N bytes&gt;`
///   → type `blob` (or the one named)
/// - `N bytes` (bare) → type `blob`
/// - `data:<mime>;base64,…` → type `<mime>`, sized as decoded
///
/// Used by [BodyTab] and [RequestDetailPanel] so both views share one
/// definition of "is this body blob-shaped?".
(String?, int?) detectBlobPayload(dynamic body) {
  if (body is String) {
    if (body.startsWith('data:')) {
      final comma = body.indexOf(',');
      final header = comma < 0 ? '' : body.substring(5, comma);
      if (header.endsWith(';base64')) {
        final pad = body.endsWith('==') ? 2 : (body.endsWith('=') ? 1 : 0);
        return (
          header.substring(0, header.length - 7),
          (body.length - comma - 1) * 3 ~/ 4 - pad,
        );
      }
    }
    final t = body.trim();
    final m = RegExp(
      r'^<\s*(?:(blob|arraybuffer|binary|large)[:,]?\s+)?(\d+)\s*bytes\s*>$',
      caseSensitive: false,
    ).firstMatch(t);
    if (m != null) return (m.group(1) ?? 'blob', int.tryParse(m.group(2)!));
    final m3 = RegExp(r'^(\d+)\s*bytes$', caseSensitive: false).firstMatch(t);
    if (m3 != null) return ('blob', int.tryParse(m3.group(1)!));
  }
  return (null, null);
}
