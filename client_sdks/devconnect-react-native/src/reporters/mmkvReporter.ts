import { DevConnect } from '../client';

/**
 * MMKV storage reporter that auto-reports all storage operations to DevConnect.
 *
 * Supports both MMKV v3 and v4:
 * - v3: `new MMKV()`, `.delete(key)`, mutable objects
 * - v4: `createMMKV()`, `.remove(key)`, frozen objects (requires Proxy)
 *
 * Usage:
 * ```typescript
 * import { MMKV } from 'react-native-mmkv';          // v3
 * // or
 * import { createMMKV } from 'react-native-mmkv';     // v4
 *
 * const storage = new MMKV();                          // or createMMKV()
 * const tracked = DevConnectMMKV.wrap(storage);
 * tracked.set('token', 'abc123');  // automatically reported
 *
 * // Or create + wrap in one call
 * const tracked = DevConnectMMKV.create();
 * tracked.set('token', 'abc123');
 * ```
 */
export class DevConnectMMKV {
  /**
   * Creates a Proxy-wrapped MMKV instance that reports all operations.
   * Works with both v3 (mutable) and v4 (frozen) MMKV objects.
   *
   * @param mmkv The MMKV instance to wrap
   * @param label Optional label for this storage instance (default: 'mmkv')
   * @returns A proxied MMKV-like object that auto-reports operations
   */
  static wrap(mmkv: any, label: string = 'mmkv'): any {
    const storageType = 'mmkv';

    // Resolve delete/remove — v4: .remove(), v3: .delete()
    const deleteFn: ((key: string) => any) | undefined =
      typeof mmkv.remove === 'function'
        ? mmkv.remove.bind(mmkv)
        : typeof mmkv.delete === 'function'
          ? mmkv.delete.bind(mmkv)
          : undefined;

    return new Proxy(mmkv, {
      get(target: any, prop: string | symbol, receiver: any) {
        const original = Reflect.get(target, prop, receiver);

        // ── Write ──
        if (prop === 'set') {
          return (key: string, value: any) => {
            const result = original.call(target, key, value);
            try {
              DevConnect.reportStorageOperation({
                storageType,
                key,
                value: safeValue(value),
                operation: 'write',
              });
            } catch (_) {}
            return result;
          };
        }

        // ── Delete/Remove — handle both v3 and v4 ──
        if (prop === 'delete' || prop === 'remove') {
          return (key: string) => {
            if (!deleteFn) return undefined;
            const result = deleteFn(key);
            try {
              DevConnect.reportStorageOperation({
                storageType,
                key,
                operation: 'delete',
              });
            } catch (_) {}
            return result;
          };
        }

        // ── Read: getString/getNumber/getBoolean ──
        if (
          prop === 'getString' ||
          prop === 'getNumber' ||
          prop === 'getBoolean'
        ) {
          return (key: string) => {
            const value = original.call(target, key);
            try {
              DevConnect.reportStorageOperation({
                storageType,
                key,
                value,
                operation: 'read',
              });
            } catch (_) {}
            return value;
          };
        }

        // ── Read: getBuffer ──
        if (prop === 'getBuffer') {
          return (key: string) => {
            const value = original.call(target, key);
            try {
              DevConnect.reportStorageOperation({
                storageType,
                key,
                value: value
                  ? `<Buffer ${value.length ?? value.byteLength} bytes>`
                  : undefined,
                operation: 'read',
              });
            } catch (_) {}
            return value;
          };
        }

        // ── Write: v3 encoding methods ──
        if (
          prop === 'encodeString' ||
          prop === 'encodeInt' ||
          prop === 'encodeBool' ||
          prop === 'encodeDouble' ||
          prop === 'encodeFloat'
        ) {
          return (key: string, value: any) => {
            const result = original.call(target, key, value);
            try {
              DevConnect.reportStorageOperation({
                storageType,
                key,
                value: safeValue(value),
                operation: 'write',
              });
            } catch (_) {}
            return result;
          };
        }

        // ── Read: v3 decoding methods ──
        if (
          prop === 'decodeString' ||
          prop === 'decodeInt' ||
          prop === 'decodeBool' ||
          prop === 'decodeDouble' ||
          prop === 'decodeFloat'
        ) {
          return (key: string, defaultValue?: any) => {
            const value =
              defaultValue !== undefined
                ? original.call(target, key, defaultValue)
                : original.call(target, key);
            try {
              DevConnect.reportStorageOperation({
                storageType,
                key,
                value,
                operation: 'read',
              });
            } catch (_) {}
            return value;
          };
        }

        // ── Delete: v3 removeValue/removeValuesForKeys ──
        if (prop === 'removeValue' || prop === 'removeValuesForKeys') {
          return (...args: any[]) => {
            const result = original.call(target, ...args);
            try {
              const keys = Array.isArray(args[0]) ? args[0] : [args[0]];
              for (const key of keys) {
                DevConnect.reportStorageOperation({
                  storageType,
                  key,
                  operation: 'delete',
                });
              }
            } catch (_) {}
            return result;
          };
        }

        // ── clearAll ──
        if (prop === 'clearAll') {
          return () => {
            const result = original.call(target);
            try {
              DevConnect.reportStorageOperation({
                storageType,
                key: '*',
                operation: 'clear',
              });
            } catch (_) {}
            return result;
          };
        }

        // ── contains ──
        if (prop === 'contains') {
          return (key: string) => {
            const result = original.call(target, key);
            try {
              DevConnect.reportStorageOperation({
                storageType,
                key,
                value: result,
                operation: 'contains',
              });
            } catch (_) {}
            return result;
          };
        }

        // ── getAllKeys — log only ──
        if (prop === 'getAllKeys') {
          return () => {
            const keys = original.call(target);
            try {
              DevConnect.log(
                `MMKV(${label}).getAllKeys: ${keys?.length ?? 0} keys`,
                'Storage',
              );
            } catch (_) {}
            return keys;
          };
        }

        // ── Everything else — pass through ──
        if (typeof original === 'function') {
          return original.bind(target);
        }
        return original;
      },
    });
  }

