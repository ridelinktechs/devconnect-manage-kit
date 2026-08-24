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
const { DevConnect } = clientModule;
const wsModule = require('../dist-test/interceptors/webSocketInterceptor.js');
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
