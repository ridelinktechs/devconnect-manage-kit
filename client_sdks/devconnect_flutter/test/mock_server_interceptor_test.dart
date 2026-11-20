import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect_manage_kit/devconnect_manage_kit.dart';
import 'package:devconnect_manage_kit/src/interceptors/network/mock_server_interceptor.dart';

/// Payloads of the queued (pre-init) messages of [type].
List<Map<String, dynamic>> _sent(String type) => [
      for (final m in DevConnectClient.queuedMessages)
        if (m['type'] == type) m['payload'] as Map<String, dynamic>,
    ];

/// The bits of Dio's RequestOptions the interceptor reads.
class _DioOptions {
  _DioOptions(this.method, String url) : uri = Uri.parse(url);
  final String method;
  final Uri uri;
  final Map<String, dynamic> headers = {};
  final Object? data = null;
  final Map<String, dynamic> extra = {};
}

/// Records how Dio's RequestInterceptorHandler was completed.
class _DioHandler {
  final done = Completer<Object>();
  bool? callFollowing;
  void next(Object options) => done.complete(options);
  void resolve(Object response, [bool callFollowingResponseInterceptor = false]) {
    callFollowing = callFollowingResponseInterceptor;
    done.complete(response);
  }
}

/// Stands in for Dio's `Response.new` (same named parameters).
class _DioResponse {
  _DioResponse({required this.requestOptions, this.statusCode, this.data});
  final Object requestOptions;
  final int? statusCode;
  final Object? data;
  final headers = _DioHeaders();
}

class _DioHeaders {
  final map = <String, List<String>>{};
  void set(String name, dynamic value) => map[name] = ['$value'];
}

