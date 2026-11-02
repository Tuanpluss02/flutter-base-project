// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../../src/core/offline/sync/sync_dataset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SyncDataset {

 String get name; OfflinePolicy get policy; String? get cursor; DateTime? get lastSuccessfulSyncAt; String? get minSupportedCursor; bool get resyncRequired;
/// Create a copy of SyncDataset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncDatasetCopyWith<SyncDataset> get copyWith => _$SyncDatasetCopyWithImpl<SyncDataset>(this as SyncDataset, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SyncDataset;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncDataset&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.policy, _this.policy) || other.policy == _this.policy)&&(identical(other.cursor, _this.cursor) || other.cursor == _this.cursor)&&(identical(other.lastSuccessfulSyncAt, _this.lastSuccessfulSyncAt) || other.lastSuccessfulSyncAt == _this.lastSuccessfulSyncAt)&&(identical(other.minSupportedCursor, _this.minSupportedCursor) || other.minSupportedCursor == _this.minSupportedCursor)&&(identical(other.resyncRequired, _this.resyncRequired) || other.resyncRequired == _this.resyncRequired));
}


@override
int get hashCode {
  final _this = this as SyncDataset;
  return Object.hash(runtimeType,_this.name,_this.policy,_this.cursor,_this.lastSuccessfulSyncAt,_this.minSupportedCursor,_this.resyncRequired);
}

@override
String toString() {
  final _this = this as SyncDataset;
  return 'SyncDataset(name: ${_this.name}, policy: ${_this.policy}, cursor: ${_this.cursor}, lastSuccessfulSyncAt: ${_this.lastSuccessfulSyncAt}, minSupportedCursor: ${_this.minSupportedCursor}, resyncRequired: ${_this.resyncRequired})';
}


}

/// @nodoc
abstract mixin class $SyncDatasetCopyWith<$Res>  {
  factory $SyncDatasetCopyWith(SyncDataset value, $Res Function(SyncDataset) _then) = _$SyncDatasetCopyWithImpl;
@useResult
$Res call({
 String name, OfflinePolicy policy, String? cursor, DateTime? lastSuccessfulSyncAt, String? minSupportedCursor, bool resyncRequired
});


$OfflinePolicyCopyWith<$Res> get policy;

}
/// @nodoc
class _$SyncDatasetCopyWithImpl<$Res>
    implements $SyncDatasetCopyWith<$Res> {
  _$SyncDatasetCopyWithImpl(this._self, this._then);

  final SyncDataset _self;
  final $Res Function(SyncDataset) _then;

/// Create a copy of SyncDataset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? policy = null,Object? cursor = freezed,Object? lastSuccessfulSyncAt = freezed,Object? minSupportedCursor = freezed,Object? resyncRequired = null,}) {
  return _then(SyncDataset(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as OfflinePolicy,cursor: freezed == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String?,lastSuccessfulSyncAt: freezed == lastSuccessfulSyncAt ? _self.lastSuccessfulSyncAt : lastSuccessfulSyncAt // ignore: cast_nullable_to_non_nullable
as DateTime?,minSupportedCursor: freezed == minSupportedCursor ? _self.minSupportedCursor : minSupportedCursor // ignore: cast_nullable_to_non_nullable
as String?,resyncRequired: null == resyncRequired ? _self.resyncRequired : resyncRequired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of SyncDataset
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OfflinePolicyCopyWith<$Res> get policy {
  
  return $OfflinePolicyCopyWith<$Res>(_self.policy, (value) {
    return _then(_self.copyWith(policy: value));
  });
}
}


/// Adds pattern-matching-related methods to [SyncDataset].
extension SyncDatasetPatterns on SyncDataset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncDataset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncDataset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncDataset value)  $default,){
final _that = this;
switch (_that) {
case _SyncDataset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncDataset value)?  $default,){
final _that = this;
switch (_that) {
case _SyncDataset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  OfflinePolicy policy,  String? cursor,  DateTime? lastSuccessfulSyncAt,  String? minSupportedCursor,  bool resyncRequired)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncDataset() when $default != null:
return $default(_that.name,_that.policy,_that.cursor,_that.lastSuccessfulSyncAt,_that.minSupportedCursor,_that.resyncRequired);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  OfflinePolicy policy,  String? cursor,  DateTime? lastSuccessfulSyncAt,  String? minSupportedCursor,  bool resyncRequired)  $default,) {final _that = this;
switch (_that) {
case _SyncDataset():
return $default(_that.name,_that.policy,_that.cursor,_that.lastSuccessfulSyncAt,_that.minSupportedCursor,_that.resyncRequired);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  OfflinePolicy policy,  String? cursor,  DateTime? lastSuccessfulSyncAt,  String? minSupportedCursor,  bool resyncRequired)?  $default,) {final _that = this;
switch (_that) {
case _SyncDataset() when $default != null:
return $default(_that.name,_that.policy,_that.cursor,_that.lastSuccessfulSyncAt,_that.minSupportedCursor,_that.resyncRequired);case _:
  return null;

}
}

}

