import { DevConnect } from '../client';

/**
 * Valtio proxy state observer that reports changes to DevConnect.
 *
 * Usage:
 * ```typescript
 * import { proxy, subscribe } from 'valtio';
 * import { watchValtio } from 'devconnect-react-native';
 *
 * const state = proxy({ count: 0, user: null });
 * watchValtio(state, 'AppState');
 *
 * // Now any mutations are automatically reported:
 * state.count++;
 * state.user = { name: 'Alice' };
 * ```
 *
 * Watch specific keys only:
 * ```typescript
 * watchValtio(state, 'AppState', { keys: ['count'] });
 * ```
 *
 * With custom subscribe function (if not globally available):
 * ```typescript
 * import { subscribe } from 'valtio';
 * watchValtio(state, 'AppState', { subscribe });
 * ```
 */

interface WatchValtioOptions {
  /** Provide the `subscribe` function from valtio if not resolving automatically */
  subscribe?: (proxyState: any, callback: (ops: any) => void) => () => void;
  /** Only report changes to these top-level keys */
  keys?: string[];
  /** Sync mode (default: false). If true, callback fires synchronously. */
  sync?: boolean;
}

/**
 * Watch a valtio proxy state and report all mutations to DevConnect.
 *
 * @param proxyState The valtio proxy object (created with `proxy()`)
 * @param label A label for this state in DevConnect (e.g., 'AppState', 'AuthStore')
 * @param options Optional configuration
 * @returns Unsubscribe function
 */
export function watchValtio(
  proxyState: any,
  label: string,
  options?: WatchValtioOptions,
): () => void {
  // Try to get subscribe from options, or from the valtio module on the proxy
  const subscribeFn = options?.subscribe ?? resolveSubscribe(proxyState);

  if (!subscribeFn) {
    DevConnect.warn(
      `watchValtio: Could not resolve subscribe function. ` +
      `Pass it via options: watchValtio(state, '${label}', { subscribe })`,
      'DevConnect',
    );
    return () => {};
  }

  let previousSnapshot: Record<string, any> | undefined = safeSerialize(proxyState);

  // Send initial state
  try {
    DevConnect.reportStateChange({
      stateManager: `valtio:${label}`,
      action: 'initial state',
      nextState: previousSnapshot,
    });
  } catch (_) {}

  const unsubscribe = subscribeFn(proxyState, (ops: any) => {
    if (!DevConnect.isListening()) {
      previousSnapshot = undefined;
      return;
    }
    try {
      const nextSnapshot = safeSerialize(proxyState);

      // Build diff from valtio operations if available
      const diff = buildDiff(ops, previousSnapshot ?? nextSnapshot, nextSnapshot, options?.keys);

      // Filter: if keys option is set and no relevant changes, skip
      if (options?.keys && diff.length === 0) {
        previousSnapshot = nextSnapshot;
        return;
      }

      DevConnect.reportStateChange({
        stateManager: `valtio:${label}`,
        action: inferAction(diff),
        previousState: previousSnapshot,
        nextState: nextSnapshot,
        diff,
      });

      previousSnapshot = nextSnapshot;
    } catch (_) {}
  });

  return unsubscribe;
}

/**
 * Try to resolve valtio's subscribe function from the proxy.
 */
function resolveSubscribe(proxyState: any): any {
  // valtio attaches metadata; try a dynamic require as fallback
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const valtio = require('valtio');
    return valtio.subscribe;
  } catch (_) {
    return undefined;
  }
}

function buildDiff(
  ops: any,
  prev: Record<string, any>,
  next: Record<string, any>,
  filterKeys?: string[],
): Array<Record<string, any>> {
  const diffs: Array<Record<string, any>> = [];

  // If valtio provides operation details, use them
  if (Array.isArray(ops)) {
    for (const op of ops) {
      const [opType, path, newValue, oldValue] = op;
      const pathStr = Array.isArray(path) ? path.join('.') : String(path ?? 'unknown');

      // Filter by keys if specified
      if (filterKeys) {
        const topKey = Array.isArray(path) ? String(path[0]) : pathStr.split('.')[0];
        if (!filterKeys.includes(topKey)) continue;
      }

      diffs.push({
        path: pathStr,
        operation: opType === 'delete' ? 'remove' : opType === 'set' ? 'replace' : String(opType),
        ...(oldValue !== undefined ? { oldValue: safeValue(oldValue) } : {}),
        ...(newValue !== undefined ? { newValue: safeValue(newValue) } : {}),
      });
    }
    return diffs;
  }

  // Fallback: calculate diff manually
  return calculateDiff(prev, next, '', filterKeys);
}

function calculateDiff(
  prev: Record<string, any>,
  next: Record<string, any>,
  path: string,
  filterKeys?: string[],
  diffs: Array<Record<string, any>> = [],
  depth = 0,
): Array<Record<string, any>> {
  if (prev === next) return diffs;

  if (typeof prev !== 'object' || typeof next !== 'object' || prev === null || next === null) {
    diffs.push({
      path: path || 'root',
      operation: 'replace',
      oldValue: prev,
      newValue: next,
    });
    return diffs;
  }

  const allKeys = new Set([...Object.keys(prev), ...Object.keys(next)]);
  for (const key of allKeys) {
    if (diffs.length >= 50) break;
    // Apply key filter at top level only
    if (filterKeys && !path && !filterKeys.includes(key)) continue;

    const currentPath = path ? `${path}.${key}` : key;
    const prevVal = prev[key];
    const nextVal = next[key];

    if (!(key in prev)) {
      diffs.push({ path: currentPath, operation: 'add', newValue: nextVal });
    } else if (!(key in next)) {
      diffs.push({ path: currentPath, operation: 'remove', oldValue: prevVal });
    } else if (prevVal !== nextVal) {
      if (
        typeof prevVal === 'object' &&
        typeof nextVal === 'object' &&
        prevVal !== null &&
        nextVal !== null &&
        depth < 10
      ) {
        calculateDiff(prevVal, nextVal, currentPath, undefined, diffs, depth + 1);
      } else {
        diffs.push({
          path: currentPath,
          operation: 'replace',
          oldValue: prevVal,
          newValue: nextVal,
        });
      }
    }
  }

  return diffs;
}

function inferAction(diff: Array<Record<string, any>>): string {
  if (diff.length === 0) return 'no changes';
  if (diff.length === 1) return `${diff[0].operation} ${diff[0].path}`;
  const paths = diff.map((d) => d.path);
  if (paths.length <= 3) return `update ${paths.join(', ')}`;
  return `update ${paths.length} fields`;
}

function safeSerialize(obj: any): Record<string, any> {
  try {
    return JSON.parse(JSON.stringify(obj));
  } catch (_) {
    return { _error: 'Could not serialize state' };
  }
}

function safeValue(value: any): any {
  try {
    return JSON.parse(JSON.stringify(value));
  } catch (_) {
    return String(value);
  }
}
