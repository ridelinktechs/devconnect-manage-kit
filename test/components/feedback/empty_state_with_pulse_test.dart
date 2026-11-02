import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:devconnect_manage_tool/components/feedback/empty_state_with_pulse.dart';

Widget _app({required bool reduceMotion}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: const Scaffold(
    body: EmptyStateWithPulse(
      icon: LucideIcons.terminal,
      title: 'No logs yet',
      subtitle: 'Connect a device to see logs',
    ),
  ),
);

void main() {
  testWidgets('the rings around the icon keep breathing', (tester) async {
    await tester.pumpWidget(_app(reduceMotion: false));
    await tester.pump(const Duration(seconds: 5));
    expect(find.byIcon(LucideIcons.terminal), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('with animations off it shows at once and holds still', (
    tester,
  ) async {
    await tester.pumpWidget(_app(reduceMotion: true));
    await tester.pump();
    expect(find.text('No logs yet'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
