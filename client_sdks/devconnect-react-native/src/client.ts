/**
 * DevConnect React Native Client
 *
 * Auto-detect desktop host via:
 * 1. Metro bundler scriptURL (like Reactotron)
 * 2. Known emulator/simulator addresses
 * 3. Subnet scanning for real devices on WiFi
 */

import { patchConsole } from './core/consolePatch';
import { _wsSend, connect } from './core/connection';
import type { DatabaseQuery, StorageAdapter } from './core/databases';
import { generateStableDeviceId } from './core/deviceId';
import { autoDetectHost } from './core/hostDiscovery';
import { _announceCommands } from './core/serverCommands';
import { generateId, safeString } from './core/util';
import { patchFetch } from './network/fetchPatch';
import { patchXHR } from './network/xhrPatch';

export { generateId, safeString };
export type { DatabaseQuery, StorageAdapter };
export { sqliteTables } from './core/databases';
export { capBody, parseBody } from './network/bodies';

interface DevConnectConfig {
  appName: string;
  appVersion?: string;
  /** Version code / build number (e.g. "42", "123") */
  versionCode?: string;
  /** Desktop IP. undefined/'auto' = auto-detect. '192.168.x.x' = manual */
  host?: string;
  /** WebSocket port (default: 9090) */
  port?: number;
  /** Auto-detect host (default: true) */
  auto?: boolean;
  enabled?: boolean;
  /** Auto-intercept fetch (default: true in __DEV__, false in production) */
  autoInterceptFetch?: boolean;
  /** Auto-intercept XMLHttpRequest (default: true in __DEV__, false in production) */
  autoInterceptXHR?: boolean;
  /** Auto-intercept console.log (default: true in __DEV__, false in production) */
  autoInterceptConsole?: boolean;
  /** Auto-start performance monitoring (default: true) */
  autoPerformance?: boolean;
  /** Auto-start memory leak detection (default: true) */
  autoMemoryLeak?: boolean;
  /** Auto-start app benchmark (default: true) */
  autoBenchmark?: boolean;
  /** Auto-start error/crash monitoring (default: true) */
  autoError?: boolean;
}

interface DCMessage {
  id: string;
  type: string;
  deviceId: string;
  timestamp: number;
  payload: Record<string, any>;
  correlationId?: string;
}

// ---- Main Class ----

export class DevConnect {
  private static instance: DevConnect | null = null;
  /** @internal */ ws: WebSocket | null = null;
  /** @internal */ config: Omit<Required<DevConnectConfig>, 'versionCode'> & { versionCode?: string };
  /** Pre-init queue: messages sent before init() is called */
  private static preInitQueue: Array<{ type: string; payload: Record<string, any> }> = [];

  /** @internal */ deviceId: string;
  /** @internal */ connected = false;
  /** @internal */ reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  /** @internal */ messageQueue: string[] = [];
  /** Messages longer than CHUNK_SIZE, sent a chunk at a time by [_sendChunk]. */
  /** @internal */ _bigMessages: string[] = [];
  /** Characters of `_bigMessages[0]` sent so far, under this id. */
  /** @internal */ _bigSent = 0;
  /** @internal */ _bigId = '';
  /** Set while a chunk waits for the desktop's ack. */
  /** @internal */ _chunkTimer: ReturnType<typeof setTimeout> | null = null;
  /** @internal */ _reduxStore: any = null;
  /** @internal */ _stateRestoreHandler: ((state: any) => void) | null = null;
  /** @internal */ _customCommandHandlers: Map<string, (args?: any) => any> = new Map();
  /** @internal */ _databases: Map<string, DatabaseQuery> = new Map();
  /** @internal */ _storages: Map<string, StorageAdapter> = new Map();
  /** Screenshot function the app registered for the Layout tab, if any. */
  /** @internal */ _screenshot: (() => Promise<string>) | null = null;
  /** Desktop-set network conditions, applied to every XHR (fetch rides on XHR). */
  /** @internal */ _throttle = { latencyMs: 0, offline: false };
  /**
   * Generic server-message subscribers (used by internal plugins).
   * Each handler receives the full parsed `msg` object and may act or
   * ignore based on `msg.type`. Handlers run synchronously inside the
   * WS receive loop, so they should be cheap and never throw — wrap
   * your own try/catch.
   */
  /** @internal */ _serverMessageHandlers: Set<(msg: any) => void> = new Set();
  /**
   * Optional app-supplied reload hook. If set, called instead of the default
   * `DevSettings.reload()` so apps can wipe in-memory state first.
   */
  /** @internal */ _reloadHandler?: () => void;
  private _benchmarks: Map<string, { title: string; startTime: number; steps: Array<{ title: string; timestamp: number }> }> = new Map();
  /** @internal */ originalFetch: typeof globalThis.fetch | null = null;
  /** @internal */ originalXHR: typeof globalThis.XMLHttpRequest | null = null;
  /** @internal */ originalConsole: { log: Function; warn: Function; error: Function; debug: Function; info: Function; trace?: Function } | null = null;
  /**
   * Map of `METHOD\0URL` keys currently in flight through the fetch
   * interceptor to the number of active concurrent requests. The XHR
   * interceptor (which React Native 0.85's fetch transport triggers
   * internally for the same call) checks this map and suppresses its
   * own duplicate report if the count is > 0.
   */
  /** @internal */ fetchInFlight: Map<string, number> = new Map();
  /** @internal */ fetchStackCount = 0;

