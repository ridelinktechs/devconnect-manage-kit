import { DevConnect } from '../../client';

/**
 * Reporter for react-native-sqlite-storage / expo-sqlite operations.
 *
 * ```typescript
 * import { DevConnectSQLite } from 'devconnect-manage-kit';
 *
 * const reporter = new DevConnectSQLite();
 * const results = await db.executeSql('SELECT * FROM users');
 * reporter.reportQuery('SELECT * FROM users', results[0].rows.raw());
 *
 * await db.executeSql('INSERT INTO users (name) VALUES (?)', ['John']);
 * reporter.reportExecute('INSERT INTO users (name) VALUES (?)', { name: 'John' });
 * ```
 */
export class DevConnectSQLite {
  reportQuery(sql: string, results?: any): void {
    DevConnect.reportStorageOperation({
      storageType: 'sqlite',
      key: sql,
      value: results,
      operation: 'read',
    });
  }

  reportExecute(sql: string, params?: any): void {
    const op = sql.trim().toUpperCase();
    const operation = op.startsWith('DELETE') ? 'delete' : 'write';
    DevConnect.reportStorageOperation({
      storageType: 'sqlite',
      key: sql,
      value: params,
      operation,
    });
  }
}
