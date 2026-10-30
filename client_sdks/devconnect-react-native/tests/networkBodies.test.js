const test = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');

const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === 'react-native') return { Platform: { OS: 'ios', Version: 'test', constants: {} }, NativeModules: {} };
  return originalLoad.call(this, request, parent, isMain);
};

/** Joins chunked messages like the desktop does, acking each chunk on the next tick. */
class FakeSocket {
  constructor() { this.sent = []; this.parts = ''; this.chunks = 0; this.unacked = 0; this.maxUnacked = 0; FakeSocket.last = this; }
  send(json) {
    const msg = JSON.parse(json);
    if (msg.type !== 'client:chunk') return this.sent.push(msg);
    this.chunks++;
    this.maxUnacked = Math.max(this.maxUnacked, ++this.unacked);
    this.parts += msg.payload.data;
    if (msg.payload.last) {
      this.sent.push(JSON.parse(this.parts));
      this.parts = '';
    }
    setTimeout(() => {
      this.unacked--;
      this.onmessage({ data: JSON.stringify({ type: 'server:chunk_ack', payload: { id: msg.payload.id } }) });
    });
  }
  close() {}
}
global.WebSocket = FakeSocket;

global.FileReader = class {
  readAsDataURL(blob) {
    blob.arrayBuffer().then((buffer) => {
      this.result = `data:${blob.type || 'application/octet-stream'};base64,${Buffer.from(buffer).toString('base64')}`;
      this.onload();
    }, (error) => {
      this.error = error;
      this.onerror();
    });
  }
};

/** An XHR the test answers with `respond`. */
class FakeXHR {
  constructor() { this.listeners = []; this.responseType = ''; this.headers = {}; }
  open() {}
  send() {}
  setRequestHeader() {}
  getAllResponseHeaders() { return Object.entries(this.headers).map(([k, v]) => `${k}: ${v}`).join('\r\n'); }
  addEventListener(_type, listener) { this.listeners.push(listener); }
  removeEventListener() {}
  respond(props) {
    Object.assign(this, { status: 200 }, props);
    return Promise.all(this.listeners.map((listener) => listener()));
  }
}
global.XMLHttpRequest = FakeXHR;

let respondWith = () => new Response('');
global.fetch = async () => respondWith();
global.__DEV__ = true;

const { DevConnect } = require('../dist-test/client.js');

let socket;
test.before(async () => {
  await DevConnect.init({
    appName: 'BodyTest', host: '127.0.0.1', auto: false, enabled: true,
    autoInterceptFetch: true, autoInterceptXHR: true, autoInterceptConsole: false,
    autoPerformance: false, autoMemoryLeak: false, autoBenchmark: false, autoError: false,
  });
  socket = FakeSocket.last;
  socket.onopen();
});
test.after(() => { DevConnect.disconnect(); Module._load = originalLoad; });

const MB = 1_048_576;
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const reported = (type, url) => socket.sent.findLast((m) => m.type === type && m.payload.url === url)?.payload;
const started = (url) => reported('client:network:request_start', url);
const completed = (url) => reported('client:network:request_complete', url);

function xhr(method, url, body) {
  const request = new XMLHttpRequest();
  request.open(method, url);
  request.send(body);
  return request;
}

test('fetch hands the response to the app without waiting for its body', async () => {
  respondWith = () => new Response(new ReadableStream({ start() {} }));
  const res = await Promise.race([fetch('https://example.com/events'), sleep(300).then(() => 'still waiting')]);
  assert.notEqual(res, 'still waiting');
});

test('an event stream is reported as a stream, not read', async () => {
  respondWith = () => new Response(new ReadableStream({ start() {} }), { headers: { 'content-type': 'text/event-stream' } });
  await fetch('https://example.com/sse');
  await sleep(20);
  assert.equal(completed('https://example.com/sse')?.responseBody, '<stream>');
});

test('small JSON and text bodies are reported as before', async () => {
  respondWith = () => new Response('{"ok":true}');
  await fetch('https://example.com/json', { method: 'POST', body: '{"a":1}' });
  respondWith = () => new Response('plain');
  await fetch('https://example.com/text', { method: 'POST', body: 'hello' });
  await sleep(10);
  assert.deepEqual(completed('https://example.com/json').responseBody, { ok: true });
  assert.deepEqual(completed('https://example.com/json').requestBody, { a: 1 });
  assert.equal(completed('https://example.com/text').responseBody, 'plain');
  assert.equal(completed('https://example.com/text').requestBody, 'hello');

  await xhr('POST', 'https://example.com/xhr-json', '{"b":2}').respond({ responseText: '{"ok":1}' });
  assert.deepEqual(completed('https://example.com/xhr-json').requestBody, { b: 2 });
  assert.deepEqual(completed('https://example.com/xhr-json').responseBody, { ok: 1 });
});