  private constructor(config: DevConnectConfig & { resolvedHost: string }) {
    this.config = {
      appName: config.appName,
      appVersion: config.appVersion ?? '1.0.0',
      versionCode: config.versionCode ?? undefined,
      host: config.resolvedHost,
      port: config.port ?? 9090,
      auto: config.auto ?? true,
      enabled: config.enabled ?? true,
      autoInterceptFetch: config.autoInterceptFetch ?? __DEV__,
      autoInterceptXHR: config.autoInterceptXHR ?? __DEV__,
      autoInterceptConsole: config.autoInterceptConsole ?? __DEV__,
      autoPerformance: config.autoPerformance ?? true,
      autoMemoryLeak: config.autoMemoryLeak ?? true,
      autoBenchmark: config.autoBenchmark ?? true,
      autoError: config.autoError ?? true,
    };
    this.deviceId = generateStableDeviceId(config.appName);
  }

  /**
   * Initialize DevConnect.
   *
   * ```typescript
   * // Auto-detect (emulator + real device)
   * await DevConnect.init({ appName: 'MyApp' });
   *
   * // Manual IP (real device)
   * await DevConnect.init({ appName: 'MyApp', host: '192.168.1.5' });
   *
   * // Custom port
   * await DevConnect.init({ appName: 'MyApp', port: 9999 });
   *
   * // Disable in production
   * await DevConnect.init({ appName: 'MyApp', enabled: !__DEV__ });
   * ```
   */
  static async init(config: DevConnectConfig): Promise<DevConnect> {
    if (DevConnect.instance) return DevConnect.instance;

    // Production kill-switch: completely no-op when disabled.
    // Default: enabled only in __DEV__ (dev builds).
    const enabled = config.enabled ?? __DEV__;
    if (!enabled) {
      // Create a dummy instance so safeSend/getInstance don't throw,
      // but do NOTHING: no WebSocket, no host detection, no timers.
      const dc = new DevConnect({ ...config, resolvedHost: 'disabled' });
      dc.config.enabled = false;
      DevConnect.instance = dc;
      DevConnect.preInitQueue = [];
      return dc;
    }

    // Create instance immediately with placeholder host so we can patch synchronously
    const dc = new DevConnect({ ...config, resolvedHost: 'localhost' });
    DevConnect.instance = dc;

    // Patch interceptors synchronously so no early network requests or logs are missed
    if (dc.config.autoInterceptFetch) patchFetch(dc);
    if (dc.config.autoInterceptXHR) patchXHR(dc);
    if (dc.config.autoInterceptConsole) patchConsole(dc);

    // Resolve real host and connect asynchronously in the background
    const port = config.port ?? 9090;
    const shouldAuto = (config.auto ?? true) && (!config.host || config.host === 'auto');

    if (shouldAuto) {
      autoDetectHost(port).then((resolvedHost) => {
        dc.config.host = resolvedHost;
        connect(dc);
      }).catch(() => {
        connect(dc);
      });
    } else {
      dc.config.host = config.host ?? 'localhost';
      connect(dc);
    }

    // Auto-start monitoring plugins
    // Using dynamic require() to avoid circular dependency at module load time
    try {
      if (dc.config.autoPerformance) {
        const { startPerformanceMonitor } = require('./plugins/performance/performanceMonitor');
        startPerformanceMonitor();
      }
      if (dc.config.autoMemoryLeak) {
        const { startMemoryLeakDetector } = require('./plugins/performance/memoryLeakDetector');
        startMemoryLeakDetector();
      }
      if (dc.config.autoBenchmark) {
        const { setupAppBenchmark } = require('./plugins/performance/appBenchmark');
        setupAppBenchmark();
      }
      if (dc.config.autoError) {
        const { startErrorMonitor } = require('./plugins/errors/errorMonitor');
        startErrorMonitor();
      }
    } catch (e) {
      // Plugins are optional — don't break init if they fail
    }

    // Migrate pending benchmarks to instance
    if (DevConnect._pendingBenchmarks.size > 0) {
      for (const [key, value] of DevConnect._pendingBenchmarks) {
        dc._benchmarks.set(key, value);
      }
      DevConnect._pendingBenchmarks.clear();
    }

    // Flush pre-init queue (messages from middleware that ran before init)
    if (DevConnect.preInitQueue.length > 0) {
      for (const msg of DevConnect.preInitQueue) {
        dc.send(msg.type, msg.payload);
      }
      DevConnect.preInitQueue = [];
    }

    return dc;
  }

