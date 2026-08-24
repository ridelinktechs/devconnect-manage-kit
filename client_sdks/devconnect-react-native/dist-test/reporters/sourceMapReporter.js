"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.uploadSourceMap = uploadSourceMap;
const client_1 = require("../client");
/** Simple SHA-256 hex digest via Web Crypto. RN ≥ 0.65 supports `globalThis.crypto.subtle`. */
async function sha256(input) {
    try {
        const subtle = globalThis.crypto?.subtle;
        if (subtle?.digest) {
            const data = new TextEncoder().encode(input);
            const buf = await subtle.digest('SHA-256', data);
            const arr = Array.from(new Uint8Array(buf));
            return arr.map(b => b.toString(16).padStart(2, '0')).join('');
        }
    }
    catch (_) { }
    // Fallback: FNV-1a 64-bit (not crypto-secure but stable).
    // Mask to 64 bits after every multiply so BigInt doesn't grow unbounded
    // for multi-megabyte inputs.
    const MASK_64 = (1n << 64n) - 1n;
    let h1 = 0xcbf29ce484222325n;
    const bytes = new TextEncoder().encode(input);
    for (let i = 0; i < bytes.byteLength; i++) {
        h1 = (h1 ^ BigInt(bytes[i])) * 0x100000001b3n;
        h1 = h1 & MASK_64; // ponytail: keep FNV-1a at 64 bits, prevents BigInt bloat on huge maps
    }
    return h1.toString(16).padStart(16, '0');
}
/** Encode a string as UTF-8 bytes and base64-encode the result. */
function toBase64(content) {
    const bytes = new TextEncoder().encode(content);
    // ponytail: use stdlib btoa when it accepts a Latin-1 string; otherwise
    // chunk through a manually-driven base64 over the byte array.
    let binary = '';
    const CHUNK = 0x8000;
    for (let i = 0; i < bytes.byteLength; i += CHUNK) {
        binary += String.fromCharCode.apply(null, Array.from(bytes.subarray(i, i + CHUNK)));
    }
    const g = globalThis;
    if (typeof g.btoa === 'function') {
        return g.btoa(binary);
    }
    // Manual fallback (no btoa available, e.g. very old RN).
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let output = '';
    let i = 0;
    while (i < binary.length) {
        const c1 = binary.charCodeAt(i++) & 0xff;
        const c2 = i < binary.length ? binary.charCodeAt(i++) & 0xff : -1;
        const c3 = i < binary.length ? binary.charCodeAt(i++) & 0xff : -1;
        const e1 = c1 >> 2;
        const e2 = ((c1 & 3) << 4) | (c2 === -1 ? 0 : c2 >> 4);
        const e3 = c2 === -1 ? 64 : (((c2 & 15) << 2) | (c3 === -1 ? 0 : c3 >> 6));
        const e4 = c3 === -1 ? 64 : (c3 & 63);
        output += chars.charAt(e1) + chars.charAt(e2) + chars.charAt(e3) + chars.charAt(e4);
    }
    return output;
}
async function uploadSourceMap(opts) {
    if (!opts.mapPath && !opts.mapContent) {
        return { uploaded: false, reason: 'mapPath or mapContent is required' };
    }
    let content = opts.mapContent;
    if (!content && opts.mapPath) {
        try {
            // RN ships `fs` via `react-native-fs` — try it first.
            const RNFS = require('react-native-fs');
            content = await RNFS.readFile(opts.mapPath, 'utf8');
        }
        catch (_) {
            // Fallback: try Node-style fs (only works in tests / Node targets).
            try {
                const fs = require('fs');
                content = await new Promise((resolve, reject) => {
                    fs.readFile(opts.mapPath, 'utf8', (err, data) => {
                        if (err)
                            reject(err);
                        else
                            resolve(data);
                    });
                });
            }
            catch (e) {
                return { uploaded: false, reason: `Failed to read ${opts.mapPath}: ${e?.message ?? e}` };
            }
        }
    }
    if (!content) {
        return { uploaded: false, reason: 'Empty source map' };
    }
    const maxBytes = opts.maxBytes ?? 5242880; // 5 MB
    // Size in UTF-8 bytes, not UTF-16 code units.
    const sizeBytes = new TextEncoder().encode(content).byteLength;
    if (sizeBytes > maxBytes) {
        return {
            uploaded: false,
            reason: `Source map exceeds ${(maxBytes / 1024 / 1024).toFixed(1)} MB; upload via desktop UI instead`,
        };
    }
    const mapId = await sha256(content);
    const encoded = toBase64(content);
    client_1.DevConnect.safeSend('client:source_map_upload', {
        mapId,
        map: encoded,
        bundleName: opts.bundleName,
        buildId: opts.buildId,
        sizeBytes,
    });
    return { uploaded: true, mapId };
}
