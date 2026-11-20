import 'dart:ui' show ColorSpace;

import 'package:flutter/painting.dart';

/// A color written in some text, and where.
typedef ColorMatch = ({int start, int end, Color color});

/// The colors written in [text]. When all of it (trimmed) is one color,
/// that's the one match; see [parseColor] for what reads as one. Otherwise
/// each `rgb()`, `hsl()` or Flutter `Color(…)` inside it matches — a hex or
/// a name inside other text is too often something else ("Order #123456").
List<ColorMatch> findColors(String text, {String? key}) {
  final start = text.length - text.trimLeft().length;
  final whole = text.trim();
  if (parseColor(whole, key: key) case final color?) {
    return [(start: start, end: start + whole.length, color: color)];
  }
  return [
    for (final m in _inText.allMatches(text))
      if (parseColor(m[0]!) case final color?)
        (start: m.start, end: m.end, color: color),
  ];
}

/// [text] as a color, if it's exactly one: hex (`#rgb`, `#rgba`, `#rrggbb`,
/// `#rrggbbaa`, in CSS's order as React Native reads it), `rgb()` /
/// `rgba()`, `hsl()` / `hsla()`, Flutter's `Color(0xAARRGGBB)` or
/// `Color(alpha: …, red: …)`, or — when [key] names a color, as in
/// `backgroundColor: white` but not `tier: gold` — a CSS color name.
Color? parseColor(String text, {String? key}) {
  if (_hex.firstMatch(text) case final m?) return _fromHex(m[1]!);
  if (_rgb.firstMatch(text) case final m?) {
    int channel(String s) => _clamp(
      s.endsWith('%') ? _percent(s) * 255 : double.parse(s),
      255,
    ).round();
    return Color.fromARGB(
      (_alpha(m[4]) * 255).round(),
      channel(m[1]!),
      channel(m[2]!),
      channel(m[3]!),
    );
  }
  if (_hsl.firstMatch(text) case final m?) {
    return HSLColor.fromAHSL(
      _alpha(m[4]),
      double.parse(m[1]!) % 360,
      _clamp(double.parse(m[2]!) / 100, 1),
      _clamp(double.parse(m[3]!) / 100, 1),
    ).toColor();
  }
  if (_flutterHex.firstMatch(text) case final m?) {
    return Color(int.parse(m[1]!, radix: 16));
  }
  if (_flutter.firstMatch(text) case final m?) {
    return Color.from(
      alpha: double.parse(m[1]!),
      red: double.parse(m[2]!),
      green: double.parse(m[3]!),
      blue: double.parse(m[4]!),
      colorSpace: ColorSpace.values.asNameMap()[m[5]] ?? ColorSpace.sRGB,
    );
  }
  if (key != null && _colorKey.hasMatch(key)) {
    if (_named[text.toLowerCase()] case final argb?) return Color(argb);
  }
  return null;
}

/// `#RRGGBB`, or `#RRGGBBAA` when not opaque: CSS's order.
String colorHex(Color color) {
  final argb = color.toARGB32();
  final alpha = argb >>> 24;
  final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  final tail = alpha == 0xFF ? '' : alpha.toRadixString(16).padLeft(2, '0');
  return '#$rgb$tail'.toUpperCase();
}

String colorRgba(Color color) {
  final argb = color.toARGB32();
  final alpha = ((argb >>> 24) / 255)
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'\.?0+$'), '');
  return 'rgba(${(argb >> 16) & 0xFF}, ${(argb >> 8) & 0xFF}, '
      '${argb & 0xFF}, $alpha)';
}

Color _fromHex(String digits) {
  final full = digits.length <= 4
      ? [for (final c in digits.split('')) '$c$c'].join()
      : digits;
  final rgba = int.parse(full.length == 6 ? '${full}ff' : full, radix: 16);
  return Color(((rgba & 0xFF) << 24) | (rgba >>> 8));
}

double _clamp(double v, double max) => v.isNaN ? 0 : v.clamp(0, max);

double _percent(String s) => double.parse(s.substring(0, s.length - 1)) / 100;

/// An alpha written as 0–1 or a percentage; none is opaque.
double _alpha(String? s) =>
    s == null ? 1 : _clamp(s.endsWith('%') ? _percent(s) : double.parse(s), 1);

