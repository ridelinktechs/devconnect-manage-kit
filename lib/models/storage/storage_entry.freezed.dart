// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'storage_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StorageEntry {

 String get id; String get deviceId; StorageType get storageType;/// Optional instance/namespace label — e.g. for MMKV this carries
/// the `mmkvId` (`'mmkv:user-storage'` → `mmkv`, `storeId='user-storage'`).
/// Multiple stores of the same [storageType] with different [storeId]
/// must coexist; dedup at the viewer is keyed on
/// `(storageType, storeId, key)`.
 String? get storeId; String get key; dynamic get value; String get operation; int get timestamp;
/// Create a copy of StorageEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorageEntryCopyWith<StorageEntry> get copyWith => _$StorageEntryCopyWithImpl<StorageEntry>(this as StorageEntry, _$identity);

  /// Serializes this StorageEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorageEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.storageType, storageType) || other.storageType == storageType)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.key, key) || other.key == key)&&const DeepCollectionEquality().equals(other.value, value)&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,deviceId,storageType,storeId,key,const DeepCollectionEquality().hash(value),operation,timestamp);

@override
String toString() {
  return 'StorageEntry(id: $id, deviceId: $deviceId, storageType: $storageType, storeId: $storeId, key: $key, value: $value, operation: $operation, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $StorageEntryCopyWith<$Res>  {
  factory $StorageEntryCopyWith(StorageEntry value, $Res Function(StorageEntry) _then) = _$StorageEntryCopyWithImpl;
@useResult
$Res call({
 String id, String deviceId, StorageType storageType, String? storeId, String key, dynamic value, String operation, int timestamp
});




}
/// @nodoc
class _$StorageEntryCopyWithImpl<$Res>
    implements $StorageEntryCopyWith<$Res> {
  _$StorageEntryCopyWithImpl(this._self, this._then);

  final StorageEntry _self;
  final $Res Function(StorageEntry) _then;

/// Create a copy of StorageEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? deviceId = null,Object? storageType = null,Object? storeId = freezed,Object? key = null,Object? value = freezed,Object? operation = null,Object? timestamp = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,storageType: null == storageType ? _self.storageType : storageType // ignore: cast_nullable_to_non_nullable
as StorageType,storeId: freezed == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String?,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as dynamic,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StorageEntry].
extension StorageEntryPatterns on StorageEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StorageEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StorageEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StorageEntry value)  $default,){
final _that = this;
switch (_that) {
case _StorageEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StorageEntry value)?  $default,){
final _that = this;
switch (_that) {
case _StorageEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String deviceId,  StorageType storageType,  String? storeId,  String key,  dynamic value,  String operation,  int timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StorageEntry() when $default != null:
return $default(_that.id,_that.deviceId,_that.storageType,_that.storeId,_that.key,_that.value,_that.operation,_that.timestamp);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String deviceId,  StorageType storageType,  String? storeId,  String key,  dynamic value,  String operation,  int timestamp)  $default,) {final _that = this;
switch (_that) {
case _StorageEntry():
return $default(_that.id,_that.deviceId,_that.storageType,_that.storeId,_that.key,_that.value,_that.operation,_that.timestamp);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String deviceId,  StorageType storageType,  String? storeId,  String key,  dynamic value,  String operation,  int timestamp)?  $default,) {final _that = this;
switch (_that) {
case _StorageEntry() when $default != null:
return $default(_that.id,_that.deviceId,_that.storageType,_that.storeId,_that.key,_that.value,_that.operation,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StorageEntry implements StorageEntry {
  const _StorageEntry({required this.id, required this.deviceId, required this.storageType, this.storeId = null, required this.key, this.value, required this.operation, required this.timestamp});
  factory _StorageEntry.fromJson(Map<String, dynamic> json) => _$StorageEntryFromJson(json);

@override final  String id;
@override final  String deviceId;
@override final  StorageType storageType;
/// Optional instance/namespace label — e.g. for MMKV this carries
/// the `mmkvId` (`'mmkv:user-storage'` → `mmkv`, `storeId='user-storage'`).
/// Multiple stores of the same [storageType] with different [storeId]
/// must coexist; dedup at the viewer is keyed on
/// `(storageType, storeId, key)`.
@override@JsonKey() final  String? storeId;
@override final  String key;
@override final  dynamic value;
@override final  String operation;
@override final  int timestamp;

/// Create a copy of StorageEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StorageEntryCopyWith<_StorageEntry> get copyWith => __$StorageEntryCopyWithImpl<_StorageEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StorageEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StorageEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.storageType, storageType) || other.storageType == storageType)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.key, key) || other.key == key)&&const DeepCollectionEquality().equals(other.value, value)&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,deviceId,storageType,storeId,key,const DeepCollectionEquality().hash(value),operation,timestamp);

@override
String toString() {
  return 'StorageEntry(id: $id, deviceId: $deviceId, storageType: $storageType, storeId: $storeId, key: $key, value: $value, operation: $operation, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$StorageEntryCopyWith<$Res> implements $StorageEntryCopyWith<$Res> {
  factory _$StorageEntryCopyWith(_StorageEntry value, $Res Function(_StorageEntry) _then) = __$StorageEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String deviceId, StorageType storageType, String? storeId, String key, dynamic value, String operation, int timestamp
});




}
/// @nodoc
class __$StorageEntryCopyWithImpl<$Res>
    implements _$StorageEntryCopyWith<$Res> {
  __$StorageEntryCopyWithImpl(this._self, this._then);

  final _StorageEntry _self;
  final $Res Function(_StorageEntry) _then;

/// Create a copy of StorageEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? deviceId = null,Object? storageType = null,Object? storeId = freezed,Object? key = null,Object? value = freezed,Object? operation = null,Object? timestamp = null,}) {
  return _then(_StorageEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,storageType: null == storageType ? _self.storageType : storageType // ignore: cast_nullable_to_non_nullable
as StorageType,storeId: freezed == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String?,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as dynamic,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DatabaseSchema {

 String get name; List<DatabaseTable> get tables;
/// Create a copy of DatabaseSchema
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DatabaseSchemaCopyWith<DatabaseSchema> get copyWith => _$DatabaseSchemaCopyWithImpl<DatabaseSchema>(this as DatabaseSchema, _$identity);

  /// Serializes this DatabaseSchema to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DatabaseSchema&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.tables, tables));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(tables));

@override
String toString() {
  return 'DatabaseSchema(name: $name, tables: $tables)';
}


}

/// @nodoc
abstract mixin class $DatabaseSchemaCopyWith<$Res>  {
  factory $DatabaseSchemaCopyWith(DatabaseSchema value, $Res Function(DatabaseSchema) _then) = _$DatabaseSchemaCopyWithImpl;
@useResult
$Res call({
 String name, List<DatabaseTable> tables
});




}
/// @nodoc
class _$DatabaseSchemaCopyWithImpl<$Res>
    implements $DatabaseSchemaCopyWith<$Res> {
  _$DatabaseSchemaCopyWithImpl(this._self, this._then);

  final DatabaseSchema _self;
  final $Res Function(DatabaseSchema) _then;

/// Create a copy of DatabaseSchema
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? tables = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tables: null == tables ? _self.tables : tables // ignore: cast_nullable_to_non_nullable
as List<DatabaseTable>,
  ));
}

}


/// Adds pattern-matching-related methods to [DatabaseSchema].
extension DatabaseSchemaPatterns on DatabaseSchema {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DatabaseSchema value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DatabaseSchema() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DatabaseSchema value)  $default,){
final _that = this;
switch (_that) {
case _DatabaseSchema():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DatabaseSchema value)?  $default,){
final _that = this;
switch (_that) {
case _DatabaseSchema() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  List<DatabaseTable> tables)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DatabaseSchema() when $default != null:
return $default(_that.name,_that.tables);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  List<DatabaseTable> tables)  $default,) {final _that = this;
switch (_that) {
case _DatabaseSchema():
return $default(_that.name,_that.tables);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  List<DatabaseTable> tables)?  $default,) {final _that = this;
switch (_that) {
case _DatabaseSchema() when $default != null:
return $default(_that.name,_that.tables);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DatabaseSchema implements DatabaseSchema {
  const _DatabaseSchema({required this.name, required final  List<DatabaseTable> tables}): _tables = tables;
  factory _DatabaseSchema.fromJson(Map<String, dynamic> json) => _$DatabaseSchemaFromJson(json);

@override final  String name;
 final  List<DatabaseTable> _tables;
@override List<DatabaseTable> get tables {
  if (_tables is EqualUnmodifiableListView) return _tables;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tables);
}


/// Create a copy of DatabaseSchema
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DatabaseSchemaCopyWith<_DatabaseSchema> get copyWith => __$DatabaseSchemaCopyWithImpl<_DatabaseSchema>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DatabaseSchemaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DatabaseSchema&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._tables, _tables));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_tables));

