import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/features/mock_server/presentation/editor/rule_draft.dart';
import 'package:devconnect_manage_tool/models/round/mock_entry.dart';

MockRule _rule({String body = '{"a":1}', Map<String, dynamic>? md}) => MockRule(
  id: 'r',
  name: 'Users',
  method: 'get',
  urlPattern: '/api/users',
  statusCode: 200,
  headers: const {'Content-Type': 'application/json', 'X-A': '1'},
  body: body,
  enabled: true,
  hitCount: 0,
  updatedAt: 0,
  metadata: md,
);

RuleDraft _draft({
  String url = '/api',
  String status = '200',
  String delay = '',
  String headers = '',
  String devices = '',
  String expires = '',
}) => RuleDraft(
  name: ' Users ',
  method: 'POST',
  url: url,
  status: status,
  delay: delay,
  headers: headers,
  body: 'text',
  devices: devices,
  expires: expires,
);

void main() {
  test('a rule shows in the editor with its JSON indented and every box '
      'filled', () {
    final draft = RuleDraft.of(
      _rule(
        md: {
          'delayMs': 300,
          'scope': {
            'deviceIds': ['a', 'b'],
          },
          'expiresAt': '2030-01-01T00:00:00Z',
        },
      ),
    );
    expect(draft.method, 'GET');
    expect(draft.body, '{\n  "a": 1\n}');
    expect(draft.headers, 'Content-Type: application/json\nX-A: 1');
    expect(draft.delay, '300');
    expect(draft.devices, 'a, b');
    expect(draft.expires, '2030-01-01T00:00:00Z');
    expect(RuleDraft.of(_rule(body: 'plain')).body, 'plain');
  });

  test('only the boxes that differ count as changes', () {
    final saved = RuleDraft.of(_rule());
    expect(saved.changesFrom(RuleDraft.of(_rule())), isEmpty);
    expect(_draft().changesFrom(saved), {
      RuleField.name,
      RuleField.method,
      RuleField.url,
      RuleField.headers,
      RuleField.body,
    });
  });

  group('can\'t be saved', () {
    for (final (url, why) in [
      ('', 'Enter a pattern; .* matches every URL'),
      ('   ', 'Enter a pattern; .* matches every URL'),
      ('[', 'Not a valid regex'),
      ('/users/(\\d+', 'Not a valid regex'),
    ]) {
      test('URL pattern "$url"', () {
        expect(_draft(url: url).errorOf(RuleField.url), startsWith(why));
      });
    }
    for (final status in ['', 'abc', '99', '600', '2OO', '20.5']) {
      test('status "$status"', () {
        expect(
          _draft(status: status).errorOf(RuleField.status),
          'Use a status code from 100 to 599',
        );
      });
    }
    for (final delay in ['-1', '1.5', 'soon']) {
      test('delay "$delay"', () {
        expect(
          _draft(delay: delay).errorOf(RuleField.delay),
          'Use whole milliseconds, 0 or more',
        );
      });
    }
    for (final (headers, line) in [
      ('oops', 1),
      ('A: 1\n: 2', 2),
      ('A: 1\n\nB', 3),
    ]) {
      test('headers ${headers.replaceAll('\n', r'\n')}', () {
        expect(
          _draft(headers: headers).errorOf(RuleField.headers),
          'Line $line needs key: value',
        );
      });
    }
    for (final at in [
      'tomorrow',
      '2026-12-31 23:59',
      '2026-12-31',
      '2026-12-31T23:59:59+0700',
      '2026-13-45T99:99:99Z',
      '2026-02-30T10:00:00Z',
      '2026-12-31T24:00:00Z',
      '2026-12-31T23:59:59+25:00',
    ]) {
      test('expiry "$at"', () {
        expect(
          _draft(expires: at).errorOf(RuleField.expires),
          'Use ISO-8601, e.g. 2026-12-31T23:59:59Z',
        );
      });
    }
  });

  test('saves the boxes every SDK can read', () {
    final ok = _draft(
      url: r'/users/\d+$',
      status: ' 100 ',
      delay: '0',
      headers: 'A: 1\n\nB:2 ',
      expires: '2026-12-31T23:59',
    );
    expect(ok.invalid, isEmpty);
    for (final at in [
      '2026-12-31T23:59:59Z',
      '2026-12-31T23:59:59.250+07:00',
      '2026-12-31T23:59:59',
    ]) {
      expect(
        _draft(expires: at).errorOf(RuleField.expires),
        isNull,
        reason: at,
      );
    }
    expect(_draft(status: '599').errorOf(RuleField.status), isNull);
  });

  test('saving trims, parses, and keeps metadata the editor doesn\'t show', () {
    final rule = _rule(
      md: {
        'matchHeaders': {'x-env': 'test'},
        'delayMs': 300,
        'expiresAt': '2030-01-01T00:00:00Z',
      },
    );
    final saved = _draft(
      url: ' /api/orders ',
      status: '503',
      delay: '',
      headers: 'Retry-After: 30\n',
      devices: ' dev , , other ',
    ).applyTo(rule, now: 42);
    expect(saved.id, 'r');
    expect(saved.name, 'Users');
    expect(saved.method, 'POST');
    expect(saved.urlPattern, '/api/orders');
    expect(saved.statusCode, 503);
    expect(saved.headers, {'Retry-After': '30'});
    expect(saved.body, 'text');
    expect(saved.updatedAt, 42);
    expect(saved.metadata, {
      'matchHeaders': {'x-env': 'test'},
      'scope': {
        'deviceIds': ['dev', 'other'],
      },
    });
    expect(
      _draft().applyTo(_rule(md: {'delayMs': 1}), now: 0).metadata,
      isNull,
    );
  });
}
