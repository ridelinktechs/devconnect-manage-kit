import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/components/feedback/lib_update_tips.dart';
import 'package:devconnect_manage_tool/core/providers/sdk_versions_provider.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';

void main() {
  testWidgets('Tips shows the version a device reports, else how to check '
      'it, and how to install the latest', (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    DeviceInfo device(String id, String platform, String sdk) => DeviceInfo(
      deviceId: id,
      deviceName: 'Pixel 8',
      platform: platform,
      osVersion: 'Android 15',
      appName: 'okicom',
      appVersion: '1.0.0',
      sdkVersion: sdk,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sdkLatestVersionsProvider.overrideWith(_Latest.new),
          connectedDevicesProvider.overrideWith(
            () => _Devices([
              device('rn', 'react_native', '1.0.0'),
              device('fl', 'flutter', '1.0.6'),
            ]),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Align(alignment: Alignment.topRight, child: LibUpdateTips()),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Tips lib'));
    await tester.pumpAndSettle();

    expect(find.text('npm ls devconnect-manage-kit'), findsOneWidget);
    expect(find.textContaining('flutter pub deps'), findsNothing);
    expect(find.text('Update'), findsOneWidget);
    expect(find.text('npm i devconnect-manage-kit@1.0.10'), findsOneWidget);
    expect(find.text('Install the latest version:'), findsNWidgets(3));
  });

  for (final (sdk, pill) in [
    ('1.0.6', 'v1.0.6 · Update'),
    ('1.0.7', 'v1.0.7 · Latest'),
    ('1.0.8', 'v1.0.8 · Update'),
    ('1.0.0', 'Tips lib'),
  ]) {
    testWidgets('a selected project on SDK $sdk reads "$pill" on the pill', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sdkLatestVersionsProvider.overrideWith(_Latest.new),
            connectedDevicesProvider.overrideWith(
              () => _Devices([
                DeviceInfo(
                  deviceId: 'fl',
                  deviceName: 'Pixel 8',
                  platform: 'flutter',
                  osVersion: 'Android 15',
                  appName: 'okicom',
                  appVersion: '1.0.0',
                  sdkVersion: sdk,
                ),
              ]),
            ),
            selectedDeviceProvider.overrideWith(() => _Selected('fl')),
          ],
          child: const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(body: LibUpdateTips()),
          ),
        ),
      );
      expect(find.text(pill), findsOneWidget);
    });
  }
}

class _Selected extends SelectedDeviceNotifier {
  _Selected(this.id);

  final String id;

  @override
  String? build() => id;
}

class _Latest extends SdkVersionsNotifier {
  @override
  SdkLatestVersions build() => const SdkLatestVersions(
    flutter: '1.0.7',
    reactNative: '1.0.10',
    android: '1.1.1',
  );
}

class _Devices extends ConnectedDevicesNotifier {
  _Devices(this.devices);

  final List<DeviceInfo> devices;

  @override
  List<DeviceInfo> build() => devices;
}
