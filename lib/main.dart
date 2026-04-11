import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/preferences/app_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppPreferences().init();

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(900, 600),
    center: true,
    title: 'DevConnect Manage Tool',
    titleBarStyle: TitleBarStyle.hidden,
    backgroundColor: Color(0xFF0D1117),
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    const ProviderScope(
      child: DevConnectApp(),
    ),
  );
}
