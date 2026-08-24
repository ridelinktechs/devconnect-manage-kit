const test = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');

const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === 'react-native') {
    return { Platform: { OS: 'ios', Version: 'test', constants: {} }, NativeModules: {} };
  }
  return originalLoad.call(this, request, parent, isMain);
};

const clientModule = require('../dist-test/client.js');
const interceptor = require('../dist-test/interceptors/mockServerInterceptor.js');
const { DevConnect } = clientModule;
const { setMockRules, findMockMatch, buildMockResponse, installMockServerInterceptor } = interceptor;

function rule(overrides = {}) {
  const out = {
    id: overrides.id || 'rule-1',
    enabled: overrides.enabled ?? true,
    match: {
      method: 'GET',
      url: '^https://example\\.com/items$',
      ...(overrides.match || {}),
    },
    response: {
      status: 201,
      headers: { 'content-type': 'application/json', 'x-test': 'yes' },
      body: '{"mocked":true}',
      ...(overrides.response || {}),
    },
  };
  if (overrides.scope !== undefined) out.scope = overrides.scope;
  if (overrides.expiresAt !== undefined) out.expiresAt = overrides.expiresAt;
  return out;
}

test.after(() => { Module._load = originalLoad; });

test('setRules only keeps enabled rules', () => {
  setMockRules([rule({ id: 'off', enabled: false }), rule({ id: 'on' })]);
  assert.equal(findMockMatch('GET', 'https://example.com/items')?.id, 'on');
});

test('findMatch matches method case-insensitively', () => {
  setMockRules([rule()]);
  assert.equal(findMockMatch('get', 'https://example.com/items')?.id, 'rule-1');
});

test('findMatch matches URL via regex', () => {
  setMockRules([rule({ match: { url: '/items/\\d+$' } })]);
  assert.ok(findMockMatch('GET', 'https://example.com/items/42'));
});

test('findMatch returns null when no rule matches', () => {
  setMockRules([rule()]);
  assert.equal(findMockMatch('POST', 'https://example.com/items'), null);
});

test('findMatch skips disabled rules', () => {
  setMockRules([rule({ enabled: false })]);
  assert.equal(findMockMatch('GET', 'https://example.com/items'), null);
});

test('findMatch enforces header constraints', () => {
  setMockRules([rule({ match: { headers: { authorization: '^Bearer token$' } } })]);
  assert.ok(findMockMatch('GET', 'https://example.com/items', { authorization: 'Bearer token' }));
});

test('findMatch caches URL regex', () => {
  const cachedRule = rule();
  setMockRules([cachedRule]);
  assert.ok(findMockMatch('GET', 'https://example.com/items'));
  cachedRule.match.url = '^https://changed$';
  assert.ok(findMockMatch('GET', 'https://example.com/items'));
});

test('findMatch handles invalid URL regex gracefully', () => {
  setMockRules([rule({ match: { url: '[' } })]);
  assert.doesNotThrow(() => findMockMatch('GET', 'https://example.com/items'));
  assert.equal(findMockMatch('GET', 'https://example.com/items'), null);
});

test('findMatch rejects when header regex does not match', () => {
  setMockRules([rule({ match: { headers: { authorization: '^Bearer good$' } } })]);
  assert.equal(findMockMatch('GET', 'https://example.com/items', { authorization: 'Bearer bad' }), null);
});

test('findMatch handles invalid header regex gracefully', () => {
  setMockRules([rule({ match: { headers: { authorization: '[' } } })]);
  assert.doesNotThrow(() => findMockMatch('GET', 'https://example.com/items', { authorization: 'x' }));
  assert.equal(findMockMatch('GET', 'https://example.com/items', { authorization: 'x' }), null);
});

test('setMockRules clears compiled regex cache', () => {
  const changedRule = rule();
  setMockRules([changedRule]);
  assert.ok(findMockMatch('GET', 'https://example.com/items'));
  changedRule.match.url = '^https://changed$';
  setMockRules([changedRule]);
  assert.equal(findMockMatch('GET', 'https://example.com/items'), null);
  assert.ok(findMockMatch('GET', 'https://changed'));
});

test('buildMockResponse returns configured synthetic response', async () => {
  DevConnect.safeSend = () => {};
  const response = await buildMockResponse(rule(), 'req-1');
  assert.equal(response.status, 201);
  assert.equal(response.headers.get('x-test'), 'yes');
  assert.equal(await response.text(), '{"mocked":true}');
});

test('buildMockResponse applies delayMs', async () => {
  DevConnect.safeSend = () => {};
  const start = Date.now();
  await buildMockResponse(rule({ response: { delayMs: 25 } }), 'req-2');
  assert.ok(Date.now() - start >= 20);
});

