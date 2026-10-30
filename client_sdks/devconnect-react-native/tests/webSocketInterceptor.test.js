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

// DevConnect captures the WebSocket present when client.js loads; record what it builds.
class NativeWebSocket {
  constructor(url) { this.url = url; this.sent = []; NativeWebSocket.built.push(this); }
  send(data) { this.sent.push(data); }
  close() {}
}
NativeWebSocket.built = [];
global.WebSocket = NativeWebSocket;

const clientModule = require('../dist-test/client.js');
const { DevConnect } = clientModule;
const wsModule = require('../dist-test/interceptors/network/webSocketInterceptor.js');
const { installWebSocketInterceptor } = wsModule;

test.after(() => { Module._load = originalLoad; });

function makeFakeInner() {
  // Minimal WebSocket-shaped object so we can drive the wrapper.
  const handlers = {};
  let ready = 0; // CONNECTING
  const inner = {
    url: '',
    readyState: 0,
    bufferedAmount: 0,
    extensions: '',
    protocol: '',
    binaryType: 'blob',
    onopen: null, onmessage: null, onerror: null, onclose: null,
    send(data) { this._lastSent = data; },
    close(code, reason) {
      this._lastClose = { code, reason };
      ready = 3;
      this.readyState = ready;
      this.onclose?.({ code: code ?? 1000, reason: reason ?? '' });
    },
    addEventListener(t, h) { handlers[t] = (handlers[t] || []).concat(h); },
    removeEventListener(t, h) { handlers[t] = (handlers[t] || []).filter(x => x !== h); },
    dispatchEvent() { return true; },
    _fireOpen() { ready = 1; this.readyState = 1; this.onopen?.({}); },
    _fireMessage(d) { this.onmessage?.({ data: d }); },
    _fireError() { this.onerror?.({ message: 'boom' }); },
  };
  return inner;
}

function installFakeWebSocket(inner) {
  // Make the wrapper use our inner by injecting the Original constructor
  // into the closure: we set global.WebSocket to a class that, when
  // instantiated, returns our inner.
  class FakeOriginal {
    constructor(url, protocols) {
      inner.url = url;
      inner.protocol = protocols?.[0] ?? '';
      return inner;
    }
  }
  global.WebSocket = FakeOriginal;
}

test('installWebSocketInterceptor emits ws_open when inner opens', () => {
  const events = [];
  DevConnect.safeSend = (type, payload) => events.push({ type, payload });
  const inner = makeFakeInner();
  installFakeWebSocket(inner);
  const uninstall = installWebSocketInterceptor();
  const w = new global.WebSocket('ws://example.com');
  inner._fireOpen();
  assert.ok(events.some(e => e.type === 'client:ws_open'));
  uninstall();
});

test('wrapper delegates readyState/bufferedAmount/extensions/protocol/binaryType to inner', () => {
  const inner = makeFakeInner();
  installFakeWebSocket(inner);
  const uninstall = installWebSocketInterceptor();
  const w = new global.WebSocket('ws://example.com');
  inner.readyState = 1;
  inner.bufferedAmount = 1234;
  inner.extensions = 'permessage-deflate';
  inner.protocol = 'chat';
  inner.binaryType = 'arraybuffer';
  assert.equal(w.readyState, 1);
  assert.equal(w.bufferedAmount, 1234);
  assert.equal(w.extensions, 'permessage-deflate');
  assert.equal(w.protocol, 'chat');
  assert.equal(w.binaryType, 'arraybuffer');
  w.binaryType = 'blob';
  assert.equal(inner.binaryType, 'blob');
  uninstall();
});

test('close emits ws_close only once (not on close() + native onclose)', () => {
  const events = [];
  DevConnect.safeSend = (type, payload) => events.push({ type, payload });
  const inner = makeFakeInner();
  installFakeWebSocket(inner);
  const uninstall = installWebSocketInterceptor();
  const w = new global.WebSocket('ws://example.com');
  w.close(1000, 'bye');
  // Inner close triggers native onclose which we also forward. Total:
  // The wrapper itself should NOT double-emit. Native onclose fires once
  // -> one ws_close event.
  const closeEvents = events.filter(e => e.type === 'client:ws_close');
  assert.equal(closeEvents.length, 1);
  uninstall();
});

