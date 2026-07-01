import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/app_preferences.dart';
import '../../../models/device_info.dart';

/// Persistent record of every device that has ever connected to this desktop.
/// Stored in AppPreferences as a JSON array under `deviceHistory`.
class DeviceHistoryEntry {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String appName;
  final String appVersion;
  final String? clientIp;
  final int firstConnectedAt;
  int lastConnectedAt;
  bool isOnline;
  int totalConnections; // how many times this device has (re)connected

  DeviceHistoryEntry({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.appName,
    required this.appVersion,
    this.clientIp,
    required this.firstConnectedAt,
    required this.lastConnectedAt,
    required this.isOnline,
    this.totalConnections = 1,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': platform,
        'appName': appName,
        'appVersion': appVersion,
        if (clientIp != null) 'clientIp': clientIp,
        'firstConnectedAt': firstConnectedAt,
        'lastConnectedAt': lastConnectedAt,
        'isOnline': isOnline,
        'totalConnections': totalConnections,
      };

  factory DeviceHistoryEntry.fromJson(Map<String, dynamic> json) {
    final id = json['deviceId'];
    // Skip entries without a valid deviceId — caller catches the
    // exception so a single bad row doesn't drop the entire history.
    if (id is! String || id.isEmpty) {
      throw FormatException('DeviceHistoryEntry missing deviceId');
    }
    return DeviceHistoryEntry(
      deviceId: id,
      deviceName: (json['deviceName'] as String?) ?? '',
      platform: (json['platform'] as String?) ?? 'unknown',
      appName: (json['appName'] as String?) ?? '',
      appVersion: (json['appVersion'] as String?) ?? '',
      clientIp: json['clientIp'] as String?,
      firstConnectedAt: (json['firstConnectedAt'] as int?) ?? 0,
      lastConnectedAt: (json['lastConnectedAt'] as int?) ?? 0,
      isOnline: (json['isOnline'] as bool?) ?? false,
      totalConnections: (json['totalConnections'] as int?) ?? 1,
    );
  }
}

class DeviceHistoryNotifier extends StateNotifier<List<DeviceHistoryEntry>> {
  static const _prefsKey = 'deviceHistory';

  DeviceHistoryNotifier() : super([]) {
    _load();
  }

  void _load() {
    try {
      final raw = AppPreferences().get<String>(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      // Parse each entry independently — one malformed entry must not
      // wipe the entire history. Bad entries are skipped silently.
      final loaded = <DeviceHistoryEntry>[];
      for (final raw in decoded) {
        if (raw is! Map<String, dynamic>) continue;
        try {
          loaded.add(DeviceHistoryEntry.fromJson(raw));
        } catch (_) {
          // Skip malformed entry, keep the rest.
        }
      }
      state = loaded;
      // Mark anything that was online at last quit as offline — the new
      // process can't know if it actually reconnected.
      for (final e in state) {
        if (e.isOnline) e.isOnline = false;
      }
      // Keep most-recent first.
      state.sort((a, b) => b.lastConnectedAt.compareTo(a.lastConnectedAt));
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
      await AppPreferences().set(_prefsKey, encoded);
    } catch (_) {}
  }

  /// Upsert: if the deviceId is new, add an entry; otherwise update.
  Future<void> onConnected(DeviceInfo info) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final idx = state.indexWhere((e) => e.deviceId == info.deviceId);
    if (idx >= 0) {
      final existing = state[idx];
      final updated = DeviceHistoryEntry(
        deviceId: existing.deviceId,
        deviceName: info.deviceName.isNotEmpty
            ? info.deviceName
            : existing.deviceName,
        platform: info.platform,
        appName: info.appName,
        appVersion: info.appVersion,
        clientIp: info.clientIp ?? existing.clientIp,
        firstConnectedAt: existing.firstConnectedAt,
        lastConnectedAt: now,
        isOnline: true,
        totalConnections: existing.totalConnections + 1,
      );
      state = [...state]..[idx] = updated;
    } else {
      state = [
        DeviceHistoryEntry(
          deviceId: info.deviceId,
          deviceName: info.deviceName,
          platform: info.platform,
          appName: info.appName,
          appVersion: info.appVersion,
          clientIp: info.clientIp,
          firstConnectedAt: now,
          lastConnectedAt: now,
          isOnline: true,
        ),
        ...state,
      ];
    }
    await _save();
  }

  /// Mark a device as offline; keep its entry but bump lastSeenAt.
  Future<void> onDisconnected(String deviceId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final idx = state.indexWhere((e) => e.deviceId == deviceId);
    if (idx < 0) return;
    final existing = state[idx];
    state = [...state]..[idx] = DeviceHistoryEntry(
          deviceId: existing.deviceId,
          deviceName: existing.deviceName,
          platform: existing.platform,
          appName: existing.appName,
          appVersion: existing.appVersion,
          clientIp: existing.clientIp,
          firstConnectedAt: existing.firstConnectedAt,
          lastConnectedAt: now,
          isOnline: false,
          totalConnections: existing.totalConnections,
        );
    await _save();
  }

  /// Drop a single entry.
  Future<void> forget(String deviceId) async {
    state = state.where((e) => e.deviceId != deviceId).toList();
    await _save();
  }

  /// Replace one entry in-place (keeps the same deviceId). Used by the
  /// "mark online/offline" toggle in the cached-devices UI.
  Future<void> replaceEntry(String deviceId, DeviceHistoryEntry updated) async {
    state = [
      for (final e in state)
        if (e.deviceId == deviceId) updated else e,
    ];
    await _save();
  }

  /// Drop every entry that's currently offline. Useful for "reset history".
  Future<void> forgetAllOffline() async {
    state = state.where((e) => e.isOnline).toList();
    await _save();
  }

  /// Drop everything.
  Future<void> forgetAll() async {
    state = [];
    await _save();
  }
}

final deviceHistoryProvider =
    StateNotifierProvider<DeviceHistoryNotifier, List<DeviceHistoryEntry>>(
  (ref) => DeviceHistoryNotifier(),
);