/**
 * DevConnect Performance Monitor Plugin
 *
 * Auto-tracks: FPS, memory usage, JS thread performance, jank frames.
 * Call `startPerformanceMonitor()` after DevConnect.init().
 */

import { DevConnect } from '../client';

let _running = false;
let _frameTimer: ReturnType<typeof requestAnimationFrame> | null = null;
let _memoryTimer: ReturnType<typeof setInterval> | null = null;

interface PerformanceMonitorOptions {
  /** FPS sampling interval in ms (default: 2000) */
  fpsInterval?: number;
  /** Memory sampling interval in ms (default: 5000) */
  memoryInterval?: number;
  /** Report jank frames above this threshold in ms (default: 32 = ~30fps) */
  jankThreshold?: number;
}

/**
 * Start automatic performance monitoring.
 *
 * ```typescript
 * import { startPerformanceMonitor } from 'devconnect/client_sdks/devconnect-react-native/src/plugins/performanceMonitor';
 * startPerformanceMonitor();
 * ```
 */
export function startPerformanceMonitor(opts: PerformanceMonitorOptions = {}): void {
  if (_running) return;
  _running = true;

  const fpsInterval = opts.fpsInterval ?? 2000;
  const memoryInterval = opts.memoryInterval ?? 5000;
  const jankThreshold = opts.jankThreshold ?? 32;

  // ---- FPS Monitor ----
  let frameCount = 0;
  let lastTime = performance.now();
  let lastFrameTime = lastTime;

  const measureFrame = () => {
    if (!_running) return;

    const now = performance.now();
    const frameDelta = now - lastFrameTime;
    lastFrameTime = now;
    frameCount++;

    // Detect jank frame
    if (frameDelta > jankThreshold) {
      DevConnect.reportPerformanceMetric({
        metricType: 'jank_frame',
        value: Math.round(frameDelta * 10) / 10,
        label: `Slow frame: ${Math.round(frameDelta)}ms`,
        metadata: { threshold: jankThreshold },
      });
    }

    // Report FPS every interval
    const elapsed = now - lastTime;
    if (elapsed >= fpsInterval) {
      const fps = Math.round((frameCount / elapsed) * 1000 * 10) / 10;
      DevConnect.reportPerformanceMetric({
        metricType: 'fps',
        value: fps,
        label: 'JS Thread FPS',
      });
      frameCount = 0;
      lastTime = now;
    }

    _frameTimer = requestAnimationFrame(measureFrame);
  };

  // Start FPS tracking after 3 frames (layout stable)
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        _frameTimer = requestAnimationFrame(measureFrame);
      });
    });
  });

  // ---- Memory Monitor ----
  _memoryTimer = setInterval(() => {
    if (!_running) return;

    // React Native performance API
    const perf = (global as any).performance;
    if (perf?.memory) {
      DevConnect.reportPerformanceMetric({
        metricType: 'memory_usage',
        value: Math.round(perf.memory.usedJSHeapSize / 1024 / 1024 * 10) / 10,
        label: 'JS Heap Used (MB)',
        metadata: {
          totalJSHeapSize: perf.memory.totalJSHeapSize,
          jsHeapSizeLimit: perf.memory.jsHeapSizeLimit,
        },
      });
    }

    // Hermes-specific GC stats
    if ((global as any).HermesInternal?.getRuntimeProperties) {
      try {
        const props = (global as any).HermesInternal.getRuntimeProperties();
        const heapSize = props['Heap size'] ?? props['js_heapSize'];
        const allocatedBytes = props['Allocated bytes'] ?? props['js_allocatedBytes'];
        if (heapSize != null) {
          DevConnect.reportPerformanceMetric({
            metricType: 'memory_usage',
            value: Math.round(Number(heapSize) / 1024 / 1024 * 10) / 10,
            label: 'Hermes Heap (MB)',
            metadata: {
              allocatedBytes,
              gcCount: props['Num GCs'] ?? props['js_numGCs'],
            },
          });
        }
      } catch (_) {}
    }
  }, memoryInterval);
}

/**
 * Stop performance monitoring.
 */
export function stopPerformanceMonitor(): void {
  _running = false;
  if (_frameTimer != null) {
    cancelAnimationFrame(_frameTimer);
    _frameTimer = null;
  }
  if (_memoryTimer != null) {
    clearInterval(_memoryTimer);
    _memoryTimer = null;
  }
}
