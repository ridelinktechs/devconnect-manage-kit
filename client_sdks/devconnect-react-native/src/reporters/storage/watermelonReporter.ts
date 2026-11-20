import { DevConnect } from '../../client';

/**
 * Reporter for WatermelonDB operations.
 *
 * ```typescript
 * import { DevConnectWatermelon } from 'devconnect-manage-kit';
 *
 * const reporter = new DevConnectWatermelon();
 * // After a query
 * const posts = await postsCollection.query().fetch();
 * reporter.reportQuery('Post', posts.length);
 *
 * // After a write
 * await database.write(async () => {
 *   await postsCollection.create(post => { post.title = 'Hello'; });
 * });
 * reporter.reportWrite('Post', { title: 'Hello' });
 *
 * // After a delete
 * reporter.reportDelete('Post', { id: post.id });
 * ```
 */
export class DevConnectWatermelon {
  reportQuery(tableName: string, resultCount: number, query?: string): void {
    DevConnect.reportStorageOperation({
      storageType: 'watermelondb',
      key: tableName,
      value: { resultCount, query },
      operation: 'read',
    });
  }

  reportWrite(tableName: string, data?: any): void {
    DevConnect.reportStorageOperation({
      storageType: 'watermelondb',
      key: tableName,
      value: data,
      operation: 'write',
    });
  }

  reportDelete(tableName: string, data?: any): void {
    DevConnect.reportStorageOperation({
      storageType: 'watermelondb',
      key: tableName,
      value: data,
      operation: 'delete',
    });
  }

  reportBatchWrite(tableName: string, count: number): void {
    DevConnect.reportStorageOperation({
      storageType: 'watermelondb',
      key: tableName,
      value: { batchCount: count },
      operation: 'write',
    });
  }
}
