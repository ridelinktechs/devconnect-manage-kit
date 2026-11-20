import { DevConnect } from '../../client';

/**
 * Zustand middleware that auto-reports state changes to DevConnect.
 *
 * Usage:
 * ```typescript
 * import { create } from 'zustand';
 * import { devConnectMiddleware } from 'devconnect-react-native';
 *
 * const useStore = create(devConnectMiddleware((set) => ({
 *   count: 0,
 *   increment: () => set((s) => ({ count: s.count + 1 })),
 * }), 'MyStore'));
 * ```
 *
 * With multiple stores, give each a unique name:
 * ```typescript
 * const useAuthStore = create(devConnectMiddleware(authStoreCreator, 'AuthStore'));
 * const useCartStore = create(devConnectMiddleware(cartStoreCreator, 'CartStore'));
 * ```
 */
export function devConnectMiddleware<T extends object>(
  storeCreator: (
    set: (partial: T | Partial<T> | ((state: T) => T | Partial<T>), replace?: boolean) => void,
    get: () => T,
    api: any,
  ) => T,
  storeName: string = 'ZustandStore',
): (set: any, get: any, api: any) => T {
  return (set: any, get: any, api: any): T => {
    let lastReported: { state: any; json: Record<string, any> } | null = null;
    const trackedSet = (
      partial: T | Partial<T> | ((state: T) => T | Partial<T>),
      replace?: boolean,
    ) => {
      const rawPrevious = get();

      set(partial, replace);

      if (!DevConnect.isListening()) return;

      const previousState = lastReported && lastReported.state === rawPrevious ? lastReported.json : safeSerialize(rawPrevious);
      const rawNext = get();
      const nextState = safeSerialize(rawNext);
      lastReported = { state: rawNext, json: nextState };

      try {
        const actionName = inferActionName(partial);
        const diff = calculateDiff(previousState, nextState);

        DevConnect.reportStateChange({
          stateManager: `zustand:${storeName}`,
          action: actionName,
          previousState,
          nextState,
          diff,
        });
      } catch (_) {}
    };

    return storeCreator(trackedSet, get, api);
  };
}

function inferActionName(partial: any): string {
  if (typeof partial === 'function') {
    return partial.name || 'anonymous setter';
  }
  if (typeof partial === 'object' && partial !== null) {
    const keys = Object.keys(partial);
    if (keys.length <= 3) return `set ${keys.join(', ')}`;
    return `set ${keys.length} fields`;
  }
  return 'set';
}

function calculateDiff(
  prev: Record<string, any>,
  next: Record<string, any>,
  path = '',
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
        calculateDiff(prevVal, nextVal, currentPath, diffs, depth + 1);
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

function safeSerialize(obj: any): Record<string, any> {
  try {
    return JSON.parse(JSON.stringify(obj));
  } catch (_) {
    return { _error: 'Could not serialize state' };
  }
}
