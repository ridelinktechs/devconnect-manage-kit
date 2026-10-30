/// Generates platform-specific source code for an arbitrary JSON-like value
/// (maps, lists, strings, numbers, bools, null).
///
/// Used by the detail panel's "Code" view to export a network request/response
/// body as idiomatic code in the language of the connected SDK.
///
/// `generate()` returns two strings:
///   * `types` — a "define file" of named types (TypeScript `interface`,
///     Dart `class`, Kotlin `data class`) representing the shape of the
///     body. Nested objects become their own named types; lists of objects
///     get an `Item` class.
///   * `code` — a typed initializer for a `body` variable. The initializer
///     is a plain literal (Map/List) so it stays copy-pasteable without
///     having to construct the class instances.
library;

/// Supported target languages.
enum CodeLang { typescript, dart, kotlin }

class GeneratedCode {
  /// Named type declarations (may be null when the root is a primitive).
  final String? types;

  /// Initializer statement for the `body` variable.
  final String code;

  const GeneratedCode({required this.types, required this.code});
}

class _FieldDef {
  final String key;
  final String type;
  _FieldDef(this.key, this.type);
}

class _ClassDef {
  final String name;
  final List<_FieldDef> fields;
  _ClassDef(this.name, this.fields);
}

class CodeGenerator {
  /// Dispatch based on the connected device's platform string.
  /// Falls back to TypeScript for unknown platforms.
  static CodeLang langForPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'flutter':
        return CodeLang.dart;
      case 'android':
        return CodeLang.kotlin;
      case 'react_native':
      case 'reactnative':
      case 'rn':
      default:
        return CodeLang.typescript;
    }
  }

  /// Human-readable language label for UI.
  static String labelFor(CodeLang lang) {
    switch (lang) {
      case CodeLang.typescript:
        return 'TypeScript';
      case CodeLang.dart:
        return 'Dart';
      case CodeLang.kotlin:
        return 'Kotlin';
    }
  }

  static GeneratedCode generate(dynamic data, CodeLang lang) {
    switch (lang) {
      case CodeLang.typescript:
        return _generateTs(data);
      case CodeLang.dart:
        return _generateDart(data);
      case CodeLang.kotlin:
        return _generateKotlin(data);
    }
  }

  // ── Name helpers ───────────────────────────────────────────────────────

  static String _pascalCase(String s) {
    final parts = s.split(RegExp(r'[_\-\s]+')).where((p) => p.isNotEmpty);
    return parts
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join();
  }

  /// Ensures a class name is unique within [taken] by appending a numeric
  /// suffix on collision.
  static String _uniqueName(String base, Set<String> taken) {
    if (!taken.contains(base)) {
      taken.add(base);
      return base;
    }
    var i = 2;
    while (taken.contains('$base$i')) {
      i++;
    }
    final name = '$base$i';
    taken.add(name);
    return name;
  }

  // ── TypeScript ─────────────────────────────────────────────────────────

  static GeneratedCode _generateTs(dynamic data) {
    if (data is! Map && data is! List) {
      // Primitive root — no interface to emit.
      return GeneratedCode(
        types: null,
        code: 'const body = ${_ts(data, 0)};',
      );
    }

    final classes = <_ClassDef>[];
    final taken = <String>{};
    final rootType = _walkTs(data, 'Body', classes, taken);

    // Post-order → reverse so the root type appears first.
    final ordered = classes.reversed.toList();
    final typeStr = ordered.map((c) {
      final fields = c.fields
          .map((f) => '  ${_tsKey(f.key)}: ${f.type};')
          .join('\n');
      return 'interface ${c.name} {\n$fields\n}';
    }).join('\n\n');

    final init = _ts(data, 0);
    return GeneratedCode(
      types: typeStr,
      code: 'const body: $rootType = $init;',
    );
  }

  static String _walkTs(
    dynamic v,
    String suggestedName,
    List<_ClassDef> out,
    Set<String> taken,
  ) {
    if (v is Map) {
      final fields = <_FieldDef>[];
      final name = _uniqueName(suggestedName, taken);
      v.forEach((key, val) {
        final keyStr = key.toString();
        fields.add(_FieldDef(keyStr, _tsFieldType(val, keyStr, out, taken)));
      });
      out.add(_ClassDef(name, fields));
      return name;
    }
    if (v is List) {
      return _tsListType(v, suggestedName, out, taken);
    }
    return _tsPrimitiveType(v);
  }

  static String _tsFieldType(
    dynamic v,
    String fieldKey,
    List<_ClassDef> out,
    Set<String> taken,
  ) {
    if (v is Map) {
      final childName = _pascalCase(fieldKey);
      return _walkTs(v, childName, out, taken);
    }
    if (v is List) {
      return _tsListType(v, fieldKey, out, taken);
    }
    return _tsPrimitiveType(v);
  }

  static String _tsListType(
    List v,
    String fieldKey,
    List<_ClassDef> out,
    Set<String> taken,
  ) {
    if (v.isEmpty) return 'unknown[]';
    final firstMap = v.firstWhere((e) => e is Map, orElse: () => null);
    if (firstMap is Map) {
      final itemName = '${_pascalCase(fieldKey)}Item';
      final cls = _walkTs(firstMap, itemName, out, taken);
      return '$cls[]';
    }
    final types = v.map(_tsPrimitiveType).toSet();
    if (types.length == 1) return '${types.first}[]';
    return 'unknown[]';
  }

  static String _tsPrimitiveType(dynamic v) {
    if (v == null) return 'null';
    if (v is bool) return 'boolean';
    if (v is num) return 'number';
    if (v is String) return 'string';
    if (v is List) return 'unknown[]';
    if (v is Map) return 'object';
    return 'unknown';
  }

  static String _ts(dynamic v, int depth) {
    if (v == null) return 'null';
    if (v is bool) return v ? 'true' : 'false';
    if (v is num) return v.toString();
    if (v is String) return _tsString(v);
    if (v is List) {
      if (v.isEmpty) return '[]';
      final indent = '  ' * (depth + 1);
      final close = '  ' * depth;
      final items = v.map((e) => '$indent${_ts(e, depth + 1)}').join(',\n');
      return '[\n$items,\n$close]';
    }
    if (v is Map) {
      if (v.isEmpty) return '{}';
      final indent = '  ' * (depth + 1);
      final close = '  ' * depth;
      final entries = v.entries.map((e) {
        final key = _tsKey(e.key.toString());
        return '$indent$key: ${_ts(e.value, depth + 1)}';
      }).join(',\n');
      return '{\n$entries,\n$close}';
    }
    return _tsString(v.toString());
  }

  static String _tsKey(String key) {
    final isValidIdent = RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$').hasMatch(key);
    return isValidIdent ? key : _tsString(key);
  }

  static String _tsString(String s) {
    final escaped = s
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
    return '"$escaped"';
  }

  // ── Dart ───────────────────────────────────────────────────────────────

  static GeneratedCode _generateDart(dynamic data) {
    if (data is! Map && data is! List) {
      return GeneratedCode(
        types: null,
        code: 'final body = ${_dart(data, 0)};',
      );
    }

    final classes = <_ClassDef>[];
    final taken = <String>{};
    final rootType = _walkDart(data, 'Body', classes, taken);

    final ordered = classes.reversed.toList();
    final typeStr = ordered.map((c) {
      final fields = c.fields
          .map((f) => '  final ${f.type} ${f.key};')
          .join('\n');
      return 'class ${c.name} {\n$fields\n}';
    }).join('\n\n');

    final init = _dart(data, 0);
    // Root list data keeps the Map or List top-level type for the var.
    final varType = (data is Map)
        ? 'Map<String, dynamic>'
        : 'List<${_dartListElemType(data as List)}>';

    return GeneratedCode(
      types: typeStr,
      code:
          'final $varType body /* matches $rootType */ = $init;',
    );
  }

  static String _walkDart(
    dynamic v,
    String suggestedName,
    List<_ClassDef> out,
    Set<String> taken,
  ) {
    if (v is Map) {
      final fields = <_FieldDef>[];
      final name = _uniqueName(suggestedName, taken);
      v.forEach((key, val) {
        final keyStr = key.toString();
        fields.add(_FieldDef(keyStr, _dartFieldType(val, keyStr, out, taken)));
      });
      out.add(_ClassDef(name, fields));
      return name;
    }
    if (v is List) {
      return _dartListFieldType(v, suggestedName, out, taken);
    }
    return _dartPrimitiveType(v);
  }

  static String _dartFieldType(
    dynamic v,
    String fieldKey,
    List<_ClassDef> out,
    Set<String> taken,
  ) {
    if (v is Map) {
      return _walkDart(v, _pascalCase(fieldKey), out, taken);
    }
    if (v is List) {
      return _dartListFieldType(v, fieldKey, out, taken);
    }
    return _dartPrimitiveType(v);
  }

  static String _dartListFieldType(
    List v,
    String fieldKey,
    List<_ClassDef> out,
    Set<String> taken,
  ) {
    if (v.isEmpty) return 'List<dynamic>';
    final firstMap = v.firstWhere((e) => e is Map, orElse: () => null);
    if (firstMap is Map) {
      final itemName = '${_pascalCase(fieldKey)}Item';
      final cls = _walkDart(firstMap, itemName, out, taken);
      return 'List<$cls>';
    }
    final types = v.map(_dartPrimitiveType).toSet();
    if (types.length == 1) return 'List<${types.first}>';
    return 'List<dynamic>';
  }

  static String _dartPrimitiveType(dynamic v) {
    if (v == null) return 'dynamic';
    if (v is bool) return 'bool';
    if (v is int) return 'int';
    if (v is double) return 'double';
    if (v is num) return 'num';
    if (v is String) return 'String';
    if (v is List) return 'List<dynamic>';
    if (v is Map) return 'Map<String, dynamic>';
    return 'dynamic';
  }

  /// Inferred element type for a Dart list literal prefix.
  static String _dartListElemType(List v) {
    if (v.isEmpty) return 'dynamic';
    final types = v.map(_dartPrimitiveType).toSet();
    return types.length == 1 ? types.first : 'dynamic';
  }

  static String _dart(dynamic v, int depth) {
    if (v == null) return 'null';
    if (v is bool) return v ? 'true' : 'false';
    if (v is num) return v.toString();
    if (v is String) return _dartString(v);
    if (v is List) {
      final elemType = _dartListElemType(v);
      if (v.isEmpty) return '<$elemType>[]';
      final indent = '  ' * (depth + 1);
      final close = '  ' * depth;
      final items = v.map((e) => '$indent${_dart(e, depth + 1)}').join(',\n');
      return '<$elemType>[\n$items,\n$close]';
    }
    if (v is Map) {
      if (v.isEmpty) return '<String, dynamic>{}';
      final indent = '  ' * (depth + 1);
      final close = '  ' * depth;
      final entries = v.entries.map((e) {
        return "$indent${_dartString(e.key.toString())}: ${_dart(e.value, depth + 1)}";
      }).join(',\n');
      return '<String, dynamic>{\n$entries,\n$close}';
    }
    return _dartString(v.toString());
  }

  static String _dartString(String s) {
    final escaped = s
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t')
        .replaceAll(r'$', r'\$');
    return "'$escaped'";
  }

  // ── Kotlin ─────────────────────────────────────────────────────────────

  static GeneratedCode _generateKotlin(dynamic data) {
    if (data is! Map && data is! List) {
      return GeneratedCode(
        types: null,
        code: 'val body = ${_kotlin(data, 0)}',
      );
    }

    final classes = <_ClassDef>[];
    final taken = <String>{};
    final rootType = _walkKotlin(data, 'Body', classes, taken);

    final ordered = classes.reversed.toList();
    final typeStr = ordered.map((c) {
      final fieldLines =
          c.fields.map((f) => '  val ${f.key}: ${f.type},').join('\n');
      return 'data class ${c.name}(\n$fieldLines\n)';
    }).join('\n\n');

    final init = _kotlin(data, 0);
    final varType = (data is Map)
        ? 'Map<String, Any?>'
        : 'List<${_kotlinListElemType(data as List)}>';

    return GeneratedCode(
      types: typeStr,
      code: 'val body: $varType /* matches $rootType */ = $init',
    );
  }

  static String _walkKotlin(
    dynamic v,
    String suggestedName,
    List<_ClassDef> out,
    Set<String> taken,
  ) {
    if (v is Map) {
      final fields = <_FieldDef>[];
      final name = _uniqueName(suggestedName, taken);
      v.forEach((key, val) {
        final keyStr = key.toString();
        fields
            .add(_FieldDef(keyStr, _kotlinFieldType(val, keyStr, out, taken)));
      });
      out.add(_ClassDef(name, fields));
      return name;
    }
    if (v is List) {
      return _kotlinListFieldType(v, suggestedName, out, taken);
    }
    return _kotlinPrimitiveType(v);
  }

  static String _kotlinFieldType(
    dynamic v,
    String fieldKey,
    List<_ClassDef> out,
    Set<String> taken,
  ) {
    if (v is Map) {
      return _walkKotlin(v, _pascalCase(fieldKey), out, taken);
    }
    if (v is List) {
      return _kotlinListFieldType(v, fieldKey, out, taken);
    }
    return _kotlinPrimitiveType(v);
  }

  static String _kotlinListFieldType(
    List v,
    String fieldKey,
    List<_ClassDef> out,
    Set<String> taken,
  ) {
    if (v.isEmpty) return 'List<Any?>';
    final firstMap = v.firstWhere((e) => e is Map, orElse: () => null);
    if (firstMap is Map) {
      final itemName = '${_pascalCase(fieldKey)}Item';
      final cls = _walkKotlin(firstMap, itemName, out, taken);
      return 'List<$cls>';
    }
    final types = v.map(_kotlinPrimitiveType).toSet();
    if (types.length == 1) return 'List<${types.first}>';
    return 'List<Any?>';
  }

  static String _kotlinPrimitiveType(dynamic v) {
    if (v == null) return 'Any?';
    if (v is bool) return 'Boolean';
    if (v is int) return 'Int';
    if (v is double) return 'Double';
    if (v is num) return 'Number';
    if (v is String) return 'String';
    if (v is List) return 'List<Any?>';
    if (v is Map) return 'Map<String, Any?>';
    return 'Any?';
  }

  static String _kotlinListElemType(List v) {
    if (v.isEmpty) return 'Any?';
    final types = v.map(_kotlinPrimitiveType).toSet();
    return types.length == 1 ? types.first : 'Any?';
  }

  static String _kotlin(dynamic v, int depth) {
    if (v == null) return 'null';
    if (v is bool) return v ? 'true' : 'false';
    if (v is int) return v.toString();
    if (v is double) return v.toString();
    if (v is num) return v.toString();
    if (v is String) return _kotlinString(v);
    if (v is List) {
      final elemType = _kotlinListElemType(v);
      if (v.isEmpty) return 'listOf<$elemType>()';
      final indent = '  ' * (depth + 1);
      final close = '  ' * depth;
      final items =
          v.map((e) => '$indent${_kotlin(e, depth + 1)}').join(',\n');
      return 'listOf<$elemType>(\n$items,\n$close)';
    }
    if (v is Map) {
      if (v.isEmpty) return 'mapOf<String, Any?>()';
      final indent = '  ' * (depth + 1);
      final close = '  ' * depth;
      final entries = v.entries.map((e) {
        return '$indent${_kotlinString(e.key.toString())} to ${_kotlin(e.value, depth + 1)}';
      }).join(',\n');
      return 'mapOf<String, Any?>(\n$entries,\n$close)';
    }
    return _kotlinString(v.toString());
  }

  static String _kotlinString(String s) {
    final escaped = s
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t')
        .replaceAll(r'$', r'\$');
    return '"$escaped"';
  }
}
