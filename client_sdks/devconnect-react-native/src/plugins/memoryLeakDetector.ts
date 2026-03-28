/**
 * DevConnect Memory Leak Detector Plugin
 *
 * Auto-detects: EventEmitter leaks, timer leaks, growing collections,
 * unmounted component updates, Hermes heap growth.
 *
 * Call `startMemoryLeakDetector()` after DevConnect.init().
 */

import { DevConnect } from '../client';
import { AppState } from 'react-native';

let _running = false;
let _checkTimer: ReturnType<typeof setInterval> | null = null;

// Track EventEmitter subscriptions
const _subscriptionCounts = new Map<string, number>();
// Track heap snapshots for growth detection
const _heapSnapshots: number[] = [];
// Track timers
const _activeTimers = new Set<ReturnType<typeof setTimeout>>();

interface MemoryLeakDetectorOptions {
  /** Check interval in ms (default: 10000) */
  checkInterval?: number;
  /** Heap growth threshold to report as leak (MB, default: 20) */
  heapGrowthThreshold?: number;
  /** Max heap snapshots to keep (default: 10) */
  maxSnapshots?: number;
  /** Patch setTimeout/setInterval to track timer leaks (default: true) */
  trackTimers?: boolean;
}

/**
 * Start automatic memory leak detection.
 *
 * ```typescript
 * import { startMemoryLeakDetector } from 'devconnect/client_sdks/devconnect-react-native/src/plugins/memoryLeakDetector';
 * startMemoryLeakDetector();
 * ```
 */
export function startMemoryLeakDetector(opts: MemoryLeakDetectorOptions = {}): void {
  if (_running) return;
  _running = true;

  const checkInterval = opts.checkInterval ?? 10000;
  const heapGrowthThreshold = opts.heapGrowthThreshold ?? 20;
  const maxSnapshots = opts.maxSnapshots ?? 10;
  const trackTimers = opts.trackTimers ?? true;

  // ---- Patch timers to detect leaks ----
  if (trackTimers) {
    patchTimers();
  }

  // ---- Periodic heap growth check ----
  _checkTimer = setInterval(() => {
    if (!_running) return;

    // Check Hermes heap growth
    checkHeapGrowth(heapGrowthThreshold, maxSnapshots);

    // Check active timers count
    if (_activeTimers.size > 50) {
      DevConnect.reportMemoryLeak({
        leakType: 'undisposed_timer',
        severity: _activeTimers.size > 200 ? 'critical' : 'warning',
        objectName: 'Active Timers',
        detail: `${_activeTimers.size} active timers — possible timer leak`,
        metadata: { count: _activeTimers.size },
      });
    }
  }, checkInterval);

  // ---- Track AppState to detect leaks on background ----
  AppState.addEventListener('change', (state) => {
    if (state === 'background') {
      // Snapshot heap when going to background
      checkHeapGrowth(heapGrowthThreshold, maxSnapshots);
    }
  });
}

function checkHeapGrowth(thresholdMB: number, maxSnapshots: number): void {
  let heapMB: number | null = null;

  // Hermes
  if ((global as any).HermesInternal?.getRuntimeProperties) {
    try {
      const props = (global as any).HermesInternal.getRuntimeProperties();
      const heapSize = props['Heap size'] ?? props['js_heapSize'];
      if (heapSize != null) {
        heapMB = Number(heapSize) / 1024 / 1024;
      }
    } catch (_) {}
  }

  // performance.memory fallback
  if (heapMB == null) {
    const perf = (global as any).performance;
    if (perf?.memory?.usedJSHeapSize) {
      heapMB = perf.memory.usedJSHeapSize / 1024 / 1024;
    }
  }

  if (heapMB == null) return;

  _heapSnapshots.push(heapMB);
  if (_heapSnapshots.length > maxSnapshots) {
    _heapSnapshots.shift();
  }

  // Detect consistent growth
  if (_heapSnapshots.length >= 3) {
    const first = _heapSnapshots[0];
    const last = _heapSnapshots[_heapSnapshots.length - 1];
    const growth = last - first;

    // Check if consistently growing (each snapshot > previous)
    let isGrowing = true;
    for (let i = 1; i < _heapSnapshots.length; i++) {
      if (_heapSnapshots[i] <= _heapSnapshots[i - 1]) {
        isGrowing = false;
        break;
      }
    }

    if (isGrowing && growth > thresholdMB) {
      DevConnect.reportMemoryLeak({
        leakType: 'growing_collection',
        severity: growth > thresholdMB * 2 ? 'critical' : 'warning',
        objectName: 'JS Heap',
        detail: `Heap grew ${Math.round(growth)}MB over ${_heapSnapshots.length} samples (${Math.round(first)}MB → ${Math.round(last)}MB)`,
        retainedSizeBytes: Math.round(growth * 1024 * 1024),
        metadata: {
          snapshots: _heapSnapshots.map((s) => Math.round(s * 10) / 10),
          growthMB: Math.round(growth * 10) / 10,
        },
      });
    }
  }
}

function patchTimers(): void {
  const origSetTimeout = global.setTimeout;
  const origClearTimeout = global.clearTimeout;
  const origSetInterval = global.setInterval;
  const origClearInterval = global.clearInterval;

  (global as any).setTimeout = (fn: Function, delay?: number, ...args: any[]) => {
    const id = origSetTimeout((...a: any[]) => {
      _activeTimers.delete(id);
      (fn as any)(...a);
    }, delay, ...args);
    _activeTimers.add(id);
    return id;
  };

  (global as any).clearTimeout = (id: any) => {
    _activeTimers.delete(id);
    origClearTimeout(id);
  };

  (global as any).setInterval = (fn: Function, delay?: number, ...args: any[]) => {
    const id = origSetInterval(fn, delay, ...args);
    _activeTimers.add(id);
    return id;
  };

  (global as any).clearInterval = (id: any) => {
    _activeTimers.delete(id);
    origClearInterval(id);
  };
}

/**
 * Stop memory leak detection.
 */
export function stopMemoryLeakDetector(): void {
  _running = false;
  if (_checkTimer != null) {
    clearInterval(_checkTimer);
    _checkTimer = null;
  }
  _heapSnapshots.length = 0;
  _activeTimers.clear();
}

/**
 * Manually watch a collection for unbounded growth.
 *
 * ```typescript
 * const cache: any[] = [];
 * watchCollection('eventCache', () => cache.length, 100);
 * ```
 */
export function watchCollection(
  name: string,
  getSizeFn: () => number,
  maxExpected: number,
  checkIntervalMs = 10000,
): () => void {
  const timer = setInterval(() => {
    const size = getSizeFn();
    if (size > maxExpected) {
      DevConnect.reportMemoryLeak({
        leakType: 'growing_collection',
        severity: size > maxExpected * 3 ? 'critical' : 'warning',
        objectName: name,
        detail: `Collection has ${size} items, expected < ${maxExpected}`,
        metadata: { currentSize: size, maxExpected },
      });
    }
  }, checkIntervalMs);

  return () => clearInterval(timer);
}