@override
String toString() {
  return 'DatabaseSchema(name: $name, tables: $tables)';
}


}

/// @nodoc
abstract mixin class _$DatabaseSchemaCopyWith<$Res> implements $DatabaseSchemaCopyWith<$Res> {
  factory _$DatabaseSchemaCopyWith(_DatabaseSchema value, $Res Function(_DatabaseSchema) _then) = __$DatabaseSchemaCopyWithImpl;
@override @useResult
$Res call({
 String name, List<DatabaseTable> tables
});




}
/// @nodoc
class __$DatabaseSchemaCopyWithImpl<$Res>
    implements _$DatabaseSchemaCopyWith<$Res> {
  __$DatabaseSchemaCopyWithImpl(this._self, this._then);

  final _DatabaseSchema _self;
  final $Res Function(_DatabaseSchema) _then;

/// Create a copy of DatabaseSchema
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? tables = null,}) {
  return _then(_DatabaseSchema(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tables: null == tables ? _self._tables : tables // ignore: cast_nullable_to_non_nullable
as List<DatabaseTable>,
  ));
}


}


/// @nodoc
mixin _$DatabaseTable {

 String get name; List<DatabaseColumn> get columns; int get rowCount;
/// Create a copy of DatabaseTable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DatabaseTableCopyWith<DatabaseTable> get copyWith => _$DatabaseTableCopyWithImpl<DatabaseTable>(this as DatabaseTable, _$identity);

  /// Serializes this DatabaseTable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DatabaseTable&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.columns, columns)&&(identical(other.rowCount, rowCount) || other.rowCount == rowCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(columns),rowCount);

@override
String toString() {
  return 'DatabaseTable(name: $name, columns: $columns, rowCount: $rowCount)';
}


}

