import 'package:flutter/material.dart';

import 'code_generator.dart';

/// Lightweight regex-based syntax highlighter for the three languages the
/// Code view supports (TypeScript, Dart, Kotlin).
///
/// Produces a `List<TextSpan>` suitable for `Text.rich(...)` or
/// `SelectableText.rich(...)`. Colors follow VSCode's Dark+ / Light+
/// palettes so the output feels familiar to users.
class CodeHighlighter {
  static List<TextSpan> highlight(String code, CodeLang lang, bool isDark) {
    final palette = isDark ? _darkPalette : _lightPalette;
    final keywords = _keywordsFor(lang);
    final types = _typesFor(lang);
    const constants = <String>{'true', 'false', 'null', 'undefined', 'this'};

    final spans = <TextSpan>[];
    int cursor = 0;
    for (final m in _pattern.allMatches(code)) {
      if (m.start > cursor) {
        spans.add(TextSpan(
          text: code.substring(cursor, m.start),
          style: TextStyle(color: palette.plain),
        ));
      }
      final text = m.group(0)!;
      Color color;
      FontWeight? weight;

      if (m.group(1) != null || m.group(2) != null) {
        color = palette.comment;
      } else if (m.group(3) != null || m.group(4) != null) {
        color = palette.string;
      } else if (m.group(5) != null) {
        color = palette.number;
      } else {
        // Identifier captured in group 6.
        if (keywords.contains(text)) {
          color = palette.keyword;
          weight = FontWeight.w600;
        } else if (types.contains(text) || _isClassLikeName(text)) {
          color = palette.type;
        } else if (constants.contains(text)) {
          color = palette.constant;
          weight = FontWeight.w600;
        } else {
          color = palette.property;
        }
      }
      spans.add(TextSpan(
        text: text,
        style: TextStyle(color: color, fontWeight: weight),
      ));
      cursor = m.end;
    }
    if (cursor < code.length) {
      spans.add(TextSpan(
        text: code.substring(cursor),
        style: TextStyle(color: palette.plain),
      ));
    }
    return spans;
  }

  /// PascalCase identifiers are treated as type references so user-defined
  /// class names (e.g. `SupportedLanguage`) get the "type" color.
  static bool _isClassLikeName(String s) {
    if (s.isEmpty) return false;
    final first = s[0];
    return first == first.toUpperCase() && first != first.toLowerCase();
  }

  static Set<String> _keywordsFor(CodeLang lang) {
    switch (lang) {
      case CodeLang.typescript:
        return const {
          'interface', 'type', 'const', 'let', 'var', 'function', 'class',
          'extends', 'implements', 'new', 'return', 'if', 'else', 'enum',
          'export', 'import', 'from', 'as', 'readonly', 'public', 'private',
          'protected', 'static',
        };
      case CodeLang.dart:
        return const {
          'final', 'const', 'var', 'class', 'new', 'return', 'if', 'else',
          'factory', 'required', 'late', 'abstract', 'extends', 'implements',
          'mixin', 'enum', 'with', 'super', 'this',
        };
      case CodeLang.kotlin:
        return const {
          'val', 'var', 'class', 'data', 'fun', 'return', 'if', 'else',
          'object', 'interface', 'abstract', 'override', 'open', 'sealed',
          'companion', 'enum', 'package', 'import', 'private', 'public',
          'internal', 'protected', 'this', 'super',
        };
    }
  }

  static Set<String> _typesFor(CodeLang lang) {
    switch (lang) {
      case CodeLang.typescript:
        return const {
          'string', 'number', 'boolean', 'unknown', 'any', 'never', 'void',
          'object', 'Array', 'Record', 'undefined', 'null', 'Promise',
          'Readonly', 'Partial',
        };
      case CodeLang.dart:
        return const {
          'String', 'int', 'double', 'num', 'bool', 'List', 'Map', 'Set',
          'dynamic', 'void', 'Object', 'Null', 'Iterable', 'Future',
          'Stream',
        };
      case CodeLang.kotlin:
        return const {
          'String', 'Int', 'Long', 'Float', 'Double', 'Boolean', 'List',
          'Map', 'Set', 'Any', 'Nothing', 'Unit', 'Number', 'Array', 'Char',
          'Byte', 'Short',
        };
    }
  }

  /// Single regex covering the three languages — they share enough
  /// lexical shape (C-style comments, JSON-like strings, identifiers)
  /// that one tokeniser is sufficient.
  static final _pattern = RegExp(
    r'(/\*[\s\S]*?\*/)'
    r'|(//[^\n]*)'
    r'|("(?:[^"\\]|\\.)*")'
    r"|('(?:[^'\\]|\\.)*')"
    r'|(\b\d+(?:\.\d+)?\b)'
    r'|([a-zA-Z_$][a-zA-Z0-9_$]*)',
    multiLine: true,
  );
}

class _Palette {
  final Color plain;
  final Color keyword;
  final Color type;
  final Color string;
  final Color number;
  final Color comment;
  final Color constant;
  final Color property;

  const _Palette({
    required this.plain,
    required this.keyword,
    required this.type,
    required this.string,
    required this.number,
    required this.comment,
    required this.constant,
    required this.property,
  });
}

/// VSCode Dark+ palette.
const _darkPalette = _Palette(
  plain: Color(0xFFD4D4D4),
  keyword: Color(0xFF569CD6),
  type: Color(0xFF4EC9B0),
  string: Color(0xFFCE9178),
  number: Color(0xFFB5CEA8),
  comment: Color(0xFF6A9955),
  constant: Color(0xFF569CD6),
  property: Color(0xFF9CDCFE),
);

/// VSCode Light+ palette.
const _lightPalette = _Palette(
  plain: Color(0xFF1F2328),
  keyword: Color(0xFF0000FF),
  type: Color(0xFF267F99),
  string: Color(0xFFA31515),
  number: Color(0xFF098658),
  comment: Color(0xFF008000),
  constant: Color(0xFF0000FF),
  property: Color(0xFF001080),
);