const _number = r'[-+]?\d*\.?\d+';
// Between arguments: a comma, or (CSS's newer syntax) just spaces.
const _gap = r'(?:\s*,\s*|\s+)';
const _alphaArg = '(?:\\s*[,/]\\s*($_number%?))?';
const _rgbCall =
    'rgba?\\(\\s*($_number%?)$_gap($_number%?)$_gap($_number%?)'
    '$_alphaArg\\s*\\)';
const _hslCall =
    'hsla?\\(\\s*($_number)(?:deg)?$_gap($_number)%?$_gap($_number)%?'
    '$_alphaArg\\s*\\)';
const _flutterHexCall = r'Color\(0x([0-9a-fA-F]{8})\)';
const _flutterCall =
    'Color\\(alpha: ($_number), red: ($_number), green: ($_number), '
    'blue: ($_number)(?:, colorSpace: ColorSpace\\.(\\w+))?\\)';

final _hex = RegExp(
  r'^#([0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$',
  caseSensitive: false,
);
final _rgb = RegExp('^$_rgbCall\$', caseSensitive: false);
final _hsl = RegExp('^$_hslCall\$', caseSensitive: false);
final _flutterHex = RegExp('^$_flutterHexCall\$');
final _flutter = RegExp('^$_flutterCall\$');
final _inText = RegExp(
  '$_rgbCall|$_hslCall|$_flutterHexCall|$_flutterCall',
  caseSensitive: false,
);

/// Keys whose values are colors: `color`, `backgroundColor`, `tintColor`,
/// SVG's `fill` / `stroke`…
final _colorKey = RegExp('colou?r|fill|stroke|tint', caseSensitive: false);

