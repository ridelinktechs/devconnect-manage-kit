import { NativeModules } from 'react-native';

// Captured before the app can install the WebSocket interceptor: DevConnect's own
// sockets must never be wrapped, or reporting a frame would send (and report) another.
export const NativeWebSocket: typeof WebSocket = (globalThis as any).WebSocket;

// ---- Encrypted host cache (persists via AsyncStorage if available) ----

const CACHE_KEY = 'DcN3t$ecR7!';
let _cachedHost: { host: string; machineId: string } | null = null;

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
    return (globalThis as any).Buffer.from(xored, 'binary').toString('base64');
  }
}

function decryptCache(encrypted: string): any {
  try {
    let decoded: string;
    try { decoded = atob(encrypted); } catch (_) {
      decoded = (globalThis as any).Buffer.from(encrypted, 'base64').toString('binary');
    }
    const plain = xorCipher(decoded, CACHE_KEY);
    return JSON.parse(plain);
  } catch (_) { return null; }
}

export async function saveHostCache(host: string, machineId?: string): Promise<void> {
  _cachedHost = machineId ? { host, machineId } : null;
  // If we have no machineId to associate the host with, write a minimal entry
  // (preserves in-memory reconnect for the lifetime of this process).
  try {
    const AsyncStorage = require('@react-native-async-storage/async-storage')?.default;
    if (AsyncStorage) {
      const payload: any = { h: host, t: Date.now() };
      if (machineId) payload.m = machineId;
      const encrypted = encryptCache(payload);
      await AsyncStorage.setItem('__dc_s', encrypted);
    }
  } catch (_) {}
}

async function clearHostCache(): Promise<void> {
  _cachedHost = null;
  try {
    const AsyncStorage = require('@react-native-async-storage/async-storage')?.default;
    if (AsyncStorage) {
      await AsyncStorage.removeItem('__dc_s');
    }
  } catch (_) {}
}

/**
 * Probe a WebSocket connection just long enough to read the server's
 * `server:hello` and check that its machineId matches what we cached.
 * Returns true only on a positive identity match.
 *
 * This prevents connecting to the wrong machine when switching between
 * iOS Simulator and a real device on the same network (where the cached
 * IP could now point at a different host that just happens to listen on
 * the same port).
 */
async function verifyCachedHost(host: string, port: number, expectedId: string): Promise<boolean> {
  return new Promise<boolean>((resolve) => {
    let done = false;
    // Declare timer/ws as mutable null so they're safely accessible from
    // `finish` even before `setTimeout` / `new WebSocket` complete.
    let timer: ReturnType<typeof setTimeout> | null = null;
    let ws: WebSocket | null = null;
    const finish = (ok: boolean) => {
      if (done) return;
      done = true;
      if (timer !== null) {
        clearTimeout(timer);
        timer = null;
      }
      if (ws) {
        try { ws.close(); } catch (_) {}
        ws = null;
      }
      resolve(ok);
    };

    try {
      ws = new NativeWebSocket(`ws://${host}:${port}`);
    } catch (_) {
      return resolve(false);
    }

    timer = setTimeout(() => finish(false), 1500);

    ws.onopen = () => {
      // Server should send server:hello immediately on connect
    };
    ws.onmessage = (event: WebSocketMessageEvent) => {
      try {
        const msg = JSON.parse(event.data as string);
        if (msg && msg.type === 'server:hello') {
          const announcedId = msg.payload && msg.payload.machineId;
          finish(announcedId === expectedId);
        }
      } catch (_) {}
    };
    ws.onerror = () => finish(false);
    ws.onclose = () => finish(false);
  });
}

async function readHostCache(port: number): Promise<{ host: string; machineId: string } | null> {
  if (_cachedHost) return _cachedHost;
  try {
    const AsyncStorage = require('@react-native-async-storage/async-storage')?.default;
    if (AsyncStorage) {
      const encrypted = await AsyncStorage.getItem('__dc_s');
      if (encrypted) {
        const data = decryptCache(encrypted);
        // Legacy caches (no machineId) cannot be verified and would re-trigger
        // the simulator/device-swap bug we are fixing — treat them as absent.
        if (data && typeof data.h === 'string' && typeof data.m === 'string' &&
            Date.now() - data.t < 24 * 60 * 60 * 1000) {
          _cachedHost = { host: data.h, machineId: data.m };
          return _cachedHost;
        }
      }
    }
  } catch (_) {}
  return null;
}

// ---- Auto-detect host (supports real device iOS/Android) ----

async function tryConnect(host: string, port: number, timeoutMs: number): Promise<boolean> {
  try {
    const ws = new NativeWebSocket(`ws://${host}:${port}`);
    return await new Promise<boolean>((resolve) => {
      const timer = setTimeout(() => { try { ws.close(); } catch (_) {} resolve(false); }, timeoutMs);
      ws.onopen = () => { clearTimeout(timer); try { ws.close(); } catch (_) {} resolve(true); };
      ws.onerror = () => { clearTimeout(timer); resolve(false); };
    });
  } catch (_) { return false; }
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

export async function autoDetectHost(port: number): Promise<string> {
  // 0. Try cached host from previous session (instant reconnect).
  //    Verify the server's stable machineId matches what we cached —
  //    catches the case where the cached IP now points at a different
  //    device (e.g. iOS Simulator ↔ real iPhone swap on the same network).
  const cached = await readHostCache(port);
  if (cached) {
    if (await verifyCachedHost(cached.host, port, cached.machineId)) {
      return cached.host;
    }
    // Stale or wrong machine — invalidate so the next discovery wins.
    await clearHostCache();
  }

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
  if (raceResult) { await saveHostCache(raceResult); return raceResult; }

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
        await saveHostCache(r.value);
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
