/// Pretty-printing for network request URLs.
///
/// Two formats are exposed:
/// - [formatUrlCompact] — single-line, truncated. For the request card list
///   where horizontal space is scarce. Decodes percent-encoding so
///   `id%2Cname` renders as `id,name`, drops the host (it lives in the host
///   row below), and shows the first 1–2 query params followed by `+ N`
///   when more are present.
/// - [formatUrlPretty] — multi-line layout for the detail panel. Renders
///   the host on its own line, the path on the next, then each query
///   parameter on its own line, prefixed with `?` for the first and `&`
///   for the rest. Decodes percent-encoding on values, keeps keys verbatim.
library;

/// One parsed query parameter. `key` is kept verbatim (per RFC 3986 keys
/// don't need encoding in practice), `value` is percent-decoded so the
/// UI shows `id,name,foo` instead of `id%2Cname%2Cfoo`.
class FormattedQueryParam {
  final String key;
  final String value;
  const FormattedQueryParam(this.key, this.value);
}

/// Result of [formatUrlCompact] / [formatUrlPretty]. Always non-null when
/// the input parses as a URI; falls back to a single-line `raw` view when
/// it doesn't.
class FormattedUrl {
  final String? host;
  final String path;
  final List<FormattedQueryParam> queryParams;
  final String raw;

  const FormattedUrl({
    required this.host,
    required this.path,
    required this.queryParams,
    required this.raw,
  });

  bool get hasQuery => queryParams.isNotEmpty;
}

/// Parses [url] into a [FormattedUrl]. Returns null if [url] is empty or
/// the SDK already marked it as `<unknown url>`. Malformed URLs fall
/// through to a single-field `FormattedUrl` with `host`/`path` null.
FormattedUrl? parseFormattedUrl(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty || trimmed == '<unknown url>') return null;

  Uri uri;
  try {
    uri = Uri.parse(trimmed);
  } catch (_) {
    return FormattedUrl(host: null, path: trimmed, queryParams: const [], raw: trimmed);
  }

  // `uri.queryParametersAll` keeps insertion order AND preserves repeated
  // keys as lists — the former matters for `?order=` style params, the
  // latter for Supabase-style `?id=in.(1,2,3)` filters.
  final params = <FormattedQueryParam>[];
  uri.queryParametersAll.forEach((k, values) {
    for (final v in values) {
      params.add(FormattedQueryParam(k, _decode(v)));
    }
  });

  return FormattedUrl(
    host: uri.host.isEmpty ? null : uri.host,
    path: uri.path.isEmpty ? '/' : uri.path,
    queryParams: params,
    raw: trimmed,
  );
}

/// Compact single-line view: `/path ?key=value, key2=value2 + N more`.
/// Truncates to [maxLength] with an ellipsis. Drops the host (it has its
/// own slot in the card row).
String formatUrlCompact(String? url, {int maxLength = 100}) {
  final parsed = parseFormattedUrl(url);
  if (parsed == null) return '';
  if (parsed.queryParams.isEmpty) return parsed.path;

  const previewCount = 2;
  final preview = parsed.queryParams
      .take(previewCount)
      .map((p) => p.value.isEmpty ? p.key : '${p.key}=${p.value}')
      .join(', ');
  final remaining = parsed.queryParams.length - previewCount;
  final tail = remaining > 0 ? ' + $remaining' : '';
  final line = '${parsed.path} ? $preview$tail';
  return line.length > maxLength ? '${line.substring(0, maxLength - 1)}…' : line;
}

/// Two-line pretty view for the detail panel:
///
///     https://host.example.com/rest/v1/legal_documents
///     ?select=id,name,...&audience=eq.customer&language=eq.vi&...
///
/// Stays at exactly two lines (scheme+host+path on top, all query params
/// joined on bottom) regardless of how many params the URL has. Pair
/// with `maxLines: 2` + `TextOverflow.ellipsis` in the widget so an
/// over-wide params line truncates instead of wrapping. Values are
/// percent-decoded.
String formatUrlPretty(String? url) {
  final parsed = parseFormattedUrl(url);
  if (parsed == null) return '';
  final scheme = Uri.tryParse(parsed.raw)?.scheme;
  final showScheme = scheme != null && scheme.isNotEmpty;
  final hostPart = parsed.host ?? '';
  final line1 = showScheme
      ? '$scheme://$hostPart${parsed.path}'
      : (hostPart.isEmpty ? parsed.path : '$hostPart${parsed.path}');
  if (parsed.queryParams.isEmpty) return line1;
  final line2 = parsed.queryParams
      .map((p) => p.value.isEmpty ? p.key : '${p.key}=${p.value}')
      .join('&');
  return '$line1\n?$line2';
}

/// Decodes a percent-encoded string. Falls back to the original input on
/// malformed escapes (which `Uri.decodeQueryComponent` would throw on) so
/// the UI never crashes on a bad URL.
String _decode(String input) {
  try {
    return Uri.decodeQueryComponent(input);
  } catch (_) {
    return input;
  }
}

/// Number of query parameters — for the card row's " + N" hint and for
/// the `?5 params` fallback when [formatUrlCompact] is in tight mode.
int queryParamCount(String? url) => parseFormattedUrl(url)?.queryParams.length ?? 0;

/// Single-line, percent-decoded URL — what `Copy URL` puts on the
/// clipboard. Still a valid URL when pasted into a browser / Postman
/// (host + path + `?k=v&k=v`), but with `%2C` → `,` and friends so the
/// pasted value is human-readable. Falls back to the raw input when the
/// value isn't a parseable URL.
String formatUrlOneLine(String? url) {
  if (url == null) return '';
  final parsed = parseFormattedUrl(url);
  if (parsed == null) return '';
  // Malformed-URL fallback: parser returned a single raw path with no
  // host and no params. Return the raw input verbatim.
  if (parsed.host == null && parsed.queryParams.isEmpty &&
      parsed.path == parsed.raw) {
    return parsed.raw;
  }
  final scheme = Uri.tryParse(parsed.raw)?.scheme;
  final schemePrefix =
      (scheme != null && scheme.isNotEmpty) ? '$scheme://' : '';
  final buf = StringBuffer('$schemePrefix${parsed.host ?? ''}${parsed.path}');
  for (var i = 0; i < parsed.queryParams.length; i++) {
    final p = parsed.queryParams[i];
    buf.write(i == 0 ? '?' : '&');
    buf.write(p.key);
    if (p.value.isNotEmpty) buf.write('=${p.value}');
  }
  return buf.toString();
}