/// CSS's color names as React Native knows them (ARGB), from
/// `@react-native/normalize-colors`.
const _named = <String, int>{
  'transparent': 0x00000000,
  'aliceblue': 0xFFF0F8FF,
  'antiquewhite': 0xFFFAEBD7,
  'aqua': 0xFF00FFFF,
  'aquamarine': 0xFF7FFFD4,
  'azure': 0xFFF0FFFF,
  'beige': 0xFFF5F5DC,
  'bisque': 0xFFFFE4C4,
  'black': 0xFF000000,
  'blanchedalmond': 0xFFFFEBCD,
  'blue': 0xFF0000FF,
  'blueviolet': 0xFF8A2BE2,
  'brown': 0xFFA52A2A,
  'burlywood': 0xFFDEB887,
  'burntsienna': 0xFFEA7E5D,
  'cadetblue': 0xFF5F9EA0,
  'chartreuse': 0xFF7FFF00,
  'chocolate': 0xFFD2691E,
  'coral': 0xFFFF7F50,
  'cornflowerblue': 0xFF6495ED,
  'cornsilk': 0xFFFFF8DC,
  'crimson': 0xFFDC143C,
  'cyan': 0xFF00FFFF,
  'darkblue': 0xFF00008B,
  'darkcyan': 0xFF008B8B,
  'darkgoldenrod': 0xFFB8860B,
  'darkgray': 0xFFA9A9A9,
  'darkgreen': 0xFF006400,
  'darkgrey': 0xFFA9A9A9,
  'darkkhaki': 0xFFBDB76B,
  'darkmagenta': 0xFF8B008B,
  'darkolivegreen': 0xFF556B2F,
  'darkorange': 0xFFFF8C00,
  'darkorchid': 0xFF9932CC,
  'darkred': 0xFF8B0000,
  'darksalmon': 0xFFE9967A,
  'darkseagreen': 0xFF8FBC8F,
  'darkslateblue': 0xFF483D8B,
  'darkslategray': 0xFF2F4F4F,
  'darkslategrey': 0xFF2F4F4F,
  'darkturquoise': 0xFF00CED1,
  'darkviolet': 0xFF9400D3,
  'deeppink': 0xFFFF1493,
  'deepskyblue': 0xFF00BFFF,
  'dimgray': 0xFF696969,
  'dimgrey': 0xFF696969,
  'dodgerblue': 0xFF1E90FF,
  'firebrick': 0xFFB22222,
  'floralwhite': 0xFFFFFAF0,
  'forestgreen': 0xFF228B22,
  'fuchsia': 0xFFFF00FF,
  'gainsboro': 0xFFDCDCDC,
  'ghostwhite': 0xFFF8F8FF,
  'gold': 0xFFFFD700,
  'goldenrod': 0xFFDAA520,
  'gray': 0xFF808080,
  'green': 0xFF008000,
  'greenyellow': 0xFFADFF2F,
  'grey': 0xFF808080,
  'honeydew': 0xFFF0FFF0,
  'hotpink': 0xFFFF69B4,
  'indianred': 0xFFCD5C5C,
  'indigo': 0xFF4B0082,
  'ivory': 0xFFFFFFF0,
  'khaki': 0xFFF0E68C,
  'lavender': 0xFFE6E6FA,
  'lavenderblush': 0xFFFFF0F5,
  'lawngreen': 0xFF7CFC00,
  'lemonchiffon': 0xFFFFFACD,
  'lightblue': 0xFFADD8E6,
  'lightcoral': 0xFFF08080,
  'lightcyan': 0xFFE0FFFF,
  'lightgoldenrodyellow': 0xFFFAFAD2,
  'lightgray': 0xFFD3D3D3,
  'lightgreen': 0xFF90EE90,
  'lightgrey': 0xFFD3D3D3,
  'lightpink': 0xFFFFB6C1,
  'lightsalmon': 0xFFFFA07A,
  'lightseagreen': 0xFF20B2AA,
  'lightskyblue': 0xFF87CEFA,
  'lightslategray': 0xFF778899,
  'lightslategrey': 0xFF778899,
  'lightsteelblue': 0xFFB0C4DE,
  'lightyellow': 0xFFFFFFE0,
  'lime': 0xFF00FF00,
  'limegreen': 0xFF32CD32,
  'linen': 0xFFFAF0E6,
  'magenta': 0xFFFF00FF,
  'maroon': 0xFF800000,
  'mediumaquamarine': 0xFF66CDAA,
  'mediumblue': 0xFF0000CD,
  'mediumorchid': 0xFFBA55D3,
  'mediumpurple': 0xFF9370DB,
  'mediumseagreen': 0xFF3CB371,
  'mediumslateblue': 0xFF7B68EE,
  'mediumspringgreen': 0xFF00FA9A,
  'mediumturquoise': 0xFF48D1CC,
  'mediumvioletred': 0xFFC71585,
  'midnightblue': 0xFF191970,
  'mintcream': 0xFFF5FFFA,
  'mistyrose': 0xFFFFE4E1,
  'moccasin': 0xFFFFE4B5,
  'navajowhite': 0xFFFFDEAD,
  'navy': 0xFF000080,
  'oldlace': 0xFFFDF5E6,
  'olive': 0xFF808000,
  'olivedrab': 0xFF6B8E23,
  'orange': 0xFFFFA500,
  'orangered': 0xFFFF4500,
  'orchid': 0xFFDA70D6,
  'palegoldenrod': 0xFFEEE8AA,
  'palegreen': 0xFF98FB98,
  'paleturquoise': 0xFFAFEEEE,
  'palevioletred': 0xFFDB7093,
  'papayawhip': 0xFFFFEFD5,
  'peachpuff': 0xFFFFDAB9,
  'peru': 0xFFCD853F,
  'pink': 0xFFFFC0CB,
  'plum': 0xFFDDA0DD,
  'powderblue': 0xFFB0E0E6,
  'purple': 0xFF800080,
  'rebeccapurple': 0xFF663399,
  'red': 0xFFFF0000,
  'rosybrown': 0xFFBC8F8F,
  'royalblue': 0xFF4169E1,
  'saddlebrown': 0xFF8B4513,
  'salmon': 0xFFFA8072,
  'sandybrown': 0xFFF4A460,
  'seagreen': 0xFF2E8B57,
  'seashell': 0xFFFFF5EE,
  'sienna': 0xFFA0522D,
  'silver': 0xFFC0C0C0,
  'skyblue': 0xFF87CEEB,
  'slateblue': 0xFF6A5ACD,
  'slategray': 0xFF708090,
  'slategrey': 0xFF708090,
  'snow': 0xFFFFFAFA,
  'springgreen': 0xFF00FF7F,
  'steelblue': 0xFF4682B4,
  'tan': 0xFFD2B48C,
  'teal': 0xFF008080,
  'thistle': 0xFFD8BFD8,
  'tomato': 0xFFFF6347,
  'turquoise': 0xFF40E0D0,
  'violet': 0xFFEE82EE,
  'wheat': 0xFFF5DEB3,
  'white': 0xFFFFFFFF,
  'whitesmoke': 0xFFF5F5F5,
  'yellow': 0xFFFFFF00,
  'yellowgreen': 0xFF9ACD32,
};
