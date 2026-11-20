import 'package:devconnect_manage_kit/src/devconnect_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// The desktop's Database tab parses this shape (DatabaseTable /
/// DatabaseColumn), so it must not drift.
void main() {
  test('reads tables, columns and row counts through the SQL runner', () async {
    final seen = <String>[];
    Future<List<Map<String, Object?>>> query(String sql) async {
      seen.add(sql);
      if (sql.startsWith('SELECT name FROM sqlite_master')) {
        return [
          {'name': 'my "users"'},
        ];
      }
      if (sql.startsWith('PRAGMA table_info')) {
        return [
          {'cid': 0, 'name': 'id', 'type': 'INTEGER', 'notnull': 1, 'pk': 1},
          {'cid': 1, 'name': 'email', 'type': 'TEXT', 'notnull': 0, 'pk': 0},
        ];
      }
      if (sql.startsWith('SELECT COUNT(*)')) {
        return [
          {'c': 3},
        ];
      }
      throw UnsupportedError(sql);
    }

    expect(await DevConnectClient.sqliteTables(query), [
      {
        'name': 'my "users"',
        'columns': [
          {
            'name': 'id',
            'type': 'INTEGER',
            'isPrimaryKey': true,
            'isNullable': false,
          },
          {
            'name': 'email',
            'type': 'TEXT',
            'isPrimaryKey': false,
            'isNullable': true,
          },
        ],
        'rowCount': 3,
      },
    ]);
    // Table names are quoted, embedded quotes doubled.
    expect(seen, contains('PRAGMA table_info("my ""users""")'));
  });

  test('an unreadable database lists no tables instead of throwing', () async {
    expect(
      await DevConnectClient.sqliteTables((_) async => throw StateError('x')),
      isEmpty,
    );
  });
}
