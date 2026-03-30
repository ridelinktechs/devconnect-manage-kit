/**
 * DevConnect Performance Monitor Plugin
 *
 * Auto-tracks: FPS, CPU, memory, jank frames, frame timing,
 * startup time, battery, thread count, memory allocation rate.
 * Call `startPerformanceMonitor()` after DevConnect.init().
 */

import { DevConnect } from '../client';
import { NativeModules } from 'react-native';

// Optional: battery from react-native-device-info (auto-detected if installed)
let _DeviceInfo: any = null;
try { _DeviceInfo = require('react-native-device-info'); } catch (_) {}
let _ExpoBattery: any = null;
try { _ExpoBattery = require('expo-battery'); } catch (_) {}

let _running = false;
let _frameTimer: ReturnType<typeof requestAnimationFrame> | null = null;
let _memoryTimer: ReturnType<typeof setInterval> | null = null;
let _cpuTimer: ReturnType<typeof setInterval> | null = null;
let _systemTimer: ReturnType<typeof setInterval> | null = null;
let _startupReported = false;
let _lastMemoryMB = 0;

interface PerformanceMonitorOptions {
  /** FPS sampling interval in ms (default: 2000) */
  fpsInterval?: number;
  /** Memory sampling interval in ms (default: 5000) */
  memoryInterval?: number;
  /** CPU sampling interval in ms (default: 3000) */
  cpuInterval?: number;
  /** System metrics interval in ms (default: 10000) */
  systemInterval?: number;
  /** Report jank frames above this threshold in ms (default: 32 = ~30fps) */
  jankThreshold?: number;
}

const _initTime = performance.now();

/**
 * Start automatic performance monitoring.
 */
