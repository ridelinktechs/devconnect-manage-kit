const test = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');

const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === 'react-native') return { Platform: { OS: 'ios', Version: 'test', constants: {} }, NativeModules: {} };
  return originalLoad.call(this, request, parent, isMain);
};
test.after(() => { Module._load = originalLoad; });

const { DevConnect } = require('../dist-test/client.js');
const { devConnectReduxMiddleware } = require('../dist-test/interceptors/state/reduxMiddleware.js');
const { devConnectMiddleware } = require('../dist-test/interceptors/state/zustandMiddleware.js');
const { watchValtio } = require('../dist-test/interceptors/state/valtioPlugin.js');
const { devConnectAtomEffect, watchAtom } = require('../dist-test/interceptors/state/jotaiPlugin.js');
const { devConnectXStateInspector } = require('../dist-test/interceptors/state/xstatePlugin.js');

let connected = true;
DevConnect.isListening = () => connected;
let reports = [];
DevConnect.safeSend = (type, payload) => reports.push(payload);

/** A state value that counts how often it gets serialized. */
function counted() {
  const value = { serialized: 0, toJSON: () => { value.serialized++; return 'counted'; } };
  return value;
}

/** Counts JSON.stringify calls made by `fn`. */
function countEncodes(fn) {
  const stringify = JSON.stringify;
  let encodes = 0;
  JSON.stringify = function (...args) { encodes++; return stringify.apply(this, args); };
  try {
    fn();
  } finally {
    JSON.stringify = stringify;
  }
  return encodes;
}

const nest = (depth, leaf) => (depth === 0 ? leaf : { a: nest(depth - 1, leaf) });
const wide = (value) => Object.fromEntries(Array.from({ length: 100 }, (_, i) => [`k${i}`, { value }]));

function assertBounded(diff) {
  assert.ok(diff.length <= 50, `${diff.length} diff entries`);
  assert.ok(diff.every((d) => d.path.split('.').length <= 12), 'diff depth');
}

test('redux: nothing is serialized while disconnected; the previous state is reused', () => {
  const meta = counted();
  let state = { n: 0, meta };
  const dispatch = devConnectReduxMiddleware({ getState: () => state })((action) => {
    state = { ...state, n: state.n + 1 };
    return action;
  });
  reports = [];
  connected = false;
  dispatch({ type: 'inc' });
  assert.equal(meta.serialized, 0);
  connected = true;
  dispatch({ type: 'inc' });
  dispatch({ type: 'inc' });
  assert.equal(meta.serialized, 3);
  assert.deepEqual(reports.map((r) => [r.previousState.n, r.nextState.n]), [[1, 2], [2, 3]]);
});

test('redux: the diff is bounded in depth and size', () => {
  let state = { deep: nest(100, 1), wide: wide(1) };
  const dispatch = devConnectReduxMiddleware({ getState: () => state })((action) => {
    state = { deep: nest(100, 2), wide: wide(2) };
    return action;
  });
  reports = [];
  dispatch({ type: 'replace' });
  assertBounded(reports[0].diff);
});

test('zustand: nothing is serialized while disconnected; the previous state is reused', () => {
  const meta = counted();
  let state;
  const set = (partial) => { state = { ...state, ...(typeof partial === 'function' ? partial(state) : partial) }; };
  state = devConnectMiddleware((trackedSet) => ({
    n: 0,
    meta,
    inc: () => trackedSet((s) => ({ n: s.n + 1 })),
    replaceAll: () => trackedSet({ deep: nest(100, 2), wide: wide(2) }),
  }), 'Counter')(set, () => state, {});
  reports = [];
  connected = false;
  state.inc();
  assert.equal(meta.serialized, 0);
  connected = true;
  state.inc();
  state.inc();
  assert.equal(meta.serialized, 3);
  assert.deepEqual(reports.map((r) => [r.previousState.n, r.nextState.n]), [[1, 2], [2, 3]]);

  set({ deep: nest(100, 1), wide: wide(1) });
  state.replaceAll();
  assertBounded(reports.at(-1).diff);
});

test('valtio: nothing is serialized while disconnected', () => {
  const meta = counted();
  const state = { n: 0, meta };
  let notify;
  watchValtio(state, 'App', { subscribe: (_proxy, callback) => { notify = callback; return () => {}; } });
  assert.equal(meta.serialized, 1);
  connected = false;
  state.n = 1;
  notify([['set', ['n'], 1, 0]]);
  assert.equal(meta.serialized, 1);
  connected = true;
  reports = [];
  state.n = 2;
  notify([['set', ['n'], 2, 1]]);
  assert.equal(meta.serialized, 2);
  assert.deepEqual(reports[0].diff, [{ path: 'n', operation: 'replace', oldValue: 1, newValue: 2 }]);
});

test('jotai: one JSON encoding per atom read, none while disconnected', () => {
  let value = { n: 0 };
  const get = () => value;
  const effect = devConnectAtomEffect({ debugLabel: 'count' });
  reports = [];
  connected = false;
  assert.equal(countEncodes(() => effect.read(get)), 0);
  connected = true;
  effect.read(get);
  value = { n: 1 };
  assert.equal(countEncodes(() => effect.read(get)), 1);
  value = { n: 1 };
  assert.equal(countEncodes(() => effect.read(get)), 1);
  assert.deepEqual(reports.map((r) => r.action), ['atom:count initialized', 'atom:count changed']);
  assert.deepEqual(reports[1].diff, [{ path: 'count', operation: 'replace', oldValue: { n: 0 }, newValue: { n: 1 } }]);

  let atomValue = 0;
  let notify;
  watchAtom({ get: () => atomValue, sub: (_atom, callback) => { notify = callback; return () => {}; } }, {}, 'watched');
  connected = false;
  atomValue = 1;
  assert.equal(countEncodes(() => notify()), 0);
  connected = true;
});

test('xstate: nothing is serialized while disconnected; the context diff needs no JSON compare and is bounded', () => {
  const inspect = devConnectXStateInspector('Machine');
  reports = [];
  connected = false;
  assert.equal(countEncodes(() => inspect({ value: 'idle', context: { n: 0 } }, { type: 'INIT' })), 0);
  connected = true;
  inspect({ value: 'idle', context: { n: 0, list: [1] } }, { type: 'A' });
  assert.equal(reports[0].action, 'A (idle -> idle)');
  assert.ok(countEncodes(() => inspect({ value: 'busy', context: { n: 1, list: [1] } }, { type: 'B' })) <= 3);
  assert.deepEqual(reports[1].diff, [
    { path: 'state', operation: 'replace', oldValue: 'idle', newValue: 'busy' },
    { path: 'context.n', operation: 'replace', oldValue: 0, newValue: 1 },
  ]);

  inspect({ value: 'busy', context: { deep: nest(100, 1), wide: wide(1) } }, { type: 'C' });
  inspect({ value: 'busy', context: { deep: nest(100, 2), wide: wide(2) } }, { type: 'D' });
  assertBounded(reports.at(-1).diff);
});