/// @nodoc
abstract mixin class $DatabaseTableCopyWith<$Res>  {
  factory $DatabaseTableCopyWith(DatabaseTable value, $Res Function(DatabaseTable) _then) = _$DatabaseTableCopyWithImpl;
@useResult
$Res call({
 String name, List<DatabaseColumn> columns, int rowCount
});




}
/// @nodoc
class _$DatabaseTableCopyWithImpl<$Res>
    implements $DatabaseTableCopyWith<$Res> {
  _$DatabaseTableCopyWithImpl(this._self, this._then);

  final DatabaseTable _self;
  final $Res Function(DatabaseTable) _then;

/// Create a copy of DatabaseTable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? columns = null,Object? rowCount = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,columns: null == columns ? _self.columns : columns // ignore: cast_nullable_to_non_nullable
as List<DatabaseColumn>,rowCount: null == rowCount ? _self.rowCount : rowCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DatabaseTable].
extension DatabaseTablePatterns on DatabaseTable {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DatabaseTable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DatabaseTable() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DatabaseTable value)  $default,){
final _that = this;
switch (_that) {
case _DatabaseTable():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DatabaseTable value)?  $default,){
final _that = this;
switch (_that) {
case _DatabaseTable() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  List<DatabaseColumn> columns,  int rowCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DatabaseTable() when $default != null:
return $default(_that.name,_that.columns,_that.rowCount);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  List<DatabaseColumn> columns,  int rowCount)  $default,) {final _that = this;
switch (_that) {
case _DatabaseTable():
return $default(_that.name,_that.columns,_that.rowCount);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  List<DatabaseColumn> columns,  int rowCount)?  $default,) {final _that = this;
switch (_that) {
case _DatabaseTable() when $default != null:
return $default(_that.name,_that.columns,_that.rowCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DatabaseTable implements DatabaseTable {
  const _DatabaseTable({required this.name, required final  List<DatabaseColumn> columns, this.rowCount = 0}): _columns = columns;
  factory _DatabaseTable.fromJson(Map<String, dynamic> json) => _$DatabaseTableFromJson(json);

@override final  String name;
 final  List<DatabaseColumn> _columns;
@override List<DatabaseColumn> get columns {
  if (_columns is EqualUnmodifiableListView) return _columns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_columns);
}

@override@JsonKey() final  int rowCount;

/// Create a copy of DatabaseTable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DatabaseTableCopyWith<_DatabaseTable> get copyWith => __$DatabaseTableCopyWithImpl<_DatabaseTable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DatabaseTableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DatabaseTable&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._columns, _columns)&&(identical(other.rowCount, rowCount) || other.rowCount == rowCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_columns),rowCount);

@override
String toString() {
  return 'DatabaseTable(name: $name, columns: $columns, rowCount: $rowCount)';
}


}

/// @nodoc
abstract mixin class _$DatabaseTableCopyWith<$Res> implements $DatabaseTableCopyWith<$Res> {
  factory _$DatabaseTableCopyWith(_DatabaseTable value, $Res Function(_DatabaseTable) _then) = __$DatabaseTableCopyWithImpl;
@override @useResult
$Res call({
 String name, List<DatabaseColumn> columns, int rowCount
});




}
/// @nodoc
class __$DatabaseTableCopyWithImpl<$Res>
    implements _$DatabaseTableCopyWith<$Res> {
  __$DatabaseTableCopyWithImpl(this._self, this._then);

  final _DatabaseTable _self;
  final $Res Function(_DatabaseTable) _then;

/// Create a copy of DatabaseTable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? columns = null,Object? rowCount = null,}) {
  return _then(_DatabaseTable(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,columns: null == columns ? _self._columns : columns // ignore: cast_nullable_to_non_nullable
as List<DatabaseColumn>,rowCount: null == rowCount ? _self.rowCount : rowCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DatabaseColumn {

 String get name; String get type; bool get isPrimaryKey; bool get isNullable;
/// Create a copy of DatabaseColumn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DatabaseColumnCopyWith<DatabaseColumn> get copyWith => _$DatabaseColumnCopyWithImpl<DatabaseColumn>(this as DatabaseColumn, _$identity);

  /// Serializes this DatabaseColumn to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DatabaseColumn&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.isPrimaryKey, isPrimaryKey) || other.isPrimaryKey == isPrimaryKey)&&(identical(other.isNullable, isNullable) || other.isNullable == isNullable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,type,isPrimaryKey,isNullable);

@override
String toString() {
  return 'DatabaseColumn(name: $name, type: $type, isPrimaryKey: $isPrimaryKey, isNullable: $isNullable)';
}


}

/// @nodoc
abstract mixin class $DatabaseColumnCopyWith<$Res>  {
  factory $DatabaseColumnCopyWith(DatabaseColumn value, $Res Function(DatabaseColumn) _then) = _$DatabaseColumnCopyWithImpl;
@useResult
$Res call({
 String name, String type, bool isPrimaryKey, bool isNullable
});




}
/// @nodoc
class _$DatabaseColumnCopyWithImpl<$Res>
    implements $DatabaseColumnCopyWith<$Res> {
  _$DatabaseColumnCopyWithImpl(this._self, this._then);

  final DatabaseColumn _self;
  final $Res Function(DatabaseColumn) _then;

/// Create a copy of DatabaseColumn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? type = null,Object? isPrimaryKey = null,Object? isNullable = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,isPrimaryKey: null == isPrimaryKey ? _self.isPrimaryKey : isPrimaryKey // ignore: cast_nullable_to_non_nullable
as bool,isNullable: null == isNullable ? _self.isNullable : isNullable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DatabaseColumn].
extension DatabaseColumnPatterns on DatabaseColumn {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DatabaseColumn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DatabaseColumn() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DatabaseColumn value)  $default,){
final _that = this;
switch (_that) {
case _DatabaseColumn():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DatabaseColumn value)?  $default,){
final _that = this;
switch (_that) {
case _DatabaseColumn() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String type,  bool isPrimaryKey,  bool isNullable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DatabaseColumn() when $default != null:
return $default(_that.name,_that.type,_that.isPrimaryKey,_that.isNullable);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String type,  bool isPrimaryKey,  bool isNullable)  $default,) {final _that = this;
switch (_that) {
case _DatabaseColumn():
return $default(_that.name,_that.type,_that.isPrimaryKey,_that.isNullable);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String type,  bool isPrimaryKey,  bool isNullable)?  $default,) {final _that = this;
switch (_that) {
case _DatabaseColumn() when $default != null:
return $default(_that.name,_that.type,_that.isPrimaryKey,_that.isNullable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DatabaseColumn implements DatabaseColumn {
  const _DatabaseColumn({required this.name, required this.type, this.isPrimaryKey = false, this.isNullable = true});
  factory _DatabaseColumn.fromJson(Map<String, dynamic> json) => _$DatabaseColumnFromJson(json);

@override final  String name;
@override final  String type;
@override@JsonKey() final  bool isPrimaryKey;
@override@JsonKey() final  bool isNullable;

/// Create a copy of DatabaseColumn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DatabaseColumnCopyWith<_DatabaseColumn> get copyWith => __$DatabaseColumnCopyWithImpl<_DatabaseColumn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DatabaseColumnToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DatabaseColumn&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.isPrimaryKey, isPrimaryKey) || other.isPrimaryKey == isPrimaryKey)&&(identical(other.isNullable, isNullable) || other.isNullable == isNullable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,type,isPrimaryKey,isNullable);

@override
String toString() {
  return 'DatabaseColumn(name: $name, type: $type, isPrimaryKey: $isPrimaryKey, isNullable: $isNullable)';
}


}

/// @nodoc
abstract mixin class _$DatabaseColumnCopyWith<$Res> implements $DatabaseColumnCopyWith<$Res> {
  factory _$DatabaseColumnCopyWith(_DatabaseColumn value, $Res Function(_DatabaseColumn) _then) = __$DatabaseColumnCopyWithImpl;
@override @useResult
$Res call({
 String name, String type, bool isPrimaryKey, bool isNullable
});




}
/// @nodoc
class __$DatabaseColumnCopyWithImpl<$Res>
    implements _$DatabaseColumnCopyWith<$Res> {
  __$DatabaseColumnCopyWithImpl(this._self, this._then);

  final _DatabaseColumn _self;
  final $Res Function(_DatabaseColumn) _then;

/// Create a copy of DatabaseColumn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? type = null,Object? isPrimaryKey = null,Object? isNullable = null,}) {
  return _then(_DatabaseColumn(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,isPrimaryKey: null == isPrimaryKey ? _self.isPrimaryKey : isPrimaryKey // ignore: cast_nullable_to_non_nullable
as bool,isNullable: null == isNullable ? _self.isNullable : isNullable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
