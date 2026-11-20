import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

/// [type] as its library spells it, for labels people read.
String storageTypeName(StorageType type) => switch (type) {
  StorageType.asyncStorage => 'AsyncStorage',
  StorageType.sharedPreferences => 'SharedPreferences',
  StorageType.hive => 'Hive',
  StorageType.sqlite => 'SQLite',
  StorageType.realm => 'Realm',
  StorageType.objectbox => 'ObjectBox',
  StorageType.floor => 'Floor',
  StorageType.sembast => 'Sembast',
  StorageType.sqflite => 'sqflite',
  StorageType.watermelondb => 'WatermelonDB',
  StorageType.encryptedStorage => 'EncryptedStorage',
  StorageType.sqldelight => 'SQLDelight',
  StorageType.mmkv => 'MMKV',
};

/// [type] and its [storeId] (an MMKV instance, say) as one label.
String storageLabel(StorageType type, String? storeId) => storeId == null
    ? storageTypeName(type)
    : '${storageTypeName(type)} · $storeId';

/// [color] made dark or light enough to read as text on its own tint.
Color storageInk(Color color, bool isDark) {
  final l = color.computeLuminance();
  return isDark
      ? Color.lerp(color, Colors.white, l < 0.1 ? 0.55 : 0.35)!
      : Color.lerp(color, Colors.black, l > 0.4 ? 0.45 : (l > 0.15 ? 0.3 : 0.1))!;
}

/// Glyph for a storage operation.
IconData storageOpIcon(String op) => switch (op.toLowerCase()) {
  'write' => LucideIcons.pencilLine,
  'delete' || 'clear' => LucideIcons.trash2,
  _ => LucideIcons.eye,
};

/// A stored value's type as the key-value table labels it, and its color.
(String, Color) storageValueKind(Object? value) => switch (value) {
  String() => ('string', const Color(0xFF3FB950)),
  num() => ('number', const Color(0xFF58A6FF)),
  bool() => ('bool', const Color(0xFFBC8CFF)),
  null => ('null', const Color(0xFF8B949E)),
  _ => ('json', const Color(0xFFF0883E)),
};