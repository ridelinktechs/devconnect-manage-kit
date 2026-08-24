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
const apolloModule = require('../dist-test/integrations/apollo.js');
const { setupApolloDevConnect } = apolloModule;

function makeMockCache() {
  const watchers = [];
  const cache = {
    extract: () => ({ __root: 'value' }),
    watch(opts) {
      const observable = {
        subscribe(observer) {
          watchers.push({ opts, observer });
          return { unsubscribe: () => {} };
        },
      };
      return observable;
    },
  };
  return { cache, watchers };
}

test.after(() => { Module._load = originalLoad; });

test('setupApolloDevConnect no-ops when no cache.watch', () => {
  const stop = setupApolloDevConnect({ cache: {} }, {});
  assert.equal(typeof stop, 'function');
});

test('cache.watch is called and the returned Observable is subscribed to', () => {
  const { cache, watchers } = makeMockCache();
  const stop = setupApolloDevConnect({ cache }, { emitInitialSnapshot: false, snapshotIntervalMs: 0 });
  assert.equal(watchers.length, 1, 'expected subscribe to be called on watch() result');
  stop();
});

test('watch callback is invoked when observer.next is called', () => {
  const { cache, watchers } = makeMockCache();
  const stop = setupApolloDevConnect({ cache }, { emitInitialSnapshot: false, snapshotIntervalMs: 0 });
  const events = [];
  DevConnect.safeSend = (type, payload) => events.push({ type, payload });
  watchers[0].observer.next({ fieldName: 'todos', broadcast: () => ({ affected: { id: 1 } }) });
  assert.ok(events.some(e => e.type === 'client:state:change'));
  stop();
});

test('initial snapshot respects maxSnapshotBytes cap (truncates UTF-8)', () => {
  const { cache } = makeMockCache();
  // Build a large extract value to exceed a 50-byte cap.
  const big = 'x'.repeat(200);
  cache.extract = () => ({ data: big });

  const events = [];
  DevConnect.safeSend = (type, payload) => events.push({ type, payload });

  const stop = setupApolloDevConnect({ cache }, {
    emitInitialSnapshot: true,
    snapshotIntervalMs: 0,
    maxSnapshotBytes: 50,
  });
  const snap = events.find(e => e.type === 'client:state:snapshot');
  assert.ok(snap, 'expected a snapshot event');
  assert.equal(snap.payload.metadata?.truncated, true);
  // State must be a string (truncated), not the full object.
  assert.equal(typeof snap.payload.state, 'string');
  stop();
});

test('periodic snapshot truncates by UTF-8 bytes (not UTF-16 chars)', async () => {
  const { cache } = makeMockCache();
  // Each 2-byte UTF-8 char counts 2 bytes but 1 UTF-16 char.
  cache.extract = () => ({ x: 'ß'.repeat(100) }); // 200 bytes in UTF-8, 100 chars
  const events = [];
  DevConnect.safeSend = (type, payload) => events.push({ type, payload });

  const stop = setupApolloDevConnect({ cache }, {
    emitInitialSnapshot: false,
    snapshotIntervalMs: 20,
    maxSnapshotBytes: 50,
  });
  await new Promise(r => setTimeout(r, 60));
  stop();
  const snaps = events.filter(e => e.type === 'client:state:snapshot');
  assert.ok(snaps.length > 0, 'expected at least one periodic snapshot');
  const last = snaps[snaps.length - 1];
  assert.equal(last.payload.metadata?.truncated, true);
});

test('initial snapshot is emitted on startup by default', () => {
  const { cache } = makeMockCache();
  const events = [];
  DevConnect.safeSend = (type, payload) => events.push({ type, payload });
  const stop = setupApolloDevConnect({ cache }, { snapshotIntervalMs: 0 });
  const snap = events.find(e => e.type === 'client:state:snapshot');
  assert.ok(snap);
  stop();
});
