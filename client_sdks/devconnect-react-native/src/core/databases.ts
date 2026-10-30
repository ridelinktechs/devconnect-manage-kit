/** A key-value store the desktop can read and edit (see `registerStorage`). */
export interface StorageAdapter {
  getAll(): Promise<Record<string, any>> | Record<string, any>;
  set(key: string, value: any): Promise<void> | void;
  remove(key: string): Promise<void> | void;
  clear(): Promise<void> | void;
}

/** Runs one SQL statement against an app database and returns its rows. */
export type DatabaseQuery = (
  sql: string,
) => Promise<Array<Record<string, any>>> | Array<Record<string, any>>;

/** Rows past this are left out of a query result, which says `truncated`. */
export const MAX_QUERY_ROWS = 1000;

/** SQLite tables with their columns and row counts; empty if unreadable. */
export async function sqliteTables(query: DatabaseQuery): Promise<Array<Record<string, any>>> {
  try {
    const names = await query(
      "SELECT name FROM sqlite_master WHERE type = 'table' " +
        "AND name NOT LIKE 'sqlite_%' AND name <> 'android_metadata' ORDER BY name",
    );
    const tables: Array<Record<string, any>> = [];
    for (const row of names) {
      const table = String(row.name);
      const quoted = `"${table.replace(/"/g, '""')}"`;
      const columns = await query(`PRAGMA table_info(${quoted})`);
      const [count] = await query(`SELECT COUNT(*) AS c FROM ${quoted}`);
      tables.push({
        name: table,
        columns: columns.map((c) => ({
          name: String(c.name),
          type: String(c.type ?? ''),
          isPrimaryKey: Number(c.pk) > 0,
          isNullable: Number(c.notnull) === 0,
        })),
        rowCount: Number(count?.c ?? 0),
      });
    }
    return tables;
  } catch (_) {
    return [];
  }
}
