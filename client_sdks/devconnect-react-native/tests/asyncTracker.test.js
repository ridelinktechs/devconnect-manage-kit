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
const { devConnectThunkTracker } = require('../dist-test/plugins/state/asyncTracker.js');

/** redux-thunk's `withExtraArgument(extra)`. */
const thunk = (extra) => ({ dispatch, getState }) => (next) => (action) =>
  typeof action === 'function' ? action(dispatch, getState, extra) : next(action);

test('a tracked thunk gets the thunk middleware\'s extra argument and is still timed', async () => {
  const ops = [];
  DevConnect.safeSend = (type, payload) => ops.push(payload);
  const api = { getState: () => ({}), dispatch: (action) => dispatch(action) };
  const dispatch = devConnectThunkTracker(api)(thunk({ client: 'api' })(api)((action) => action));

  let extra;
  const result = await api.dispatch(async function loadUser(_dispatch, _getState, arg) {
    extra = arg;
    return 'done';
  });

  assert.deepEqual(extra, { client: 'api' });
  assert.equal(result, 'done');
  assert.deepEqual(ops.map((o) => [o.description, o.status]), [['loadUser', 'start'], ['loadUser', 'resolve']]);
});
