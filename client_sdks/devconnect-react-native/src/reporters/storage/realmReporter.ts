import { DevConnect } from '../../client';

/**
 * Reporter for Realm React Native operations.
 *
 * ```typescript
 * import { DevConnectRealm } from 'devconnect-manage-kit';
 *
 * const reporter = new DevConnectRealm();
 * const users = realm.objects('User');
 * reporter.reportQuery('User', users.length);
 *
 * realm.write(() => { realm.create('User', { name: 'John' }); });
 * reporter.reportWrite('User', { name: 'John' });
 * ```
 */
export class DevConnectRealm {
  reportQuery(className: string, resultCount: number): void {
    DevConnect.reportStorageOperation({
      storageType: 'realm',
      key: className,
      value: { resultCount },
      operation: 'read',
    });
  }

  reportWrite(className: string, data?: any): void {
    DevConnect.reportStorageOperation({
      storageType: 'realm',
      key: className,
      value: data,
      operation: 'write',
    });
  }

  reportDelete(className: string, data?: any): void {
    DevConnect.reportStorageOperation({
      storageType: 'realm',
      key: className,
      value: data,
      operation: 'delete',
    });
  }
}
