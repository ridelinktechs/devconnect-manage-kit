import { DevConnect } from '../client';

/**
 * Integrates `@tanstack/react-query` with DevConnect so the desktop
 * State Inspector can show every query's status, data, and cache hits.
 *
 * Usage:
 * ```typescript
 * import { QueryClient } from '@tanstack/react-query';
 * import { setupReactQueryDevConnect } from 'devconnect-react-native';
 *
 * const queryClient = new QueryClient();
 * setupReactQueryDevConnect(queryClient);
 * ```
 *
 * On every cache notification we emit a `client:state:change` event with
 * `stateManager = "ReactQuery::<queryKey>"`. We throttle per-key to a
 * max of 4 events / sec (per spec: "max 1 emit per query per 250 ms").
 */
export interface ReactQueryIntegrationOptions {
  /**
   * Per-query throttle in milliseconds. Default: 250.
   * Setting to 0 disables throttling.
   */
  throttleMs?: number;
  /**
   * If true, emit a `client:state:snapshot` for every query on startup.
   * Default: false (snapshots are expensive on large caches).
   */
  emitInitialSnapshot?: boolean;
}

export function setupReactQueryDevConnect(
  queryClient: any,
  options: ReactQueryIntegrationOptions = {},
): () => void {
  if (!queryClient || typeof queryClient.getQueryCache !== 'function') {
    // Not a real QueryClient — silently no-op.
    return () => {};
  }

  const queryCache = queryClient.getQueryCache();
  if (!queryCache || typeof queryCache.subscribe !== 'function') {
    // No way to observe cache writes — silently no-op.
    return () => {};
  }

  const throttleMs = options.throttleMs ?? 250;
  const emitInitial = options.emitInitialSnapshot ?? false;
  const lastEmitMs = new Map<string, number>();

  const unsubscribe = queryCache.subscribe((event: any) => {
    try {
      const query = event?.query;
      if (!query) return;

      const key = query.queryKey;
      const keyString = formatKey(key);
      const stateManager = `ReactQuery::${keyString}`;

      // Throttle per-key.
      const now = Date.now();
      const last = lastEmitMs.get(keyString) ?? 0;
      if (throttleMs > 0 && now - last < throttleMs) return;
      lastEmitMs.set(keyString, now);

      const queryState = query.state ?? {};
      const status = queryState.fetchStatus ?? queryState.status ?? 'unknown';
      const dataUpdatedAt = queryState.dataUpdatedAt;
      const errorUpdatedAt = queryState.errorUpdatedAt;
      const isStale = typeof query.isStale === 'function' ? query.isStale() : false;
      const observers = typeof query.getObserversCount === 'function'
        ? query.getObserversCount()
        : (Array.isArray(query.observers) ? query.observers.length : undefined);

      const nextState: Record<string, any> = {
        status,
        isStale,
        observers,
      };
      if (dataUpdatedAt) nextState.dataUpdatedAt = dataUpdatedAt;
      if (errorUpdatedAt) nextState.errorUpdatedAt = errorUpdatedAt;
      if (queryState.data !== undefined) {
        nextState.data = safeSerialize(queryState.data);
      }
      if (queryState.error) {
        nextState.error = String(queryState.error?.message ?? queryState.error);
      }

      // Map event type to a verb in `action`.
      const type: string = event?.type ?? 'updated';
      const action = `query:${keyString} ${type}`;

      DevConnect.reportStateChange({
        stateManager,
        action,
        nextState,
      });
    } catch (_) {
      // Swallow — interceptor must never break the app.
    }
  });

  if (emitInitial) {
    try {
      const queries = queryCache.getAll?.() ?? [];
      for (const q of queries) {
        const key = formatKey(q.queryKey);
        const queryState = q.state ?? {};
        DevConnect.reportStateChange({
          stateManager: `ReactQuery::${key}`,
          action: `query:${key} snapshot`,
          nextState: {
            status: queryState.fetchStatus ?? 'unknown',
            data: safeSerialize(queryState.data),
            isStale: typeof q.isStale === 'function' ? q.isStale() : false,
          },
        });
      }
    } catch (_) {}
  }

  return () => {
    try {
      unsubscribe?.();
    } catch (_) {}
    lastEmitMs.clear();
  };
}

/**
 * Deterministic, cyclic-safe serialization of a query key. Object keys are
 * sorted so `{a:1,b:2}` and `{b:2,a:1}` produce the same output.
 */
function formatKey(key: any): string {
  try {
    return stableStringify(key);
  } catch (_) {
    return '<unknown>';
  }
}

function stableStringify(value: any): string {
  const seen = new WeakSet();
  function walk(v: any): any {
    if (v === null) return null;
    if (typeof v === 'string') return v;
    if (typeof v === 'number' || typeof v === 'boolean') return v;
    if (typeof v === 'bigint') return v.toString();
    if (Array.isArray(v)) return v.map(walk);
    if (typeof v === 'object') {
      if (seen.has(v)) return '[Circular]';
      seen.add(v);
      const out: Record<string, any> = {};
      const keys = Object.keys(v).sort();
      for (const k of keys) out[k] = walk(v[k]);
      return out;
    }
    if (typeof v === 'function') return `[Function ${v.name || 'anonymous'}]`;
    if (typeof v === 'undefined') return '[undefined]';
    return String(v);
  }
  return JSON.stringify(walk(value));
}

function safeSerialize(value: any): any {
  try {
    return JSON.parse(JSON.stringify(value));
  } catch (_) {
    return { _error: 'Could not serialize value' };
  }
}
