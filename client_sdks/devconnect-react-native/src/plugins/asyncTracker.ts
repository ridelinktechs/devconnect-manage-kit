/**
 * DevConnect Async Operation Tracker Plugin
 *
 * Auto-tracks Redux Thunk actions, Promise-based operations.
 * Call `setupAsyncTracker()` after DevConnect.init().
 */

import { DevConnect } from '../client';

let _initialized = false;

/**
 * Redux Thunk middleware that auto-reports async actions to DevConnect.
 *
 * ```typescript
 * import { devConnectThunkTracker } from 'devconnect/client_sdks/devconnect-react-native/src/plugins/asyncTracker';
 * const store = createStore(reducer, applyMiddleware(thunk, devConnectThunkTracker));
 * ```
 */
export const devConnectThunkTracker = (store: any) => (next: any) => (action: any) => {
  // Regular action — pass through
  if (typeof action !== 'function') {
    return next(action);
  }

  // Thunk action — track as async operation
  const actionName = action.name || action.displayName || 'anonymousThunk';
  const startTime = Date.now();

  DevConnect.reportAsyncOperation({
    operationType: 'async_task',
    description: actionName,
    status: 'start',
    metadata: { source: 'redux-thunk' },
  });

  try {
    const result = action(store.dispatch, store.getState, undefined);

    // If thunk returns a promise, track resolve/reject
    if (result && typeof result.then === 'function') {
      return result.then(
        (resolved: any) => {
          DevConnect.reportAsyncOperation({
            operationType: 'async_task',
            description: actionName,
            status: 'resolve',
            duration: Date.now() - startTime,
            metadata: { source: 'redux-thunk' },
          });
          return resolved;
        },
        (error: any) => {
          DevConnect.reportAsyncOperation({
            operationType: 'async_task',
            description: actionName,
            status: 'reject',
            duration: Date.now() - startTime,
            error: error?.message ?? String(error),
            metadata: { source: 'redux-thunk' },
          });
          throw error;
        },
      );
    }

    // Sync thunk
    DevConnect.reportAsyncOperation({
      operationType: 'async_task',
      description: actionName,
      status: 'resolve',
      duration: Date.now() - startTime,
      metadata: { source: 'redux-thunk', sync: true },
    });

    return result;
  } catch (error: any) {
    DevConnect.reportAsyncOperation({
      operationType: 'async_task',
      description: actionName,
      status: 'reject',
      duration: Date.now() - startTime,
      error: error?.message ?? String(error),
      metadata: { source: 'redux-thunk' },
    });
    throw error;
  }
};

/**
 * Track any async function as an async operation.
 *
 * ```typescript
 * const data = await trackAsync('fetchUser', async () => {
 *   return await api.getUser(id);
 * });
 * ```
 */
export async function trackAsync<T>(
  description: string,
  fn: () => Promise<T>,
  operationType: string = 'async_task',
): Promise<T> {
  const startTime = Date.now();

  DevConnect.reportAsyncOperation({
    operationType: operationType as any,
    description,
    status: 'start',
  });

  try {
    const result = await fn();
    DevConnect.reportAsyncOperation({
      operationType: operationType as any,
      description,
      status: 'resolve',
      duration: Date.now() - startTime,
    });
    return result;
  } catch (error: any) {
    DevConnect.reportAsyncOperation({
      operationType: operationType as any,
      description,
      status: 'reject',
      duration: Date.now() - startTime,
      error: error?.message ?? String(error),
    });
    throw error;
  }
}
