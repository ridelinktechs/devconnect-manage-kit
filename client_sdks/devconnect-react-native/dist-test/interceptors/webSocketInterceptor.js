"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.installWebSocketInterceptor = installWebSocketInterceptor;
const client_1 = require("../client");
/**
 * WebSocket inspector for React Native.
 *
 * Patches `global.WebSocket` so every constructed socket automatically
 * emits `client:ws_open`, `client:ws_frame`, and `client:ws_close`
 * events to the desktop.
 *
 * Spec (Round 3 / 3.3): "On RN: wrap `global.WebSocket` constructor."
 *
 * Usage:
 * ```typescript
 * import { installWebSocketInterceptor } from 'devconnect-react-native';
 * installWebSocketInterceptor();
 * ```
 *
 * Idempotent — multiple calls are safe. Returns a cleanup function that
 * restores the original constructor.
 */
let _originalWebSocket = null;
let _installed = false;
function installWebSocketInterceptor() {
    if (_installed)
        return () => { };
    _installed = true;
    _originalWebSocket = global.WebSocket;
    if (!_originalWebSocket) {
        _installed = false;
        return () => { };
    }
    const Original = _originalWebSocket;
    class DevConnectWrappedWebSocket {
        constructor(url, protocols) {
            this._closed = false;
            this._onerrorDone = false;
            this.onopen = null;
            this.onmessage = null;
            this.onerror = null;
            this.onclose = null;
            this.url = url;
            this._inner = protocols !== undefined
                ? new Original(url, protocols)
                : new Original(url);
            // Forward lifecycle events.
            this._inner.onopen = (ev) => {
                try {
                    client_1.DevConnect.safeSend('client:ws_open', {
                        url,
                        openedAt: Date.now(),
                        protocol: this._inner.protocol,
                    });
                }
                catch (_) { }
                this.onopen?.(ev);
            };
            this._inner.onmessage = (ev) => {
                try {
                    const data = ev.data;
                    const isBinary = typeof data !== 'string';
                    const sizeBytes = isBinary
                        ? (data?.byteLength ?? data?.size ?? 0)
                        : (data.length);
                    client_1.DevConnect.safeSend('client:ws_frame', {
                        url,
                        direction: 'receive',
                        opcode: isBinary ? 'binary' : 'text',
                        sizeBytes,
                        ...(isBinary ? {} : { payload: data }),
                        timestamp: Date.now(),
                    });
                }
                catch (_) { }
                this.onmessage?.(ev);
            };
            this._inner.onerror = (ev) => {
                // Don't double-emit close on a bare error; native onclose will follow.
                this._onerrorDone = true;
                try {
                    client_1.DevConnect.safeSend('client:ws_close', {
                        url,
                        error: ev?.message ?? 'WebSocket error',
                        timestamp: Date.now(),
                    });
                }
                catch (_) { }
                this.onerror?.(ev);
            };
            this._inner.onclose = (ev) => {
                this.readyState; // touch
                if (this._closed)
                    return;
                this._closed = true;
                try {
                    client_1.DevConnect.safeSend('client:ws_close', {
                        url,
                        code: ev.code,
                        reason: ev.reason,
                        timestamp: Date.now(),
                    });
                }
                catch (_) { }
                this.onclose?.(ev);
            };
        }
        send(data) {
            try {
                const isBinary = typeof data !== 'string';
                const sizeBytes = isBinary
                    ? (data?.byteLength ?? data?.size ?? 0)
                    : (data.length);
                client_1.DevConnect.safeSend('client:ws_frame', {
                    url: this.url,
                    direction: 'send',
                    opcode: isBinary ? 'binary' : 'text',
                    sizeBytes,
                    ...(isBinary ? {} : { payload: data }),
                    timestamp: Date.now(),
                });
            }
            catch (_) { }
            this._inner.send(data);
        }
        close(code, reason) {
            // Don't pre-emit close here; let the native onclose fire so we only
            // emit one close per socket. If the native onclose never fires
            // (e.g. socket was never open), fall through to ensure consumer
            // always gets a single close event.
            try {
                this._inner.close(code, reason);
            }
            catch (_) { }
            if (this._closed)
                return;
            // best-effort: if native never reported close, emit one now
            // but only if we're not already in a closing/closed state.
            if (this._inner.readyState === 3 /* CLOSED */) {
                this._closed = true;
                try {
                    client_1.DevConnect.safeSend('client:ws_close', {
                        url: this.url,
                        ...(code != null ? { code } : {}),
                        ...(reason ? { reason } : {}),
                        timestamp: Date.now(),
                    });
                }
                catch (_) { }
            }
        }
        addEventListener(type, listener, options) {
            this._inner.addEventListener(type, listener, options);
        }
        removeEventListener(type, listener, options) {
            this._inner.removeEventListener(type, listener, options);
        }
        dispatchEvent(event) {
            return this._inner.dispatchEvent(event);
        }
        // View-only properties on the inner socket.
        get readyState() { return this._inner.readyState; }
        get bufferedAmount() { return this._inner.bufferedAmount; }
        get extensions() { return this._inner.extensions; }
        get protocol() { return this._inner.protocol; }
        get binaryType() { return this._inner.binaryType; }
        set binaryType(v) { this._inner.binaryType = v; }
    }
    // Monkey-patch the global. RN's WebSocket lives on the global, so
    // callers like `new WebSocket(url)` automatically get our wrapper.
    let installedWrapper = null;
    try {
        installedWrapper = DevConnectWrappedWebSocket;
        global.WebSocket = installedWrapper;
    }
    catch (_) {
        // Some RN versions freeze globals — fall back to a no-op install.
        _installed = false;
        return () => { };
    }
    return () => {
        // Only restore if `global.WebSocket` is still our wrapper. If a later
        // install replaced it, leave that one in place.
        try {
            if (global.WebSocket === installedWrapper && _originalWebSocket) {
                global.WebSocket = _originalWebSocket;
            }
        }
        catch (_) { }
        _installed = false;
    };
}
