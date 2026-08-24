import 'dart:async';
import 'dart:convert';

import '../devconnect_client.dart';

bool _serverHandlerRegistered = false;

/// Wire the mock server interceptor to the DevConnect message loop
/// so that `server:mock_rules_update` automatically calls [setMockRules].
/// Idempotent — repeated calls are no-ops.
void installMockServerInterceptor() {
  if (_serverHandlerRegistered) return;
  try {
    DevConnectClient.instance.registerServerHandler(
      'server:mock_rules_update',
      (msg) {
        try {
          final rules = msg['rules'];
          if (rules is List) {
            setMockRules(parseRules(rules));
          }
        } catch (_) {}
      },
    );
    _serverHandlerRegistered = true;
  } catch (_) {}
}

/// Mock server rule pushed by the DevConnect desktop.
class MockRule {
  final String id;
  final bool enabled;
  final MockMatch match;
  final MockResponse response;

  const MockRule({
    required this.id,
    required this.enabled,
    required this.match,
    required this.response,
  });

  factory MockRule.fromJson(Map<String, dynamic> json) => MockRule(
        id: json['id'] as String,
        enabled: json['enabled'] as bool? ?? true,
        match: MockMatch.fromJson(json['match'] as Map<String, dynamic>),
        response: MockResponse.fromJson(json['response'] as Map<String, dynamic>),
      );
}

class MockMatch {
  final String method;
  final String url; // regex
  final Map<String, String>? headers;

  const MockMatch({
    required this.method,
    required this.url,
    this.headers,
  });

  factory MockMatch.fromJson(Map<String, dynamic> json) => MockMatch(
        method: (json['method'] as String? ?? 'GET').toUpperCase(),
        url: json['url'] as String? ?? '.*',
        headers: (json['headers'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())),
      );
}

class MockResponse {
  final int status;
  final Map<String, String>? headers;
  final String body;
  final int? delayMs;

  const MockResponse({
    required this.status,
    required this.body,
    this.headers,
    this.delayMs,
  });

  factory MockResponse.fromJson(Map<String, dynamic> json) => MockResponse(
        status: json['status'] as int? ?? 200,
        body: json['body'] as String? ?? '',
        headers: (json['headers'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())),
        delayMs: json['delayMs'] as int?,
      );
}

class _MockRuleStore {
  final List<MockRule> _rules = [];
  final Map<String, RegExp> _regexCache = {};
  // Header regex cache: keyed by `ruleId|headerKey` → compiled RegExp.
  // Infrastructure is here; the production `findMatch` does not yet
  // populate it — that is the bug we are about to fix.
  final Map<String, RegExp> _headerRegexCache = {};

  /// Number of cached header regexes. Exposed for tests so we can
  /// assert that compilation is amortized, not repeated per call.
  int get headerRegexCacheSize => _headerRegexCache.length;

  void setRules(List<MockRule> rules) {
    _rules
      ..clear()
      ..addAll(rules.where((r) => r.enabled));
    _regexCache.clear();
    _headerRegexCache.clear();
  }

  MockRule? findMatch(String method, String url, Map<String, String>? headers) {
    for (final rule in _rules) {
      if (!rule.enabled) continue;
      if (rule.match.method.toUpperCase() != method.toUpperCase()) continue;
      final regex = _regexCache[rule.id] ?? (() {
        try {
          return RegExp(rule.match.url);
        } catch (_) {
          return null;
        }
      })();
      if (regex == null) continue;
      _regexCache[rule.id] = regex;
      if (!regex.hasMatch(url)) continue;
      if (rule.match.headers != null && headers != null) {
        // Lowercase incoming header keys once so callers can pass either
        // casing — Dart's standard HTTP APIs expose them in their original
        // case (e.g. 'X-Trace-Id') while the rule keys are typically lower.
        final lowerHeaders = <String, String>{
          for (final e in headers.entries) e.key.toLowerCase(): e.value,
        };
        bool ok = true;
        for (final entry in rule.match.headers!.entries) {
          final cacheKey = '${rule.id}|${entry.key}';
          final cached = _headerRegexCache[cacheKey];
          RegExp re;
          if (cached != null) {
            re = cached;
          } else {
            try {
              re = RegExp(entry.value);
              _headerRegexCache[cacheKey] = re;
            } catch (_) {
              // Invalid regex in a required header — rule can never match.
              ok = false;
              break;
            }
          }
          final actual = lowerHeaders[entry.key.toLowerCase()] ?? '';
          if (!re.hasMatch(actual)) {
            ok = false;
            break;
          }
        }
        if (!ok) continue;
      }
      return rule;
    }
    return null;
  }
}

final _store = _MockRuleStore();

/// Replace the rule list (called from `server:mock_rules_update`).
void setMockRules(List<MockRule> rules) => _store.setRules(rules);

/// Look up a matching rule. Returns null when no match — caller falls
/// through to the real network.
MockRule? findMockMatch(String method, String url, Map<String, String>? headers) =>
    _store.findMatch(method, url, headers);

/// Number of cached header regexes across all rules. Exposed for tests
/// so they can assert that header regexes are compiled once per rule,
/// not once per request.
int get mockHeaderRegexCacheSize => _store.headerRegexCacheSize;

/// Build a synthetic HTTP response from a rule. Apply [delayMs] before
/// returning so the consumer sees realistic latency.
Future<MockedHttpResponse> buildMockResponse(MockRule rule, String requestId) async {
  if (rule.response.delayMs != null && rule.response.delayMs! > 0) {
    await Future.delayed(Duration(milliseconds: rule.response.delayMs!));
  }
  try {
    DevConnectClient.safeSend('client:mocked_request', {
      'ruleId': rule.id,
      'status': rule.response.status,
      'requestId': requestId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  } catch (_) {}
  return MockedHttpResponse(
    status: rule.response.status,
    body: rule.response.body,
    headers: rule.response.headers ?? const {},
  );
}

class MockedHttpResponse {
  final int status;
  final String body;
  final Map<String, String> headers;
  const MockedHttpResponse({
    required this.status,
    required this.body,
    required this.headers,
  });
  String get bodyUtf8 => body;
  Map<String, dynamic>? get bodyJson {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

/// Parse rules from a JSON list (e.g. from the desktop).
List<MockRule> parseRules(List<dynamic> json) =>
    json.whereType<Map<String, dynamic>>().map(MockRule.fromJson).toList();