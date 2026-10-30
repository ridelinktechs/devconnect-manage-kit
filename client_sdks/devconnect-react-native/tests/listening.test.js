const test = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');

const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === 'react-native') return { Platform: { OS: 'android', Version: 'test', constants: {} }, NativeModules: {} };
  return originalLoad.call(this, request, parent, isMain);
};

class FakeSocket {
  constructor() { FakeSocket.last = this; }
  send() {}
  close() {}
}
global.WebSocket = FakeSocket;

const { DevConnect } = require('../dist-test/client.js');

test('state changes are kept while the first connection attempt runs, dropped once the desktop is known absent', async () => {
  await DevConnect.init({
    appName: 'ListenTest', host: '127.0.0.1', auto: false, enabled: true,
    autoInterceptFetch: false, autoInterceptXHR: false, autoInterceptConsole: false,
    autoPerformance: false, autoMemoryLeak: false, autoBenchmark: false, autoError: false,
  });
  try {
    assert.equal(DevConnect.isListening(), true); // e.g. a store rehydrating at startup
    FakeSocket.last.onclose(); // no desktop there
    assert.equal(DevConnect.isListening(), false);
  } finally {
    DevConnect.disconnect();
    Module._load = originalLoad;
  }
});