  static getInstance(): DevConnect {
    if (!DevConnect.instance) {
      throw new Error('DevConnect not initialized. Call DevConnect.init() first.');
    }
    return DevConnect.instance;
  }

  /** Returns instance or null if not yet initialized. Use this in middleware/plugins that may run before init(). */
  static getInstanceSafe(): DevConnect | null {
    return DevConnect.instance ?? null;
  }

  /** Send a message safely - queues to pre-init queue if init() hasn't been called yet */
  static safeSend(type: string, payload: Record<string, any>): void {
    const instance = DevConnect.getInstanceSafe();
    if (instance) {
      instance.send(type, payload);
    } else if (!__DEV__) {
      // Production: don't queue anything
      return;
    } else if (DevConnect.preInitQueue.length < 500) {
      DevConnect.preInitQueue.push({ type, payload });
    }
  }

  // ---- WebSocket ----

  send(type: string, payload: Record<string, any>, correlationId?: string): void {
    if (!this.config.enabled) return;
    const message: DCMessage = {
      id: generateId(),
      type,
      deviceId: this.deviceId,
      timestamp: Date.now(),
      payload,
      ...(correlationId ? { correlationId } : {}),
    };
    try {
      const json = JSON.stringify(message);
      if (this.connected && this.ws) {
        _wsSend(this, json);
      } else if (this.messageQueue.length < 1000) {
        this.messageQueue.push(json);
      }
    } catch (_) {}
  }

  // ---- Public API ----

  private static _toStr(msg: any): string {
    if (msg === null || msg === undefined) return String(msg);
    if (typeof msg === 'string') return msg;
    try { return JSON.stringify(msg, null, 2); } catch (_) { return safeString(msg); }
  }
  static log(message: any, tag?: string, metadata?: Record<string, any>): void {
    DevConnect.safeSend('client:log', { level: 'info', message: DevConnect._toStr(message), ...(tag ? { tag } : {}), ...(metadata ? { metadata } : {}) });
  }
  static debug(message: any, tag?: string, metadata?: Record<string, any>): void {
    DevConnect.safeSend('client:log', { level: 'debug', message: DevConnect._toStr(message), ...(tag ? { tag } : {}), ...(metadata ? { metadata } : {}) });
  }
  static warn(message: any, tag?: string, metadata?: Record<string, any>): void {
    DevConnect.safeSend('client:log', { level: 'warn', message: DevConnect._toStr(message), ...(tag ? { tag } : {}), ...(metadata ? { metadata } : {}) });
  }
  static error(message: any, tag?: string, stackTrace?: string, metadata?: Record<string, any>): void {
    DevConnect.safeSend('client:log', { level: 'error', message: DevConnect._toStr(message), ...(tag ? { tag } : {}), ...(stackTrace ? { stackTrace } : {}), ...(metadata ? { metadata } : {}) });
  }

