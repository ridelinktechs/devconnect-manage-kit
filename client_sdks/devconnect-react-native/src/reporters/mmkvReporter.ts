import { DevConnect } from '../client';

/**
 * MMKV storage reporter that auto-reports all storage operations to DevConnect.
 *
 * Usage:
 * ```typescript
 * import { MMKV } from 'react-native-mmkv';
 * import { DevConnectMMKV } from 'devconnect-react-native';
 *
 * const storage = new MMKV();
 *
 * // Option 1: Patch in-place (monkey-patches the instance)
 * DevConnectMMKV.wrap(storage);
 * storage.set('token', 'abc123');  // automatically reported
 *
 * // Option 2: Use a wrapped version
 * const trackedStorage = DevConnectMMKV.create(storage);
 * trackedStorage.set('token', 'abc123');
 * ```
 *
 * With a named instance:
 * ```typescript
 * const storage = new MMKV({ id: 'user-storage' });
 * DevConnectMMKV.wrap(storage, 'user-storage');
 * ```
 */
export class DevConnectMMKV {
  /**
   * Monkey-patches an MMKV instance in-place so all calls are auto-intercepted.
   *
   * @param mmkv The MMKV instance to patch
   * @param label Optional label to identify this storage instance (default: 'mmkv')
   */
  static wrap(mmkv: any, label: string = 'mmkv'): void {
    const storageType = `mmkv:${label}`;

    // --- set(key, value) ---
    const originalSet = mmkv.set.bind(mmkv);
    mmkv.set = (key: string, value: any) => {
      const result = originalSet(key, value);
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

    // --- getString(key) ---
    const originalGetString = mmkv.getString?.bind(mmkv);
    if (originalGetString) {
      mmkv.getString = (key: string) => {
        const value = originalGetString(key);
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

    // --- getNumber(key) ---
    const originalGetNumber = mmkv.getNumber?.bind(mmkv);
    if (originalGetNumber) {
      mmkv.getNumber = (key: string) => {
        const value = originalGetNumber(key);
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

    // --- getBoolean(key) ---
    const originalGetBoolean = mmkv.getBoolean?.bind(mmkv);
    if (originalGetBoolean) {
      mmkv.getBoolean = (key: string) => {
        const value = originalGetBoolean(key);
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

    // --- getBuffer(key) ---
    const originalGetBuffer = mmkv.getBuffer?.bind(mmkv);
    if (originalGetBuffer) {
      mmkv.getBuffer = (key: string) => {
        const value = originalGetBuffer(key);
        try {
          DevConnect.reportStorageOperation({
            storageType,
            key,
            value: value ? `<Buffer ${value.length} bytes>` : undefined,
            operation: 'read',
          });
        } catch (_) {}
        return value;
      };
    }

    // --- delete(key) ---
    const originalDelete = mmkv.delete.bind(mmkv);
    mmkv.delete = (key: string) => {
      const result = originalDelete(key);
      try {
        DevConnect.reportStorageOperation({
          storageType,
          key,
          operation: 'delete',
        });
      } catch (_) {}
      return result;
    };

    // --- clearAll() ---
    const originalClearAll = mmkv.clearAll?.bind(mmkv);
    if (originalClearAll) {
      mmkv.clearAll = () => {
        const result = originalClearAll();
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

    // --- getAllKeys() ---
    const originalGetAllKeys = mmkv.getAllKeys?.bind(mmkv);
    if (originalGetAllKeys) {
      mmkv.getAllKeys = () => {
        const keys = originalGetAllKeys();
        try {
          DevConnect.log(
            `MMKV(${label}).getAllKeys: ${keys?.length ?? 0} keys`,
            'Storage',
          );
        } catch (_) {}
        return keys;
      };
    }

    // --- contains(key) ---
    const originalContains = mmkv.contains?.bind(mmkv);
    if (originalContains) {
      mmkv.contains = (key: string) => {
        const result = originalContains(key);
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
  }

  /**
   * Returns a wrapped proxy of an MMKV instance that reports operations.
   * Does not modify the original instance.
   *
   * @param mmkv The MMKV instance to wrap
   * @param label Optional label to identify this storage instance
   * @returns A proxied MMKV-like object
   */
  static create(mmkv: any, label: string = 'mmkv'): any {
    const storageType = `mmkv:${label}`;

    return {
      set(key: string, value: any) {
        mmkv.set(key, value);
        try {
          DevConnect.reportStorageOperation({
            storageType,
            key,
            value: safeValue(value),
            operation: 'write',
          });
        } catch (_) {}
      },

      getString(key: string): string | undefined {
        const value = mmkv.getString(key);
        try {
          DevConnect.reportStorageOperation({
            storageType,
            key,
            value,
            operation: 'read',
          });
        } catch (_) {}
        return value;
      },

      getNumber(key: string): number | undefined {
        const value = mmkv.getNumber(key);
        try {
          DevConnect.reportStorageOperation({
            storageType,
            key,
            value,
            operation: 'read',
          });
        } catch (_) {}
        return value;
      },

      getBoolean(key: string): boolean | undefined {
        const value = mmkv.getBoolean(key);
        try {
          DevConnect.reportStorageOperation({
            storageType,
            key,
            value,
            operation: 'read',
          });
        } catch (_) {}
        return value;
      },

      getBuffer(key: string): any {
        const value = mmkv.getBuffer?.(key);
        try {
          DevConnect.reportStorageOperation({
            storageType,
            key,
            value: value ? `<Buffer ${value.length} bytes>` : undefined,
            operation: 'read',
          });
        } catch (_) {}
        return value;
      },

      delete(key: string) {
        mmkv.delete(key);
        try {
          DevConnect.reportStorageOperation({
            storageType,
            key,
            operation: 'delete',
          });
        } catch (_) {}
      },

      clearAll() {
        mmkv.clearAll();
        try {
          DevConnect.reportStorageOperation({
            storageType,
            key: '*',
            operation: 'clear',
          });
        } catch (_) {}
      },

      getAllKeys(): string[] {
        const keys = mmkv.getAllKeys();
        try {
          DevConnect.log(
            `MMKV(${label}).getAllKeys: ${keys?.length ?? 0} keys`,
            'Storage',
          );
        } catch (_) {}
        return keys;
      },

      contains(key: string): boolean {
        const result = mmkv.contains(key);
        try {
          DevConnect.reportStorageOperation({
            storageType,
            key,
            value: result,
            operation: 'contains',
          });
        } catch (_) {}
        return result;
      },
    };
  }
}

function safeValue(value: any): any {
  if (value === null || value === undefined) return value;
  if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
    return value;
  }
  if (value instanceof ArrayBuffer || (typeof Buffer !== 'undefined' && Buffer.isBuffer(value))) {
    return `<Buffer ${(value as any).byteLength ?? (value as any).length} bytes>`;
  }
  try {
    return JSON.parse(JSON.stringify(value));
  } catch (_) {
    return String(value);
  }
}
