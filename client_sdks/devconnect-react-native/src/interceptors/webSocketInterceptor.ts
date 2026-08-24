import { DevConnect } from '../client';

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
let _originalWebSocket: typeof WebSocket | null = null;
let _installed = false;

export function installWebSocketInterceptor(): () => void {
  if (_installed) return () => {};
  _installed = true;

  _originalWebSocket = (global as any).WebSocket;
  if (!_originalWebSocket) {
    _installed = false;
    return () => {};
  }

  const Original = _originalWebSocket;

  class DevConnectWrappedWebSocket {
    public readonly url: string;
    private _inner: WebSocket;
    private _closed = false;
    private _onerrorDone = false;

    public onopen: ((ev: Event) => any) | null = null;
    public onmessage: ((ev: MessageEvent) => any) | null = null;
    public onerror: ((ev: Event) => any) | null = null;
    public onclose: ((ev: CloseEvent) => any) | null = null;

    constructor(url: string, protocols?: string | string[]) {
      this.url = url;
      this._inner = protocols !== undefined
        ? new Original(url, protocols)
        : new Original(url);

      // Forward lifecycle events.
      this._inner.onopen = (ev: Event) => {
        try {
          DevConnect.safeSend('client:ws_open', {
            url,
            openedAt: Date.now(),
            protocol: this._inner.protocol,
          });
        } catch (_) {}
        this.onopen?.(ev);
      };

      this._inner.onmessage = (ev: MessageEvent) => {
        try {
          const data = ev.data;
          const isBinary = typeof data !== 'string';
          const sizeBytes = isBinary
            ? ((data as any)?.byteLength ?? (data as any)?.size ?? 0)
            : ((data as string).length);
          DevConnect.safeSend('client:ws_frame', {
            url,
            direction: 'receive',
            opcode: isBinary ? 'binary' : 'text',
            sizeBytes,
            ...(isBinary ? {} : { payload: data }),
            timestamp: Date.now(),
          });
        } catch (_) {}
        this.onmessage?.(ev);
      };

      this._inner.onerror = (ev: Event) => {
        // Don't double-emit close on a bare error; native onclose will follow.
        this._onerrorDone = true;
        try {
          DevConnect.safeSend('client:ws_close', {
            url,
            error: (ev as any)?.message ?? 'WebSocket error',
            timestamp: Date.now(),
          });
        } catch (_) {}
        this.onerror?.(ev);
      };

      this._inner.onclose = (ev: CloseEvent) => {
        this.readyState; // touch
        if (this._closed) return;
        this._closed = true;
        try {
          DevConnect.safeSend('client:ws_close', {
            url,
            code: ev.code,
            reason: ev.reason,
            timestamp: Date.now(),
          });
        } catch (_) {}
        this.onclose?.(ev);
      };
    }

    send(data: string | ArrayBufferLike | Blob | ArrayBufferView): void {
      try {
        const isBinary = typeof data !== 'string';
        const sizeBytes = isBinary
          ? ((data as any)?.byteLength ?? (data as any)?.size ?? 0)
          : ((data as string).length);
        DevConnect.safeSend('client:ws_frame', {
          url: this.url,
          direction: 'send',
          opcode: isBinary ? 'binary' : 'text',
          sizeBytes,
          ...(isBinary ? {} : { payload: data }),
          timestamp: Date.now(),
        });
      } catch (_) {}
      this._inner.send(data);
    }

    close(code?: number, reason?: string): void {
      // Don't pre-emit close here; let the native onclose fire so we only
      // emit one close per socket. If the native onclose never fires
      // (e.g. socket was never open), fall through to ensure consumer
      // always gets a single close event.
      try {
        this._inner.close(code, reason);
      } catch (_) {}
      if (this._closed) return;
      // best-effort: if native never reported close, emit one now
      // but only if we're not already in a closing/closed state.
      if (this._inner.readyState === 3 /* CLOSED */) {
        this._closed = true;
        try {
          DevConnect.safeSend('client:ws_close', {
            url: this.url,
            ...(code != null ? { code } : {}),
            ...(reason ? { reason } : {}),
            timestamp: Date.now(),
          });
        } catch (_) {}
      }
    }

    addEventListener(type: string, listener: any, options?: any): void {
      this._inner.addEventListener(type, listener, options);
    }

    removeEventListener(type: string, listener: any, options?: any): void {
      this._inner.removeEventListener(type, listener, options);
    }

    dispatchEvent(event: Event): boolean {
      return this._inner.dispatchEvent(event);
    }

    // View-only properties on the inner socket.
    get readyState(): number { return this._inner.readyState; }
    get bufferedAmount(): number { return this._inner.bufferedAmount; }
    get extensions(): string { return this._inner.extensions; }
    get protocol(): string { return this._inner.protocol; }
    get binaryType(): BinaryType { return this._inner.binaryType; }
    set binaryType(v: BinaryType) { this._inner.binaryType = v; }
  }

  // Monkey-patch the global. RN's WebSocket lives on the global, so
  // callers like `new WebSocket(url)` automatically get our wrapper.
  let installedWrapper: typeof WebSocket | null = null;
  try {
    installedWrapper = DevConnectWrappedWebSocket as unknown as typeof WebSocket;
    (global as any).WebSocket = installedWrapper;
  } catch (_) {
    // Some RN versions freeze globals — fall back to a no-op install.
    _installed = false;
    return () => {};
  }

  return () => {
    // Only restore if `global.WebSocket` is still our wrapper. If a later
    // install replaced it, leave that one in place.
    try {
      if ((global as any).WebSocket === installedWrapper && _originalWebSocket) {
        (global as any).WebSocket = _originalWebSocket;
      }
    } catch (_) {}
    _installed = false;
  };
}