  static reportStateChange(opts: { stateManager: string; action: string; previousState?: Record<string, any>; nextState?: Record<string, any>; diff?: Array<Record<string, any>> }): void {
    DevConnect.safeSend('client:state:change', opts);
  }

  static reportStorageOperation(opts: { storageType: string; key: string; value?: any; operation: string }): void {
    DevConnect.safeSend('client:storage:operation', opts);
  }

  // ---- Performance Profiling ----

  /**
   * Report a performance metric (FPS, memory, CPU, jank frame, etc.).
   *
   * ```typescript
   * // Report FPS
   * DevConnect.reportPerformanceMetric({
   *   metricType: 'fps',
   *   value: 58.5,
   *   label: 'Main Thread FPS',
   * });
   *
   * // Report memory usage in MB
   * DevConnect.reportPerformanceMetric({
   *   metricType: 'memory_usage',
   *   value: 142.3,
   *   label: 'Heap Used',
   * });
   *
   * // Report CPU usage percentage
   * DevConnect.reportPerformanceMetric({
   *   metricType: 'cpu_usage',
   *   value: 35.2,
   * });
   *
   * // Report a jank frame (build time in ms)
   * DevConnect.reportPerformanceMetric({
   *   metricType: 'jank_frame',
   *   value: 32.1,
   *   label: 'Slow render in UserList',
   * });
   * ```
   */
  static reportPerformanceMetric(opts: {
    metricType: 'fps' | 'frame_build_time' | 'frame_raster_time' | 'memory_usage' | 'memory_peak' | 'memory_allocation_rate' | 'cpu_usage' | 'jank_frame' | 'startup_time' | 'battery_level' | 'thermal_state' | 'thread_count' | 'disk_read' | 'disk_write' | 'anr';
    value: number;
    label?: string;
    metadata?: Record<string, any>;
  }): void {
    DevConnect.safeSend('client:performance:metric', {
      metricType: opts.metricType,
      value: opts.value,
      ...(opts.label ? { label: opts.label } : {}),
      ...(opts.metadata ? { metadata: opts.metadata } : {}),
    });
  }

  // ---- Memory Leak Detection ----

  /**
   * Report a detected memory leak.
   *
   * ```typescript
   * // Report an undisposed subscription
   * DevConnect.reportMemoryLeak({
   *   leakType: 'undisposed_stream',
   *   severity: 'warning',
   *   objectName: 'UserDataSubscription',
   *   detail: 'EventEmitter listener not removed in ProfileScreen',
   *   retainedSizeBytes: 2048,
   *   stackTrace: new Error().stack,
   * });
   *
   * // Report a growing collection
   * DevConnect.reportMemoryLeak({
   *   leakType: 'growing_collection',
   *   severity: 'critical',
   *   objectName: 'eventCache',
   *   detail: 'Array grows unbounded — 15000 items, expected < 100',
   *   retainedSizeBytes: 1200000,
   *   metadata: { currentSize: 15000, maxExpected: 100 },
   * });
   * ```
   */
  static reportMemoryLeak(opts: {
    leakType: 'undisposed_controller' | 'undisposed_stream' | 'undisposed_timer' | 'undisposed_animation_controller' | 'widget_leak' | 'growing_collection' | 'custom';
    severity: 'info' | 'warning' | 'critical';
    objectName: string;
    detail?: string;
    retainedSizeBytes?: number;
    stackTrace?: string;
    metadata?: Record<string, any>;
  }): void {
    DevConnect.safeSend('client:memory:leak', {
      leakType: opts.leakType,
      severity: opts.severity,
      objectName: opts.objectName,
      ...(opts.detail ? { detail: opts.detail } : {}),
      ...(opts.retainedSizeBytes != null ? { retainedSizeBytes: opts.retainedSizeBytes } : {}),
      ...(opts.stackTrace ? { stackTrace: opts.stackTrace } : {}),
      ...(opts.metadata ? { metadata: opts.metadata } : {}),
    });
  }

  // ---- Connection ----

  /** Check if currently connected to DevConnect desktop. */
  static isConnected(): boolean {
    return DevConnect.instance?.connected ?? false;
  }

