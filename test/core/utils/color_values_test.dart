import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/utils/format/color_values.dart';

void main() {
  test('reads every way a color is written', () {
    const cases = <(String, String?, int?)>[
      ('#fff', null, 0xFFFFFFFF),
      ('#F80', null, 0xFFFF8800),
      ('#f808', null, 0x88FF8800), // #rgba
      ('#4F46E5', null, 0xFF4F46E5),
      ('#4F46E580', null, 0x804F46E5), // RRGGBBAA, as CSS and RN read it
      ('rgb(255, 0, 0)', null, 0xFFFF0000),
      ('rgba(0,0,0,0.5)', null, 0x80000000),
      ('rgb(255 0 0 / 50%)', null, 0x80FF0000),
      ('RGB(100%, 0%, 0%)', null, 0xFFFF0000),
      ('rgb(300, -5, 0)', null, 0xFFFF0000), // out of range: clamped
      ('hsl(0, 100%, 50%)', null, 0xFFFF0000),
      ('hsla(240deg 100% 50% / 1)', null, 0xFF0000FF),
      ('Color(0xff2196f3)', null, 0xFF2196F3), // Flutter before 3.27
      (
        'Color(alpha: 1.0000, red: 0.1294, green: 0.5882, blue: 0.9529, '
            'colorSpace: ColorSpace.sRGB)',
        null,
        0xFF2196F3,
      ),
      ('white', 'backgroundColor', 0xFFFFFFFF),
      ('RebeccaPurple', 'color', 0xFF663399),
      ('transparent', 'tintColor', 0x00000000),
      // Not colors.
      ('gold', 'tier', null),
      ('white', null, null),
      ('#12345', null, null),
      ('#ggg', null, null),
      ('rgb(1, 2)', null, null),
      ('16', 'color', null),
    ];
    for (final (text, key, argb) in cases) {
      expect(
        parseColor(text, key: key)?.toARGB32(),
        argb,
        reason: '$text (key: $key)',
      );
    }
  });

  test('finds colors inside text, but only unmistakable ones', () {
    const decoration =
        'BoxDecoration(color: Color(0xff2196f3), '
        'border: Border.all(color: Color(0x80000000)))';
    expect(
      [
        for (final c in findColors(decoration))
          (decoration.substring(c.start, c.end), c.color.toARGB32()),
      ],
      [('Color(0xff2196f3)', 0xFF2196F3), ('Color(0x80000000)', 0x80000000)],
    );
    expect(findColors('color: rgb(0, 128, 0); x').single.start, 7);
    // A whole value, spaces around it.
    final whole = findColors('  #fff ').single;
    expect((whole.start, whole.end), (2, 6));
    expect(findColors('Order #123456'), isEmpty);
    expect(findColors('the gold tier', key: 'color'), isEmpty);
  });

  test('describes a color as hex and rgba()', () {
    expect(colorHex(const Color(0xFF4F46E5)), '#4F46E5');
    expect(colorHex(const Color(0x804F46E5)), '#4F46E580');
    expect(colorRgba(const Color(0x80000000)), 'rgba(0, 0, 0, 0.5)');
    expect(colorRgba(const Color(0xFFFF0000)), 'rgba(255, 0, 0, 1)');
    expect(colorRgba(const Color(0x00000000)), 'rgba(0, 0, 0, 0)');
  });
}
