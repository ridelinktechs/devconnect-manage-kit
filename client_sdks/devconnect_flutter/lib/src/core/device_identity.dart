import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

/// Get a stable device identifier using device_info_plus.
/// Android: UUID from androidId + packageName
/// iOS: identifierForVendor (already UUID)
Future<String> getStableDeviceId(String appName) async {
  try {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      final id = android.id; // ANDROID_ID
      // Convert to UUID v5 format via Uuid.v5
      return const Uuid().v5(Namespace.url.value, '$id:$appName');
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      return ios.identifierForVendor ??
          const Uuid()
              .v5(Namespace.url.value, '$appName:${Platform.localHostname}');
    } else if (Platform.isMacOS) {
      final mac = await deviceInfo.macOsInfo;
      final guid = mac.systemGUID ?? mac.computerName;
      return const Uuid().v5(Namespace.url.value, '$guid:$appName');
    }
  } catch (_) {}
  // Fallback
  return const Uuid().v5(Namespace.url.value,
      '$appName:${Platform.localHostname}:${Platform.operatingSystem}');
}

String defaultDeviceName() {
  // Use localHostname for a meaningful device name (e.g., "Johns-iPhone")
  final hostname = Platform.localHostname;
  if (hostname.isNotEmpty && hostname != 'localhost') return hostname;
  if (Platform.isAndroid) return 'Android Device';
  if (Platform.isIOS) return 'iOS Device';
  if (Platform.isMacOS) return 'macOS';
  if (Platform.isWindows) return 'Windows';
  if (Platform.isLinux) return 'Linux';
  return 'Unknown Device';
}
