/**
 * DevConnect App Benchmark Plugin
 *
 * Auto-benchmarks: app startup, screen transitions, interactions.
 * Automatically called by DevConnect.init() when autoBenchmark is true.
 */

import { DevConnect } from '../client';
import { AppState } from 'react-native';

let _startupDone = false;
let _appStateDone = false;

interface AppBenchmarkOptions {
  /** Track app startup time (default: true) */
  trackStartup?: boolean;
  /** Track app state changes (default: true) */
  trackAppState?: boolean;
}

/**
 * Wait for first render using requestAnimationFrame chain.
 * Waits for 3 consecutive frames to ensure layout is stable.
 */
function waitForFirstRender(): Promise<void> {
  return new Promise((resolve) => {
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          resolve();
        });
      });
    });
  });
}

/**
 * Setup automatic app benchmarking.
 *
 * ```typescript
 * import { setupAppBenchmark } from 'devconnect/client_sdks/devconnect-react-native/src/plugins/appBenchmark';
 * setupAppBenchmark();
 * ```
 */
export function setupAppBenchmark(opts: AppBenchmarkOptions = {}): void {
  const trackStartup = opts.trackStartup ?? true;
  const trackAppState = opts.trackAppState ?? true;

  // ---- App Startup Benchmark ----
  if (trackStartup && !_startupDone) {
    _startupDone = true;

    DevConnect.benchmark('App Startup');
    DevConnect.benchmarkStep('App Startup', 'JS Bundle Loaded');

    waitForFirstRender().then(() => {
      DevConnect.benchmarkStep('App Startup', 'First Render Complete');

      // One more frame to confirm fully interactive
      requestAnimationFrame(() => {
        DevConnect.benchmarkStep('App Startup', 'Fully Interactive');
        DevConnect.benchmarkStop('App Startup');
      });
    });
  }

  // ---- App State Benchmark (background/foreground) ----
  if (trackAppState && !_appStateDone) {
    _appStateDone = true;
    let backgroundTime = 0;

    AppState.addEventListener('change', (state) => {
      if (state === 'background') {
        backgroundTime = Date.now();
        DevConnect.benchmark('App Background');
        DevConnect.benchmarkStep('App Background', 'Entered Background');
      } else if (state === 'active' && backgroundTime > 0) {
        DevConnect.benchmarkStep('App Background', 'Returned to Foreground');
        DevConnect.benchmarkStop('App Background');
        backgroundTime = 0;
      }
    });
  }
}

/**
 * Benchmark a screen render.
 * Call at the start of a screen component, returns a stop function.
 *
 * ```typescript
 * // In your screen component:
 * useEffect(() => {
 *   const stop = benchmarkScreen('HomeScreen');
 *   return stop; // auto-stop on unmount if not already stopped
 * }, []);
 * ```
 */
export function benchmarkScreen(screenName: string): () => void {
  const title = `Screen: ${screenName}`;
  DevConnect.benchmark(title);
  DevConnect.benchmarkStep(title, 'Component Mount');

  let stopped = false;

  waitForFirstRender().then(() => {
    if (!stopped) {
      DevConnect.benchmarkStep(title, 'Render Complete');
      requestAnimationFrame(() => {
        if (!stopped) {
          DevConnect.benchmarkStep(title, 'First Paint');
          DevConnect.benchmarkStop(title);
          stopped = true;
        }
      });
    }
  });

  return () => {
    if (!stopped) {
      DevConnect.benchmarkStop(title);
      stopped = true;
    }
  };
}

/**
 * Benchmark an async operation (API call, data processing, etc.).
 *
 * ```typescript
 * const result = await benchmarkAsync('fetchUserData', async () => {
 *   return await api.getUser(userId);
 * });
 * ```
 */
export async function benchmarkAsync<T>(
  title: string,
  fn: () => Promise<T>,
): Promise<T> {
  DevConnect.benchmark(title);
  DevConnect.benchmarkStep(title, 'Start');
  try {
    const result = await fn();
    DevConnect.benchmarkStep(title, 'Complete');
    DevConnect.benchmarkStop(title);
    return result;
  } catch (error) {
    DevConnect.benchmarkStep(title, 'Error');
    DevConnect.benchmarkStop(title);
    throw error;
  }
}
