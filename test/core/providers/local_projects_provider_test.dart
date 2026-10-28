import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/providers/local_projects_provider.dart';
import 'package:devconnect_manage_tool/core/providers/sdk_versions_provider.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';

void main() {
  test('recognises Metro and flutter run command lines', () {
    expect(
      devServerPlatform(
        '/Users/x/.nvm/versions/node/v22.23.4/bin/node '
        '/Users/x/okicom-workspace/Tenant/morioka/node_modules/.bin/'
        'react-native start --client-logs --reset-cache',
      ),
      SdkPlatform.reactNative,
    );
    expect(
      devServerPlatform('node /x/expo/bin/cli start'),
      SdkPlatform.reactNative,
    );
    // yarn's own wrapper process — the real Metro is its child.
    expect(
      devServerPlatform(
        'node /opt/homebrew/libexec/lib/cli.js start --reset-cache',
      ),
      isNull,
    );
    expect(
      devServerPlatform(
        '/f/bin/cache/dart-sdk/bin/dart --packages=/f/.dart_tool/x '
        '/f/bin/cache/flutter_tools.snapshot --no-color run --machine -d emulator-5554',
      ),
      SdkPlatform.flutter,
    );
    expect(devServerPlatform('/f/flutter_tools.snapshot daemon'), isNull);
  });

  test('reads the hoisted npm install and the pubspec.lock entry', () {
    final root = Directory.systemTemp.createTempSync('dc_scan');
    addTearDown(() => root.deleteSync(recursive: true));

    File('${root.path}/node_modules/devconnect-manage-kit/package.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"name":"devconnect-manage-kit","version":"1.0.9"}');
    final tenant = Directory('${root.path}/Tenant/morioka')
      ..createSync(recursive: true);
    expect(installedSdkVersion(SdkPlatform.reactNative, tenant.path), '1.0.9');

    File('${root.path}/app/pubspec.lock')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
packages:
  dio:
    dependency: transitive
    version: "5.0.0"
  devconnect_manage_kit:
    dependency: "direct main"
    description:
      name: devconnect_manage_kit
      url: "https://pub.dev"
    source: hosted
    version: "1.0.6"
''');
    expect(
      installedSdkVersion(SdkPlatform.flutter, '${root.path}/app'),
      '1.0.6',
    );
    expect(installedSdkVersion(SdkPlatform.android, root.path), isNull);
  });

  test('a folder the OS won\'t let us read surfaces, not reads as missing', () {
    final root = Directory.systemTemp.createTempSync('dc_denied');
    final modules = Directory('${root.path}/node_modules')..createSync();
    File('${modules.path}/devconnect-manage-kit/package.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"version":"1.0.9"}');
    Process.runSync('chmod', ['000', modules.path]);
    addTearDown(() {
      Process.runSync('chmod', ['755', modules.path]);
      root.deleteSync(recursive: true);
    });

    expect(
      () => installedSdkVersion(SdkPlatform.reactNative, root.path),
      throwsA(isA<PathAccessException>()),
    );
  });

  test('device version: disk first, legacy handshake 1.0.0 is unknown', () {
    DeviceInfo device(String sdk) => DeviceInfo(
      deviceId: 'd',
      deviceName: 'Pixel 8',
      platform: 'react_native',
      osVersion: 'Android 15',
      appName: 'okicom',
      appVersion: '1.0.0',
      sdkVersion: sdk,
    );
    const onDisk = LocalProject(SdkPlatform.reactNative, '/w/okicom', '1.0.9');
    const denied = LocalProject(SdkPlatform.reactNative, '/w/okicom', null);

    expect(deviceSdkVersion(device('1.0.0'), const []), isNull);
    expect(deviceSdkVersion(device('1.0.10'), const []), '1.0.10');
    expect(deviceSdkVersion(device('1.0.0'), [onDisk]), '1.0.9');
    expect(deviceSdkVersion(device('1.0.10'), [denied]), isNull);
  });

  test(
    'maps a device to the only dev server of its platform, else by name',
    () {
      DeviceInfo device(String app) => DeviceInfo(
        deviceId: app,
        deviceName: 'iPhone 15',
        platform: 'react_native',
        osVersion: 'iOS 18',
        appName: app,
        appVersion: '1.0.0',
      );
      const morioka = LocalProject(
        SdkPlatform.reactNative,
        '/w/Tenant/morioka',
        '1.0.9',
      );
      const chiba = LocalProject(
        SdkPlatform.reactNative,
        '/w/Tenant/chiba',
        '1.0.5',
      );
      const flutterApp = LocalProject(
        SdkPlatform.flutter,
        '/w/okicom',
        '1.0.6',
      );

      expect(localProjectFor(device('okicom'), [morioka, flutterApp]), morioka);
      expect(localProjectFor(device('Chiba'), [morioka, chiba]), chiba);
      expect(localProjectFor(device('okicom'), [morioka, chiba]), isNull);
    },
  );
}
