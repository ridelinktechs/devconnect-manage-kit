import { DevConnect } from '../client';

/**
 * Integrates `@apollo/client` with DevConnect.
 *
 * Emits a `client:state:snapshot` of `cache.extract()` on startup and when it
 * changed (checked every N ms while the desktop is connected), truncated to
 * 1 MB (per spec "Truncate to first 1 MB with `…` suffix;
 * emit `metadata.truncated = true`").
 *
 * The cache is not watched: Apollo's `cache.watch()` needs a query and a
 * callback (there is no "watch everything"), and a watch without them makes
 * every cache write throw.
 *
 * Usage:
 * ```typescript
 * import { ApolloClient, InMemoryCache } from '@apollo/client';
 * import { setupApolloDevConnect } from 'devconnect-react-native';
 *
 * const apollo = new ApolloClient({ cache: new InMemoryCache(), ... });
 * const stop = setupApolloDevConnect(apollo);
 * // later: stop();
 * ```
 */
export interface ApolloIntegrationOptions {
  /**
   * If > 0, check `cache.extract()` every N milliseconds while the desktop
   * is connected and emit a `client:state:snapshot` when it changed. Default: 1000.
   * Set to 0 to disable periodic snapshots.
   */
  snapshotIntervalMs?: number;
  /**
   * Cap on snapshot payload size in bytes. Default: 1_048_576 (1 MB).
   * Per spec: "Truncate to first 1 MB with `…` suffix".
   */
  maxSnapshotBytes?: number;
  /**
   * If true, emit a single snapshot on startup. Default: true.
   */
  emitInitialSnapshot?: boolean;
}

/**
 * Build a snapshot payload from the cache's JSON, capped at `maxBytes`
 * UTF-8 bytes. Returns the payload plus a flag indicating whether the
 * data was truncated and the original UTF-8 byte size.
 */
function buildCappedSnapshot(json: string, maxBytes: number): { state: any; truncated: boolean; originalSize: number } {
  const encoder = new TextEncoder();
  const originalSize = encoder.encode(json).byteLength;
  if (originalSize <= maxBytes) {
    return { state: JSON.parse(json), truncated: false, originalSize };
  }
  // Truncate at a valid code-point boundary, keeping `…` suffix budget.
  const suffix = '…';
  const budget = Math.max(0, maxBytes - encoder.encode(suffix).byteLength);
  const { read } = encoder.encodeInto(json, new Uint8Array(budget));
  return {
    state: json.slice(0, read) + suffix,
    truncated: true,
    originalSize,
  };
}

export function setupApolloDevConnect(
  apolloClient: any,
  options: ApolloIntegrationOptions = {},
): () => void {
  if (!apolloClient || typeof apolloClient.cache?.watch !== 'function') {
    // Not a real Apollo client — silently no-op.
    return () => {};
  }

  const cache = apolloClient.cache;
  const snapshotIntervalMs = options.snapshotIntervalMs ?? 1000;
  const maxSnapshotBytes = options.maxSnapshotBytes ?? 1_048_576;
  const emitInitial = options.emitInitialSnapshot ?? true;

  /** JSON of the last snapshot sent; reset while disconnected so a reconnected desktop gets one again. */
  let lastJson: string | undefined;
  const sendSnapshot = () => {
    try {
      const raw = cache.extract?.();
      if (!raw) return;
      const json = safeStringify(raw);
      if (json === lastJson) return;
      lastJson = json;
      const { state, truncated, originalSize } = buildCappedSnapshot(json, maxSnapshotBytes);
      DevConnect.safeSend('client:state:snapshot', {
        stateManager: 'Apollo',
        state,
        ...(truncated ? { metadata: { truncated: true, originalSize } } : {}),
      });
    } catch (_) {}
  };

  // Periodic `cache.extract()` snapshot.
  let intervalHandle: ReturnType<typeof setInterval> | null = null;
  if (snapshotIntervalMs > 0) {
    intervalHandle = setInterval(() => {
      if (DevConnect.isListening()) sendSnapshot();
      else lastJson = undefined;
    }, snapshotIntervalMs);
  }

  // Initial snapshot — also capped.
  if (emitInitial) sendSnapshot();

  return () => {
    if (intervalHandle) {
      clearInterval(intervalHandle);
      intervalHandle = null;
    }
  };
}

function safeStringify(value: any): string {
  try {
    return JSON.stringify(value);
  } catch (_) {
    return JSON.stringify({ _error: 'Could not serialize value' });
  }
}
