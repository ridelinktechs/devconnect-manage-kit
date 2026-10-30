import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/components/misc/color_sample.dart';
import 'package:devconnect_manage_tool/components/viewers/json_viewer.dart';
import 'package:devconnect_manage_tool/l10n/app_localizations.dart';

void main() {
  testWidgets('colors get a sample, look-alikes don\'t', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: JsonViewer(
            data: {
              'color': '#4F46E5',
              'border': '1px solid rgb(0, 128, 0)',
              'tier': 'gold',
              'title': 'Order #123456',
            },
          ),
        ),
      ),
    );
    final samples = tester.widgetList<ColorSample>(find.byType(ColorSample));
    expect(samples.map((s) => s.color.toARGB32()), [0xFF4F46E5, 0xFF008000]);
    expect(find.byTooltip('#4F46E5   rgba(79, 70, 229, 1)'), findsOneWidget);
  });
}
