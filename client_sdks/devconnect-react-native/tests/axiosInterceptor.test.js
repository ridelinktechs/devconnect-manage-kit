const test = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');

const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === 'react-native') return { Platform: { OS: 'android', Version: 'test', constants: {} }, NativeModules: {} };
  return originalLoad.call(this, request, parent, isMain);
};
test.after(() => { Module._load = originalLoad; });

const { setupAxiosInterceptor } = require('../dist-test/interceptors/axiosInterceptor.js');

test('a request the reporting can\'t read still goes out', () => {
  let onRequest;
  setupAxiosInterceptor({
    interceptors: {
      request: { use: (fn) => { onRequest = fn; } },
      response: { use: () => {} },
    },
  });
  // A URL object instead of a string: the URL building used to throw,
  // which rejected the app's own request.
  const config = { url: new URL('https://api.example.com/users'), method: 'get' };
  assert.equal(onRequest(config), config);
});
