import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/components/viewers/json_paths.dart';

void main() {
  test('builds JSONPath-style paths', () {
    expect(jsonChildPath('', 'data'), 'data');
    expect(jsonChildPath('data', 'users'), 'data.users');
    expect(jsonChildPath('data.users', 0), 'data.users[0]');
    expect(jsonChildPath('headers', 'content-type'), 'headers["content-type"]');
    expect(jsonChildPath('', 'a "b"'), '["a \\"b\\""]');
  });

  const data = {
    'data': {
      'users': [
        {'name': 'An', 'city': 'Hanoi'},
        {'name': 'Binh', 'city': 'Da Nang'},
      ],
      'cityCount': 2,
    },
  };

  test('finds keys and values in document order, and their containers', () {
    final found = jsonSearch(data, 'CITY');
    expect(found.matches, [
      'data.users[0].city',
      'data.users[1].city',
      'data.cityCount',
    ]);
    expect(found.ancestors, {
      '',
      'data',
      'data.users',
      'data.users[0]',
      'data.users[1]',
    });

    expect(jsonSearch(data, 'nang').matches, ['data.users[1].city']);
    expect(jsonSearch(data, '  ').matches, isEmpty);
  });

  test('a list of objects becomes a table, anything else does not', () {
    expect(
      jsonTableColumns([
        {'id': 1, 'name': 'An'},
        {'id': 2, 'email': 'b@c.d'},
      ]),
      ['id', 'name', 'email'],
    );
    expect(jsonTableColumns([1, 2]), isNull);
    expect(jsonTableColumns(const []), isNull);
    expect(jsonTableColumns(data), isNull);
  });

  const users = [
    {'id': 1, 'name': 'An Nguyen', 'city': 'Hanoi'},
    {
      'id': 2,
      'name': 'Binh, "B" Tran',
      'tags': ['vip'],
    },
    {'id': 3, 'name': 'Chi Le', 'city': 'Hue'},
  ];

  test('filters table rows by any cell, case-insensitively', () {
    expect(jsonTableFilter(users, 'HUE'), [2]);
    expect(jsonTableFilter(users, 'vip'), [1]);
    expect(jsonTableFilter(users, '  '), [0, 1, 2]);
    expect(jsonTableFilter(users, 'nobody'), isEmpty);
  });

  test('exports a table as CSV with quoting and empty missing cells', () {
    expect(
      jsonTableCsv(users.cast<Map>(), jsonTableColumns(users)!),
      'id,name,city,tags\r\n'
      '1,An Nguyen,Hanoi,\r\n'
      '2,"Binh, ""B"" Tran",,"[""vip""]"\r\n'
      '3,Chi Le,Hue,',
    );
  });
}