  /** Connected, or the first connection attempt is still under way: changes made now are queued, not lost. */
  static isListening(): boolean {
    const instance = DevConnect.instance;
    if (!instance) return typeof __DEV__ !== 'undefined' && __DEV__;
    return instance.connected || (instance.config.enabled && instance.reconnectTimer === null);
  }

  /** Disconnect from DevConnect desktop. */
  static disconnect(): void {
    const instance = DevConnect.getInstanceSafe();
    if (instance) {
      if (instance.reconnectTimer) {
        clearTimeout(instance.reconnectTimer);
        instance.reconnectTimer = null;
      }
      instance.connected = false;
      try { instance.ws?.close(); } catch (_) {}
      instance.ws = null;
      instance.restorePatches();
    }
  }

  private restorePatches(): void {
    if (this.originalFetch) {
      (globalThis as any).fetch = this.originalFetch;
      this.originalFetch = null;
    }
    if (this.originalXHR) {
      (globalThis as any).XMLHttpRequest = this.originalXHR;
      this.originalXHR = null;
    }
    if (this.originalConsole) {
      console.log = this.originalConsole.log as any;
      console.warn = this.originalConsole.warn as any;
      console.error = this.originalConsole.error as any;
      console.debug = this.originalConsole.debug as any;
      console.info = this.originalConsole.info as any;
      if (this.originalConsole.trace) console.trace = this.originalConsole.trace as any;
      this.originalConsole = null;
    }
  }

  // ---- Tagged Logger ----

  /**
   * Create a tagged logger instance.
   *
   * ```typescript
   * const logger = DevConnect.logger('AuthService');
   * logger.log('User logged in');
   * logger.debug('Token refreshed');
   * logger.warn('Session expiring');
   * logger.error('Login failed', 'stack trace...');
   * ```
   */
  static logger(tag: string): {
    log: (message: string, metadata?: Record<string, any>) => void;
    debug: (message: string, metadata?: Record<string, any>) => void;
    warn: (message: string, metadata?: Record<string, any>) => void;
    error: (message: string, stackTrace?: string, metadata?: Record<string, any>) => void;
  } {
    return {
      log: (message, metadata?) => DevConnect.log(message, tag, metadata),
      debug: (message, metadata?) => DevConnect.debug(message, tag, metadata),
      warn: (message, metadata?) => DevConnect.warn(message, tag, metadata),
      error: (message, stackTrace?, metadata?) => DevConnect.error(message, tag, stackTrace, metadata),
    };
  }

  // ---- Network (manual reporting) ----

  /**
   * Manually report a network request start.
   * Useful when auto-interception is disabled or for custom transports.
   *
   * ```typescript
   * const requestId = 'req-123';
   * DevConnect.reportNetworkStart({
   *   requestId,
   *   method: 'POST',
   *   url: 'https://api.example.com/data',
   *   headers: { 'Authorization': 'Bearer xxx' },
   * });
   * ```
   */
  static reportNetworkStart(opts: {
    requestId: string;
    method: string;
    url: string;
    headers?: Record<string, string>;
    body?: any;
  }): void {
    DevConnect.safeSend('client:network:request_start', {
      requestId: opts.requestId,
      method: opts.method,
      url: opts.url,
      startTime: Date.now(),
      ...(opts.headers ? { requestHeaders: opts.headers } : {}),
      ...(opts.body !== undefined ? { requestBody: opts.body } : {}),
    });
  }

  /**
   * Manually report a network request completion.
   *
   * ```typescript
   * DevConnect.reportNetworkComplete({
   *   requestId: 'req-123',
   *   method: 'POST',
   *   url: 'https://api.example.com/data',
   *   statusCode: 200,
   *   startTime: 1711180800000,
   *   responseBody: { success: true },
   * });
   * ```
   */
  static reportNetworkComplete(opts: {
    requestId: string;
    method: string;
    url: string;
    statusCode: number;
    startTime: number;
    requestHeaders?: Record<string, string>;
    responseHeaders?: Record<string, string>;
    requestBody?: any;
    responseBody?: any;
    error?: string;
  }): void {
    const now = Date.now();
    DevConnect.safeSend('client:network:request_complete', {
      requestId: opts.requestId,
      method: opts.method,
      url: opts.url,
      statusCode: opts.statusCode,
      startTime: opts.startTime,
      endTime: now,
      duration: now - opts.startTime,
      ...(opts.requestHeaders ? { requestHeaders: opts.requestHeaders } : {}),
      ...(opts.responseHeaders ? { responseHeaders: opts.responseHeaders } : {}),
      ...(opts.requestBody !== undefined ? { requestBody: opts.requestBody } : {}),
      ...(opts.responseBody !== undefined ? { responseBody: opts.responseBody } : {}),
      ...(opts.error ? { error: opts.error } : {}),
    });
  }

