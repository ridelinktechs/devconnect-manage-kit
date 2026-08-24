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
const rqModule = require('../dist-test/integrations/reactQuery.js');
const { setupReactQueryDevConnect } = rqModule;

test.after(() => { Module._load = originalLoad; });

test('setupReactQueryDevConnect no-ops when queryClient.getQueryCache is missing', () => {
  const stop = setupReactQueryDevConnect({}, {});
  assert.equal(typeof stop, 'function');
});

test('setupReactQueryDevConnect no-ops when queryCache.subscribe is missing', () => {
  const cache = { getAll: () => [] }; // no subscribe
  const stop = setupReactQueryDevConnect({ getQueryCache: () => cache }, {});
  assert.equal(typeof stop, 'function');
});

test('subscribe is called when present', () => {
  let subscribed = false;
  const cache = {
    subscribe: (cb) => { subscribed = true; return () => {}; },
    getAll: () => [],
  };
  const stop = setupReactQueryDevConnect({ getQueryCache: () => cache }, { emitInitialSnapshot: false });
  assert.equal(subscribed, true);
  stop();
});

test('subscribe callback emits state:change with a deterministic key for object keys', () => {
  const events = [];
  DevConnect.reportStateChange = (e) => events.push(e);
  DevConnect.safeSend = () => {};

  const cache = {
    subscribe: (cb) => {
      // Fire one synthetic event with an object-element key.
      cb({ type: 'updated', query: { queryKey: [{ id: 1 }, { id: 2 }], state: { fetchStatus: 'idle' } } });
      return () => {};
    },
    getAll: () => [],
  };
  const stop = setupReactQueryDevConnect({ getQueryCache: () => cache }, {
    emitInitialSnapshot: false,
    throttleMs: 0,
  });
  assert.ok(events.length >= 1);
  // The key must include the actual object contents, not "[object Object]".
  const sm = events[0].stateManager;
  assert.doesNotMatch(sm, /\[object Object\]/);
  stop();
});

test('subscribe handles queryKey as primitive (string) and array', () => {
  const events = [];
  DevConnect.reportStateChange = (e) => events.push(e);
  DevConnect.safeSend = () => {};

  const seen = new Set();
  const cache = {
    subscribe: (cb) => {
      cb({ type: 'updated', query: { queryKey: 'simple', state: { fetchStatus: 'idle' } } });
      cb({ type: 'updated', query: { queryKey: ['a', 1, true], state: { fetchStatus: 'idle' } } });
      return () => {};
    },
    getAll: () => [],
  };
  const stop = setupReactQueryDevConnect({ getQueryCache: () => cache }, {
    emitInitialSnapshot: false,
    throttleMs: 0,
  });
  for (const e of events) seen.add(e.stateManager);
  // Two distinct stateManagers — primitive and array shouldn't collide.
  assert.ok(seen.size >= 2);
  stop();
});