export function startPerformanceMonitor(opts: PerformanceMonitorOptions = {}): void {
  if (_running) return;
  _running = true;

  const fpsInterval = opts.fpsInterval ?? 2000;
  const memoryInterval = opts.memoryInterval ?? 5000;
  const jankThreshold = opts.jankThreshold ?? 32;

  // ---- Startup Time ----
  if (!_startupReported) {
    // Report after first interactive frame
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        const startupMs = Math.round(performance.now() - _initTime);
        DevConnect.reportPerformanceMetric({
          metricType: 'startup_time',
          value: startupMs,
          label: `App startup: ${startupMs}ms`,
        });
        _startupReported = true;
      });
    });
  }

  // ---- FPS + Frame Timing Monitor ----
  let frameCount = 0;
  let lastTime = performance.now();
  let lastFrameTime = lastTime;
  let totalBuildTime = 0;

  const measureFrame = () => {
    if (!_running) return;

    const now = performance.now();
    const frameDelta = now - lastFrameTime;
    lastFrameTime = now;
    frameCount++;
    totalBuildTime += frameDelta;

    // Report individual frame build time (every frame)
    DevConnect.reportPerformanceMetric({
      metricType: 'frame_build_time',
      value: Math.round(frameDelta * 10) / 10,
      label: `Frame: ${Math.round(frameDelta)}ms`,
    });

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
      totalBuildTime = 0;
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

  // ---- Memory Monitor + Allocation Rate ----
  _memoryTimer = setInterval(() => {
    if (!_running) return;
    let reported = false;
    let currentMB = 0;

    // 1) Hermes getInstrumentedStats
    if ((global as any).HermesInternal?.getInstrumentedStats) {
      try {
        const stats = (global as any).HermesInternal.getInstrumentedStats();
        const heapSize = stats.js_totalAllocatedBytes ?? stats.js_heapSize ?? stats.js_allocatedBytes;
        if (heapSize != null && Number(heapSize) > 0) {
          currentMB = Math.round(Number(heapSize) / 1024 / 1024 * 10) / 10;
          DevConnect.reportPerformanceMetric({
            metricType: 'memory_usage',
            value: currentMB,
            label: 'Hermes Heap (MB)',
            metadata: {
              heapSize: stats.js_heapSize,
              allocatedBytes: stats.js_allocatedBytes,
              externalBytes: stats.js_externalBytes,
              gcCount: stats.js_numGCs,
            },
          });
          reported = true;
        }
      } catch (_) {}
    }

    // 2) Hermes getRuntimeProperties
    if (!reported && (global as any).HermesInternal?.getRuntimeProperties) {
      try {
        const props = (global as any).HermesInternal.getRuntimeProperties();
        const heapSize = props['Heap size'] ?? props['js_heapSize'];
        const allocatedBytes = props['Allocated bytes'] ?? props['js_allocatedBytes'];
        const value = allocatedBytes ?? heapSize;
        if (value != null && Number(value) > 0) {
          currentMB = Math.round(Number(value) / 1024 / 1024 * 10) / 10;
          DevConnect.reportPerformanceMetric({
            metricType: 'memory_usage',
            value: currentMB,
            label: 'Hermes Heap (MB)',
            metadata: { heapSize, allocatedBytes, gcCount: props['Num GCs'] ?? props['js_numGCs'] },
          });
          reported = true;
        }
      } catch (_) {}
    }

    // 3) Chrome V8 performance.memory
    if (!reported) {
      const perf = (global as any).performance;
      if (perf?.memory?.usedJSHeapSize > 0) {
        currentMB = Math.round(perf.memory.usedJSHeapSize / 1024 / 1024 * 10) / 10;
        DevConnect.reportPerformanceMetric({
          metricType: 'memory_usage',
          value: currentMB,
          label: 'JS Heap Used (MB)',
          metadata: { totalJSHeapSize: perf.memory.totalJSHeapSize, jsHeapSizeLimit: perf.memory.jsHeapSizeLimit },
        });
        reported = true;
      }
    }

    // 4) Node.js process.memoryUsage
    if (!reported && typeof process !== 'undefined' && (process as any).memoryUsage) {
      try {
        const mem = (process as any).memoryUsage();
        if (mem.heapUsed > 0) {
          currentMB = Math.round(mem.heapUsed / 1024 / 1024 * 10) / 10;
          DevConnect.reportPerformanceMetric({
            metricType: 'memory_usage',
            value: currentMB,
            label: 'Node Heap (MB)',
            metadata: { heapTotal: mem.heapTotal, rss: mem.rss, external: mem.external },
          });
          reported = true;
        }
      } catch (_) {}
    }

    // Memory allocation rate (MB/s)
    if (currentMB > 0 && _lastMemoryMB > 0) {
      const deltaMB = currentMB - _lastMemoryMB;
      const ratePerSec = Math.round(deltaMB / (memoryInterval / 1000) * 100) / 100;
      DevConnect.reportPerformanceMetric({
        metricType: 'memory_allocation_rate',
        value: ratePerSec,
        label: `${ratePerSec >= 0 ? '+' : ''}${ratePerSec} MB/s`,
      });
    }
    _lastMemoryMB = currentMB;
  }, memoryInterval);

  // ---- CPU Usage Estimator ----
  const cpuInterval = opts.cpuInterval ?? 3000;
  let cpuLastCheck = performance.now();
  let cpuBusyTime = 0;
  let cpuSampleCount = 0;

  const cpuSampler = () => {
    if (!_running) return;
    const now = performance.now();
    const delta = now - cpuLastCheck;
    cpuLastCheck = now;
    if (delta > 20) {
      cpuBusyTime += Math.min(delta, 100);
    }
    cpuSampleCount++;
    requestAnimationFrame(cpuSampler);
  };
  requestAnimationFrame(cpuSampler);

  _cpuTimer = setInterval(() => {
    if (!_running || cpuSampleCount === 0) return;
    const usage = Math.min(100, Math.round((cpuBusyTime / cpuInterval) * 100 * 10) / 10);
    DevConnect.reportPerformanceMetric({
      metricType: 'cpu_usage',
      value: usage,
      label: 'JS Thread Utilization (%)',
      metadata: { busyTimeMs: Math.round(cpuBusyTime), samples: cpuSampleCount },
    });
    cpuBusyTime = 0;
    cpuSampleCount = 0;
  }, cpuInterval);

  // ---- System Metrics (battery, thread count) ----
  const systemInterval = opts.systemInterval ?? 10000;
  _systemTimer = setInterval(() => {
    if (!_running) return;

    // Battery level
    try {
      let batteryReported = false;
      const reportBattery = (level: number, charging?: boolean) => {
        if (batteryReported) return;
        batteryReported = true;
        // -1 = emulator/simulator (no battery hardware)
        if (level < 0) {
          DevConnect.reportPerformanceMetric({
            metricType: 'battery_level',
            value: -1,
            label: 'Battery: N/A (emulator)',
            metadata: { emulator: true },
          });
          return;
        }
        const pct = level <= 1 ? Math.round(level * 100) : Math.round(level);
        DevConnect.reportPerformanceMetric({
          metricType: 'battery_level',
          value: pct,
          label: `Battery: ${pct}%${charging ? ' (charging)' : ''}`,
          metadata: charging != null ? { charging } : {},
        });
      };

      if (_DeviceInfo?.getBatteryLevel) {
        _DeviceInfo.getBatteryLevel().then((level: number) => reportBattery(level)).catch(() => {});
      } else if (_ExpoBattery?.getBatteryLevelAsync) {
        _ExpoBattery.getBatteryLevelAsync().then((level: number) => reportBattery(level)).catch(() => {});
      } else {
        const rnDI = NativeModules.RNDeviceInfo;
        if (rnDI?.getBatteryLevel) {
          rnDI.getBatteryLevel().then((level: number) => reportBattery(level)).catch(() => {});
        }
      }
    } catch (_) {}

    // Thread count (JS is single-threaded, native threads not accessible)
    DevConnect.reportPerformanceMetric({
      metricType: 'thread_count',
      value: 1,
      label: 'JS Thread',
      metadata: { note: 'JS single-thread; native threads not accessible from JS' },
    });
  }, systemInterval);
}

/**
 * Stop performance monitoring.
 */
export function stopPerformanceMonitor(): void {
  _running = false;
  if (_frameTimer != null) { cancelAnimationFrame(_frameTimer); _frameTimer = null; }
  if (_memoryTimer != null) { clearInterval(_memoryTimer); _memoryTimer = null; }
  if (_cpuTimer != null) { clearInterval(_cpuTimer); _cpuTimer = null; }
  if (_systemTimer != null) { clearInterval(_systemTimer); _systemTimer = null; }
}