  // ---- Redux dispatch from desktop ----

  /**
   * Connect Redux store so desktop can dispatch actions into the app.
   *
   * ```typescript
   * const store = createStore(reducer);
   * DevConnect.connectReduxStore(store);
   * // Now desktop can dispatch actions into your app!
   * ```
   */
  static connectReduxStore(store: any): void {
    const instance = DevConnect.getInstanceSafe();
    if (instance) {
      instance._reduxStore = store;
      try {
        instance.send('client:state:snapshot', {
          stateManager: 'redux',
          state: JSON.parse(JSON.stringify(store.getState())),
        });
      } catch (_) {}
    } else {
      // Store reference will be set when init() completes
      DevConnect.safeSend('client:state:snapshot', {
        stateManager: 'redux',
        state: (() => { try { return JSON.parse(JSON.stringify(store.getState())); } catch (_) { return {}; } })(),
      });
      // Defer store binding - check periodically until init completes
      const interval = setInterval(() => {
        const dc = DevConnect.getInstanceSafe();
        if (dc) {
          dc._reduxStore = store;
          clearInterval(interval);
        }
      }, 100);
      setTimeout(() => clearInterval(interval), 10000);
    }
  }

  // ---- State snapshot + restore ----

  /**
   * Set handler for state restore from desktop.
   *
   * ```typescript
   * DevConnect.onStateRestore((state) => {
   *   store.dispatch({ type: 'RESTORE_STATE', payload: state });
   * });
   * ```
   */
  static onStateRestore(handler: (state: any) => void): void {
    const instance = DevConnect.getInstanceSafe();
    if (instance) {
      instance._stateRestoreHandler = handler;
    } else {
      const interval = setInterval(() => {
        const dc = DevConnect.getInstanceSafe();
        if (dc) {
          dc._stateRestoreHandler = handler;
          clearInterval(interval);
        }
      }, 100);
      setTimeout(() => clearInterval(interval), 10000);
    }
  }

  /**
   * Send a state snapshot to desktop (for saving/restoring later).
   */
  static sendStateSnapshot(stateManager: string, state: any): void {
    try {
      DevConnect.safeSend('client:state:snapshot', {
        stateManager,
        state: JSON.parse(JSON.stringify(state)),
      });
    } catch (_) {}
  }

  // ---- Benchmark API ----

  /**
   * Start a benchmark timer.
   *
   * ```typescript
   * DevConnect.benchmark('loadUserData');
   * await fetchUser();
   * DevConnect.benchmarkStep('loadUserData', 'fetched user');
   * await fetchPosts();
   * DevConnect.benchmarkStop('loadUserData');
   * ```
   */
  private static _pendingBenchmarks: Map<string, { title: string; startTime: number; steps: Array<{ title: string; timestamp: number }> }> = new Map();

  static benchmark(title: string): void {
    const dc = DevConnect.getInstanceSafe();
    const map = dc?._benchmarks ?? DevConnect._pendingBenchmarks;
    map.set(title, { title, startTime: Date.now(), steps: [] });
  }

  static benchmarkStep(title: string, stepTitle: string): void {
    const dc = DevConnect.getInstanceSafe();
    const map = dc?._benchmarks ?? DevConnect._pendingBenchmarks;
    const b = map.get(title);
    if (b) b.steps.push({ title: stepTitle, timestamp: Date.now() });
  }

  static benchmarkStop(title: string): void {
    const dc = DevConnect.getInstanceSafe();
    const map = dc?._benchmarks ?? DevConnect._pendingBenchmarks;
    const b = map.get(title);
    if (b) {
      const endTime = Date.now();
      const steps = b.steps.map((s, i) => ({
        ...s,
        delta: i === 0 ? s.timestamp - b.startTime : s.timestamp - b.steps[i - 1].timestamp,
      }));

      // Send via safeSend so it queues if not connected yet
      DevConnect.safeSend('client:benchmark', {
        title: b.title,
        startTime: b.startTime,
        endTime,
        duration: endTime - b.startTime,
        steps,
      });

      map.delete(title);
    }
  }

