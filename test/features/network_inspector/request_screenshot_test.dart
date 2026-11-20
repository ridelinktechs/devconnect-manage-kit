import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/theme/theme_provider.dart';
import 'package:devconnect_manage_tool/core/utils/code/code_generator.dart';
import 'package:devconnect_manage_tool/features/network_inspector/presentation/request/request_screenshot.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';
import 'package:devconnect_manage_tool/models/network/network_entry.dart';

void main() {
  const entry = NetworkEntry(
    id: '1',
    deviceId: 'ios',
    method: 'GET',
    url: 'https://api.example.com/items?q=a%2Cb',
    statusCode: 200,
    requestHeaders: {'accept': 'application/json'},
    responseHeaders: {'content-type': 'image/png'},
    responseBody: '<2048 bytes>',
    startTime: 0,
    endTime: 120,
    duration: 120,
    isComplete: true,
  );

  Future<void> shoot(WidgetTester tester, {int? tabIndex}) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: RequestScreenshot(
            entry: entry,
            isDark: false,
            tabIndex: tabIndex,
            viewMode: BodyViewMode.tree,
            codeLang: CodeLang.typescript,
          ),
        ),
      ),
    ),
  );

  testWidgets('the whole request: url, headers and a binary body note', (
    tester,
  ) async {
    await shoot(tester);

    expect(find.text('https://api.example.com/items?q=a,b'), findsOneWidget);
    expect(find.text('accept'), findsOneWidget);
    expect(find.textContaining('blob payload (2048 bytes)'), findsOneWidget);
  });

  testWidgets('one tab: its name and only its content', (tester) async {
    await shoot(tester, tabIndex: 0);

    expect(find.text('Headers'), findsOneWidget);
    expect(find.text('content-type'), findsOneWidget);
    expect(find.textContaining('payload'), findsNothing);
  });
}
