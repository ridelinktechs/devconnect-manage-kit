import 'dart:convert';
import 'dart:isolate';

import 'package:http/http.dart' as http;

/// One JavaScript stack frame: where it ran, or (once symbolicated) where
/// that code lives in the sources.
class JsFrame {
  final String? method;
  final String file;
  final int line;
  final int column;

  const JsFrame(this.method, this.file, this.line, this.column);

  /// Library code — dimmed, like Chrome's ignore list.
  bool get isLibrary => file.contains('node_modules');

  @override
  String toString() => 'at ${method ?? '<anonymous>'} ($file:$line:$column)';

  @override
  bool operator ==(Object other) =>
      other is JsFrame &&
      other.method == method &&
      other.file == file &&
      other.line == line &&
      other.column == column;

  @override
  int get hashCode => Object.hash(method, file, line, column);
}

// V8 / Hermes: `at fn (file:1:2)`, `at file:1:2`, `at fn (address at file:1:2)`.
final _v8 = RegExp(
  r'^\s*at (?:(.+?) \()?(?:address at )?(.+?):(\d+):(\d+)\)?\s*$',
);
// JSC / Safari: `fn@file:1:2`, `@file:1:2`.
final _jsc = RegExp(r'^\s*([^@\s]*)@(.+?):(\d+):(\d+)\s*$');

/// The frames of a React Native stack trace, in order; lines that aren't
/// frames (the message, `at apply (native)`) are skipped.
List<JsFrame> parseJsStack(String stack) => [
  for (final line in const LineSplitter().convert(stack))
    if ((_v8.firstMatch(line) ?? _jsc.firstMatch(line)) case final m?)
      JsFrame(
        (m[1] == null || m[1]!.isEmpty) ? null : m[1],
        m[2]!,
        int.parse(m[3]!),
        int.parse(m[4]!),
      ),
];

/// The Metro dev server that served [file] (a bundle URL), as the desktop
/// reaches it: an emulator's host alias is this machine.
Uri? metroOf(String file) {
  final uri = Uri.tryParse(file);
  if (uri == null || !uri.isScheme('http') || !uri.path.contains('.bundle')) {
    return null;
  }
  const hostAliases = {'10.0.2.2', '10.0.3.2'}; // Android emulator, Genymotion
  return Uri(
    scheme: 'http',
    host: hostAliases.contains(uri.host) ? 'localhost' : uri.host,
    port: uri.port,
  );
}

/// Maps [frames] to their sources: through the Metro that served the
/// bundle (dev builds), else the uploaded [sourceMaps] (release builds),
/// newest first. Null when neither knows them.
Future<List<JsFrame>?> symbolicate(
  List<JsFrame> frames,
  Iterable<Map<String, dynamic>> sourceMaps, {
  http.Client? client,
}) async {
  if (frames.isEmpty) return null;
  final metro = frames.map((f) => metroOf(f.file)).nonNulls.firstOrNull;
  if (metro != null) {
    final viaMetro = await _metroSymbolicate(metro, frames, client);
    if (viaMetro != null) return viaMetro;
  }
  final maps = sourceMaps.toList().reversed.toList();
  if (maps.isEmpty) return null;
  // Decoding a multi-megabyte map would stall the UI.
  return Isolate.run(() {
    for (final map in maps) {
      final consumer = SourceMapConsumer(map);
      final mapped = [
        for (final f in frames)
          if (consumer.lookup(f.line - 1, f.column - 1) case final p?)
            JsFrame(p.name ?? f.method, p.source, p.line, p.column)
          else
            f,
      ];
      if (!_sameFrames(mapped, frames)) return mapped;
    }
    return null;
  });
}

bool _sameFrames(List<JsFrame> a, List<JsFrame> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Future<List<JsFrame>?> _metroSymbolicate(
  Uri metro,
  List<JsFrame> frames,
  http.Client? client,
) async {
  final c = client ?? http.Client();
  try {
    final res = await c
        .post(
          metro.replace(path: '/symbolicate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'stack': [
              for (final f in frames)
                {
                  'file': f.file,
                  'lineNumber': f.line,
                  'column': f.column,
                  'methodName': f.method ?? '<anonymous>',
                },
            ],
          }),
        )
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) return null;
    final stack = (jsonDecode(res.body) as Map)['stack'] as List;
    return [
      for (final f in stack.cast<Map>())
        JsFrame(
          f['methodName'] as String?,
          '${f['file']}',
          (f['lineNumber'] as num?)?.toInt() ?? 0,
          (f['column'] as num?)?.toInt() ?? 0,
        ),
    ];
  } catch (_) {
    return null; // Metro not running or not reachable from here
  } finally {
    if (client == null) c.close();
  }
}

/// Reads a source map (v3): generated position → original position.
class SourceMapConsumer {
  final List<String> _sources;
  final List<String> _names;

  /// Per generated line, its segments `[column, source, line, column, name?]`
  /// with absolute values, ordered by generated column.
  final List<List<List<int>>> _lines;

  SourceMapConsumer._(this._sources, this._names, this._lines);

  factory SourceMapConsumer(Map<String, dynamic> map) {
    final root = map['sourceRoot'] as String? ?? '';
    final sources = [
      for (final s in map['sources'] as List? ?? const []) '$root$s',
    ];
    final names = [for (final n in map['names'] as List? ?? const []) '$n'];
    final lines = <List<List<int>>>[];
    var source = 0, line = 0, column = 0, name = 0;
    for (final generatedLine in (map['mappings'] as String? ?? '').split(';')) {
      var generatedColumn = 0;
      final segments = <List<int>>[];
      for (final segment in generatedLine.split(',')) {
        if (segment.isEmpty) continue;
        final v = _decodeVlq(segment);
        generatedColumn += v[0];
        if (v.length < 4) continue; // maps to no source
        source += v[1];
        line += v[2];
        column += v[3];
        if (v.length > 4) name += v[4];
        segments.add([
          generatedColumn,
          source,
          line,
          column,
          if (v.length > 4) name,
        ]);
      }
      lines.add(segments);
    }
    return SourceMapConsumer._(sources, names, lines);
  }

  /// Original position of the 0-based generated [line] / [column], or null.
  ({String source, int line, int column, String? name})? lookup(
    int line,
    int column,
  ) {
    if (line < 0 || line >= _lines.length) return null;
    final segments = _lines[line];
    // Last segment starting at or before [column].
    var lo = 0, hi = segments.length - 1, found = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (segments[mid][0] <= column) {
        found = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    if (found < 0) return null;
    final s = segments[found];
    if (s[1] >= _sources.length) return null;
    return (
      source: _sources[s[1]],
      line: s[2] + 1,
      column: s[3] + 1,
      name: s.length > 4 && s[4] < _names.length ? _names[s[4]] : null,
    );
  }

  static const _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  static List<int> _decodeVlq(String segment) {
    final out = <int>[];
    var value = 0, shift = 0;
    for (final unit in segment.codeUnits) {
      final digit = _alphabet.indexOf(String.fromCharCode(unit));
      if (digit < 0) return out;
      value += (digit & 31) << shift;
      if (digit & 32 != 0) {
        shift += 5;
      } else {
        out.add(value & 1 == 1 ? -(value >> 1) : value >> 1);
        value = 0;
        shift = 0;
      }
    }
    return out;
  }
}
