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

test("uses Apollo's Observable, pairs events by operationId, unsubscribes downstream", () => {
  class Observable {
    constructor(subscriber) { this.subscriber = subscriber; }
    subscribe(observer) {
      const teardown = this.subscriber(observer);
      return { unsubscribe: () => teardown?.() };
    }
  }
  class ApolloLink { constructor(request) { this.request = request; } }
  const realLoad = Module._load;
  Module._load = function (request, parent, isMain) {
    if (request === '@apollo/client') return { ApolloLink, Observable };
    return realLoad.call(this, request, parent, isMain);
  };
  const path = require.resolve('../dist-test/interceptors/apollo/devConnectApolloLink.js');
  delete require.cache[path];
  try {
    const link = require(path).devConnectApolloLink();
    const events = [];
    DevConnect.safeSend = (type, payload) => events.push({ type, payload });
    const operation = { operationName: 'GetUser', query: { definitions: [] }, variables: { id: 1 } };
    const observer = { next() {}, error() {}, complete() {} };

    // An errors-only response (no data), then unsubscribe.
    let downstreamClosed = false;
    const result = link.request(operation, () => new Observable((o) => {
      o.next({ errors: [{ message: 'denied' }] });
      return () => { downstreamClosed = true; };
    }));
    assert.ok(result instanceof Observable);
    result.subscribe(observer).unsubscribe();
    assert.ok(downstreamClosed);

    // A transport failure.
    link.request(operation, () => new Observable((o) => o.error(new Error('offline')))).subscribe(observer);

    assert.deepEqual(events.map((e) => e.type), [
      'client:graphql_operation', 'client:graphql_response',
      'client:graphql_operation', 'client:graphql_response',
    ]);
    const [op1, res1, op2, res2] = events.map((e) => e.payload);
    assert.equal(res1.operationId, op1.operationId);
    assert.equal(res2.operationId, op2.operationId);
    assert.notEqual(op1.operationId, op2.operationId);
    assert.equal('data' in res1, false);
    assert.deepEqual(res1.errors, [{ message: 'denied', locations: [] }]);
    assert.equal(res2.error, 'offline');
    assert.equal(typeof res2.latencyMs, 'number');
  } finally {
    Module._load = realLoad;
    delete require.cache[path];
  }
});