test('cleanup restores only if global.WebSocket is still the wrapper', () => {
  const inner = makeFakeInner();
  installFakeWebSocket(inner);
  const uninstall = installWebSocketInterceptor();
  const wrapperRef = global.WebSocket;
  // Simulate a later install replacing global.WebSocket.
  global.WebSocket = function Newer() {};
  uninstall();
  // Newer install should not have been touched.
  assert.notEqual(global.WebSocket, wrapperRef);
  // Restore for cleanliness.
  global.WebSocket = wrapperRef;
  uninstall();
});

test('passes every constructor argument through and exposes the readyState constants', () => {
  let args;
  global.WebSocket = class { constructor(...a) { args = a; return makeFakeInner(); } };
  const uninstall = installWebSocketInterceptor();
  const options = { headers: { Authorization: 'Bearer x' } }; // RN's third argument
  const w = new global.WebSocket('ws://example.com', ['chat'], options);
  assert.deepEqual(args, ['ws://example.com', ['chat'], options]);
  for (const [name, value] of Object.entries({ CONNECTING: 0, OPEN: 1, CLOSING: 2, CLOSED: 3 })) {
    assert.equal(global.WebSocket[name], value);
    assert.equal(w[name], value);
  }
  uninstall();
});

test('one connectionId per socket, text and binary frames, an error folded into the single close', () => {
  const events = [];
  DevConnect.safeSend = (type, payload) => events.push({ type, payload });
  const inner = makeFakeInner();
  installFakeWebSocket(inner);
  const uninstall = installWebSocketInterceptor();
  const w = new global.WebSocket('ws://example.com');
  inner._fireOpen();
  w.send('é€😀'); // 2 + 3 + 4 UTF-8 bytes
  inner._fireMessage(new ArrayBuffer(4));
  inner._fireError();
  inner.onclose({ code: 1006, reason: '' });

  assert.deepEqual(events.map((e) => e.type), ['client:ws_open', 'client:ws_frame', 'client:ws_frame', 'client:ws_close']);
  const [open, sent, received, close] = events.map((e) => e.payload);
  const { connectionId } = open;
  assert.ok(connectionId);
  assert.deepEqual(open, { connectionId, url: 'ws://example.com' });
  assert.deepEqual(sent, { connectionId, url: 'ws://example.com', direction: 'send', opcode: 'text', payload: 'é€😀', sizeBytes: 9 });
  assert.deepEqual(received, { connectionId, url: 'ws://example.com', direction: 'receive', opcode: 'binary', payload: '<binary 4 bytes>', sizeBytes: 4 });
  assert.equal(close.connectionId, connectionId);
  assert.equal(close.code, 1006);
  assert.equal(close.error, 'boom');
  uninstall();
});

test('a report that goes out through a wrapped socket is not reported again', () => {
  const events = [];
  const inner = makeFakeInner();
  installFakeWebSocket(inner);
  const uninstall = installWebSocketInterceptor();
  const w = new global.WebSocket('ws://example.com');
  // Worst case: DevConnect's own socket wrapped, so every report is itself a send.
  DevConnect.safeSend = (type, payload) => { events.push({ type, payload }); w.send(JSON.stringify(payload)); };
  w.send('hello');
  assert.equal(events.length, 1);
  assert.equal(inner._lastSent, 'hello');
  uninstall();
});

test("DevConnect's own socket is built with the native constructor, never the wrapper", async () => {
  const events = [];
  DevConnect.safeSend = (type, payload) => events.push({ type, payload });
  const inner = makeFakeInner();
  installFakeWebSocket(inner);
  const uninstall = installWebSocketInterceptor();
  await DevConnect.init({
    appName: 'WsTest', host: '127.0.0.1', auto: false, enabled: true,
    autoInterceptFetch: false, autoInterceptXHR: false, autoInterceptConsole: false,
    autoPerformance: false, autoMemoryLeak: false, autoBenchmark: false, autoError: false,
  });
  assert.equal(NativeWebSocket.built.length, 1);
  const own = NativeWebSocket.built[0];
  own.onopen();
  DevConnect.getInstance().send('client:log', { message: 'hi' });
  assert.equal(own.sent.length, 1);
  assert.equal(events.length, 0); // nothing was reported as a ws frame
  DevConnect.disconnect();
  uninstall();
});