void main() {
  // Reset global rule store between tests so they don't bleed.
  setUp(() {
    setMockRules(const []);
    DevConnectClient.queuedMessages.clear();
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
      // A missing header never matches.
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
      final res = await buildMockResponse(rule,
          method: 'GET', url: 'https://x/y', requestId: 'req-1');
      sw.stop();

      expect(res.status, 200);
      expect(res.body, '{"ok":true}');
      expect(res.headers, isEmpty);
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(100));
      expect(_sent('client:mocked_request').single, {
        'ruleId': 'delay-1',
        'url': 'https://x/y',
        'method': 'GET',
        'status': 200,
        'requestId': 'req-1',
      });
    });

    test('returns immediately when delayMs is 0 or null', () async {
      final ruleNoDelay = MockRule.fromJson({
        'id': 'no-delay',
        'match': {'method': 'GET', 'url': '.*'},
        'response': {'status': 204, 'body': ''},
      });

      final sw = Stopwatch()..start();
      final res = await buildMockResponse(ruleNoDelay,
          method: 'GET', url: 'https://x/y', requestId: 'req-2');
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

      final res = await buildMockResponse(rule,
          method: 'GET', url: 'https://x/y', requestId: 'req-3');
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

  group('rule lifecycle', () {
    Map<String, dynamic> rule(String id, String url,
            [Map<String, dynamic> extra = const {}]) =>
        {
          'id': id,
          'match': {'method': 'GET', 'url': url},
          'response': <String, dynamic>{},
          ...extra,
        };

    test('skips expired rules; a future or unparseable expiresAt still matches',
        () {
      final now = DateTime.now();
      setMockRules(parseRules([
        rule('old', '/old', {
          'expiresAt': now.subtract(const Duration(minutes: 1)).toUtc().toIso8601String(),
        }),
        rule('new', '/new', {
          'expiresAt': now.add(const Duration(hours: 1)).toUtc().toIso8601String(),
        }),
        rule('garbled', '/garbled', {'expiresAt': 'next tuesday'}),
      ]));

      expect(findMockMatch('GET', 'https://x/old', null), isNull);
      expect(findMockMatch('GET', 'https://x/new', null)?.id, 'new');
      expect(findMockMatch('GET', 'https://x/garbled', null)?.id, 'garbled');
    });

    test('a rule with header matchers never matches a request without them',
        () {
      setMockRules(parseRules([
        {
          'id': 'h3',
          'match': {
            'method': 'GET',
            'url': '.*',
            'headers': {'X-Debug': '.*'},
          },
          'response': <String, dynamic>{},
        },
      ]));

      expect(findMockMatch('GET', 'https://x/y', null), isNull);
      expect(findMockMatch('GET', 'https://x/y', {'accept': '*/*'}), isNull);
      expect(findMockMatch('GET', 'https://x/y', {'x-debug': ''})?.id, 'h3');
    });

    test('scope.deviceIds limits a rule to the listed devices', () {
      setMockRules(parseRules([
        rule('scoped', '/a', {
          'scope': {'deviceIds': ['dev-a']},
        }),
        rule('everyone', '/b', {
          'scope': {'deviceIds': <String>[]},
        }),
      ]));

      expect(findMockMatch('GET', '/a', null, deviceId: 'dev-a')?.id, 'scoped');
      expect(findMockMatch('GET', '/a', null, deviceId: 'dev-b'), isNull);
      expect(findMockMatch('GET', '/a', null), isNull,
          reason: 'device id unknown before init');
      expect(findMockMatch('GET', '/b', null, deviceId: 'dev-b')?.id, 'everyone');
    });

    test('each push replaces the whole list; an empty push clears it', () {
      applyMockRulesUpdate({
        'rules': [rule('a', '/a'), rule('b', '/b')],
      });
      expect(findMockMatch('GET', '/a', null)?.id, 'a');

      // Toggle: the desktop re-sends the full list with `enabled` flags;
      // a malformed entry is skipped without dropping the update.
      applyMockRulesUpdate({
        'rules': [
          rule('a', '/a', {'enabled': false}),
          rule('b', '/b'),
          {'id': 'malformed'},
        ],
      });
      expect(findMockMatch('GET', '/a', null), isNull);
      expect(findMockMatch('GET', '/b', null)?.id, 'b');

      applyMockRulesUpdate({'rules': <dynamic>[]});
      expect(findMockMatch('GET', '/b', null), isNull);
    });
  });

  group('interceptors', () {
    test('a pushed rule makes the Dio interceptor resolve a mocked response',
        () async {
      applyMockRulesUpdate({
        'rules': [
          {
            'id': 'dio-1',
            'name': 'User 7',
            'enabled': true,
            'match': {'method': 'GET', 'url': r'/users/\d+'},
            'response': {
              'status': 201,
              'body': '{"id":7}',
              'headers': {'x-mock': 'yes'},
              'delayMs': 20,
            },
          },
        ],
      });
      final options = _DioOptions('GET', 'https://api.x.dev/users/7');
      final handler = _DioHandler();

      DevConnectDioInterceptor(responseFactory: _DioResponse.new)
          .onRequest(options, handler);
      final response = await handler.done.future as _DioResponse;

      expect(response.requestOptions, same(options));
      expect(response.statusCode, 201);
      expect(response.data, {'id': 7});
      expect(response.headers.map, {
        'x-mock': ['yes'],
      });
      expect(handler.callFollowing, isTrue,
          reason: 'response interceptors must still report the response');
      expect(_sent('client:mocked_request').single, {
        'ruleId': 'dio-1',
        'url': 'https://api.x.dev/users/7',
        'method': 'GET',
        'status': 201,
        'requestId': options.extra['_dc_request_id'],
      });
    });

    test('a Dio request without a matching rule goes to the network',
        () async {
      setMockRules(parseRules([
        {
          'id': 'post-only',
          'match': {'method': 'POST', 'url': '.*'},
          'response': <String, dynamic>{},
        },
      ]));
      final options = _DioOptions('GET', 'https://api.x.dev/users/7');
      final handler = _DioHandler();

      DevConnectDioInterceptor(responseFactory: _DioResponse.new)
          .onRequest(options, handler);

      expect(await handler.done.future, same(options));
      expect(_sent('client:mocked_request'), isEmpty);
    });

    test('HttpOverrides answers a matching request without reaching the server',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var hits = 0;
      server.listen((request) {
        hits++;
        request.response.close();
      });
      setMockRules(parseRules([
        {
          'id': 'io-1',
          'match': {'method': 'GET', 'url': '/mocked'},
          'response': {
            'status': 503,
            'body': '{"down":true}',
            'headers': {'Content-Type': 'application/json'},
          },
        },
        {
          'id': 'io-post',
          'match': {'method': 'POST', 'url': '/orders'},
          'response': {'status': 201, 'body': 'created'},
        },
      ]));

      await HttpOverrides.runWithHttpOverrides(() async {
        final client = HttpClient();
        final base = 'http://127.0.0.1:${server.port}';
        final mocked =
            await (await client.getUrl(Uri.parse('$base/mocked'))).close();
        expect(mocked.statusCode, 503);
        expect(mocked.headers.contentType?.mimeType, 'application/json');
        expect(await utf8.decodeStream(mocked), '{"down":true}');

        // A body write sends the headers: the mock must be decided before.
        final post = await client.postUrl(Uri.parse('$base/orders'));
        post.write('{"item":1}');
        await post.flush();
        final created = await post.close();
        expect(created.statusCode, 201);
        expect(await utf8.decodeStream(created), 'created');

        final real = await (await client.getUrl(Uri.parse('$base/real'))).close();
        expect(real.statusCode, 200);
        await real.drain<void>();
        client.close();
      }, DevConnectHttpOverrides());

      expect(hits, 1, reason: 'only the unmocked request reaches the server');
      expect(_sent('client:mocked_request').map((p) => p['ruleId']),
          ['io-1', 'io-post']);
    });
  });
}