test('binary request bodies are reported as their size', async () => {
  await fetch('https://example.com/upload', { method: 'POST', body: new Uint8Array([255, 216, 255]) });
  await fetch('https://example.com/upload-buffer', { method: 'POST', body: new ArrayBuffer(4) });
  xhr('POST', 'https://example.com/xhr-upload', new Uint8Array(5));
  assert.equal(started('https://example.com/upload').requestBody, '<3 bytes>');
  assert.equal(started('https://example.com/upload-buffer').requestBody, '<4 bytes>');
  assert.equal(started('https://example.com/xhr-upload').requestBody, '<5 bytes>');
});

test('text bodies are reported whole at any size; past 1 MB as text, unparsed', async () => {
  const json = JSON.stringify(Array.from({ length: 300_000 }, (_, i) => ({ i })));
  await fetch('https://example.com/big-upload', { method: 'POST', body: 'u'.repeat(MB + 1) });
  respondWith = () => new Response('x'.repeat(MB + 1));
  await fetch('https://example.com/big');
  respondWith = () => new Response(json, { headers: { 'content-type': 'application/json' } });
  await fetch('https://example.com/big-json');
  respondWith = () => new Response('{"a":1}', { headers: { 'content-length': String(11 * MB) } });
  await fetch('https://example.com/declared-huge');
  await sleep(100);
  assert.equal(started('https://example.com/big-upload').requestBody, 'u'.repeat(MB + 1));
  assert.equal(completed('https://example.com/big').responseBody, 'x'.repeat(MB + 1));
  assert.equal(completed('https://example.com/big-json').responseBody, json);
  assert.deepEqual(completed('https://example.com/declared-huge').responseBody, { a: 1 });

  await xhr('GET', 'https://example.com/xhr-big').respond({ responseText: 'y'.repeat(MB + 1) });
  await sleep(50);
  assert.equal(completed('https://example.com/xhr-big').responseBody, 'y'.repeat(MB + 1));

  await xhr('GET', 'https://example.com/xhr-huge').respond({
    responseType: 'blob', response: { size: 11 * MB, text: async () => '{"ok":true}' }, headers: { 'content-type': 'application/json' },
  });
  assert.deepEqual(completed('https://example.com/xhr-huge').responseBody, { ok: true });
});

test('a message longer than a chunk goes out a chunk at a time and arrives whole', async () => {
  const chunks = socket.chunks;
  respondWith = () => new Response('z'.repeat(3 * MB), { headers: { 'content-type': 'text/plain' } });
  await fetch('https://example.com/chunked');
  await sleep(100);
  assert.equal(completed('https://example.com/chunked').responseBody, 'z'.repeat(3 * MB));
  assert.ok(socket.chunks - chunks >= 3);
  assert.equal(socket.maxUnacked, 1);
});

test('images are sent for the desktop to show; other binaries by their size', async () => {
  const png = new Uint8Array([137, 80, 78, 71]);
  respondWith = () => new Response(png, { headers: { 'content-type': 'image/png' } });
  await fetch('https://example.com/a.png');
  respondWith = () => new Response(new Uint8Array(11 * MB), { headers: { 'content-type': 'image/jpeg' } });
  await fetch('https://example.com/huge.jpg');
  respondWith = () => new Response(new Uint8Array(1000), { headers: { 'content-type': 'video/mp4' } });
  await fetch('https://example.com/clip.mp4');
  respondWith = () => new Response(new Uint8Array(4), { headers: { 'content-length': String(11 * MB) } });
  await fetch('https://example.com/untyped');
  await sleep(100);
  assert.equal(completed('https://example.com/a.png').responseBody, `data:image/png;base64,${Buffer.from(png).toString('base64')}`);
  assert.equal(completed('https://example.com/huge.jpg').responseBody, `<${11 * MB} bytes>`);
  assert.equal(completed('https://example.com/clip.mp4').responseBody, '<1000 bytes>');
  assert.equal(completed('https://example.com/untyped').responseBody, `<${11 * MB} bytes>`);

  const image = { size: 3, type: 'image/png', arrayBuffer: async () => new Uint8Array([1, 2, 3]).buffer };
  await xhr('GET', 'https://example.com/xhr.png').respond({
    responseType: 'blob', response: image, headers: { 'content-type': 'image/png' },
  });
  assert.equal(completed('https://example.com/xhr.png').responseBody, 'data:image/png;base64,AQID');
});
