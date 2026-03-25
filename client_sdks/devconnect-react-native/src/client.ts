/**
 * DevConnect React Native Client
 *
 * Auto-detect desktop host via:
 * 1. Metro bundler scriptURL (like Reactotron)
 * 2. Known emulator/simulator addresses
 * 3. Subnet scanning for real devices on WiFi
 */

import { Platform, NativeModules } from 'react-native';

interface DevConnectConfig {
  appName: string;
  appVersion?: string;
  /** Desktop IP. undefined/'auto' = auto-detect. '192.168.x.x' = manual */
  host?: string;
  port?: number;
  /** Auto-detect host (default: true) */
  auto?: boolean;
  enabled?: boolean;
  autoInterceptFetch?: boolean;
  autoInterceptXHR?: boolean;
  autoInterceptConsole?: boolean;
}

interface DCMessage {
  id: string;
  type: string;
  deviceId: string;
  timestamp: number;
  payload: Record<string, any>;
  correlationId?: string;
}

function generateId(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

// ---- Encrypted host cache (persists via AsyncStorage if available) ----

const CACHE_KEY = 'DcN3t$ecR7!';
let _cachedHost: string | null = null;

function xorCipher(input: string, key: string): string {
  let out = '';
  for (let i = 0; i < input.length; i++) {
    out += String.fromCharCode(input.charCodeAt(i) ^ key.charCodeAt(i % key.length));
  }
  return out;
}

function encryptCache(data: object): string {
  const plain = JSON.stringify(data);
  // XOR then base64
  const xored = xorCipher(plain, CACHE_KEY);
  // Use btoa-safe encoding (char codes 0-255)
  try { return btoa(xored); } catch (_) {
    return Buffer.from(xored, 'binary').toString('base64');
  }
}

function decryptCache(encrypted: string): any {
  try {
    let decoded: string;
    try { decoded = atob(encrypted); } catch (_) {
      decoded = Buffer.from(encrypted, 'base64').toString('binary');
    }
    const plain = xorCipher(decoded, CACHE_KEY);
    return JSON.parse(plain);
  } catch (_) { return null; }
}

async function saveHostCache(host: string): Promise<void> {
  _cachedHost = host;
  try {
    const AsyncStorage = require('@react-native-async-storage/async-storage')?.default;
    if (AsyncStorage) {
      const encrypted = encryptCache({ h: host, t: Date.now() });
      await AsyncStorage.setItem('__dc_s', encrypted);
    }
  } catch (_) {}
}

async function readHostCache(): Promise<string | null> {
  if (_cachedHost) return _cachedHost;
  try {
    const AsyncStorage = require('@react-native-async-storage/async-storage')?.default;
    if (AsyncStorage) {
      const encrypted = await AsyncStorage.getItem('__dc_s');
      if (encrypted) {
        const data = decryptCache(encrypted);
        if (data && Date.now() - data.t < 24 * 60 * 60 * 1000) {
          _cachedHost = data.h;
          return data.h;
        }
      }
    }
  } catch (_) {}
  return null;
}

// ---- Auto-detect host (supports real device iOS/Android) ----

async function tryConnect(host: string, port: number, timeoutMs: number): Promise<boolean> {
  try {
    console.log(`[DevConnect] tryConnect ws://${host}:${port} (${timeoutMs}ms)`);
    const ws = new WebSocket(`ws://${host}:${port}`);
    return await new Promise<boolean>((resolve) => {
      const timer = setTimeout(() => { console.log(`[DevConnect] tryConnect TIMEOUT ${host}`); try { ws.close(); } catch (_) {} resolve(false); }, timeoutMs);
      ws.onopen = () => { console.log(`[DevConnect] tryConnect OK ${host}`); clearTimeout(timer); try { ws.close(); } catch (_) {} resolve(true); };
      ws.onerror = (e: any) => { console.log(`[DevConnect] tryConnect ERROR ${host}:`, e?.message || e); clearTimeout(timer); resolve(false); };
    });
  } catch (e: any) { console.log(`[DevConnect] tryConnect EXCEPTION ${host}:`, e?.message); return false; }
}

/**
 * Extract the dev server host from Metro's scriptURL.
 * This is how Reactotron auto-discovers the desktop IP on real devices —
 * the RN runtime already knows the dev machine's IP because Metro serves
 * the JS bundle from it.
 */
function getDevServerHost(): string | null {
  try {
    // React Native exposes the bundle URL via SourceCode native module
    const scriptURL =
      NativeModules?.SourceCode?.scriptURL ??
      NativeModules?.SourceCode?.getConstants?.()?.scriptURL;
    if (scriptURL && typeof scriptURL === 'string') {
      // scriptURL looks like "http://192.168.1.5:8081/index.bundle?..."
      const match = scriptURL.match(/^https?:\/\/([^:\/]+)/);
      if (match && match[1] && match[1] !== 'localhost' && match[1] !== '127.0.0.1') {
        return match[1];
      }
    }
  } catch (_) {}
  return null;
}

async function autoDetectHost(port: number): Promise<string> {
  console.log('[DevConnect] autoDetectHost started, port:', port);
  // 0. Try cached host from previous session (instant reconnect)
  const cached = await readHostCache();
  console.log('[DevConnect] cached host:', cached);
  if (cached && await tryConnect(cached, port, 600)) { console.log('[DevConnect] using cached host:', cached); return cached; }

  // 1. Race: Metro scriptURL + known hosts in parallel
  //    USB (adb reverse) → localhost/10.0.2.2 responds fast
  //    WiFi debug → Metro host responds fast
  const raceCandidates: Promise<string | null>[] = [];

  // Metro bundler host (real device gets desktop IP from bundle URL)
  const devHost = getDevServerHost();
  if (devHost) {
    raceCandidates.push(
      tryConnect(devHost, port, 800).then((ok) => ok ? devHost : null)
    );
  }

  // Known emulator/simulator/USB addresses
  for (const host of ['localhost', '10.0.2.2', '10.0.3.2', '127.0.0.1']) {
    raceCandidates.push(
      tryConnect(host, port, 800).then((ok) => ok ? host : null)
    );
  }

  // First non-null wins
  const raceResult = await firstNonNull(raceCandidates);
  if (raceResult) { saveHostCache(raceResult); return raceResult; }

  // 2. Scan local subnets for real device (WiFi)
  const subnets: string[] = [];
  if (devHost) {
    const parts = devHost.split('.');
    if (parts.length === 4) {
      subnets.push(`${parts[0]}.${parts[1]}.${parts[2]}`);
    }
  }
  for (const s of ['192.168.1', '192.168.0', '192.168.2', '10.0.0', '10.0.1', '172.16.0']) {
    if (!subnets.includes(s)) subnets.push(s);
  }

  for (const subnet of subnets) {
    const batch = Array.from({ length: 30 }, (_, i) => `${subnet}.${i + 1}`);
    const results = await Promise.allSettled(
      batch.map((h) => tryConnect(h, port, 400).then((ok) => ok ? h : null))
    );
    for (const r of results) {
      if (r.status === 'fulfilled' && r.value) {
        saveHostCache(r.value);
        return r.value;
      }
    }
  }

  return 'localhost';
}

/** Returns the first non-null resolved value from a list of promises. */
async function firstNonNull(promises: Promise<string | null>[]): Promise<string | null> {
  return new Promise((resolve) => {
    let remaining = promises.length;
    for (const p of promises) {
      p.then((v) => {
        if (v != null) resolve(v);
        else if (--remaining === 0) resolve(null);
      }).catch(() => {
        if (--remaining === 0) resolve(null);
      });
    }
  });
}

// ---- URL classification (app vs library) ----

const libraryDomains = [
  'firebaseio.com', 'googleapis.com', 'firebase.google.com',
  'firebaseinstallations.googleapis.com', 'fcmregistrations.googleapis.com',
  'crashlyticsreports-pa.googleapis.com', 'firebaseremoteconfig.googleapis.com',
  'google-analytics.com', 'analytics.google.com', 'googletagmanager.com',
  'app-measurement.com', 'doubleclick.net',
  'facebook.com', 'graph.facebook.com', 'fbcdn.net',
  'sentry.io', 'bugsnag.com', 'instabug.com',
  'segment.io', 'segment.com', 'mixpanel.com', 'amplitude.com',
  'appsflyer.com', 'adjust.com', 'branch.io',
  'codepush.appcenter.ms', 'appcenter.ms',
  'clients3.google.com', 'clients4.google.com',
  'connectivitycheck', 'generate_204',
];

function classifyUrl(url: string): string {
  try {
    const lower = url.toLowerCase();
    for (const domain of libraryDomains) {
      if (lower.includes(domain)) return 'library';
    }
    if (lower.includes('/generate_204') || lower.includes('connectivitycheck')) return 'system';
  } catch (_) {}
  return 'app';
}

// ---- Main Class ----

export class DevConnect {
  private static instance: DevConnect | null = null;
  private ws: WebSocket | null = null;
  private config: Required<DevConnectConfig>;
  /** Pre-init queue: messages sent before init() is called */
  private static preInitQueue: Array<{ type: string; payload: Record<string, any> }> = [];

  private deviceId: string;
  private connected = false;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private messageQueue: string[] = [];
  private _reduxStore: any = null;
  private _stateRestoreHandler: ((state: any) => void) | null = null;
  private _customCommandHandlers: Map<string, (args?: any) => any> = new Map();
  private _benchmarks: Map<string, { title: string; startTime: number; steps: Array<{ title: string; timestamp: number }> }> = new Map();

  private constructor(config: DevConnectConfig & { resolvedHost: string }) {
    this.config = {
      appName: config.appName,
      appVersion: config.appVersion ?? '1.0.0',
      host: config.resolvedHost,
      port: config.port ?? 9090,
      auto: config.auto ?? true,
      enabled: config.enabled ?? __DEV__,
      autoInterceptFetch: config.autoInterceptFetch ?? true,
      autoInterceptXHR: config.autoInterceptXHR ?? true,
      autoInterceptConsole: config.autoInterceptConsole ?? true,
    };
    this.deviceId = generateId();
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
    console.log('[DevConnect] init() called, config:', JSON.stringify(config));
    if (DevConnect.instance) { console.log('[DevConnect] already initialized'); return DevConnect.instance; }

    const port = config.port ?? 9090;
    const shouldAuto = (config.auto ?? true) && (!config.host || config.host === 'auto');
    console.log('[DevConnect] shouldAuto:', shouldAuto, 'port:', port);
    const resolvedHost = shouldAuto
      ? await autoDetectHost(port)
      : (config.host ?? 'localhost');
    console.log('[DevConnect] resolvedHost:', resolvedHost);

    const dc = new DevConnect({ ...config, resolvedHost });
    DevConnect.instance = dc;

    if (dc.config.enabled) {
      dc.connect();
      if (dc.config.autoInterceptFetch) dc.patchFetch();
      if (dc.config.autoInterceptXHR) dc.patchXHR();
      if (dc.config.autoInterceptConsole) dc.patchConsole();

      // Flush pre-init queue (messages from middleware that ran before init)
      if (DevConnect.preInitQueue.length > 0) {
        for (const msg of DevConnect.preInitQueue) {
          dc.send(msg.type, msg.payload);
        }
        DevConnect.preInitQueue = [];
      }
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
    } else if (DevConnect.preInitQueue.length < 500) {
      DevConnect.preInitQueue.push({ type, payload });
    }
  }

  // ---- WebSocket ----

  private connect(): void {
    try {
      console.log(`[DevConnect] connect() ws://${this.config.host}:${this.config.port}`);
      this.ws = new WebSocket(`ws://${this.config.host}:${this.config.port}`);

      this.ws.onopen = () => {
        console.log('[DevConnect] WebSocket OPEN');
        this.connected = true;
        this.messageQueue.forEach((msg) => this.ws?.send(msg));
        this.messageQueue = [];
      };

      this.ws.onmessage = (event: WebSocketMessageEvent) => {
        try {
          const msg = JSON.parse(event.data as string);
          if (msg.type === 'server:hello') {
            this.sendHandshake();
          } else if (msg.type === 'server:redux:dispatch') {
            // Desktop dispatching a Redux action into the app
            if (this._reduxStore && msg.payload?.action) {
              this._reduxStore.dispatch(msg.payload.action);
            }
          } else if (msg.type === 'server:state:restore') {
            // Desktop restoring a state snapshot
            if (this._stateRestoreHandler && msg.payload?.state) {
              this._stateRestoreHandler(msg.payload.state);
            }
          } else if (msg.type === 'server:custom:command') {
            // Desktop sending a custom command
            const cmd = msg.payload?.command;
            const handler = this._customCommandHandlers.get(cmd);
            if (handler) {
              const result = handler(msg.payload?.args);
              this.send('client:custom:command_result', {
                command: cmd,
                result,
              }, msg.correlationId);
            }
          }
        } catch (_) {}
      };

      this.ws.onclose = () => { console.log('[DevConnect] WebSocket CLOSED'); this.connected = false; this.scheduleReconnect(); };
      this.ws.onerror = (e: any) => { console.log('[DevConnect] WebSocket ERROR:', e?.message || e); this.connected = false; this.scheduleReconnect(); };
    } catch (e: any) {
      console.log('[DevConnect] connect() EXCEPTION:', e?.message);
      this.scheduleReconnect();
    }
  }

  private sendHandshake(): void {
    const os = Platform.OS; // 'ios' | 'android'
    const version = Platform.Version; // e.g. '17.4' (iOS) or 34 (Android API level)
    const osLabel = os === 'ios' ? 'iOS' : os === 'android' ? 'Android' : os;

    // Get actual device model name
    let deviceModel = `${osLabel} Device`;
    try {
      if (os === 'ios') {
        // iOS: get model name from PlatformConstants
        const constants = (NativeModules.PlatformConstants || NativeModules.DeviceInfo) as Record<string, any> | undefined;
        const iosModel = constants?.interfaceIdiom;
        const systemName = constants?.systemName;
        if (systemName) {
          deviceModel = `${systemName} Device`;
        } else if (iosModel) {
          deviceModel = iosModel === 'phone' ? 'iPhone' : iosModel === 'pad' ? 'iPad' : iosModel;
        }
      } else if (os === 'android') {
        // Android: get model from PlatformConstants
        const constants = (NativeModules.PlatformConstants || Platform.constants) as Record<string, any> | undefined;
        const model = constants?.Model || constants?.Brand;
        if (model) {
          deviceModel = model;
        }
      }
    } catch (_) {
      // Fallback to generic name
    }

    this.send('client:handshake', {
      deviceInfo: {
        deviceId: this.deviceId,
        deviceName: deviceModel,
        platform: 'react_native',
        osVersion: `${osLabel} ${version}`,
        appName: this.config.appName,
        appVersion: this.config.appVersion,
        sdkVersion: '1.0.0',
      },
    });
  }

  private scheduleReconnect(): void {
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);
    this.reconnectTimer = setTimeout(async () => {
      if (!this.connected) {
        if (this.config.auto) {
          this.config.host = await autoDetectHost(this.config.port);
        }
        this.connect();
      }
    }, 3000);
  }

  send(type: string, payload: Record<string, any>, correlationId?: string): void {
    const message: DCMessage = {
      id: generateId(),
      type,
      deviceId: this.deviceId,
      timestamp: Date.now(),
      payload,
      ...(correlationId ? { correlationId } : {}),
    };
    const json = JSON.stringify(message);
    if (this.connected && this.ws) {
      this.ws.send(json);
    } else if (this.messageQueue.length < 1000) {
      this.messageQueue.push(json);
    }
  }

  // ---- Fetch interceptor ----

  private patchFetch(): void {
    const originalFetch = global.fetch;
    const dc = this;

    global.fetch = async function (input: RequestInfo | URL, init?: RequestInit): Promise<Response> {
      const requestId = generateId();
      const startTime = Date.now();
      const method = init?.method?.toUpperCase() ?? 'GET';
      const url = typeof input === 'string' ? input : input.toString();

      const reqHeaders: Record<string, string> = {};
      if (init?.headers) {
        if (init.headers instanceof Headers) {
          init.headers.forEach((v, k) => (reqHeaders[k] = v));
        } else if (typeof init.headers === 'object') {
          Object.entries(init.headers).forEach(([k, v]) => (reqHeaders[k] = String(v)));
        }
      }

      let requestBody: any;
      if (init?.body) {
        try { requestBody = JSON.parse(init.body as string); } catch (_) { requestBody = String(init.body); }
      }

      const source = classifyUrl(url);
      dc.send('client:network:request_start', { requestId, method, url, startTime, requestHeaders: reqHeaders, requestBody, source });

      try {
        const response = await originalFetch(input, init);
        const clone = response.clone();
        let responseBody: any;
        try { const text = await clone.text(); try { responseBody = JSON.parse(text); } catch (_) { responseBody = text; } } catch (_) {}
        const resHeaders: Record<string, string> = {};
        response.headers.forEach((v, k) => (resHeaders[k] = v));

        dc.send('client:network:request_complete', {
          requestId, method, url, statusCode: response.status, startTime,
          endTime: Date.now(), duration: Date.now() - startTime,
          requestHeaders: reqHeaders, responseHeaders: resHeaders, requestBody, responseBody, source,
        });
        return response;
      } catch (error: any) {
        dc.send('client:network:request_complete', {
          requestId, method, url, statusCode: 0, startTime,
          endTime: Date.now(), duration: Date.now() - startTime,
          requestHeaders: reqHeaders, requestBody, error: error?.message ?? String(error), source,
        });
        throw error;
      }
    };
  }

  // ---- XHR interceptor ----

  private patchXHR(): void {
    const dc = this;
    const OriginalXHR = global.XMLHttpRequest;

    function PatchedXHR(this: any) {
      const xhr = new OriginalXHR();
      const requestId = generateId();
      let method = 'GET', url = '', startTime = 0;
      const reqHeaders: Record<string, string> = {};
      let requestBody: any;

      const origOpen = xhr.open.bind(xhr);
      xhr.open = (m: string, u: string, ...args: any[]) => { method = m.toUpperCase(); url = u; return origOpen(m, u, ...args); };

      const origSetHeader = xhr.setRequestHeader.bind(xhr);
      xhr.setRequestHeader = (n: string, v: string) => { reqHeaders[n] = v; return origSetHeader(n, v); };

      const origSend = xhr.send.bind(xhr);
      xhr.send = (body?: any) => {
        startTime = Date.now();
        if (body) { try { requestBody = JSON.parse(body); } catch (_) { requestBody = body; } }
        dc.send('client:network:request_start', { requestId, method, url, startTime, requestHeaders: reqHeaders, requestBody, source: classifyUrl(url) });
        return origSend(body);
      };

      xhr.addEventListener('loadend', () => {
        const resHeaders: Record<string, string> = {};
        try { xhr.getAllResponseHeaders().split('\r\n').forEach((l: string) => { const i = l.indexOf(':'); if (i > 0) resHeaders[l.substring(0, i).trim()] = l.substring(i + 1).trim(); }); } catch (_) {}
        let responseBody: any;
        // Only read responseText if responseType allows it (not blob/arraybuffer)
        const rt = xhr.responseType;
        if (!rt || rt === '' || rt === 'text') {
          try { responseBody = JSON.parse(xhr.responseText); } catch (_) { responseBody = xhr.responseText; }
        } else if (rt === 'json') {
          responseBody = xhr.response;
        } else {
          responseBody = `<${rt} ${xhr.response?.size ?? xhr.response?.byteLength ?? '?'} bytes>`;
        }
        dc.send('client:network:request_complete', {
          requestId, method, url, statusCode: xhr.status, startTime,
          endTime: Date.now(), duration: Date.now() - startTime,
          requestHeaders: reqHeaders, responseHeaders: resHeaders, requestBody, responseBody,
          source: classifyUrl(url),
          ...(xhr.status === 0 ? { error: 'Network request failed' } : {}),
        });
      });
      return xhr;
    }
    (global as any).XMLHttpRequest = PatchedXHR;
  }

  // ---- Console interceptor ----

  private patchConsole(): void {
    const dc = this;
    const orig = {
      log: console.log.bind(console), warn: console.warn.bind(console),
      error: console.error.bind(console), debug: console.debug.bind(console),
      info: console.info.bind(console), trace: console.trace?.bind(console),
    };

    const systemPrefixes = [
      'Running "', 'BUNDLE ', 'nativeRequire ', 'Require cycle:', 'Remote debugger',
      'Debugger and device', 'Download the React DevTools', 'New NativeEventEmitter',
      'Sending `', 'ViewManager:', 'Unbalanced calls', 'componentWillReceiveProps',
      'componentWillMount', 'Each child in a list', 'VirtualizedList:', 'LogBox',
      'DevConnect', '[DevConnect]',
    ];

    const isEmptyObj = (args: any[]) => {
      if (args.length === 1 && typeof args[0] === 'object' && args[0] !== null) {
        try { if (Object.keys(args[0]).length === 0) return true; } catch (_) {}
      }
      return false;
    };

    const isInternalError = (args: any[]) => {
      const s = String(args[0] ?? '');
      return s.includes("'responseText'") || s.includes('responseType') || s.includes('DevConnect');
    };

    const isSys = (args: any[]) => args.length === 0 || isEmptyObj(args) || isInternalError(args) || systemPrefixes.some((p) => String(args[0]).startsWith(p));
    const toStr = (args: any[]) => args.map((a) => typeof a === 'string' ? a : (() => { try { return JSON.stringify(a, null, 2); } catch (_) { return String(a); } })()).join(' ');
    const toMeta = (args: any[]): Record<string, any> | undefined => {
      if (args.length === 1 && typeof args[0] === 'object' && args[0] !== null) { try { return JSON.parse(JSON.stringify(args[0])); } catch (_) {} }
      return undefined;
    };

    const patch = (method: string, level: string, origFn: Function) => (...args: any[]) => {
      origFn(...args);
      if (!isSys(args)) dc.send('client:log', { level, message: toStr(args), tag: `console.${method}`, ...(toMeta(args) ? { metadata: toMeta(args) } : {}) });
    };

    console.log = patch('log', 'debug', orig.log);
    console.debug = patch('debug', 'debug', orig.debug);
    console.info = patch('info', 'info', orig.info);
    console.warn = patch('warn', 'warn', orig.warn);
    console.error = patch('error', 'error', orig.error);
    if (console.trace) console.trace = patch('trace', 'debug', orig.trace!);
  }

  // ---- Public API ----

  static log(message: string, tag?: string, metadata?: Record<string, any>): void {
    DevConnect.safeSend('client:log', { level: 'info', message, ...(tag ? { tag } : {}), ...(metadata ? { metadata } : {}) });
  }
  static debug(message: string, tag?: string, metadata?: Record<string, any>): void {
    DevConnect.safeSend('client:log', { level: 'debug', message, ...(tag ? { tag } : {}), ...(metadata ? { metadata } : {}) });
  }
  static warn(message: string, tag?: string, metadata?: Record<string, any>): void {
    DevConnect.safeSend('client:log', { level: 'warn', message, ...(tag ? { tag } : {}), ...(metadata ? { metadata } : {}) });
  }
  static error(message: string, tag?: string, stackTrace?: string, metadata?: Record<string, any>): void {
    DevConnect.safeSend('client:log', { level: 'error', message, ...(tag ? { tag } : {}), ...(stackTrace ? { stackTrace } : {}), ...(metadata ? { metadata } : {}) });
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
    metricType: 'fps' | 'frame_build_time' | 'frame_raster_time' | 'memory_usage' | 'memory_peak' | 'cpu_usage' | 'jank_frame';
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
  static benchmark(title: string): void {
    const dc = DevConnect.getInstanceSafe();
    if (dc) {
      dc._benchmarks.set(title, { title, startTime: Date.now(), steps: [] });
    }
  }

  static benchmarkStep(title: string, stepTitle: string): void {
    const dc = DevConnect.getInstanceSafe();
    if (dc) {
      const b = dc._benchmarks.get(title);
      if (b) b.steps.push({ title: stepTitle, timestamp: Date.now() });
    }
  }

  static benchmarkStop(title: string): void {
    const dc = DevConnect.getInstanceSafe();
    if (!dc) return;
    const b = dc._benchmarks.get(title);
    if (b) {
      const endTime = Date.now();
      const steps = b.steps.map((s, i) => ({
        ...s,
        delta: i === 0 ? s.timestamp - b.startTime : s.timestamp - b.steps[i - 1].timestamp,
      }));

      dc.send('client:benchmark', {
        title: b.title,
        startTime: b.startTime,
        endTime,
        duration: endTime - b.startTime,
        steps,
      });

      dc._benchmarks.delete(title);
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
    const instance = DevConnect.getInstanceSafe();
    if (instance) {
      instance._customCommandHandlers.set(name, handler);
    } else {
      const interval = setInterval(() => {
        const dc = DevConnect.getInstanceSafe();
        if (dc) {
          dc._customCommandHandlers.set(name, handler);
          clearInterval(interval);
        }
      }, 100);
      setTimeout(() => clearInterval(interval), 10000);
    }
  }
}

declare let __DEV__: boolean;
