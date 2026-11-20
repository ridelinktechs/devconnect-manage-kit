import { DevConnect, generateId } from '../../client';

/**
 * WebSocket inspector for React Native.
 *
 * Patches `global.WebSocket` so every socket constructed afterwards emits
 * `client:ws_open`, `client:ws_frame` (each sent/received frame) and exactly
 * one `client:ws_close` to the desktop, all carrying the socket's
 * `connectionId`. DevConnect's own connection is never wrapped.
 *
 * Spec (Round 3 / 3.3): "On RN: wrap `global.WebSocket` constructor."
 *
 * Usage:
 * ```typescript
 * import { installWebSocketInterceptor } from 'devconnect-manage-kit';
 * installWebSocketInterceptor();
 * ```
 *
 * Idempotent — multiple calls are safe. Returns a cleanup function that
 * restores the original constructor.
 */
let _originalWebSocket: typeof WebSocket | null = null;
let _installed = false;
/** Set while reporting, so a report sent through a wrapped socket is never reported again. */
let _reporting = false;

function report(type: string, payload: Record<string, any>): void {
  if (_reporting) return;
  _reporting = true;
  try {
    DevConnect.safeSend(type, payload);
  } catch (_) {
  } finally {
    _reporting = false;
  }
}

/** Text frames as-is with their UTF-8 size; binary frames summarised. */
function describeFrame(data: any): { opcode: string; payload: string; sizeBytes: number } {
  if (typeof data === 'string') return { opcode: 'text', payload: data, sizeBytes: utf8Length(data) };
  const size = data?.byteLength ?? data?.size ?? 0;
  return { opcode: 'binary', payload: `<binary ${size} bytes>`, sizeBytes: size };
}

/** UTF-8 byte count without TextEncoder (missing on older RN engines). */
function utf8Length(s: string): number {
  let bytes = s.length;
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    // < U+0800 takes 2 bytes; each surrogate half adds 1 (a pair is 4); the rest take 3.
    if (c >= 0x80) bytes += c < 0x800 || (c >= 0xd800 && c <= 0xdfff) ? 1 : 2;
  }
  return bytes;
}

export function installWebSocketInterceptor(): () => void {
  if (_installed) return () => {};
  _installed = true;

  _originalWebSocket = (globalThis as any).WebSocket;
  if (!_originalWebSocket) {
    _installed = false;
    return () => {};
  }

  const Original = _originalWebSocket;

  class DevConnectWrappedWebSocket {
    static readonly CONNECTING = 0;
    static readonly OPEN = 1;
    static readonly CLOSING = 2;
    static readonly CLOSED = 3;
    readonly CONNECTING = 0;
    readonly OPEN = 1;
    readonly CLOSING = 2;
    readonly CLOSED = 3;

    public readonly url: string;
    private _inner: WebSocket;
    private _connectionId = generateId();
    /** Reported with the close that follows it: one `client:ws_close` per connection. */
    private _error: string | undefined;

    public onopen: ((ev: Event) => any) | null = null;
    public onmessage: ((ev: MessageEvent) => any) | null = null;
    public onerror: ((ev: Event) => any) | null = null;
    public onclose: ((ev: CloseEvent) => any) | null = null;

    // Every argument reaches the real socket (RN's third one carries headers).
    constructor(url: string, ...rest: any[]) {
      this.url = url;
      this._inner = new (Original as any)(url, ...rest);
      const connectionId = this._connectionId;

      // Forward lifecycle events.
      this._inner.onopen = (ev: Event) => {
        report('client:ws_open', { connectionId, url });
        this.onopen?.(ev);
      };

      this._inner.onmessage = (ev: MessageEvent) => {
        report('client:ws_frame', { connectionId, url, direction: 'receive', ...describeFrame(ev.data) });
        this.onmessage?.(ev);
      };

      this._inner.onerror = (ev: Event) => {
        this._error = (ev as any)?.message ?? 'WebSocket error';
        this.onerror?.(ev);
      };

      this._inner.onclose = (ev: CloseEvent) => {
        // Undefined fields (no code, no error) are dropped when the message is serialised.
        report('client:ws_close', { connectionId, url, code: ev?.code, reason: ev?.reason, error: this._error });
        this.onclose?.(ev);
      };
    }

    send(data: string | ArrayBufferLike | Blob | ArrayBufferView): void {
      report('client:ws_frame', {
        connectionId: this._connectionId,
        url: this.url,
        direction: 'send',
        ...describeFrame(data),
      });
      this._inner.send(data);
    }

    close(code?: number, reason?: string): void {
      // The native onclose reports it — once.
      this._inner.close(code, reason);
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
    (globalThis as any).WebSocket = installedWrapper;
  } catch (_) {
    // Some RN versions freeze globals — fall back to a no-op install.
    _installed = false;
    return () => {};
  }

  return () => {
    // Only restore if `global.WebSocket` is still our wrapper. If a later
    // install replaced it, leave that one in place.
    try {
      if ((globalThis as any).WebSocket === installedWrapper && _originalWebSocket) {
        (globalThis as any).WebSocket = _originalWebSocket;
      }
    } catch (_) {}
    _installed = false;
  };
}