  // ---- Custom Display ----

  /**
   * Send a custom display value to DevConnect desktop.
   *
   * ```typescript
   * DevConnect.display('User Profile', {
   *   value: { name: 'John', age: 30, role: 'admin' },
   *   preview: 'John, 30',
   * });
   *
   * DevConnect.display('Current Theme', {
   *   value: themeObject,
   *   preview: 'Dark Mode',
   *   metadata: { source: 'ThemeProvider' },
   * });
   * ```
   */
  static display(name: string, opts?: {
    value?: any;
    preview?: string;
    image?: string;
    metadata?: Record<string, any>;
  }): void {
    DevConnect.safeSend('client:display', {
      name,
      ...(opts?.value !== undefined ? { value: opts.value } : {}),
      ...(opts?.preview ? { preview: opts.preview } : {}),
      ...(opts?.image ? { image: opts.image } : {}),
      ...(opts?.metadata ? { metadata: opts.metadata } : {}),
    });
  }

  // ---- Async Operations (Saga/Task tracking) ----

  /**
   * Report an async operation (Redux Saga step, background task, etc.).
   *
   * ```typescript
   * // Report saga take
   * DevConnect.reportAsyncOperation({
   *   operationType: 'saga_take',
   *   description: 'Waiting for FETCH_USER',
   *   status: 'start',
   *   sagaName: 'userSaga',
   * });
   *
   * // Report saga call completion
   * DevConnect.reportAsyncOperation({
   *   operationType: 'saga_call',
   *   description: 'fetchUserAPI()',
   *   status: 'resolve',
   *   sagaName: 'userSaga',
   *   duration: 350,
   *   result: { userId: 123 },
   * });
   *
   * // Report async task failure
   * DevConnect.reportAsyncOperation({
   *   operationType: 'async_task',
   *   description: 'Upload image',
   *   status: 'reject',
   *   duration: 5000,
   *   error: 'Network timeout',
   * });
   * ```
   */
  static reportAsyncOperation(opts: {
    operationType: 'saga_take' | 'saga_put' | 'saga_call' | 'saga_fork' | 'saga_all' | 'saga_race' | 'saga_select' | 'saga_delay' | 'async_task' | 'background_job' | 'custom';
    description: string;
    status: 'start' | 'resolve' | 'reject';
    duration?: number;
    sagaName?: string;
    error?: string;
    result?: any;
    metadata?: Record<string, any>;
  }): void {
    DevConnect.safeSend('client:async:operation', {
      operationType: opts.operationType,
      description: opts.description,
      status: opts.status,
      ...(opts.duration != null ? { duration: opts.duration } : {}),
      ...(opts.sagaName ? { sagaName: opts.sagaName } : {}),
      ...(opts.error ? { error: opts.error } : {}),
      ...(opts.result !== undefined ? { result: opts.result } : {}),
      ...(opts.metadata ? { metadata: opts.metadata } : {}),
    });
  }

  // ---- Custom commands (desktop -> app) ----

  /**
   * Register a custom command that desktop can trigger.
   *
   * ```typescript
   * DevConnect.registerCommand('clearCache', () => {
   *   AsyncStorage.clear();
   *   return { success: true };
   * });
   *
   * DevConnect.registerCommand('setUser', (args) => {
   *   store.dispatch({ type: 'SET_USER', payload: args });
   * });
   * ```
   */
  static registerCommand(name: string, handler: (args?: any) => any): void {
    // Before the handshake the desktop wouldn't know the device yet; the
    // handshake announces every command registered by then.
    const register = (dc: DevConnect) => {
      dc._customCommandHandlers.set(name, handler);
      if (dc.connected) _announceCommands(dc);
    };
    const instance = DevConnect.getInstanceSafe();
    if (instance) {
      register(instance);
    } else {
      const interval = setInterval(() => {
        const dc = DevConnect.getInstanceSafe();
        if (dc) {
          register(dc);
          clearInterval(interval);
        }
      }, 100);
      setTimeout(() => clearInterval(interval), 10000);
    }
  }

