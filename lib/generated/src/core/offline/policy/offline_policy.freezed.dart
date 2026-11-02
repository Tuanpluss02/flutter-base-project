// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../../src/core/offline/policy/offline_policy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OfflinePolicy {

 String get dataset; DataClassification get classification; Duration get ttl; Set<OfflineOperation> get allowedOperations; ConflictPolicy get conflictPolicy;
/// Create a copy of OfflinePolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfflinePolicyCopyWith<OfflinePolicy> get copyWith => _$OfflinePolicyCopyWithImpl<OfflinePolicy>(this as OfflinePolicy, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OfflinePolicy;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OfflinePolicy&&(identical(other.dataset, _this.dataset) || other.dataset == _this.dataset)&&(identical(other.classification, _this.classification) || other.classification == _this.classification)&&(identical(other.ttl, _this.ttl) || other.ttl == _this.ttl)&&const DeepCollectionEquality().equals(other.allowedOperations, _this.allowedOperations)&&(identical(other.conflictPolicy, _this.conflictPolicy) || other.conflictPolicy == _this.conflictPolicy));
}


@override
int get hashCode {
  final _this = this as OfflinePolicy;
  return Object.hash(runtimeType,_this.dataset,_this.classification,_this.ttl,const DeepCollectionEquality().hash(_this.allowedOperations),_this.conflictPolicy);
}

@override
String toString() {
  final _this = this as OfflinePolicy;
  return 'OfflinePolicy(dataset: ${_this.dataset}, classification: ${_this.classification}, ttl: ${_this.ttl}, allowedOperations: ${_this.allowedOperations}, conflictPolicy: ${_this.conflictPolicy})';
}


}

/// @nodoc
abstract mixin class $OfflinePolicyCopyWith<$Res>  {
  factory $OfflinePolicyCopyWith(OfflinePolicy value, $Res Function(OfflinePolicy) _then) = _$OfflinePolicyCopyWithImpl;
@useResult
$Res call({
 String dataset, DataClassification classification, Duration ttl, Set<OfflineOperation> allowedOperations, ConflictPolicy conflictPolicy
});




}
/// @nodoc
class _$OfflinePolicyCopyWithImpl<$Res>
    implements $OfflinePolicyCopyWith<$Res> {
  _$OfflinePolicyCopyWithImpl(this._self, this._then);

  final OfflinePolicy _self;
  final $Res Function(OfflinePolicy) _then;

/// Create a copy of OfflinePolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dataset = null,Object? classification = null,Object? ttl = null,Object? allowedOperations = null,Object? conflictPolicy = null,}) {
  return _then(OfflinePolicy(
dataset: null == dataset ? _self.dataset : dataset // ignore: cast_nullable_to_non_nullable
as String,classification: null == classification ? _self.classification : classification // ignore: cast_nullable_to_non_nullable
as DataClassification,ttl: null == ttl ? _self.ttl : ttl // ignore: cast_nullable_to_non_nullable
as Duration,allowedOperations: null == allowedOperations ? _self.allowedOperations : allowedOperations // ignore: cast_nullable_to_non_nullable
as Set<OfflineOperation>,conflictPolicy: null == conflictPolicy ? _self.conflictPolicy : conflictPolicy // ignore: cast_nullable_to_non_nullable
as ConflictPolicy,
  ));
}

}


