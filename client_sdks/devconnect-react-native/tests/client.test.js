const test = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');

// Shared so a test can switch Platform.OS.
const rn = { Platform: { OS: 'android', Version: 'test', constants: {} }, NativeModules: {} };
const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === 'react-native') return rn;
  return originalLoad.call(this, request, parent, isMain);
};

// DevConnect builds its own socket from the WebSocket present when client.js loads.
class FakeSocket {
  constructor() { this.sent = []; FakeSocket.last = this; }
  send(json) { this.sent.push(JSON.parse(json)); }
  close() {}
}
global.WebSocket = FakeSocket;

// The state checks of React Native's XMLHttpRequest.
class FakeXHR {
  constructor() { this.UNSENT = 0; this.OPENED = 1; this.readyState = 0; this.sent = false; }
  open(method, url) {
    if (this.readyState !== 0) throw new Error('Cannot open, already sending');
    this.url = url;
    this.readyState = 1;
  }
  send(body) {
    if (this.readyState !== 1) throw new Error('Request has not been opened');
    this.sent = true;
    this.body = body;
  }
  abort() { this.readyState = 0; this.sent = false; } // unsent: just reset, no events
  setRequestHeader() {}
  addEventListener() {}
  removeEventListener() {}
}
global.XMLHttpRequest = FakeXHR;

// The app's console: recorded instead of printed.
const methods = ['log', 'info', 'warn', 'error', 'debug'];
const realConsole = {};
const printed = [];
for (const m of methods) {
  realConsole[m] = console[m];
  console[m] = (...args) => printed.push(args);
}

global.__DEV__ = true;
const { DevConnect } = require('../dist-test/client.js');
const { startErrorMonitor } = require('../dist-test/plugins/errorMonitor.js');

// Queued before init(), which flushes it: JSON can't encode a cycle.
const loop = { name: 'loop' };
loop.self = loop;
DevConnect.safeSend('client:log', { level: 'info', message: 'early cycle', metadata: loop });
DevConnect.safeSend('client:log', { level: 'info', message: 'early' });

let socket;
let initError = null;
test.before(async () => {
  await DevConnect.init({
    appName: 'ClientTest', host: '127.0.0.1', auto: false, enabled: true,
    autoInterceptFetch: false, autoInterceptXHR: true, autoInterceptConsole: true,
    autoPerformance: false, autoMemoryLeak: false, autoBenchmark: false, autoError: true,
  }).catch((e) => { initError = e; });
  socket = FakeSocket.last;
  socket.onopen();
});

test.after(() => {
  DevConnect.disconnect();
  Object.assign(console, realConsole);
  Module._load = originalLoad;
});

/** Delivers a message to DevConnect the way the desktop does. */
const fromDesktop = (type, payload) => socket.onmessage({ data: JSON.stringify({ type, payload }) });
const logged = () => socket.sent.filter((m) => m.type === 'client:log').map((m) => m.payload.message);
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

test('a payload JSON can\'t encode is dropped, never thrown into the app', () => {
  assert.equal(initError, null);
  assert.ok(logged().includes('early'));
  const nullLoop = Object.create(null);
  nullLoop.self = nullLoop;
  assert.doesNotThrow(() => DevConnect.log('cycle', 'tag', loop));
  assert.doesNotThrow(() => DevConnect.warn('bigint', 'tag', { n: 10n }));
  assert.doesNotThrow(() => DevConnect.log(nullLoop)); // no JSON, no toString
  DevConnect.log('next');
  assert.equal(logged().at(-1), 'next');
  assert.ok(!logged().includes('cycle') && !logged().includes('bigint'));
});

test('console calls never throw on a null-prototype object', () => {
  rn.Platform.OS = 'ios';
  startErrorMonitor(); // iOS's crash-pattern wrapper too (init installed Android's)
  const query = Object.assign(Object.create(null), { page: '2' }); // what query-string's parse returns
  const nullLoop = Object.create(null);
  nullLoop.self = nullLoop;
  printed.length = 0;
  for (const m of methods) {
    assert.doesNotThrow(() => console[m](query), `console.${m}`);
    assert.doesNotThrow(() => console[m](nullLoop), `console.${m}`);
  }
  assert.equal(printed.length, 10); // the app's own output still comes out
  assert.ok(logged().includes('{\n  "page": "2"\n}'));
  assert.doesNotThrow(() => console.error('java.lang.IllegalStateException', nullLoop));
  assert.doesNotThrow(() => console.error('*** NSException ***', nullLoop));
});

test('an XHR aborted during the throttle delay is dropped, not a crash', async () => {
  fromDesktop('server:network:throttle', { latencyMs: 20 });
  try {
    const kept = new XMLHttpRequest();
    kept.open('POST', 'https://example.com/slow');
    kept.send('body');
    const aborted = new XMLHttpRequest();
    aborted.open('GET', 'https://example.com/slow');
    aborted.send();
    aborted.abort(); // e.g. an AbortController on unmount
    assert.equal(kept.sent, false);
    await sleep(50); // a throw from the delayed send fails this test
    assert.equal(kept.body, 'body');
    assert.equal(aborted.sent, false);
  } finally {
    fromDesktop('server:network:throttle', {});
  }
});

test('offline throttle fails the XHR like a dead network instead of throwing', () => {
  fromDesktop('server:network:throttle', { offline: true });
  try {
    const xhr = new XMLHttpRequest();
    xhr.open('GET', 'https://example.com/items');
    assert.doesNotThrow(() => xhr.send());
    assert.equal(xhr.url, 'http://127.0.0.1:9'); // refused right away
    const start = socket.sent.findLast((m) => m.type === 'client:network:request_start');
    assert.equal(start.payload.url, 'https://example.com/items');
  } finally {
    fromDesktop('server:network:throttle', {});
  }
});
