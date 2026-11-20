import { DevConnect } from '../../client';

/**
 * Reporter for react-native-encrypted-storage.
 *
 * ```typescript
 * import EncryptedStorage from 'react-native-encrypted-storage';
 * import { DevConnectEncryptedStorage } from 'devconnect-manage-kit';
 *
 * DevConnectEncryptedStorage.patchInPlace(EncryptedStorage);
 * // All getItem/setItem/removeItem/clear automatically reported
 * ```
 */
export class DevConnectEncryptedStorage {
  static patchInPlace(storage: any): void {
    const origGet = storage.getItem.bind(storage);
    const origSet = storage.setItem.bind(storage);
    const origRemove = storage.removeItem.bind(storage);
    const origClear = storage.clear.bind(storage);

    storage.getItem = async (key: string) => {
      const value = await origGet(key);
      DevConnect.reportStorageOperation({
        storageType: 'encrypted_storage', key, value, operation: 'read',
      });
      return value;
    };

    storage.setItem = async (key: string, value: string) => {
      await origSet(key, value);
      DevConnect.reportStorageOperation({
        storageType: 'encrypted_storage', key, value: '***', operation: 'write',
      });
    };

    storage.removeItem = async (key: string) => {
      await origRemove(key);
      DevConnect.reportStorageOperation({
        storageType: 'encrypted_storage', key, operation: 'delete',
      });
    };

    storage.clear = async () => {
      await origClear();
      DevConnect.reportStorageOperation({
        storageType: 'encrypted_storage', key: '*', operation: 'clear',
      });
    };
  }
}