/// Adds pattern-matching-related methods to [OfflinePolicy].
extension OfflinePolicyPatterns on OfflinePolicy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OfflinePolicy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OfflinePolicy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OfflinePolicy value)  $default,){
final _that = this;
switch (_that) {
case _OfflinePolicy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OfflinePolicy value)?  $default,){
final _that = this;
switch (_that) {
case _OfflinePolicy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String dataset,  DataClassification classification,  Duration ttl,  Set<OfflineOperation> allowedOperations,  ConflictPolicy conflictPolicy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OfflinePolicy() when $default != null:
return $default(_that.dataset,_that.classification,_that.ttl,_that.allowedOperations,_that.conflictPolicy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String dataset,  DataClassification classification,  Duration ttl,  Set<OfflineOperation> allowedOperations,  ConflictPolicy conflictPolicy)  $default,) {final _that = this;
switch (_that) {
case _OfflinePolicy():
return $default(_that.dataset,_that.classification,_that.ttl,_that.allowedOperations,_that.conflictPolicy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String dataset,  DataClassification classification,  Duration ttl,  Set<OfflineOperation> allowedOperations,  ConflictPolicy conflictPolicy)?  $default,) {final _that = this;
switch (_that) {
case _OfflinePolicy() when $default != null:
return $default(_that.dataset,_that.classification,_that.ttl,_that.allowedOperations,_that.conflictPolicy);case _:
  return null;

}
}

}

/// @nodoc


class _OfflinePolicy implements OfflinePolicy {
  const _OfflinePolicy({required this.dataset, required this.classification, required this.ttl, required  Set<OfflineOperation> allowedOperations, required this.conflictPolicy}): _allowedOperations = allowedOperations;
  

@override final  String dataset;
@override final  DataClassification classification;
@override final  Duration ttl;
 final  Set<OfflineOperation> _allowedOperations;
@override Set<OfflineOperation> get allowedOperations {
  if (_allowedOperations is EqualUnmodifiableSetView) return _allowedOperations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_allowedOperations);
}

@override final  ConflictPolicy conflictPolicy;

/// Create a copy of OfflinePolicy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OfflinePolicyCopyWith<_OfflinePolicy> get copyWith => __$OfflinePolicyCopyWithImpl<_OfflinePolicy>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OfflinePolicy&&(identical(other.dataset, dataset) || other.dataset == dataset)&&(identical(other.classification, classification) || other.classification == classification)&&(identical(other.ttl, ttl) || other.ttl == ttl)&&const DeepCollectionEquality().equals(other.allowedOperations, _allowedOperations)&&(identical(other.conflictPolicy, conflictPolicy) || other.conflictPolicy == conflictPolicy));
}


@override
int get hashCode {
    return Object.hash(runtimeType,dataset,classification,ttl,const DeepCollectionEquality().hash(_allowedOperations),conflictPolicy);
}

@override
String toString() {
    return 'OfflinePolicy(dataset: $dataset, classification: $classification, ttl: $ttl, allowedOperations: $allowedOperations, conflictPolicy: $conflictPolicy)';
}


}

/// @nodoc
abstract mixin class _$OfflinePolicyCopyWith<$Res> implements $OfflinePolicyCopyWith<$Res> {
  factory _$OfflinePolicyCopyWith(_OfflinePolicy value, $Res Function(_OfflinePolicy) _then) = __$OfflinePolicyCopyWithImpl;
@override @useResult
$Res call({
 String dataset, DataClassification classification, Duration ttl, Set<OfflineOperation> allowedOperations, ConflictPolicy conflictPolicy
});




}
/// @nodoc
class __$OfflinePolicyCopyWithImpl<$Res>
    implements _$OfflinePolicyCopyWith<$Res> {
  __$OfflinePolicyCopyWithImpl(this._self, this._then);

  final _OfflinePolicy _self;
  final $Res Function(_OfflinePolicy) _then;

/// Create a copy of OfflinePolicy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dataset = null,Object? classification = null,Object? ttl = null,Object? allowedOperations = null,Object? conflictPolicy = null,}) {
  return _then(_OfflinePolicy(
dataset: null == dataset ? _self.dataset : dataset // ignore: cast_nullable_to_non_nullable
as String,classification: null == classification ? _self.classification : classification // ignore: cast_nullable_to_non_nullable
as DataClassification,ttl: null == ttl ? _self.ttl : ttl // ignore: cast_nullable_to_non_nullable
as Duration,allowedOperations: null == allowedOperations ? _self._allowedOperations : allowedOperations // ignore: cast_nullable_to_non_nullable
as Set<OfflineOperation>,conflictPolicy: null == conflictPolicy ? _self.conflictPolicy : conflictPolicy // ignore: cast_nullable_to_non_nullable
as ConflictPolicy,
  ));
}


}

// dart format on