  /**
   * Gives the desktop's Layout tab a screenshot to draw component bounds on
   * (React Native has no built-in one). With react-native-view-shot:
   *
   * ```typescript
   * DevConnect.registerScreenshot(() => captureScreen({ format: 'png', result: 'base64' }));
   * ```
   */
  static registerScreenshot(capture: () => Promise<string>): void {
    const instance = DevConnect.getInstanceSafe();
    if (instance) {
      instance._screenshot = capture;
    } else {
      const interval = setInterval(() => {
        const dc = DevConnect.getInstanceSafe();
        if (dc) {
          dc._screenshot = capture;
          clearInterval(interval);
        }
      }, 100);
      setTimeout(() => clearInterval(interval), 10000);
    }
  }

  /**
   * Let the desktop's Storage tab show, edit, delete and clear a key-value
   * store. `DevConnectAsyncStorage` and `DevConnectMMKV` register theirs;
   * call this for any other store.
   */
  static registerStorage(storageType: string, adapter: StorageAdapter): void {
    const instance = DevConnect.getInstanceSafe();
    if (instance) {
      instance._storages.set(storageType, adapter);
    } else {
      const interval = setInterval(() => {
        const dc = DevConnect.getInstanceSafe();
        if (dc) {
          dc._storages.set(storageType, adapter);
          clearInterval(interval);
        }
      }, 100);
      setTimeout(() => clearInterval(interval), 10000);
    }
  }

  /**
   * Let the desktop's Database tab browse and query a SQLite database.
   * `query` runs one SQL statement and returns its rows (sync or async):
   *
   * ```typescript
   * // op-sqlite
   * DevConnect.registerDatabase('app.db', async (sql) => (await db.execute(sql)).rows);
   * // expo-sqlite
   * DevConnect.registerDatabase('app.db', (sql) => db.getAllAsync(sql));
   * ```
   */
  static registerDatabase(name: string, query: DatabaseQuery): void {
    const instance = DevConnect.getInstanceSafe();
    if (instance) {
      instance._databases.set(name, query);
    } else {
      const interval = setInterval(() => {
        const dc = DevConnect.getInstanceSafe();
        if (dc) {
          dc._databases.set(name, query);
          clearInterval(interval);
        }
      }, 100);
      setTimeout(() => clearInterval(interval), 10000);
    }
  }

  /**
   * Register a custom handler for `server:reload` requests from the desktop.
   *
   * By default, the SDK calls `DevSettings.reload()` (the same path the
   * dev menu's "Reload" uses) — that tears down the bridge and reloads
   * the JS bundle from Metro. Register a custom handler when you need to
   * wipe in-memory state before the reload, e.g. clear Redux store and
   * in-memory caches:
   *
   * ```typescript
   * DevConnect.registerReloadHandler(() => {
   *   store.dispatch({ type: 'RESET' });
   *   // falling back to default reload is up to you
   *   DevSettings.reload('DevConnect reload');
   * });
   * ```
   */
  static registerReloadHandler(handler: () => void): void {
    const instance = DevConnect.getInstanceSafe();
    if (instance) {
      instance._reloadHandler = handler;
    } else {
      const interval = setInterval(() => {
        const dc = DevConnect.getInstanceSafe();
        if (dc) {
          dc._reloadHandler = handler;
          clearInterval(interval);
        }
      }, 100);
      setTimeout(() => clearInterval(interval), 10000);
    }
  }

  /**
   * Subscribe to *all* server messages. Used by internal plugins that
   * need to react to protocol messages the core SDK doesn't handle
   * natively.
   *
   * The handler is invoked synchronously inside the WebSocket receive
   * loop for every parsed message — inspect `msg.type` to filter.
   * Throws inside the handler are swallowed so a misbehaving plugin
   * can't break the receive loop.
   *
   * Returns an unsubscribe function — call it to remove the handler.
   */
  static addServerMessageHandler(handler: (msg: any) => void): () => void {
    const instance = DevConnect.getInstanceSafe();
    if (!instance) {
      // SDK not initialized yet — nothing to subscribe to. Return a
      // no-op unsubscribe so callers don't crash.
      return () => {};
    }
    instance._serverMessageHandlers.add(handler);
    return () => instance._serverMessageHandlers.delete(handler);
  }
}

declare let __DEV__: boolean;
