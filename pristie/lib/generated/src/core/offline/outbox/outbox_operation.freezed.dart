// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../../src/core/offline/outbox/outbox_operation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OutboxOperation {

 String get id; DataScope get dataScope; int get dataScopeEpoch; String get entityKey; OfflineOperation get operation; int get payloadVersion; String get payloadJson; String? get baseVersion; int get sequence; OutboxState get state; int get attemptCount; DateTime? get nextAttemptAt; String? get leaseOwner; DateTime? get leaseExpiresAt; String get idempotencyKey; DateTime get createdAt;
/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutboxOperationCopyWith<OutboxOperation> get copyWith => _$OutboxOperationCopyWithImpl<OutboxOperation>(this as OutboxOperation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OutboxOperation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutboxOperation&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.dataScope, _this.dataScope) || other.dataScope == _this.dataScope)&&(identical(other.dataScopeEpoch, _this.dataScopeEpoch) || other.dataScopeEpoch == _this.dataScopeEpoch)&&(identical(other.entityKey, _this.entityKey) || other.entityKey == _this.entityKey)&&(identical(other.operation, _this.operation) || other.operation == _this.operation)&&(identical(other.payloadVersion, _this.payloadVersion) || other.payloadVersion == _this.payloadVersion)&&(identical(other.payloadJson, _this.payloadJson) || other.payloadJson == _this.payloadJson)&&(identical(other.baseVersion, _this.baseVersion) || other.baseVersion == _this.baseVersion)&&(identical(other.sequence, _this.sequence) || other.sequence == _this.sequence)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.attemptCount, _this.attemptCount) || other.attemptCount == _this.attemptCount)&&(identical(other.nextAttemptAt, _this.nextAttemptAt) || other.nextAttemptAt == _this.nextAttemptAt)&&(identical(other.leaseOwner, _this.leaseOwner) || other.leaseOwner == _this.leaseOwner)&&(identical(other.leaseExpiresAt, _this.leaseExpiresAt) || other.leaseExpiresAt == _this.leaseExpiresAt)&&(identical(other.idempotencyKey, _this.idempotencyKey) || other.idempotencyKey == _this.idempotencyKey)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as OutboxOperation;
  return Object.hash(runtimeType,_this.id,_this.dataScope,_this.dataScopeEpoch,_this.entityKey,_this.operation,_this.payloadVersion,_this.payloadJson,_this.baseVersion,_this.sequence,_this.state,_this.attemptCount,_this.nextAttemptAt,_this.leaseOwner,_this.leaseExpiresAt,_this.idempotencyKey,_this.createdAt);
}

