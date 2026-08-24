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
const linkModule = require('../dist-test/interceptors/apollo/devConnectApolloLink.js');
const { devConnectApolloLink } = linkModule;

test.after(() => { Module._load = originalLoad; });

test('devConnectApolloLink is a callable function', () => {
  assert.equal(typeof devConnectApolloLink, 'function');
});

test('devConnectApolloLink throws a clear error when @apollo/client is not installed', () => {
  // Hide Apollo from require so the lazy loader fails.
  const realLoad = Module._load;
  Module._load = function (request, parent, isMain) {
    if (request === '@apollo/client') {
      throw new Error("Cannot find module '@apollo/client'");
    }
    return realLoad.call(this, request, parent, isMain);
  };
  // The require cache may already hold a previous resolution; clear it.
  delete require.cache[require.resolve('../dist-test/interceptors/apollo/devConnectApolloLink.js')];
  // Re-require to reset the lazy loader state.
  const fresh = require('../dist-test/interceptors/apollo/devConnectApolloLink.js');
  try {
    assert.throws(() => fresh.devConnectApolloLink(), /@apollo\/client is not installed/);
  } finally {
    Module._load = realLoad;
    delete require.cache[require.resolve('../dist-test/interceptors/apollo/devConnectApolloLink.js')];
  }
});