/// @nodoc


class _SyncDataset implements SyncDataset {
  const _SyncDataset({required this.name, required this.policy, this.cursor, this.lastSuccessfulSyncAt, this.minSupportedCursor, this.resyncRequired = false});
  

@override final  String name;
@override final  OfflinePolicy policy;
@override final  String? cursor;
@override final  DateTime? lastSuccessfulSyncAt;
@override final  String? minSupportedCursor;
@override@JsonKey() final  bool resyncRequired;

/// Create a copy of SyncDataset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncDatasetCopyWith<_SyncDataset> get copyWith => __$SyncDatasetCopyWithImpl<_SyncDataset>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncDataset&&(identical(other.name, name) || other.name == name)&&(identical(other.policy, policy) || other.policy == policy)&&(identical(other.cursor, cursor) || other.cursor == cursor)&&(identical(other.lastSuccessfulSyncAt, lastSuccessfulSyncAt) || other.lastSuccessfulSyncAt == lastSuccessfulSyncAt)&&(identical(other.minSupportedCursor, minSupportedCursor) || other.minSupportedCursor == minSupportedCursor)&&(identical(other.resyncRequired, resyncRequired) || other.resyncRequired == resyncRequired));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,policy,cursor,lastSuccessfulSyncAt,minSupportedCursor,resyncRequired);
}

@override
String toString() {
    return 'SyncDataset(name: $name, policy: $policy, cursor: $cursor, lastSuccessfulSyncAt: $lastSuccessfulSyncAt, minSupportedCursor: $minSupportedCursor, resyncRequired: $resyncRequired)';
}


}

/// @nodoc
abstract mixin class _$SyncDatasetCopyWith<$Res> implements $SyncDatasetCopyWith<$Res> {
  factory _$SyncDatasetCopyWith(_SyncDataset value, $Res Function(_SyncDataset) _then) = __$SyncDatasetCopyWithImpl;
@override @useResult
$Res call({
 String name, OfflinePolicy policy, String? cursor, DateTime? lastSuccessfulSyncAt, String? minSupportedCursor, bool resyncRequired
});


@override $OfflinePolicyCopyWith<$Res> get policy;

}
/// @nodoc
class __$SyncDatasetCopyWithImpl<$Res>
    implements _$SyncDatasetCopyWith<$Res> {
  __$SyncDatasetCopyWithImpl(this._self, this._then);

  final _SyncDataset _self;
  final $Res Function(_SyncDataset) _then;

/// Create a copy of SyncDataset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? policy = null,Object? cursor = freezed,Object? lastSuccessfulSyncAt = freezed,Object? minSupportedCursor = freezed,Object? resyncRequired = null,}) {
  return _then(_SyncDataset(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as OfflinePolicy,cursor: freezed == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String?,lastSuccessfulSyncAt: freezed == lastSuccessfulSyncAt ? _self.lastSuccessfulSyncAt : lastSuccessfulSyncAt // ignore: cast_nullable_to_non_nullable
as DateTime?,minSupportedCursor: freezed == minSupportedCursor ? _self.minSupportedCursor : minSupportedCursor // ignore: cast_nullable_to_non_nullable
as String?,resyncRequired: null == resyncRequired ? _self.resyncRequired : resyncRequired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of SyncDataset
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OfflinePolicyCopyWith<$Res> get policy {
  
  return $OfflinePolicyCopyWith<$Res>(_self.policy, (value) {
    return _then(_self.copyWith(policy: value));
  });
}
}

// dart format on