@override
String toString() {
  final _this = this as OutboxOperation;
  return 'OutboxOperation(id: ${_this.id}, dataScope: ${_this.dataScope}, dataScopeEpoch: ${_this.dataScopeEpoch}, entityKey: ${_this.entityKey}, operation: ${_this.operation}, payloadVersion: ${_this.payloadVersion}, payloadJson: ${_this.payloadJson}, baseVersion: ${_this.baseVersion}, sequence: ${_this.sequence}, state: ${_this.state}, attemptCount: ${_this.attemptCount}, nextAttemptAt: ${_this.nextAttemptAt}, leaseOwner: ${_this.leaseOwner}, leaseExpiresAt: ${_this.leaseExpiresAt}, idempotencyKey: ${_this.idempotencyKey}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $OutboxOperationCopyWith<$Res>  {
  factory $OutboxOperationCopyWith(OutboxOperation value, $Res Function(OutboxOperation) _then) = _$OutboxOperationCopyWithImpl;
@useResult
$Res call({
 String id, DataScope dataScope, int dataScopeEpoch, String entityKey, OfflineOperation operation, int payloadVersion, String payloadJson, String? baseVersion, int sequence, OutboxState state, int attemptCount, DateTime? nextAttemptAt, String? leaseOwner, DateTime? leaseExpiresAt, String idempotencyKey, DateTime createdAt
});


$DataScopeCopyWith<$Res> get dataScope;

}
/// @nodoc
class _$OutboxOperationCopyWithImpl<$Res>
    implements $OutboxOperationCopyWith<$Res> {
  _$OutboxOperationCopyWithImpl(this._self, this._then);

  final OutboxOperation _self;
  final $Res Function(OutboxOperation) _then;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? dataScope = null,Object? dataScopeEpoch = null,Object? entityKey = null,Object? operation = null,Object? payloadVersion = null,Object? payloadJson = null,Object? baseVersion = freezed,Object? sequence = null,Object? state = null,Object? attemptCount = null,Object? nextAttemptAt = freezed,Object? leaseOwner = freezed,Object? leaseExpiresAt = freezed,Object? idempotencyKey = null,Object? createdAt = null,}) {
  return _then(OutboxOperation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,dataScope: null == dataScope ? _self.dataScope : dataScope // ignore: cast_nullable_to_non_nullable
as DataScope,dataScopeEpoch: null == dataScopeEpoch ? _self.dataScopeEpoch : dataScopeEpoch // ignore: cast_nullable_to_non_nullable
as int,entityKey: null == entityKey ? _self.entityKey : entityKey // ignore: cast_nullable_to_non_nullable
as String,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as OfflineOperation,payloadVersion: null == payloadVersion ? _self.payloadVersion : payloadVersion // ignore: cast_nullable_to_non_nullable
as int,payloadJson: null == payloadJson ? _self.payloadJson : payloadJson // ignore: cast_nullable_to_non_nullable
as String,baseVersion: freezed == baseVersion ? _self.baseVersion : baseVersion // ignore: cast_nullable_to_non_nullable
as String?,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as OutboxState,attemptCount: null == attemptCount ? _self.attemptCount : attemptCount // ignore: cast_nullable_to_non_nullable
as int,nextAttemptAt: freezed == nextAttemptAt ? _self.nextAttemptAt : nextAttemptAt // ignore: cast_nullable_to_non_nullable
as DateTime?,leaseOwner: freezed == leaseOwner ? _self.leaseOwner : leaseOwner // ignore: cast_nullable_to_non_nullable
as String?,leaseExpiresAt: freezed == leaseExpiresAt ? _self.leaseExpiresAt : leaseExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataScopeCopyWith<$Res> get dataScope {
  
  return $DataScopeCopyWith<$Res>(_self.dataScope, (value) {
    return _then(_self.copyWith(dataScope: value));
  });
}
}


/// Adds pattern-matching-related methods to [OutboxOperation].
extension OutboxOperationPatterns on OutboxOperation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutboxOperation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutboxOperation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutboxOperation value)  $default,){
final _that = this;
switch (_that) {
case _OutboxOperation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutboxOperation value)?  $default,){
final _that = this;
switch (_that) {
case _OutboxOperation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DataScope dataScope,  int dataScopeEpoch,  String entityKey,  OfflineOperation operation,  int payloadVersion,  String payloadJson,  String? baseVersion,  int sequence,  OutboxState state,  int attemptCount,  DateTime? nextAttemptAt,  String? leaseOwner,  DateTime? leaseExpiresAt,  String idempotencyKey,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutboxOperation() when $default != null:
return $default(_that.id,_that.dataScope,_that.dataScopeEpoch,_that.entityKey,_that.operation,_that.payloadVersion,_that.payloadJson,_that.baseVersion,_that.sequence,_that.state,_that.attemptCount,_that.nextAttemptAt,_that.leaseOwner,_that.leaseExpiresAt,_that.idempotencyKey,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DataScope dataScope,  int dataScopeEpoch,  String entityKey,  OfflineOperation operation,  int payloadVersion,  String payloadJson,  String? baseVersion,  int sequence,  OutboxState state,  int attemptCount,  DateTime? nextAttemptAt,  String? leaseOwner,  DateTime? leaseExpiresAt,  String idempotencyKey,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _OutboxOperation():
return $default(_that.id,_that.dataScope,_that.dataScopeEpoch,_that.entityKey,_that.operation,_that.payloadVersion,_that.payloadJson,_that.baseVersion,_that.sequence,_that.state,_that.attemptCount,_that.nextAttemptAt,_that.leaseOwner,_that.leaseExpiresAt,_that.idempotencyKey,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DataScope dataScope,  int dataScopeEpoch,  String entityKey,  OfflineOperation operation,  int payloadVersion,  String payloadJson,  String? baseVersion,  int sequence,  OutboxState state,  int attemptCount,  DateTime? nextAttemptAt,  String? leaseOwner,  DateTime? leaseExpiresAt,  String idempotencyKey,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _OutboxOperation() when $default != null:
return $default(_that.id,_that.dataScope,_that.dataScopeEpoch,_that.entityKey,_that.operation,_that.payloadVersion,_that.payloadJson,_that.baseVersion,_that.sequence,_that.state,_that.attemptCount,_that.nextAttemptAt,_that.leaseOwner,_that.leaseExpiresAt,_that.idempotencyKey,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _OutboxOperation implements OutboxOperation {
  const _OutboxOperation({required this.id, required this.dataScope, required this.dataScopeEpoch, required this.entityKey, required this.operation, required this.payloadVersion, required this.payloadJson, this.baseVersion, required this.sequence, required this.state, this.attemptCount = 0, this.nextAttemptAt, this.leaseOwner, this.leaseExpiresAt, required this.idempotencyKey, required this.createdAt});
  

@override final  String id;
@override final  DataScope dataScope;
@override final  int dataScopeEpoch;
@override final  String entityKey;
@override final  OfflineOperation operation;
@override final  int payloadVersion;
@override final  String payloadJson;
@override final  String? baseVersion;
@override final  int sequence;
@override final  OutboxState state;
@override@JsonKey() final  int attemptCount;
@override final  DateTime? nextAttemptAt;
@override final  String? leaseOwner;
@override final  DateTime? leaseExpiresAt;
@override final  String idempotencyKey;
@override final  DateTime createdAt;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutboxOperationCopyWith<_OutboxOperation> get copyWith => __$OutboxOperationCopyWithImpl<_OutboxOperation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutboxOperation&&(identical(other.id, id) || other.id == id)&&(identical(other.dataScope, dataScope) || other.dataScope == dataScope)&&(identical(other.dataScopeEpoch, dataScopeEpoch) || other.dataScopeEpoch == dataScopeEpoch)&&(identical(other.entityKey, entityKey) || other.entityKey == entityKey)&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.payloadVersion, payloadVersion) || other.payloadVersion == payloadVersion)&&(identical(other.payloadJson, payloadJson) || other.payloadJson == payloadJson)&&(identical(other.baseVersion, baseVersion) || other.baseVersion == baseVersion)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.state, state) || other.state == state)&&(identical(other.attemptCount, attemptCount) || other.attemptCount == attemptCount)&&(identical(other.nextAttemptAt, nextAttemptAt) || other.nextAttemptAt == nextAttemptAt)&&(identical(other.leaseOwner, leaseOwner) || other.leaseOwner == leaseOwner)&&(identical(other.leaseExpiresAt, leaseExpiresAt) || other.leaseExpiresAt == leaseExpiresAt)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,dataScope,dataScopeEpoch,entityKey,operation,payloadVersion,payloadJson,baseVersion,sequence,state,attemptCount,nextAttemptAt,leaseOwner,leaseExpiresAt,idempotencyKey,createdAt);
}