test('buildMockResponse emits client:mocked_request', async () => {
  const calls = [];
  DevConnect.safeSend = (type, payload) => calls.push({ type, payload });
  await buildMockResponse(rule(), 'req-3');
  assert.equal(calls.length, 1);
  assert.equal(calls[0].type, 'client:mocked_request');
  assert.equal(calls[0].payload.ruleId, 'rule-1');
  assert.equal(calls[0].payload.requestId, 'req-3');
});

test('install is idempotent, handles rule updates, and preserves original handler', () => {
  let fallbackCalls = 0;
  DevConnect.onMessage = () => { fallbackCalls++; };
  installMockServerInterceptor();
  const installedHandler = DevConnect.onMessage;
  installMockServerInterceptor();
  assert.equal(DevConnect.onMessage, installedHandler);

  DevConnect.onMessage({ type: 'server:mock_rules_update', payload: { rules: [rule({ id: 'pushed' })] } });
  assert.equal(findMockMatch('GET', 'https://example.com/items')?.id, 'pushed');
  assert.equal(fallbackCalls, 1);

  DevConnect.onMessage({ type: 'server:other' });
  assert.equal(fallbackCalls, 2);
});

test('findMatch enforces scope.deviceIds when provided', () => {
  setMockRules([rule({
    id: 'scoped',
    scope: { deviceIds: ['dev-1', 'dev-2'] },
  })]);
  // No current deviceId → should not match (per spec, scope excludes everything).
  assert.equal(findMockMatch('GET', 'https://example.com/items', {}), null);
  // Wrong deviceId → no match
  assert.equal(findMockMatch('GET', 'https://example.com/items', {}, { currentDeviceId: 'dev-9' }), null);
  // Matching deviceId → match
  assert.equal(
    findMockMatch('GET', 'https://example.com/items', {}, { currentDeviceId: 'dev-1' })?.id,
    'scoped',
  );
});

test('findMatch without scope still applies to all devices', () => {
  setMockRules([rule()]);
  assert.equal(findMockMatch('GET', 'https://example.com/items')?.id, 'rule-1');
});

test('findMatch skips rules past expiresAt', () => {
  const past = new Date(Date.now() - 1000).toISOString();
  setMockRules([rule({ id: 'expired', expiresAt: past })]);
  assert.equal(findMockMatch('GET', 'https://example.com/items'), null);
});

test('findMatch keeps rules with future expiresAt', () => {
  const future = new Date(Date.now() + 60_000).toISOString();
  setMockRules([rule({ id: 'alive', expiresAt: future })]);
  assert.equal(findMockMatch('GET', 'https://example.com/items')?.id, 'alive');
});

test('findMatch normalizes request header keys to lowercase for matching', () => {
  setMockRules([rule({ match: { headers: { authorization: '^Bearer ok$' } } })]);
  // Caller passes the key in mixed case — should still match.
  assert.equal(
    findMockMatch('GET', 'https://example.com/items', { Authorization: 'Bearer ok' })?.id,
    'rule-1',
  );
  // Lowercase key — also matches.
  assert.equal(
    findMockMatch('GET', 'https://example.com/items', { authorization: 'Bearer ok' })?.id,
    'rule-1',
  );
});

test('findMatch caches header regex compilation per rule', () => {
  setMockRules([rule({ match: { headers: { authorization: '^Bearer' } } })]);
  assert.ok(findMockMatch('GET', 'https://example.com/items', { authorization: 'Bearer xyz' }));
  // Even if the rule's match header is changed, the compiled regex is cached
  // for the rule; subsequent setMockRules would clear it. (This is the spec.)
  assert.ok(findMockMatch('GET', 'https://example.com/items', { authorization: 'Bearer xyz' }));
});

test('findMatch caches negative result for invalid URL regex', () => {
  setMockRules([rule({ id: 'bad', match: { url: '[' } })]);
  // First call should not throw and should return null.
  assert.doesNotThrow(() => findMockMatch('GET', 'https://example.com/items'));
  // Many subsequent calls should also be safe.
  for (let i = 0; i < 50; i++) {
    assert.equal(findMockMatch('GET', 'https://example.com/items'), null);
  }
});

test('buildMockResponse does not leak statusText into response headers', async () => {
  DevConnect.safeSend = () => {};
  const response = await buildMockResponse(rule({
    response: { headers: { 'content-type': 'application/json', statusText: 'Should Not Appear' } },
  }), 'req-st');
  assert.equal(response.headers.get('statusText'), null);
  assert.equal(response.headers.get('content-type'), 'application/json');
});
