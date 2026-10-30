import { DevConnect } from '../client';

/** The last reported state with its serialized copy, reused as the next action's previous state. */
let lastReported: { state: any; json: Record<string, any> } | null = null;

/**
 * Redux middleware that auto-reports all dispatched actions and state changes.
 *
 * Usage:
 * ```typescript
 * import { createStore, applyMiddleware } from 'redux';
 * import { devConnectReduxMiddleware } from 'devconnect-react-native';
 *
 * const store = createStore(
 *   rootReducer,
 *   applyMiddleware(devConnectReduxMiddleware)
 * );
 * ```
 *
 * Works with Redux Toolkit too:
 * ```typescript
 * const store = configureStore({
 *   reducer: rootReducer,
 *   middleware: (getDefault) => getDefault().concat(devConnectReduxMiddleware),
 * });
 * ```
 */
export const devConnectReduxMiddleware = (store: any) => (next: any) => (action: any) => {
  const previousState = store.getState();

  const result = next(action);

  if (!DevConnect.isListening()) return result;

  const nextState = store.getState();

  try {
    // Calculate simple diff
    const diff = calculateDiff(previousState, nextState);
    const serializedPrevious = lastReported && lastReported.state === previousState ? lastReported.json : safeSerialize(previousState);
    lastReported = {
      state: nextState,
      json: nextState === previousState ? serializedPrevious : safeSerialize(nextState),
    };

    DevConnect.reportStateChange({
      stateManager: 'redux',
      action: typeof action === 'object' ? action.type ?? 'unknown' : String(action),
      previousState: serializedPrevious,
      nextState: lastReported.json,
      diff,
    });
  } catch (_) {}

  return result;
};

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

  // Check for additions and changes
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
        depth < 10 // limit recursion
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
    // Limit depth to prevent circular references
    return JSON.parse(JSON.stringify(obj, null, 0));
  } catch (_) {
    return { _error: 'Could not serialize state' };
  }
}
