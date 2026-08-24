/// Round 4: a single mock audit record. The SDK reports every request
/// that was intercepted by a mock rule so the desktop can audit
/// what the device actually saw vs what was wired.
class MockedRequestEntry {
  final String id;
  final String deviceId;
  final String method;
  final String url;
  final String matchedRuleId;
  final String matchedRuleName;
  final int statusCode;
  final int timestamp;
  final Map<String, dynamic>? metadata;

  const MockedRequestEntry({
    required this.id,
    required this.deviceId,
    required this.method,
    required this.url,
    required this.matchedRuleId,
    required this.matchedRuleName,
    required this.statusCode,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceId': deviceId,
        'method': method,
        'url': url,
        'matchedRuleId': matchedRuleId,
        'matchedRuleName': matchedRuleName,
        'statusCode': statusCode,
        'timestamp': timestamp,
        if (metadata != null) 'metadata': metadata,
      };

  /// Parses the SDK's `client:mocked_request` audit payload. The wire
  /// shape is intentionally minimal — only `ruleId`, `status`,
  /// `requestId`, `timestamp` — and the caller enriches `method` /
  /// `url` / `matchedRuleName` by looking the rule up locally.
  factory MockedRequestEntry.fromAuditPayload(
    Map<String, dynamic> p, {
    required String id,
    required String deviceId,
    required int timestamp,
    String method = 'GET',
    String url = '',
    String matchedRuleName = '',
    Map<String, dynamic>? metadata,
  }) =>
      MockedRequestEntry(
        id: id,
        deviceId: deviceId,
        method: p['method'] as String? ?? method,
        url: p['url'] as String? ?? url,
        matchedRuleId: p['ruleId'] as String? ?? (p['matchedRuleId'] as String? ?? ''),
        matchedRuleName: matchedRuleName,
        statusCode: p['status'] as int? ?? (p['statusCode'] as int? ?? 200),
        timestamp: timestamp,
        metadata: metadata ?? (p['metadata'] as Map?)?.cast<String, dynamic>(),
      );

  factory MockedRequestEntry.fromJson(Map<String, dynamic> json) =>
      MockedRequestEntry.fromAuditPayload(
        json,
        id: json['id'] as String,
        deviceId: json['deviceId'] as String,
        timestamp: json['timestamp'] as int? ?? 0,
        method: json['method'] as String? ?? 'GET',
        url: json['url'] as String? ?? '',
        matchedRuleName: json['matchedRuleName'] as String? ?? '',
        metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
      );
}

/// Round 4: a mock rule the desktop pushes to the SDK. Designed so a
/// rule with [enabled] = false survives in the list but is not pushed
/// down to the device.
class MockRule {
  final String id;
  final String name;
  final String method;
  final String urlPattern;
  final int statusCode;
  final Map<String, String> headers;
  final String body;
  final bool enabled;
  final int hitCount;
  final int updatedAt;
  final Map<String, dynamic>? metadata;

  const MockRule({
    required this.id,
    required this.name,
    required this.method,
    required this.urlPattern,
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.enabled,
    required this.hitCount,
    required this.updatedAt,
    this.metadata,
  });

  /// `metadata` is special: callers may want to clear it (empty map)
  /// as well as set it, so the sentinel `clearMetadata: true` strips
  /// it. Default keeps [metadata] untouched.
  MockRule copyWith({
    String? name,
    String? method,
    String? urlPattern,
    int? statusCode,
    Map<String, String>? headers,
    String? body,
    bool? enabled,
    int? hitCount,
    int? updatedAt,
    Map<String, dynamic>? metadata,
    bool clearMetadata = false,
  }) =>
      MockRule(
        id: id,
        name: name ?? this.name,
        method: method ?? this.method,
        urlPattern: urlPattern ?? this.urlPattern,
        statusCode: statusCode ?? this.statusCode,
        headers: headers ?? this.headers,
        body: body ?? this.body,
        enabled: enabled ?? this.enabled,
        hitCount: hitCount ?? this.hitCount,
        updatedAt: updatedAt ?? this.updatedAt,
        metadata: clearMetadata ? null : (metadata ?? this.metadata),
      );

  /// Local JSON for persistence / UI. Flat shape — desktop-only fields
  /// like `name`, `hitCount`, `updatedAt` live here.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'method': method,
        'urlPattern': urlPattern,
        'statusCode': statusCode,
        'headers': headers,
        'body': body,
        'enabled': enabled,
        'hitCount': hitCount,
        'updatedAt': updatedAt,
        if (metadata != null) 'metadata': metadata,
      };

  /// Wire JSON for `server:mock_rules_update`. Mirrors the SDK's
  /// `MockRule` model — nested `match`/`response` shape with only the
  /// fields the SDK actually needs to intercept. Optional `scope` and
  /// `expiresAt` are forwarded when present in [metadata].
  Map<String, dynamic> toWireJson() {
    final wire = <String, dynamic>{
      'id': id,
      'name': name,
      'enabled': enabled,
      'match': {
        'method': method,
        'url': urlPattern,
        if (metadata != null && metadata!.containsKey('matchHeaders'))
          'headers': metadata!['matchHeaders'],
      },
      'response': {
        'status': statusCode,
        'body': body,
        if (headers.isNotEmpty) 'headers': headers,
      },
    };
    if (metadata != null) {
      if (metadata!.containsKey('scope')) wire['scope'] = metadata!['scope'];
      if (metadata!.containsKey('expiresAt')) {
        wire['expiresAt'] = metadata!['expiresAt'];
      }
      if (metadata!.containsKey('delayMs')) {
        wire['response']['delayMs'] = metadata!['delayMs'];
      }
    }
    return wire;
  }

  factory MockRule.fromJson(Map<String, dynamic> json) => MockRule(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        method: json['method'] as String? ?? 'GET',
        urlPattern: json['urlPattern'] as String? ?? '',
        statusCode: json['statusCode'] as int? ?? 200,
        headers: (json['headers'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            const {},
        body: json['body'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
        hitCount: json['hitCount'] as int? ?? 0,
        updatedAt: json['updatedAt'] as int? ?? 0,
        metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
      );
}