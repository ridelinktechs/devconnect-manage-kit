const test = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');

const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === 'react-native') return { Platform: { OS: 'android', Version: 'test', constants: {} }, NativeModules: {} };
  return originalLoad.call(this, request, parent, isMain);
};
test.after(() => { Module._load = originalLoad; });

const { DevConnect } = require('../dist-test/client.js');
const { setupAxiosInterceptor } = require('../dist-test/interceptors/network/axiosInterceptor.js');

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

test('binary bodies are reported as their size, not one key per byte', () => {
  const sent = [];
  DevConnect.safeSend = (type, payload) => sent.push(payload);
  let onRequest, onResponse;
  setupAxiosInterceptor({
    interceptors: {
      request: { use: (fn) => { onRequest = fn; } },
      response: { use: (fn) => { onResponse = fn; } },
    },
  });
  const config = onRequest({ url: 'https://api.example.com/upload', method: 'post', data: new Uint8Array([1, 2, 3]) });
  assert.equal(sent.at(-1).requestBody, '<3 bytes>');
  onResponse({ config: { ...config, data: config.data.buffer }, status: 200, headers: {}, data: new ArrayBuffer(8) });
  assert.equal(sent.at(-1).requestBody, '<3 bytes>');
  assert.equal(sent.at(-1).responseBody, '<8 bytes>');
});
