import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../models/storage/storage_entry.dart';

/// Tinted accent color for each storage backend. Centralized here so
/// the toolbar chip + tile left border + detail panel can all stay
/// in sync without duplicating the switch.
Color storageTypeColor(StorageType type) {
  switch (type) {
    case StorageType.asyncStorage: return const Color(0xFF61DAFB);
    case StorageType.sharedPreferences: return const Color(0xFF3DDC84);
    case StorageType.hive: return const Color(0xFFFFC107);
    case StorageType.sqlite: return const Color(0xFF003B57);
    case StorageType.realm: return const Color(0xFF39477F);
    case StorageType.objectbox: return const Color(0xFF00C853);
    case StorageType.floor: return const Color(0xFF607D8B);
    case StorageType.sembast: return const Color(0xFF8D6E63);
    case StorageType.sqflite: return const Color(0xFF1565C0);
    case StorageType.watermelondb: return const Color(0xFF4CAF50);
    case StorageType.encryptedStorage: return const Color(0xFFE91E63);
    case StorageType.sqldelight: return const Color(0xFF0288D1);
    case StorageType.mmkv: return const Color(0xFFFF6F00);
  }
}

/// Two-letter abbreviation for each storage backend — used as the
/// toolbar chip label and as the tile's compact type badge.
String storageTypeAbbrev(StorageType type) {
  switch (type) {
    case StorageType.asyncStorage: return 'AS';
    case StorageType.sharedPreferences: return 'SP';
    case StorageType.hive: return 'HV';
    case StorageType.sqlite: return 'SQL';
    case StorageType.realm: return 'RLM';
    case StorageType.objectbox: return 'OBX';
    case StorageType.floor: return 'FLR';
    case StorageType.sembast: return 'SMB';
    case StorageType.sqflite: return 'SQF';
    case StorageType.watermelondb: return 'WDB';
    case StorageType.encryptedStorage: return 'ENC';
    case StorageType.sqldelight: return 'SDL';
    case StorageType.mmkv: return 'MKV';
  }
}

/// Accent color for a storage operation (`write`/`read`/`delete`).
/// Two palettes are exposed — the bright Tailwind 400s used by the
/// detail panel screenshots vs. the muted `ColorTokens` used by the
/// list tiles — keep them distinct so the detail panel can read on
/// a white surface.
Color storageOpColor(String op) {
  switch (op.toLowerCase()) {
    case 'write': return ColorTokens.success;
    case 'delete':
    case 'clear': return ColorTokens.error;
    default: return ColorTokens.info;
  }
}

/// Detail-panel (screenshot) variant of [storageOpColor]. Slightly
/// brighter palette — used for the badges in the captured PNG.
Color storageOpAccentColor(String op) {
  switch (op.toLowerCase()) {
    case 'write': return const Color(0xFF34D399); // emerald 400
    case 'read': return const Color(0xFF60A5FA); // blue 400
    case 'delete':
    case 'clear': return const Color(0xFFF87171); // red 400
    default: return const Color(0xFFFBBF24); // amber 400
  }
}