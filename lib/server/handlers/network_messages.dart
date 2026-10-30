part of '../ws_message_handler.dart';

extension _NetworkMessages on WsMessageHandler {
  /// Build a unique id for one logical network request.
  ///
  /// One round-trip = one start + one complete (whether success or
  /// error) sharing a `requestId`. All messages of that round-trip
  /// must emit the SAME id so the provider can merge them into a
  /// single row.
  ///
  /// When two genuinely concurrent requests arrive with the same
  /// `requestId`, the first start mints `base` as the canonical id and
  /// marks it open; the second start sees the open trip and mints a
  /// fresh disambiguated id (also marked open). Each round-trip's
  /// complete then finds its own canonical id via the open-trips map.
  String _uniqueNetworkId(DCMessage message, Map<String, dynamic> payload) {
    final raw = payload['requestId'] as String?;
    final base = (raw != null && raw.isNotEmpty) ? raw : message.id;
    final isComplete =
        message.type == WsMessageTypes.clientNetworkRequestComplete;
    final canonical = _mintOrReuseCanonical(base, isComplete);
    if (!isComplete) {
      // Start — register the round-trip as open so the matching
      // complete can find it. Also remember the base for dedup.
      _openTrips[canonical] = base;
    } else {
      // Complete — drop the open-trip entry. If no open trip existed
      // (orphan complete or disambiguated start whose complete we
      // also disambiguated), nothing to remove.
      _openTrips.remove(canonical);
    }
    _trimOpenTrips();
    return canonical;
  }

  /// For a start: if no round-trip is currently open for this base,
  /// mint a fresh canonical id and remember it as open. If another
  /// round-trip is already open for the same base, disambiguate and
  /// remember a fresh id.
  ///
  /// For a complete: locate the open round-trip for this base and
  /// reuse its canonical id (this is the start→complete round-trip
  /// case). If no open trip exists (orphan complete), mint a fresh
  /// canonical id and don't open a trip (it'll just stand alone).
  String _mintOrReuseCanonical(String base, bool isComplete) {
    if (!isComplete) {
      // Find any existing open trip for this base.
      final existing = _existingOpenCanonicalForBase(base);
      if (existing != null && _isOpenFor(existing)) {
        return _disambiguate(base);
      }
      return base;
    }
    // Complete: find the open round-trip for this base.
    final existing = _existingOpenCanonicalForBase(base);
    if (existing != null) {
      return existing;
    }
    return base;
  }

  String? _existingOpenCanonicalForBase(String base) {
    for (final entry in _openTrips.entries) {
      if (entry.value == base) return entry.key;
    }
    return null;
  }

  bool _isOpenFor(String canonical) => _openTrips.containsKey(canonical);

  String _disambiguate(String base) {
    final seq = (++_networkSeq).toRadixString(36);
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rand = _uuid.v4().substring(0, 4);
    return '$base-$micros-$seq-$rand';
  }

  void _trimOpenTrips() {
    if (_openTrips.length <= 2048) return;
    final drop = _openTrips.length - 1024;
    final keys = _openTrips.keys.toList(growable: false);
    for (var i = 0; i < drop; i++) {
      _openTrips.remove(keys[i]);
    }
  }

  void _handleNetwork(DCMessage message) {
    final p = message.payload;
    final reqHeaders = _castStringMap(p['requestHeaders']);
    final resHeaders = _castStringMap(p['responseHeaders']);
    final reqBody = p['requestBody'];
    final resBody = p['responseBody'];
    final url = normalizeNetworkUrl(p['url'] as String?);
    final detected = detectService(
      url,
      headers: {...reqHeaders, ...resHeaders},
      body: reqBody,
    );
    final entry = NetworkEntry(
      id: _uniqueNetworkId(message, p),
      deviceId: message.deviceId,
      method: p['method'] as String? ?? 'GET',
      url: url,
      statusCode: p['statusCode'] as int? ?? 0,
      requestHeaders: reqHeaders,
      responseHeaders: resHeaders,
      requestBody: reqBody,
      responseBody: resBody,
      startTime: p['startTime'] as int? ?? message.timestamp,
      endTime: p['endTime'] as int?,
      duration: p['duration'] as int?,
      error: p['error'] as String?,
      isComplete: message.type == WsMessageTypes.clientNetworkRequestComplete,
      source: p['source'] as String? ?? 'app',
      serviceName: detected?.name,
      serviceAction: detected?.action,
      via: p['via'] as String? ?? NetworkVia.unknown,
    );
    _networkController.add(entry);
  }

  /// Coerce a JSON-decoded map (keys/values are `dynamic`) into a flat
  /// `Map<String, String>`. Header values from RN SDKs are sometimes
  /// objects or arrays (e.g. `map: { apiKey: 'xxx' }`); calling `.toString()`
  /// on those would yield `[object Object]` (JS-style) or a noisy
  /// `{key: value}` rendering (Dart-style). JSON-encode nested types so
  /// the UI can render them as inspectable JSON. Primitives pass through
  /// unchanged — no quotes around `42` or `true`.
  Map<String, String> _castStringMap(dynamic map) {
    if (map is! Map) return {};
    return map.map((k, v) => MapEntry(k.toString(), _stringifyHeaderValue(v)));
  }

  /// Render a single header value as a string the UI can show. Handles
  /// three layers of defense so an object/array header survives intact
  /// end-to-end:
  ///   1. Real `Map`/`List` Dart values → pretty-print JSON (the SDK
  ///      sent a structured value, e.g. `map: { apiKey: 'x' }`).
  ///   2. Strings that look like JSON (start with `{`/`[`, end with
  ///      `}`/`]`) → try to parse and pretty-print. This catches the
  ///      case where the SDK pre-stringified via `JSON.stringify` before
  ///      sending over WS.
  ///   3. Strings that are unrecoverable (e.g. the literal
  ///      `[object Object]` from JS's `String(obj)`) → label them as
  ///      `<unrecoverable object>` so the user knows the original shape
  ///      is gone, but at least they don't see a useless placeholder.
  String _stringifyHeaderValue(dynamic v) {
    if (v == null) return '';
    if (v is String) return _decodeMaybeJsonString(v);
    if (v is num || v is bool) return v.toString();
    if (v is List || v is Map) {
      try {
        return const JsonEncoder.withIndent('  ').convert(v);
      } catch (_) {
        try {
          return jsonEncode(v);
        } catch (_) {
          return v.toString();
        }
      }
    }
    return v.toString();
  }

  /// If [s] looks like a JSON document (object or array), try to parse
  /// and pretty-print it. Otherwise return [s] verbatim. Strings that
  /// are unrecoverable object literals (`[object Object]`) get labeled
  /// so the user knows the original value was lost upstream.
  String _decodeMaybeJsonString(String s) {
    final t = s.trim();
    final looksLikeObject = t.startsWith('{') && t.endsWith('}');
    final looksLikeArray = t.startsWith('[') && t.endsWith(']');
    if (looksLikeObject || looksLikeArray) {
      try {
        final decoded = jsonDecode(t);
        if (decoded is Map || decoded is List) {
          return const JsonEncoder.withIndent('  ').convert(decoded);
        }
      } catch (_) {}
    }
    // JS's String(obj) on a plain object produces the literal
    // "[object Object]". There's no way to recover the original, so
    // label it clearly so the user knows the SDK stripped the value.
    if (s == '[object Object]') return '<unrecoverable object>';
    return s;
  }
}
