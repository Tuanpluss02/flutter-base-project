// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'data_scope.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DataScope {

 String get accountId; String? get tenantId;
/// Create a copy of DataScope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataScopeCopyWith<DataScope> get copyWith => _$DataScopeCopyWithImpl<DataScope>(this as DataScope, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DataScope;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataScope&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.tenantId, _this.tenantId) || other.tenantId == _this.tenantId));
}


@override
int get hashCode {
  final _this = this as DataScope;
  return Object.hash(runtimeType,_this.accountId,_this.tenantId);
}

@override
String toString() {
  final _this = this as DataScope;
  return 'DataScope(accountId: ${_this.accountId}, tenantId: ${_this.tenantId})';
}


}

/// @nodoc
abstract mixin class $DataScopeCopyWith<$Res>  {
  factory $DataScopeCopyWith(DataScope value, $Res Function(DataScope) _then) = _$DataScopeCopyWithImpl;
@useResult
$Res call({
 String accountId, String? tenantId
});




}
/// @nodoc
class _$DataScopeCopyWithImpl<$Res>
    implements $DataScopeCopyWith<$Res> {
  _$DataScopeCopyWithImpl(this._self, this._then);

  final DataScope _self;
  final $Res Function(DataScope) _then;

/// Create a copy of DataScope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = null,Object? tenantId = freezed,}) {
  return _then(DataScope(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,tenantId: freezed == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DataScope].
extension DataScopePatterns on DataScope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DataScope value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DataScope() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DataScope value)  $default,){
final _that = this;
switch (_that) {
case _DataScope():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DataScope value)?  $default,){
final _that = this;
switch (_that) {
case _DataScope() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accountId,  String? tenantId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DataScope() when $default != null:
return $default(_that.accountId,_that.tenantId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accountId,  String? tenantId)  $default,) {final _that = this;
switch (_that) {
case _DataScope():
return $default(_that.accountId,_that.tenantId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accountId,  String? tenantId)?  $default,) {final _that = this;
switch (_that) {
case _DataScope() when $default != null:
return $default(_that.accountId,_that.tenantId);case _:
  return null;

}
}

}

/// @nodoc


class _DataScope implements DataScope {
  const _DataScope({required this.accountId, this.tenantId});
  

@override final  String accountId;
@override final  String? tenantId;

/// Create a copy of DataScope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DataScopeCopyWith<_DataScope> get copyWith => __$DataScopeCopyWithImpl<_DataScope>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DataScope&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,accountId,tenantId);
}

@override
String toString() {
    return 'DataScope(accountId: $accountId, tenantId: $tenantId)';
}


}

/// @nodoc
abstract mixin class _$DataScopeCopyWith<$Res> implements $DataScopeCopyWith<$Res> {
  factory _$DataScopeCopyWith(_DataScope value, $Res Function(_DataScope) _then) = __$DataScopeCopyWithImpl;
@override @useResult
$Res call({
 String accountId, String? tenantId
});




}
/// @nodoc
class __$DataScopeCopyWithImpl<$Res>
    implements _$DataScopeCopyWith<$Res> {
  __$DataScopeCopyWithImpl(this._self, this._then);

  final _DataScope _self;
  final $Res Function(_DataScope) _then;

/// Create a copy of DataScope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = null,Object? tenantId = freezed,}) {
  return _then(_DataScope(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,tenantId: freezed == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
