// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StorageEntry _$StorageEntryFromJson(Map<String, dynamic> json) =>
    _StorageEntry(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      storageType: $enumDecode(_$StorageTypeEnumMap, json['storageType']),
      storeId: json['storeId'] as String? ?? null,
      key: json['key'] as String,
      value: json['value'],
      operation: json['operation'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
    );

Map<String, dynamic> _$StorageEntryToJson(_StorageEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'storageType': _$StorageTypeEnumMap[instance.storageType]!,
      'storeId': instance.storeId,
      'key': instance.key,
      'value': instance.value,
      'operation': instance.operation,
      'timestamp': instance.timestamp,
    };

const _$StorageTypeEnumMap = {
  StorageType.asyncStorage: 'asyncStorage',
  StorageType.sharedPreferences: 'sharedPreferences',
  StorageType.hive: 'hive',
  StorageType.sqlite: 'sqlite',
  StorageType.realm: 'realm',
  StorageType.objectbox: 'objectbox',
  StorageType.floor: 'floor',
  StorageType.sembast: 'sembast',
  StorageType.sqflite: 'sqflite',
  StorageType.watermelondb: 'watermelondb',
  StorageType.encryptedStorage: 'encryptedStorage',
  StorageType.sqldelight: 'sqldelight',
  StorageType.mmkv: 'mmkv',
};

_DatabaseSchema _$DatabaseSchemaFromJson(Map<String, dynamic> json) =>
    _DatabaseSchema(
      name: json['name'] as String,
      tables: (json['tables'] as List<dynamic>)
          .map((e) => DatabaseTable.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DatabaseSchemaToJson(_DatabaseSchema instance) =>
    <String, dynamic>{'name': instance.name, 'tables': instance.tables};

_DatabaseTable _$DatabaseTableFromJson(Map<String, dynamic> json) =>
    _DatabaseTable(
      name: json['name'] as String,
      columns: (json['columns'] as List<dynamic>)
          .map((e) => DatabaseColumn.fromJson(e as Map<String, dynamic>))
          .toList(),
      rowCount: (json['rowCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$DatabaseTableToJson(_DatabaseTable instance) =>
    <String, dynamic>{
      'name': instance.name,
      'columns': instance.columns,
      'rowCount': instance.rowCount,
    };

_DatabaseColumn _$DatabaseColumnFromJson(Map<String, dynamic> json) =>
    _DatabaseColumn(
      name: json['name'] as String,
      type: json['type'] as String,
      isPrimaryKey: json['isPrimaryKey'] as bool? ?? false,
      isNullable: json['isNullable'] as bool? ?? true,
    );

Map<String, dynamic> _$DatabaseColumnToJson(_DatabaseColumn instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'isPrimaryKey': instance.isPrimaryKey,
      'isNullable': instance.isNullable,
    };
