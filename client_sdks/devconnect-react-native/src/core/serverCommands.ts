import { Platform, NativeModules, Dimensions } from 'react-native';
import type { DevConnect } from '../client';
import { captureComponentTree, withTimeout, type LayoutNode } from '../plugins/layout/layoutInspector';
import { SDK_VERSION } from '../version';
import { MAX_QUERY_ROWS, sqliteTables, type StorageAdapter } from './databases';

/**
 * Default handler for `server:reload`.
 *
 * RN offers a public `DevSettings.reload()` (auto-linked from
 * `react-native`) that's the same path the dev menu's "Reload" option
 * uses — it tears down the bridge and re-bootstraps the JS bundle from
 * Metro. Works in dev builds only; release builds no-op.
 *
 * Apps can register a custom reload handler via
 * `DevConnect.registerReloadHandler(() => { ... })` to wipe in-memory
 * caches before the reload (e.g. Redux/MobX stores).
 */
export function _reloadApp(dc: DevConnect): void {
  // Try the custom handler first. If it succeeds we're done — the
  // handler takes full responsibility for the reload. If it throws,
  // we DO fall through to the default DevSettings.reload() below,
  // so the user still gets a reload even when their custom code
  // crashed mid-execution.
  if (dc._reloadHandler) {
    try {
      dc._reloadHandler();
      return;
    } catch (_) {
      // handler threw — continue to default below
    }
  }
  try {
    const DevSettings = (NativeModules as any).DevSettings;
    if (DevSettings && typeof DevSettings.reload === 'function') {
      // DevSettings.reload() takes no arguments. Older versions of the
      // native side may still throw "called with 1 arguments but expects
      // 0" if you pass anything — keep the call empty to stay compatible.
      DevSettings.reload();
    }
  } catch (_) {
    // DevSettings not available (release build / not yet initialized)
  }
}

export function sendHandshake(dc: DevConnect): void {
  const os = Platform.OS; // 'ios' | 'android'
  const version = Platform.Version; // e.g. '17.4' (iOS) or 34 (Android API level)
  const osLabel = os === 'ios' ? 'iOS' : os === 'android' ? 'Android' : os;

  // Get actual device model name
  let deviceModel = `${osLabel} Device`;
  try {
    if (os === 'ios') {
      // iOS: prefer interfaceIdiom (iPhone/iPad/tv) over generic systemName
      const constants = (NativeModules.PlatformConstants || NativeModules.DeviceInfo) as Record<string, any> | undefined;
      const iosModel = constants?.interfaceIdiom;
      const systemName = constants?.systemName;
      if (iosModel === 'phone') {
        deviceModel = 'iPhone';
      } else if (iosModel === 'pad') {
        deviceModel = 'iPad';
      } else if (iosModel === 'tv') {
        deviceModel = 'tvOS Device';
      } else if (systemName) {
        deviceModel = `${systemName} Device`;
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

  dc.send('client:handshake', {
    deviceInfo: {
      deviceId: dc.deviceId,
      deviceName: deviceModel,
      platform: 'react_native',
      osVersion: `${osLabel} ${version}`,
      appName: dc.config.appName,
      appVersion: dc.config.appVersion,
      ...(dc.config.versionCode ? { versionCode: dc.config.versionCode } : {}),
      sdkVersion: SDK_VERSION,
    },
  });
  _announceCommands(dc);
}

/** Read / write / delete / clear a registered storage, then send its contents. */
export async function _handleStorageCommand(dc: DevConnect, type: string, p: Record<string, any>): Promise<void> {
  const targets: Array<[string, StorageAdapter | undefined]> = p.storageType
    ? [[p.storageType, dc._storages.get(p.storageType)]]
    : [...dc._storages];
  for (const [storageType, adapter] of targets) {
    if (!adapter) continue;
    try {
      if (type === 'server:storage:write') await adapter.set(p.key, p.value);
      else if (type === 'server:storage:delete') await adapter.remove(p.key);
      else if (type === 'server:storage:clear') await adapter.clear();
      dc.send('client:storage:all_data', { storageType, entries: await adapter.getAll() });
    } catch (e: any) {
      dc.send('client:storage:all_data', { storageType, entries: {}, error: e?.message ?? String(e) });
    }
  }
}

/** Screen size, the registered screenshot and the component tree, for the Layout tab. */
export async function _layoutSnapshot(dc: DevConnect): Promise<Record<string, any>> {
  const { width, height } = Dimensions.get('window');
  // A failure is reported, not swallowed: an empty tree alone says nothing.
  let roots: LayoutNode[] = [];
  let truncated = false;
  let error: string | undefined;
  try {
    ({ roots, truncated } = await captureComponentTree());
  } catch (e: any) {
    error = String(e?.message ?? e);
  }
  let screenshot: string | null = null;
  if (dc._screenshot) {
    try {
      screenshot = String(await withTimeout(dc._screenshot(), 5000))
        .replace(/^data:image\/\w+;base64,/, '');
    } catch (_) {
      // The tree is still useful without a picture.
    }
  }
  return {
    width,
    height,
    screenshot,
    root: roots.length === 1
      ? roots[0]
      : { id: 'root', name: 'Root', x: 0, y: 0, w: width, h: height, props: {}, children: roots },
    ...(truncated ? { truncated } : {}),
    ...(error ? { error } : {}),
  };
}

/** Sends a captured request again through the app's own (intercepted) fetch. */
export function _replayRequest(p: Record<string, any>): void {
  if (typeof p.url !== 'string') return;
  const method = String(p.method ?? 'GET').toUpperCase();
  const hasBody = p.body != null && method !== 'GET' && method !== 'HEAD';
  // The global fetch is the intercepted one, so the replay is captured.
  fetch(p.url, {
    method,
    headers: p.headers ?? {},
    body: hasBody ? (typeof p.body === 'string' ? p.body : JSON.stringify(p.body)) : undefined,
  }).catch(() => {}); // the failure is reported like any other request
}

export async function _databaseSchemas(dc: DevConnect): Promise<Array<Record<string, any>>> {
  const schemas: Array<Record<string, any>> = [];
  for (const [name, query] of dc._databases) {
    schemas.push({ name, tables: await sqliteTables(query) });
  }
  return schemas;
}

export async function _runDatabaseQuery(dc: DevConnect, database: string | undefined, sql: string): Promise<Record<string, any>> {
  const start = Date.now();
  const result: Record<string, any> = { database };
  try {
    const query = dc._databases.get(database ?? '') ?? dc._databases.values().next().value;
    if (!query) throw new Error('No database registered with DevConnect.registerDatabase');
    const limited = /^\s*(select|with)\b/i.test(sql)
      ? `SELECT * FROM (${sql.replace(/[\s;]+$/, '')}\n) LIMIT ${MAX_QUERY_ROWS + 1}`
      : sql;
    let rows: Array<Record<string, any>>;
    try {
      rows = (await query(limited)) ?? [];
    } catch (e) {
      if (limited === sql) throw e;
      rows = (await query(sql)) ?? [];
    }
    result.columns = rows.length > 0 ? Object.keys(rows[0]) : [];
    result.rows = rows.slice(0, MAX_QUERY_ROWS);
    result.truncated = rows.length > MAX_QUERY_ROWS;
  } catch (e: any) {
    result.columns = [];
    result.rows = [];
    result.error = e?.message ?? String(e);
  }
  result.executionTimeMs = Date.now() - start;
  return result;
}

/** Tells the desktop which custom commands it can run (Commands panel). */
export function _announceCommands(dc: DevConnect): void {
  dc.send('client:custom:commands', {
    commands: [...dc._customCommandHandlers.keys()],
  });
}
