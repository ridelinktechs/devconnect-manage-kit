import { DevConnect } from '../../client';

/**
 * Manual storage reporter for non-AsyncStorage stores (MMKV, SecureStore, etc.)
 *
 * ```typescript
 * const mmkvReporter = new DevConnectStorage('mmkv');
 * mmkvReporter.reportWrite('user_token', 'abc123');
 * ```
 */
export class DevConnectStorage {
  constructor(private storageType: string = 'async_storage') {}

  reportRead(key: string, value?: any): void {
    DevConnect.reportStorageOperation({
      storageType: this.storageType, key, value, operation: 'read',
    });
  }

  reportWrite(key: string, value?: any): void {
    DevConnect.reportStorageOperation({
      storageType: this.storageType, key, value, operation: 'write',
    });
  }

  reportDelete(key: string): void {
    DevConnect.reportStorageOperation({
      storageType: this.storageType, key, operation: 'delete',
    });
  }

  reportClear(): void {
    DevConnect.reportStorageOperation({
      storageType: this.storageType, key: '*', operation: 'clear',
    });
  }
}
