const test = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');

// Where the root view measures (Android: one status bar up when translucent).
let rootBox = [0, 0, 400, 800];
const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === 'react-native') {
    return {
      StyleSheet: { flatten: (s) => (Array.isArray(s) ? Object.assign({}, ...s) : s) },
      UIManager: { measureInWindow: (tag, cb) => setImmediate(() => cb(...rootBox)) },
      Platform: { OS: 'ios', Version: '18.0', constants: {} },
      NativeModules: {},
      Dimensions: { get: () => ({ width: 400, height: 800 }) },
    };
  }
  return originalLoad.call(this, request, parent, isMain);
};
test.after(() => { Module._load = originalLoad; });

const { captureComponentTree } = require('../dist-test/plugins/layoutInspector.js');

// Minimal fibers: host views measure asynchronously like the bridge does.
function link(fiber, children) {
  fiber.child = children[0] ?? null;
  children.forEach((c, i) => { c.sibling = children[i + 1] ?? null; });
  return fiber;
}
const host = (name, box, children = [], style) => link({
  tag: 5,
  type: name,
  memoizedProps: { style },
  stateNode: { measureInWindow: (cb) => setImmediate(() => cb(...box)) },
}, children);
const component = (name, children = []) => {
  const type = function () {};
  Object.defineProperty(type, 'name', { value: name });
  return link({ tag: 0, type, memoizedProps: {} }, children);
};
const unnamed = (children) => link({ tag: 10, type: null, memoizedProps: {} }, children); // e.g. a context provider
const mount = (fiber) => {
  globalThis.__REACT_DEVTOOLS_GLOBAL_HOOK__ = {
    renderers: new Map([[1, {}]]),
    getFiberRoots: () => new Set([{
      containerInfo: 1,
      current: link({ tag: 3, type: null, memoizedProps: {} }, [fiber]),
    }]),
  };
};

test('named tree with bounds; components span their views', async () => {
  mount(component('App', [
    host('RCTView', [0, 0, 400, 800], [
      unnamed([host('RCTText', [10, 20, 100, 30])]),
      component('_Private', [host('RCTView', [10, 60, 50, 50])]),
      component('Card', [host('RCTView', [0, 200, 400, 100], [], { padding: 8 })]),
    ]),
  ]));
  const [app] = await captureComponentTree();
  assert.equal(app.name, 'App');
  assert.deepEqual([app.x, app.y, app.w, app.h], [0, 0, 400, 800]);
  const view = app.children[0];
  assert.deepEqual(view.children.map((c) => c.name), ['RCTText', 'RCTView', 'Card']);
  const card = view.children[2];
  assert.deepEqual([card.x, card.y, card.w, card.h], [0, 200, 400, 100]);
  assert.deepEqual(card.padding, [8, 8, 8, 8]);
});

test('a fiber tree thousands of levels deep is read without overflowing', async () => {
  let fiber = host('RCTView', [0, 0, 400, 800]);
  for (let i = 0; i < 20000; i++) fiber = unnamed([fiber]);
  mount(fiber);
  const roots = await captureComponentTree();
  assert.deepEqual(roots.map((r) => r.name), ['RCTView']);
});

test('a view Android flattened away spans its children instead of 0×0', async () => {
  // Android answers measureInWindow for a layout-only view with no arguments.
  const flattened = link({
    tag: 5,
    type: 'RCTView',
    memoizedProps: { style: { flex: 1 } },
    stateNode: { measureInWindow: (cb) => setImmediate(() => cb()) },
  }, [host('RCTText', [10, 20, 100, 30]), host('RCTImage', [10, 60, 50, 50])]);
  mount(flattened);
  const [view] = await captureComponentTree();
  assert.deepEqual([view.x, view.y, view.w, view.h], [10, 20, 100, 90]);
});

test('boxes are relative to the root view (Android translucent status bar)', async () => {
  rootBox = [0, -49, 400, 849]; // the root draws under a 49dp status bar
  try {
    mount(host('RCTView', [0, 0, 400, 100])); // measureInWindow: 0 = just below it
    const [view] = await captureComponentTree();
    assert.deepEqual([view.x, view.y], [0, 49]);
  } finally {
    rootBox = [0, 0, 400, 800];
  }
});

test('says why when there is no DevTools hook', async () => {
  delete globalThis.__REACT_DEVTOOLS_GLOBAL_HOOK__;
  await assert.rejects(captureComponentTree(), /dev builds only/);
});
