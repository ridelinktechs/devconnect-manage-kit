import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/utils/app/reload_apps.dart';
import 'package:devconnect_manage_tool/l10n/generated/app_localizations.dart';
import 'package:devconnect_manage_tool/models/device_info.dart';

void main() {
  final loc = lookupS(const Locale('en'));
  DeviceInfo device(String platform) => DeviceInfo(
    deviceId: platform,
    deviceName: 'd',
    platform: platform,
    osVersion: 'os',
    appName: 'app',
    appVersion: '1.0.0',
  );
  List<(String, bool)> actions(List<String> platforms) => [
    for (final a in reloadActionsFor(platforms.map(device).toList(), loc))
      (a.label, a.hotRestart),
  ];

  test('reload buttons follow the target devices\' platform', () {
    expect(actions([]), isEmpty);
    expect(actions(['flutter']), [
      (loc.reloadAppHotReload, false),
      (loc.reloadAppHotRestart, true),
    ]);
    expect(actions(['react_native', 'reactnative']), [
      (loc.reloadAppMetro, false),
    ]);
    // Activity.recreate() is a restart in effect, sent as a plain reload.
    expect(actions(['android']), [(loc.reloadAppHotRestart, false)]);
    expect(actions(['flutter', 'android']), [(loc.reloadApp, false)]);
  });
}