  /**
   * Creates a new MMKV instance and wraps it for auto-reporting.
   * Auto-detects v3 (new MMKV) vs v4 (createMMKV).
   *
   * @param config Optional MMKV configuration
   * @param label Optional label for this storage instance
   * @returns A proxied MMKV instance
   */
  static create(config?: any, label: string = 'mmkv'): any {
    let mmkv: any;

    try {
      const mod = require('react-native-mmkv');

      if (typeof mod.createMMKV === 'function') {
        // v4: createMMKV() factory
        mmkv = mod.createMMKV(config);
      } else if (typeof mod.MMKV === 'function') {
        // v3: new MMKV()
        mmkv = new mod.MMKV(config);
      } else {
        throw new Error(
          'react-native-mmkv: no MMKV constructor or createMMKV factory found',
        );
      }
    } catch (e: any) {
      if (e.message?.includes('react-native-mmkv')) throw e;
      throw new Error(
        `Failed to create MMKV instance. Make sure react-native-mmkv is installed. Error: ${e}`,
      );
    }

    return DevConnectMMKV.wrap(mmkv, label);
  }
}

function safeValue(value: any): any {
  if (value === null || value === undefined) return value;
  if (
    typeof value === 'string' ||
    typeof value === 'number' ||
    typeof value === 'boolean'
  ) {
    return value;
  }
  if (
    value instanceof ArrayBuffer ||
    (typeof Buffer !== 'undefined' && Buffer.isBuffer(value))
  ) {
    return `<Buffer ${(value as any).byteLength ?? (value as any).length} bytes>`;
  }
  try {
    return JSON.parse(JSON.stringify(value));
  } catch (_) {
    return String(value);
  }
}