@override
String toString() {
    return 'OutboxOperation(id: $id, dataScope: $dataScope, dataScopeEpoch: $dataScopeEpoch, entityKey: $entityKey, operation: $operation, payloadVersion: $payloadVersion, payloadJson: $payloadJson, baseVersion: $baseVersion, sequence: $sequence, state: $state, attemptCount: $attemptCount, nextAttemptAt: $nextAttemptAt, leaseOwner: $leaseOwner, leaseExpiresAt: $leaseExpiresAt, idempotencyKey: $idempotencyKey, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$OutboxOperationCopyWith<$Res> implements $OutboxOperationCopyWith<$Res> {
  factory _$OutboxOperationCopyWith(_OutboxOperation value, $Res Function(_OutboxOperation) _then) = __$OutboxOperationCopyWithImpl;
@override @useResult
$Res call({
 String id, DataScope dataScope, int dataScopeEpoch, String entityKey, OfflineOperation operation, int payloadVersion, String payloadJson, String? baseVersion, int sequence, OutboxState state, int attemptCount, DateTime? nextAttemptAt, String? leaseOwner, DateTime? leaseExpiresAt, String idempotencyKey, DateTime createdAt
});


@override $DataScopeCopyWith<$Res> get dataScope;

}
/// @nodoc
class __$OutboxOperationCopyWithImpl<$Res>
    implements _$OutboxOperationCopyWith<$Res> {
  __$OutboxOperationCopyWithImpl(this._self, this._then);

  final _OutboxOperation _self;
  final $Res Function(_OutboxOperation) _then;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? dataScope = null,Object? dataScopeEpoch = null,Object? entityKey = null,Object? operation = null,Object? payloadVersion = null,Object? payloadJson = null,Object? baseVersion = freezed,Object? sequence = null,Object? state = null,Object? attemptCount = null,Object? nextAttemptAt = freezed,Object? leaseOwner = freezed,Object? leaseExpiresAt = freezed,Object? idempotencyKey = null,Object? createdAt = null,}) {
  return _then(_OutboxOperation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,dataScope: null == dataScope ? _self.dataScope : dataScope // ignore: cast_nullable_to_non_nullable
as DataScope,dataScopeEpoch: null == dataScopeEpoch ? _self.dataScopeEpoch : dataScopeEpoch // ignore: cast_nullable_to_non_nullable
as int,entityKey: null == entityKey ? _self.entityKey : entityKey // ignore: cast_nullable_to_non_nullable
as String,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as OfflineOperation,payloadVersion: null == payloadVersion ? _self.payloadVersion : payloadVersion // ignore: cast_nullable_to_non_nullable
as int,payloadJson: null == payloadJson ? _self.payloadJson : payloadJson // ignore: cast_nullable_to_non_nullable
as String,baseVersion: freezed == baseVersion ? _self.baseVersion : baseVersion // ignore: cast_nullable_to_non_nullable
as String?,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as OutboxState,attemptCount: null == attemptCount ? _self.attemptCount : attemptCount // ignore: cast_nullable_to_non_nullable
as int,nextAttemptAt: freezed == nextAttemptAt ? _self.nextAttemptAt : nextAttemptAt // ignore: cast_nullable_to_non_nullable
as DateTime?,leaseOwner: freezed == leaseOwner ? _self.leaseOwner : leaseOwner // ignore: cast_nullable_to_non_nullable
as String?,leaseExpiresAt: freezed == leaseExpiresAt ? _self.leaseExpiresAt : leaseExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataScopeCopyWith<$Res> get dataScope {
  
  return $DataScopeCopyWith<$Res>(_self.dataScope, (value) {
    return _then(_self.copyWith(dataScope: value));
  });
}
}

// dart format on
