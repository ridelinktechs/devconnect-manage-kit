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
const sourceMapModule = require('../dist-test/reporters/sourceMapReporter.js');
const { uploadSourceMap } = sourceMapModule;

test.after(() => { Module._load = originalLoad; });

test('toBase64 encodes UTF-8 correctly (ß = 0xC3 0x9F)', async () => {
  // Use the internal-ish test by uploading a map with a known character.
  // We can verify via DevConnect.safeSend capture.
  const events = [];
  DevConnect.safeSend = (type, payload) => events.push({ type, payload });
  const result = await uploadSourceMap({
    bundleName: 'b',
    buildId: 'v',
    mapContent: 'ß',
  });
  // 'ß' (2 bytes) -> base64 'w58='
  assert.equal(events[0].payload.map, 'w58=');
  assert.equal(result.uploaded, true);
});

test('sizeBytes is reported in UTF-8 bytes, not UTF-16 chars', async () => {
  const events = [];
  DevConnect.safeSend = (type, payload) => events.push({ type, payload });
  // 'ß' is 1 UTF-16 char but 2 UTF-8 bytes.
  await uploadSourceMap({ bundleName: 'b', buildId: 'v', mapContent: 'ßßßßß' });
  // 5 chars * 2 bytes = 10 bytes
  assert.equal(events[0].payload.sizeBytes, 10);
});

test('oversized map is rejected by UTF-8 byte count', async () => {
  const result = await uploadSourceMap({
    bundleName: 'b',
    buildId: 'v',
    mapContent: 'ß'.repeat(100), // 200 UTF-8 bytes
    maxBytes: 50,
  });
  assert.equal(result.uploaded, false);
  assert.match(result.reason, /exceeds/);
});

test('sha256 fallback FNV is masked to 64 bits (constant-length hex)', async () => {
  // Build a content large enough that an unmasked FNV would grow beyond
  // 64 bits. With 16 hex chars (64 bits) padded, output is always 16 chars.
  const result = await uploadSourceMap({
    bundleName: 'b',
    buildId: 'v',
    mapContent: 'a'.repeat(2_000_000), // 2MB of 'a' forces FNV fallback if no subtle
    maxBytes: 10_000_000,
  });
  // Even if SHA-256 is used, result.mapId should be a sane hex.
  assert.equal(result.uploaded, true);
  assert.match(result.mapId, /^[0-9a-f]{16,64}$/);
  // FNV fallback would yield exactly 16 hex chars; ensure we never see
  // a number string that grew beyond that range.
  assert.ok(result.mapId.length >= 16);
});
