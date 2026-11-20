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

class FakeSocket {
  constructor() { this.sent = []; FakeSocket.last = this; }
  send(json) { this.sent.push(JSON.parse(json)); }
  close() {}
}
global.WebSocket = FakeSocket;

const { DevConnect } = require('../dist-test/client.js');
const { devConnectReduxMiddleware } = require('../dist-test/interceptors/state/reduxMiddleware.js');

let socket;
let store;

/** createStore + applyMiddleware, as small as Redux's. */
function createStore(reducer, middleware) {
  let state = reducer(undefined, { type: '@@INIT' });
  const base = (action) => { state = reducer(state, action); return action; };
  const api = { getState: () => state, dispatch: (action) => api.dispatchAll(action) };
  api.dispatchAll = middleware(api)(base);
  return { getState: api.getState, dispatch: api.dispatch };
}

function reducer(state = { user: null, cart: [] }, action) {
  switch (action.type) {
    case 'LOGIN': return { ...state, user: action.name };
    case 'LOGOUT': return { ...state, user: null };
    case 'RESTORE_STATE': return action.payload;
    case 'BOOM': throw new Error('reducer failed');
    default: return state;
  }
}

/** Delivers a message to DevConnect the way the desktop does. */
function fromDesktop(type, payload) {
  socket.onmessage({ data: JSON.stringify({ type, payload }) });
}

const sent = (type) => socket.sent.filter((m) => m.type === type).map((m) => m.payload);

test.before(async () => {
  await DevConnect.init({
    appName: 'StateCommandsTest', host: '127.0.0.1', auto: false, enabled: true,
    autoInterceptFetch: false, autoInterceptXHR: false, autoInterceptConsole: false,
    autoPerformance: false, autoMemoryLeak: false, autoBenchmark: false, autoError: false,
  });
  socket = FakeSocket.last;
  socket.onopen();
});

test.after(() => { DevConnect.disconnect(); Module._load = originalLoad; });

test('before the app wires anything, a dispatch or a restore is ignored without an error', () => {
  assert.doesNotThrow(() => fromDesktop('server:redux:dispatch', { action: { type: 'LOGIN', name: 'Ada' } }));
  assert.doesNotThrow(() => fromDesktop('server:state:restore', { state: { user: 'x' } }));
});

test('connecting the store sends its state to the desktop', () => {
  store = createStore(reducer, devConnectReduxMiddleware);
  DevConnect.connectReduxStore(store);
  const snapshot = sent('client:state:snapshot').at(-1);
  assert.equal(snapshot.stateManager, 'redux');
  assert.deepEqual(snapshot.state, { user: null, cart: [] });
});

test('an action dispatched from the desktop runs in the app\'s store and comes back to the timeline', () => {
  const before = sent('client:state:change').length;
  fromDesktop('server:redux:dispatch', { action: { type: 'LOGIN', name: 'Ada' } });
  assert.equal(store.getState().user, 'Ada');
  const changes = sent('client:state:change');
  assert.equal(changes.length, before + 1);
  const change = changes.at(-1);
  assert.equal(change.stateManager, 'redux');
  assert.equal(change.action, 'LOGIN');
  assert.deepEqual(change.nextState, { user: 'Ada', cart: [] });
  assert.deepEqual(change.diff, [{ path: 'user', operation: 'replace', oldValue: null, newValue: 'Ada' }]);
});

test('a dispatch without an action leaves the store alone', () => {
  const state = store.getState();
  fromDesktop('server:redux:dispatch', {});
  fromDesktop('server:redux:dispatch', { action: null });
  assert.equal(store.getState(), state);
});

test('a restored snapshot reaches the handler the app registered', () => {
  const got = [];
  DevConnect.onStateRestore((state) => got.push(state));
  fromDesktop('server:state:restore', { state: { user: 'Bob', cart: [1] } });
  fromDesktop('server:state:restore', {});
  assert.deepEqual(got, [{ user: 'Bob', cart: [1] }]);
});

test('with the usual RESTORE_STATE wiring, a restore replaces the store\'s state and shows in the timeline', () => {
  DevConnect.onStateRestore((state) => store.dispatch({ type: 'RESTORE_STATE', payload: state }));
  fromDesktop('server:state:restore', { state: { user: 'Cy', cart: [2, 3] } });
  assert.deepEqual(store.getState(), { user: 'Cy', cart: [2, 3] });
  const change = sent('client:state:change').at(-1);
  assert.equal(change.action, 'RESTORE_STATE');
  assert.deepEqual(change.nextState, { user: 'Cy', cart: [2, 3] });
});

test('an action the store rejects, or a restore handler that throws, shows in the desktop\'s Console', () => {
  const before = sent('client:log').length;
  fromDesktop('server:redux:dispatch', { action: { type: 'BOOM' } });
  DevConnect.onStateRestore(() => { throw new Error('bad snapshot'); });
  fromDesktop('server:state:restore', { state: { a: 1 } });
  const logs = sent('client:log').slice(before);
  assert.deepEqual(logs.map((l) => [l.level, l.message]), [
    ['error', 'Redux dispatch threw: reducer failed'],
    ['error', 'onStateRestore threw: bad snapshot'],
  ]);
  assert.equal(logs[0].tag, 'DevConnect');
});
