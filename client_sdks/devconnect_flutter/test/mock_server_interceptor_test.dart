import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect_manage_kit/src/interceptors/mock_server_interceptor.dart';

void main() {
  // Reset global rule store between tests so they don't bleed.
  setUp(() {
    setMockRules(const []);
  });

  group('MockRule.fromJson', () {
    test('parses valid JSON', () {
      final rule = MockRule.fromJson({
        'id': 'r1',
        'enabled': true,
        'match': {
          'method': 'GET',
          'url': r'^https://api.example.com/users$',
        },
        'response': {
          'status': 200,
          'body': '{"users":[]}',
          'headers': {'content-type': 'application/json'},
          'delayMs': 250,
        },
      });

      expect(rule.id, 'r1');
      expect(rule.enabled, isTrue);
      expect(rule.match.method, 'GET');
      expect(rule.match.url, r'^https://api.example.com/users$');
      expect(rule.match.headers, isNull);
      expect(rule.response.status, 200);
      expect(rule.response.body, '{"users":[]}');
      expect(rule.response.headers, {'content-type': 'application/json'});
      expect(rule.response.delayMs, 250);
    });

    test('handles missing optional fields with sensible defaults', () {
      final rule = MockRule.fromJson({
        'id': 'r2',
        'match': <String, dynamic>{'url': '.*'},
        'response': <String, dynamic>{},
      });

      expect(rule.enabled, isTrue); // default
      expect(rule.match.method, 'GET'); // default
      expect(rule.match.url, '.*');
      expect(rule.response.status, 200); // default
      expect(rule.response.body, '');
      expect(rule.response.headers, isNull);
      expect(rule.response.delayMs, isNull);
    });

    test('defaults method to GET and uppercases the input', () {
      final rule = MockRule.fromJson({
        'id': 'r3',
        'match': <String, dynamic>{'method': 'post', 'url': '.*'},
        'response': <String, dynamic>{},
      });

      expect(rule.match.method, 'POST');
    });

    test('coerces header values to strings', () {
      final rule = MockRule.fromJson({
        'id': 'r4',
        'match': {
          'method': 'GET',
          'url': '.*',
          'headers': {'x-trace': 12345, 'x-tag': 'abc'},
        },
        'response': {'headers': {'content-type': 'text/plain'}},
      });

      expect(rule.match.headers, {'x-trace': '12345', 'x-tag': 'abc'});
      expect(rule.response.headers, {'content-type': 'text/plain'});
    });
  });

  group('findMockMatch', () {
    test('matches method case-insensitively', () {
      setMockRules([
        MockRule.fromJson({
          'id': 'm1',
          'match': {'method': 'post', 'url': '.*'},
          'response': {'status': 200, 'body': '{}'},
        }),
      ]);

      final r1 = findMockMatch('POST', 'https://x/y', null);
      final r2 = findMockMatch('post', 'https://x/y', null);
      final r3 = findMockMatch('Post', 'https://x/y', null);

      expect(r1, isNotNull);
      expect(r2, isNotNull);
      expect(r3, isNotNull);
      expect(r1!.id, 'm1');
    });

    test('matches URL via regex', () {
      setMockRules([
        MockRule.fromJson({
          'id': 'u1',
          'match': {'method': 'GET', 'url': r'^https://api\.example\.com/users/\d+$'},
          'response': {'status': 200, 'body': '{}'},
        }),
      ]);

      final ok = findMockMatch('GET', 'https://api.example.com/users/42', null);
      final miss = findMockMatch('GET', 'https://api.example.com/posts', null);
      final miss2 = findMockMatch('GET', 'https://other.example.com/users/1', null);

      expect(ok, isNotNull);
      expect(miss, isNull);
      expect(miss2, isNull);
    });

    test('returns null when no rule matches', () {
      setMockRules([
        MockRule.fromJson({
          'id': 'n1',
          'match': {'method': 'DELETE', 'url': '.*'},
          'response': {'status': 204, 'body': ''},
        }),
      ]);

      final res = findMockMatch('GET', 'https://x/y', null);
      expect(res, isNull);
    });

    test('skips disabled rules', () {
      setMockRules([
        MockRule.fromJson({
          'id': 'd1',
          'enabled': false,
          'match': {'method': 'GET', 'url': '.*'},
          'response': {'status': 200, 'body': '{}'},
        }),
      ]);

      final res = findMockMatch('GET', 'https://x/y', null);
      expect(res, isNull);
    });

    test('enforces header constraints (regex match)', () {
      setMockRules([
        MockRule.fromJson({
          'id': 'h1',
          'match': {
            'method': 'GET',
            'url': '.*',
            'headers': {
              'authorization': r'^Bearer .+',
              'x-tenant': r'^(acme|globex)$',
            },
          },
          'response': {'status': 200, 'body': '{}'},
        }),
      ]);

      final ok = findMockMatch('GET', 'https://x/y', {
        'authorization': 'Bearer abc',
        'x-tenant': 'acme',
      });
      final badAuth = findMockMatch('GET', 'https://x/y', {
        'authorization': 'Basic xyz',
        'x-tenant': 'acme',
      });
      final badTenant = findMockMatch('GET', 'https://x/y', {
        'authorization': 'Bearer abc',
        'x-tenant': 'other',
      });
      final missingHeader = findMockMatch('GET', 'https://x/y', {
        'authorization': 'Bearer abc',
      });

      expect(ok, isNotNull);
      expect(badAuth, isNull);
      expect(badTenant, isNull);
      // Missing header → empty string default → fails the regex.
      expect(missingHeader, isNull);
    });

    test('header lookup is case-insensitive on incoming request headers', () {
      setMockRules([
        MockRule.fromJson({
          'id': 'h2',
          'match': {
            'method': 'GET',
            'url': '.*',
            'headers': {'x-trace-id': r'^T-'},
          },
          'response': {'status': 200, 'body': '{}'},
        }),
      ]);

      final ok = findMockMatch('GET', 'https://x/y', {
        'X-Trace-Id': 'T-001',
      });
      expect(ok, isNotNull);
    });

    test('does not throw on invalid regex in match.url', () {
      setMockRules([
        MockRule.fromJson({
          'id': 'bad-regex',
          'match': {'method': 'GET', 'url': r'(unclosed'},
          'response': {'status': 200, 'body': '{}'},
        }),
      ]);

      // Should return null without throwing, since the rule is unusable.
      final res = findMockMatch('GET', 'https://x/y', null);
      expect(res, isNull);
    });

    test('does not throw on invalid regex in match.headers', () {
      setMockRules([
        MockRule.fromJson({
          'id': 'bad-header-regex',
          'match': {
            'method': 'GET',
            'url': '.*',
            'headers': {'x-foo': r'(unclosed'},
          },
          'response': {'status': 200, 'body': '{}'},
        }),
      ]);

      // Should return null because the header regex fails to compile.
      final res = findMockMatch('GET', 'https://x/y', {'x-foo': 'bar'});
      expect(res, isNull);
    });

    test('caches regex via built-in cache (idempotent across calls)', () {
      setMockRules([
        MockRule.fromJson({
          'id': 'cache-1',
          'match': {'method': 'GET', 'url': r'^https://api/cache$'},
          'response': {'status': 200, 'body': '{}'},
        }),
      ]);

      // Same rule, different URLs — one matches, one doesn't. Both
      // calls must succeed without throwing, exercising the cache.
      final hit = findMockMatch('GET', 'https://api/cache', null);
      final miss = findMockMatch('GET', 'https://api/other', null);
      final hitAgain = findMockMatch('GET', 'https://api/cache', null);

      expect(hit, isNotNull);
      expect(miss, isNull);
      expect(hitAgain, isNotNull);
    });

    test('header regex is compiled once and cached across calls', () {
      // Bug: every call to `findMatch` re-compiles every header regex
      // from scratch. With a busy rule set this is quadratic. The fix:
      // cache by `rule.id|headerKey` like the URL regex cache.
      setMockRules([
        MockRule.fromJson({
          'id': 'hdr-cache',
          'match': {
            'method': 'GET',
            'url': '.*',
            'headers': {
              'authorization': r'^Bearer .+',
              'x-tenant': r'^(acme|globex)$',
            },
          },
          'response': {'status': 200, 'body': '{}'},
        }),
      ]);

      final initialCacheSize = mockHeaderRegexCacheSize;
      expect(initialCacheSize, 0,
          reason: 'Fresh store has no cached header regexes.');

      // First call should compile and cache both header regexes.
      findMockMatch('GET', 'https://x/y', {
        'authorization': 'Bearer abc',
        'x-tenant': 'acme',
      });
      final afterFirstCall = mockHeaderRegexCacheSize;
      expect(afterFirstCall, 2,
          reason: 'Two headers in the rule → two cached regexes.');

      // Subsequent calls must not grow the cache (amortized cost).
      findMockMatch('GET', 'https://x/y', {
        'authorization': 'Bearer abc',
        'x-tenant': 'globex',
      });
      findMockMatch('GET', 'https://x/other', {
        'authorization': 'Bearer xyz',
        'x-tenant': 'acme',
      });
      expect(mockHeaderRegexCacheSize, 2,
          reason: 'Cache size must stay constant across additional calls '
              '(no re-compilation).');
    });
  });

  group('buildMockResponse', () {
    test('applies delayMs before returning', () async {
      final rule = MockRule.fromJson({
        'id': 'delay-1',
        'match': {'method': 'GET', 'url': '.*'},
        'response': {'status': 200, 'body': '{"ok":true}', 'delayMs': 120},
      });

      final sw = Stopwatch()..start();
      final res = await buildMockResponse(rule, 'req-1');
      sw.stop();

      expect(res.status, 200);
      expect(res.body, '{"ok":true}');
      expect(res.headers, isEmpty);
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(100));
    });

    test('returns immediately when delayMs is 0 or null', () async {
      final ruleNoDelay = MockRule.fromJson({
        'id': 'no-delay',
        'match': {'method': 'GET', 'url': '.*'},
        'response': {'status': 204, 'body': ''},
      });

      final sw = Stopwatch()..start();
      final res = await buildMockResponse(ruleNoDelay, 'req-2');
      sw.stop();

      expect(res.status, 204);
      expect(sw.elapsedMilliseconds, lessThan(50));
    });

    test('exposes response headers from the rule', () async {
      final rule = MockRule.fromJson({
        'id': 'hdr-1',
        'match': {'method': 'GET', 'url': '.*'},
        'response': {
          'status': 200,
          'body': '{}',
          'headers': {'content-type': 'application/json'},
        },
      });

      final res = await buildMockResponse(rule, 'req-3');
      expect(res.headers, {'content-type': 'application/json'});
    });
  });

  group('setMockRules', () {
    test('only keeps enabled rules', () {
      setMockRules([
        MockRule.fromJson({
          'id': 'on-1',
          'enabled': true,
          'match': {'method': 'GET', 'url': r'^/on$'},
          'response': {'status': 200, 'body': '{"on":true}'},
        }),
        MockRule.fromJson({
          'id': 'off-1',
          'enabled': false,
          'match': {'method': 'GET', 'url': r'^/off$'},
          'response': {'status': 200, 'body': '{"off":true}'},
        }),
      ]);

      final onHit = findMockMatch('GET', '/on', null);
      final offHit = findMockMatch('GET', '/off', null);

      expect(onHit, isNotNull);
      expect(offHit, isNull);
    });

    test('replacing rules clears old state', () {
      setMockRules([
        MockRule.fromJson({
          'id': 'first',
          'match': {'method': 'GET', 'url': r'^/first$'},
          'response': {'status': 200, 'body': '{}'},
        }),
      ]);
      expect(findMockMatch('GET', '/first', null), isNotNull);

      setMockRules([
        MockRule.fromJson({
          'id': 'second',
          'match': {'method': 'GET', 'url': r'^/second$'},
          'response': {'status': 200, 'body': '{}'},
        }),
      ]);

      expect(findMockMatch('GET', '/first', null), isNull);
      expect(findMockMatch('GET', '/second', null), isNotNull);
    });
  });

  group('parseRules', () {
    test('skips non-Map entries', () {
      final rules = parseRules([
        <String, dynamic>{
          'id': 'a',
          'match': <String, dynamic>{'method': 'GET', 'url': '.*'},
          'response': <String, dynamic>{},
        },
        'not-a-map',
        42,
        null,
        <String, dynamic>{
          'id': 'b',
          'match': <String, dynamic>{'method': 'GET', 'url': '.*'},
          'response': <String, dynamic>{},
        },
      ]);

      expect(rules.length, 2);
      expect(rules.map((r) => r.id).toSet(), {'a', 'b'});
    });

    test('returns empty list for empty input', () {
      expect(parseRules([]), isEmpty);
    });
  });

  group('MockedHttpResponse.bodyJson', () {
    test('parses JSON body', () {
      const res = MockedHttpResponse(
        status: 200,
        body: '{"a":1,"b":"x"}',
        headers: {},
      );
      expect(res.bodyJson, {'a': 1, 'b': 'x'});
    });

    test('returns null on bad JSON', () {
      const res = MockedHttpResponse(
        status: 200,
        body: 'not-json',
        headers: {},
      );
      expect(res.bodyJson, isNull);
    });

    test('returns null when body is a JSON array (not a map)', () {
      const res = MockedHttpResponse(
        status: 200,
        body: '[1,2,3]',
        headers: {},
      );
      // Implementation forces Map<String, dynamic> via `as` cast, so this throws
      // and is caught → null.
      expect(res.bodyJson, isNull);
    });

    test('returns null for empty body', () {
      const res = MockedHttpResponse(status: 200, body: '', headers: {});
      expect(res.bodyJson, isNull);
    });
  });
}
