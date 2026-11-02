// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../../src/core/offline/sync/sync_send_outcome.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SyncSendOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncSendOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SyncSendOutcome()';
}


}

/// @nodoc
class $SyncSendOutcomeCopyWith<$Res>  {
$SyncSendOutcomeCopyWith(SyncSendOutcome _, $Res Function(SyncSendOutcome) __);
}


/// Adds pattern-matching-related methods to [SyncSendOutcome].
extension SyncSendOutcomePatterns on SyncSendOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SyncSent value)?  synced,TResult Function( SyncRetryable value)?  retryable,TResult Function( SyncRequestInProgress value)?  requestInProgress,TResult Function( SyncVersionConflict value)?  versionConflict,TResult Function( SyncNeedsAttention value)?  needsAttention,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SyncSent() when synced != null:
return synced(_that);case SyncRetryable() when retryable != null:
return retryable(_that);case SyncRequestInProgress() when requestInProgress != null:
return requestInProgress(_that);case SyncVersionConflict() when versionConflict != null:
return versionConflict(_that);case SyncNeedsAttention() when needsAttention != null:
return needsAttention(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SyncSent value)  synced,required TResult Function( SyncRetryable value)  retryable,required TResult Function( SyncRequestInProgress value)  requestInProgress,required TResult Function( SyncVersionConflict value)  versionConflict,required TResult Function( SyncNeedsAttention value)  needsAttention,}){
final _that = this;
switch (_that) {
case SyncSent():
return synced(_that);case SyncRetryable():
return retryable(_that);case SyncRequestInProgress():
return requestInProgress(_that);case SyncVersionConflict():
return versionConflict(_that);case SyncNeedsAttention():
return needsAttention(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SyncSent value)?  synced,TResult? Function( SyncRetryable value)?  retryable,TResult? Function( SyncRequestInProgress value)?  requestInProgress,TResult? Function( SyncVersionConflict value)?  versionConflict,TResult? Function( SyncNeedsAttention value)?  needsAttention,}){
final _that = this;
switch (_that) {
case SyncSent() when synced != null:
return synced(_that);case SyncRetryable() when retryable != null:
return retryable(_that);case SyncRequestInProgress() when requestInProgress != null:
return requestInProgress(_that);case SyncVersionConflict() when versionConflict != null:
return versionConflict(_that);case SyncNeedsAttention() when needsAttention != null:
return needsAttention(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? serverVersion,  Map<String, Object?>? serverRecord)?  synced,TResult Function( AppFailure failure,  Duration? retryAfter)?  retryable,TResult Function( Duration? retryAfter)?  requestInProgress,TResult Function( SyncConflict conflict)?  versionConflict,TResult Function( AppFailure failure)?  needsAttention,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SyncSent() when synced != null:
return synced(_that.serverVersion,_that.serverRecord);case SyncRetryable() when retryable != null:
return retryable(_that.failure,_that.retryAfter);case SyncRequestInProgress() when requestInProgress != null:
return requestInProgress(_that.retryAfter);case SyncVersionConflict() when versionConflict != null:
return versionConflict(_that.conflict);case SyncNeedsAttention() when needsAttention != null:
return needsAttention(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? serverVersion,  Map<String, Object?>? serverRecord)  synced,required TResult Function( AppFailure failure,  Duration? retryAfter)  retryable,required TResult Function( Duration? retryAfter)  requestInProgress,required TResult Function( SyncConflict conflict)  versionConflict,required TResult Function( AppFailure failure)  needsAttention,}) {final _that = this;
switch (_that) {
case SyncSent():
return synced(_that.serverVersion,_that.serverRecord);case SyncRetryable():
return retryable(_that.failure,_that.retryAfter);case SyncRequestInProgress():
return requestInProgress(_that.retryAfter);case SyncVersionConflict():
return versionConflict(_that.conflict);case SyncNeedsAttention():
return needsAttention(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? serverVersion,  Map<String, Object?>? serverRecord)?  synced,TResult? Function( AppFailure failure,  Duration? retryAfter)?  retryable,TResult? Function( Duration? retryAfter)?  requestInProgress,TResult? Function( SyncConflict conflict)?  versionConflict,TResult? Function( AppFailure failure)?  needsAttention,}) {final _that = this;
switch (_that) {
case SyncSent() when synced != null:
return synced(_that.serverVersion,_that.serverRecord);case SyncRetryable() when retryable != null:
return retryable(_that.failure,_that.retryAfter);case SyncRequestInProgress() when requestInProgress != null:
return requestInProgress(_that.retryAfter);case SyncVersionConflict() when versionConflict != null:
return versionConflict(_that.conflict);case SyncNeedsAttention() when needsAttention != null:
return needsAttention(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SyncSent implements SyncSendOutcome {
  const SyncSent({this.serverVersion,  Map<String, Object?>? serverRecord}): _serverRecord = serverRecord;
  

 final  String? serverVersion;
 final  Map<String, Object?>? _serverRecord;
 Map<String, Object?>? get serverRecord {
  final value = _serverRecord;
  if (value == null) return null;
  if (_serverRecord is EqualUnmodifiableMapView) return _serverRecord;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of SyncSendOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncSentCopyWith<SyncSent> get copyWith => _$SyncSentCopyWithImpl<SyncSent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncSent&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&const DeepCollectionEquality().equals(other.serverRecord, _serverRecord));
}


@override
int get hashCode {
    return Object.hash(runtimeType,serverVersion,const DeepCollectionEquality().hash(_serverRecord));
}

@override
String toString() {
    return 'SyncSendOutcome.synced(serverVersion: $serverVersion, serverRecord: $serverRecord)';
}


}

/// @nodoc
abstract mixin class $SyncSentCopyWith<$Res> implements $SyncSendOutcomeCopyWith<$Res> {
  factory $SyncSentCopyWith(SyncSent value, $Res Function(SyncSent) _then) = _$SyncSentCopyWithImpl;
@useResult
$Res call({
 String? serverVersion, Map<String, Object?>? serverRecord
});




}
/// @nodoc
class _$SyncSentCopyWithImpl<$Res>
    implements $SyncSentCopyWith<$Res> {
  _$SyncSentCopyWithImpl(this._self, this._then);

  final SyncSent _self;
  final $Res Function(SyncSent) _then;

/// Create a copy of SyncSendOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? serverVersion = freezed,Object? serverRecord = freezed,}) {
  return _then(SyncSent(
serverVersion: freezed == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String?,serverRecord: freezed == serverRecord ? _self._serverRecord : serverRecord // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}


}

/// @nodoc


class SyncRetryable implements SyncSendOutcome {
  const SyncRetryable(this.failure, this.retryAfter);
  

 final  AppFailure failure;
 final  Duration? retryAfter;

/// Create a copy of SyncSendOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncRetryableCopyWith<SyncRetryable> get copyWith => _$SyncRetryableCopyWithImpl<SyncRetryable>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncRetryable&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.retryAfter, retryAfter) || other.retryAfter == retryAfter));
}


@override
int get hashCode {
    return Object.hash(runtimeType,failure,retryAfter);
}

@override
String toString() {
    return 'SyncSendOutcome.retryable(failure: $failure, retryAfter: $retryAfter)';
}


}

/// @nodoc
abstract mixin class $SyncRetryableCopyWith<$Res> implements $SyncSendOutcomeCopyWith<$Res> {
  factory $SyncRetryableCopyWith(SyncRetryable value, $Res Function(SyncRetryable) _then) = _$SyncRetryableCopyWithImpl;
@useResult
$Res call({
 AppFailure failure, Duration? retryAfter
});


$AppFailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SyncRetryableCopyWithImpl<$Res>
    implements $SyncRetryableCopyWith<$Res> {
  _$SyncRetryableCopyWithImpl(this._self, this._then);

  final SyncRetryable _self;
  final $Res Function(SyncRetryable) _then;

/// Create a copy of SyncSendOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? retryAfter = freezed,}) {
  return _then(SyncRetryable(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure,freezed == retryAfter ? _self.retryAfter : retryAfter // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}

/// Create a copy of SyncSendOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res> get failure {
  
  return $AppFailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc


class SyncRequestInProgress implements SyncSendOutcome {
  const SyncRequestInProgress([this.retryAfter]);
  

 final  Duration? retryAfter;

/// Create a copy of SyncSendOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncRequestInProgressCopyWith<SyncRequestInProgress> get copyWith => _$SyncRequestInProgressCopyWithImpl<SyncRequestInProgress>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncRequestInProgress&&(identical(other.retryAfter, retryAfter) || other.retryAfter == retryAfter));
}


@override
int get hashCode {
    return Object.hash(runtimeType,retryAfter);
}

@override
String toString() {
    return 'SyncSendOutcome.requestInProgress(retryAfter: $retryAfter)';
}


}

/// @nodoc
abstract mixin class $SyncRequestInProgressCopyWith<$Res> implements $SyncSendOutcomeCopyWith<$Res> {
  factory $SyncRequestInProgressCopyWith(SyncRequestInProgress value, $Res Function(SyncRequestInProgress) _then) = _$SyncRequestInProgressCopyWithImpl;
@useResult
$Res call({
 Duration? retryAfter
});




}
/// @nodoc
class _$SyncRequestInProgressCopyWithImpl<$Res>
    implements $SyncRequestInProgressCopyWith<$Res> {
  _$SyncRequestInProgressCopyWithImpl(this._self, this._then);

  final SyncRequestInProgress _self;
  final $Res Function(SyncRequestInProgress) _then;

/// Create a copy of SyncSendOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? retryAfter = freezed,}) {
  return _then(SyncRequestInProgress(
freezed == retryAfter ? _self.retryAfter : retryAfter // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

/// @nodoc


class SyncVersionConflict implements SyncSendOutcome {
  const SyncVersionConflict(this.conflict);
  

 final  SyncConflict conflict;

/// Create a copy of SyncSendOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncVersionConflictCopyWith<SyncVersionConflict> get copyWith => _$SyncVersionConflictCopyWithImpl<SyncVersionConflict>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncVersionConflict&&(identical(other.conflict, conflict) || other.conflict == conflict));
}


@override
int get hashCode {
    return Object.hash(runtimeType,conflict);
}

@override
String toString() {
    return 'SyncSendOutcome.versionConflict(conflict: $conflict)';
}


}

/// @nodoc
abstract mixin class $SyncVersionConflictCopyWith<$Res> implements $SyncSendOutcomeCopyWith<$Res> {
  factory $SyncVersionConflictCopyWith(SyncVersionConflict value, $Res Function(SyncVersionConflict) _then) = _$SyncVersionConflictCopyWithImpl;
@useResult
$Res call({
 SyncConflict conflict
});




}
/// @nodoc
class _$SyncVersionConflictCopyWithImpl<$Res>
    implements $SyncVersionConflictCopyWith<$Res> {
  _$SyncVersionConflictCopyWithImpl(this._self, this._then);

  final SyncVersionConflict _self;
  final $Res Function(SyncVersionConflict) _then;

/// Create a copy of SyncSendOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? conflict = null,}) {
  return _then(SyncVersionConflict(
null == conflict ? _self.conflict : conflict // ignore: cast_nullable_to_non_nullable
as SyncConflict,
  ));
}


}

/// @nodoc


class SyncNeedsAttention implements SyncSendOutcome {
  const SyncNeedsAttention(this.failure);
  

 final  AppFailure failure;

/// Create a copy of SyncSendOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncNeedsAttentionCopyWith<SyncNeedsAttention> get copyWith => _$SyncNeedsAttentionCopyWithImpl<SyncNeedsAttention>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncNeedsAttention&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,failure);
}

@override
String toString() {
    return 'SyncSendOutcome.needsAttention(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SyncNeedsAttentionCopyWith<$Res> implements $SyncSendOutcomeCopyWith<$Res> {
  factory $SyncNeedsAttentionCopyWith(SyncNeedsAttention value, $Res Function(SyncNeedsAttention) _then) = _$SyncNeedsAttentionCopyWithImpl;
@useResult
$Res call({
 AppFailure failure
});


$AppFailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SyncNeedsAttentionCopyWithImpl<$Res>
    implements $SyncNeedsAttentionCopyWith<$Res> {
  _$SyncNeedsAttentionCopyWithImpl(this._self, this._then);

  final SyncNeedsAttention _self;
  final $Res Function(SyncNeedsAttention) _then;

/// Create a copy of SyncSendOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SyncNeedsAttention(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure,
  ));
}

/// Create a copy of SyncSendOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res> get failure {
  
  return $AppFailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
