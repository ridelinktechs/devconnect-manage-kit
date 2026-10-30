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
const { patchLoglevel, wrapLogger, devConnectTransport } = require('../dist-test/interceptors/logging/logLibraryPlugins.js');

const sent = [];
DevConnect.safeSend = (type, payload) => sent.push(payload.message);
const loop = { name: 'loop' };
loop.self = loop;

test('loglevel: an argument JSON can\'t encode is still logged, never thrown', () => {
  const printed = [];
  const log = {
    methodFactory: (name) => (...args) => printed.push([name, ...args]),
    getLevel: () => 0,
    setLevel() { this.debug = this.methodFactory('debug', 0, undefined); },
  };
  patchLoglevel(log);
  assert.doesNotThrow(() => log.debug('x', loop));
  assert.doesNotThrow(() => log.debug('n', 10n));
  assert.deepEqual(printed, [['debug', 'x', loop], ['debug', 'n', 10n]]);
  assert.deepEqual(sent.slice(-2), ['x [object Object]', 'n 10']);
});

test('wrapLogger: an argument JSON can\'t encode is still logged, never thrown', () => {
  const printed = [];
  const wrapped = wrapLogger({ warn: (...args) => printed.push(args) }, 'mine');
  assert.doesNotThrow(() => wrapped.warn('x', loop));
  assert.deepEqual(printed, [['x', loop]]);
  assert.equal(sent.at(-1), 'x [object Object]');
});

test('react-native-logs transport: a message JSON can\'t encode never throws', () => {
  assert.doesNotThrow(() => devConnectTransport({ msg: loop, rawMsg: [loop], level: { severity: 0, text: 'debug' } }));
  assert.equal(sent.at(-1), '[object Object]');
});
