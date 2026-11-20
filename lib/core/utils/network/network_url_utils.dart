/// Helpers for normalising network-request URLs coming off the wire.
///
/// Older or poorly-behaved client SDKs sometimes send a value that is not
/// a real URL string — most commonly the default JS
/// `Object.prototype.toString()` rendering of a Request object:
/// `"[object Object]"`, or a URL-encoded variant like
/// `"%5Bobject%20Object%5D"`. We surface those as a clear placeholder so
/// the inspector list/detail panels don't show a wall of encoded
/// brackets.
library;

/// Returns true if [url] is a string but does not look like a real URL.
/// Detects:
/// - The classic JS `Object.prototype.toString()` rendering.
/// - Empty strings.
/// - Strings that don't contain either `://` or start with `/` (i.e. a
///   relative path, which is still meaningful), AND have no host-like
///   component. We deliberately keep the check loose so legitimate
///   relative paths like `/api/users` still pass through.
bool isMalformedNetworkUrl(String? url) {
  if (url == null) return true;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return true;
  if (trimmed == '[object Object]') return true;
  // URL-encoded variant — also matches things like
  // `%5Bobject%20Object%5D` or `%5Bobject Object%5D`.
  if (trimmed.toLowerCase().contains('[object') &&
      trimmed.toLowerCase().contains('object]')) {
    return true;
  }
  if (trimmed.toLowerCase() == '%5bobject%20object%5d') return true;
  return false;
}

/// Normalise a raw URL value coming off the wire. Returns
/// `'<unknown url>'` for values that aren't usable URLs.
String normalizeNetworkUrl(String? url) =>
    isMalformedNetworkUrl(url) ? '<unknown url>' : url!.trim();
