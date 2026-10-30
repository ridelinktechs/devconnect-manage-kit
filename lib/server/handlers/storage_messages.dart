part of '../ws_message_handler.dart';

/// Parses the wire `storageType` string into the [StorageType] enum
/// plus an optional instance/namespace [storeId].
///
/// SDKs may send `<type>:<storeId>` to distinguish between multiple
/// instances of the same backend — e.g. two MMKV instances
/// (`mmkv:user-storage` and `mmkv:settings`). Bare `<type>` strings
/// leave [storeId] null. The base type match is case-insensitive; the
/// label is preserved verbatim. Unrecognised bases fall back to
/// [StorageType.sharedPreferences] (same behaviour as the legacy parser).
({StorageType storageType, String? storeId}) parseStorageTypeAndStoreId(
  String raw,
) {
  final lower = raw.toLowerCase();
  final colon = lower.indexOf(':');
  String base;
  String? label;
  if (colon >= 0) {
    base = lower.substring(0, colon);
    final tail = raw.substring(colon + 1).trim();
    label = tail.isEmpty ? null : tail;
  } else {
    base = lower;
  }

  final StorageType type;
  switch (base) {
    case 'async_storage':
    case 'asyncstorage':
      type = StorageType.asyncStorage;
      break;
    case 'shared_preferences':
    case 'sharedpreferences':
      type = StorageType.sharedPreferences;
      break;
    case 'hive':
      type = StorageType.hive;
      break;
    case 'sqlite':
      type = StorageType.sqlite;
      break;
    case 'realm':
      type = StorageType.realm;
      break;
    case 'objectbox':
      type = StorageType.objectbox;
      break;
    case 'floor':
      type = StorageType.floor;
      break;
    case 'sembast':
      type = StorageType.sembast;
      break;
    case 'sqflite':
      type = StorageType.sqflite;
      break;
    case 'watermelondb':
      type = StorageType.watermelondb;
      break;
    case 'encrypted_storage':
    case 'encryptedstorage':
      type = StorageType.encryptedStorage;
      break;
    case 'sqldelight':
      type = StorageType.sqldelight;
      break;
    case 'mmkv':
      type = StorageType.mmkv;
      break;
    default:
      type = StorageType.sharedPreferences;
      break;
  }
  return (storageType: type, storeId: label);
}

extension _StorageMessages on WsMessageHandler {
  void _handleStorage(DCMessage message) {
    final p = message.payload;
    final parsed = parseStorageTypeAndStoreId(
      p['storageType'] as String? ?? '',
    );
    final entry = StorageEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      storageType: parsed.storageType,
      storeId: parsed.storeId,
      key: p['key'] as String? ?? '',
      value: p['value'],
      operation: p['operation'] as String? ?? 'read',
      timestamp: message.timestamp,
    );
    _storageController.add(entry);
  }
}
