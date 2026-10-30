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

let connected = true;
DevConnect.isListening = () => connected;
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

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

test('never registers a cache.watch (a watch without query + callback breaks every Apollo cache write)', () => {
  const { cache } = makeMockCache();
  let watchCalls = 0;
  cache.watch = () => { watchCalls++; return () => {}; }; // Apollo's real shape: returns an unsubscribe function
  const stop = setupApolloDevConnect({ cache }, { emitInitialSnapshot: false, snapshotIntervalMs: 0 });
  assert.equal(watchCalls, 0);
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

test('periodic snapshots leave the cache alone while the desktop is disconnected', async () => {
  const { cache } = makeMockCache();
  let extracts = 0;
  cache.extract = () => { extracts++; return { a: 1 }; };
  const events = [];
  DevConnect.safeSend = (type, payload) => events.push(payload);
  connected = false;
  try {
    const stop = setupApolloDevConnect({ cache }, { emitInitialSnapshot: false, snapshotIntervalMs: 10 });
    await sleep(50);
    stop();
  } finally {
    connected = true;
  }
  assert.equal(extracts, 0);
  assert.equal(events.length, 0);
});

test('an unchanged cache is sent again only after a change or a reconnect', async () => {
  const { cache } = makeMockCache();
  let data = { a: 1 };
  cache.extract = () => ({ ...data });
  const events = [];
  DevConnect.safeSend = (type, payload) => events.push(payload);
  const stop = setupApolloDevConnect({ cache }, { emitInitialSnapshot: false, snapshotIntervalMs: 10 });
  await sleep(50);
  data = { a: 2 };
  await sleep(50);
  connected = false;
  await sleep(30);
  connected = true;
  await sleep(30);
  stop();
  assert.deepEqual(events.map((e) => e.state), [{ a: 1 }, { a: 2 }, { a: 2 }]);
});

test('truncation finds the cut in one pass, without an encode/decode loop', () => {
  const RealEncoder = global.TextEncoder;
  let encodes = 0;
  global.TextEncoder = class extends RealEncoder {
    encode(input) { encodes++; return super.encode(input); }
  };
  const { cache } = makeMockCache();
  cache.extract = () => ({ x: 'ß'.repeat(5000) });
  const events = [];
  DevConnect.safeSend = (type, payload) => events.push(payload);
  try {
    setupApolloDevConnect({ cache }, { snapshotIntervalMs: 0, maxSnapshotBytes: 1000 })();
  } finally {
    global.TextEncoder = RealEncoder;
  }
  assert.ok(encodes <= 2, `${encodes} encodes`);
  const { state, metadata } = events[0];
  assert.deepEqual(metadata, { truncated: true, originalSize: 10008 });
  assert.ok(state.endsWith('…'));
  assert.ok(JSON.stringify(cache.extract()).startsWith(state.slice(0, -1)));
  assert.equal(Buffer.byteLength(state), 999);
});
