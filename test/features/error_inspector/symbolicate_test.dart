import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:devconnect_manage_tool/features/error_inspector/symbolication/symbolicate.dart';

/// Line 0: column 0 → App.tsx 1:1, column 10 → App.tsx 5:3 `onPress`.
/// Line 1: column 0 → App.tsx 6:3.
const _map = {
  'version': 3,
  'sources': ['App.tsx'],
  'sourceRoot': 'src/',
  'names': ['onPress'],
  'mappings': 'AAAA,UAIEA;AACA',
};

void main() {
  test('parses Hermes, V8 and JSC frames, skipping the rest', () {
    final frames = parseJsStack('''
TypeError: undefined is not a function
    at onPress (http://localhost:8081/index.bundle?platform=ios&dev=true:120:15)
    at apply (native)
    at baz (address at index.android.bundle:1:9876)
    at http://10.0.2.2:8081/index.bundle?platform=android:7:3
render@http://localhost:8081/index.bundle?platform=ios:42:8
@index.ios.bundle:1:500''');
    expect(frames, const [
      JsFrame(
        'onPress',
        'http://localhost:8081/index.bundle?platform=ios&dev=true',
        120,
        15,
      ),
      JsFrame('baz', 'index.android.bundle', 1, 9876),
      JsFrame(null, 'http://10.0.2.2:8081/index.bundle?platform=android', 7, 3),
      JsFrame(
        'render',
        'http://localhost:8081/index.bundle?platform=ios',
        42,
        8,
      ),
      JsFrame(null, 'index.ios.bundle', 1, 500),
    ]);
  });

  test('finds the Metro that served a bundle, as reachable from here', () {
    expect(
      metroOf('http://10.0.2.2:8081/index.bundle?platform=android'),
      Uri.parse('http://localhost:8081'),
    );
    expect(
      metroOf('http://192.168.1.5:8088/index.bundle'),
      Uri.parse('http://192.168.1.5:8088'),
    );
    expect(metroOf('index.android.bundle'), isNull);
  });

  test('decodes source map positions', () {
    final consumer = SourceMapConsumer(_map);
    expect(consumer.lookup(0, 12), (
      source: 'src/App.tsx',
      line: 5,
      column: 3,
      name: 'onPress',
    ));
    expect(consumer.lookup(0, 4), (
      source: 'src/App.tsx',
      line: 1,
      column: 1,
      name: null,
    ));
    expect(consumer.lookup(1, 0)?.line, 6);
    expect(consumer.lookup(9, 0), isNull);
  });

  test('release frames resolve through an uploaded source map', () async {
    final frames = parseJsStack(
      '    at a (address at index.android.bundle:1:13)',
    );
    expect(await symbolicate(frames, [_map]), const [
      JsFrame('onPress', 'src/App.tsx', 5, 3),
    ]);
    expect(await symbolicate(frames, const []), isNull);
  });

  test('dev frames resolve through Metro', () async {
    final client = MockClient((request) async {
      expect(request.url, Uri.parse('http://localhost:8081/symbolicate'));
      final stack = (jsonDecode(request.body) as Map)['stack'] as List;
      expect((stack.single as Map)['lineNumber'], 120);
      return http.Response(
        jsonEncode({
          'stack': [
            {
              'file': '/Users/me/app/src/App.tsx',
              'lineNumber': 10,
              'column': 5,
              'methodName': 'onPress',
            },
          ],
        }),
        200,
      );
    });
    final frames = parseJsStack(
      '    at onPress (http://10.0.2.2:8081/index.bundle?platform=android:120:15)',
    );
    expect(await symbolicate(frames, const [], client: client), const [
      JsFrame('onPress', '/Users/me/app/src/App.tsx', 10, 5),
    ]);
  });
}
