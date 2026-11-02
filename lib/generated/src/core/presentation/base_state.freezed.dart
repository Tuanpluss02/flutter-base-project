// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../src/core/presentation/base_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BaseState<T> {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BaseState<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BaseState<$T>()';
}


}

/// @nodoc
class $BaseStateCopyWith<T,$Res>  {
$BaseStateCopyWith(BaseState<T> _, $Res Function(BaseState<T>) __);
}


/// Adds pattern-matching-related methods to [BaseState].
extension BaseStatePatterns<T> on BaseState<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Initial<T> value)?  initial,TResult Function( Loading<T> value)?  loading,TResult Function( Data<T> value)?  data,TResult Function( ErrorState<T> value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Initial() when initial != null:
return initial(_that);case Loading() when loading != null:
return loading(_that);case Data() when data != null:
return data(_that);case ErrorState() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Initial<T> value)  initial,required TResult Function( Loading<T> value)  loading,required TResult Function( Data<T> value)  data,required TResult Function( ErrorState<T> value)  error,}){
final _that = this;
switch (_that) {
case Initial():
return initial(_that);case Loading():
return loading(_that);case Data():
return data(_that);case ErrorState():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Initial<T> value)?  initial,TResult? Function( Loading<T> value)?  loading,TResult? Function( Data<T> value)?  data,TResult? Function( ErrorState<T> value)?  error,}){
final _that = this;
switch (_that) {
case Initial() when initial != null:
return initial(_that);case Loading() when loading != null:
return loading(_that);case Data() when data != null:
return data(_that);case ErrorState() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( T data)?  data,TResult Function( AppFailure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Initial() when initial != null:
return initial();case Loading() when loading != null:
return loading();case Data() when data != null:
return data(_that.data);case ErrorState() when error != null:
return error(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( T data)  data,required TResult Function( AppFailure failure)  error,}) {final _that = this;
switch (_that) {
case Initial():
return initial();case Loading():
return loading();case Data():
return data(_that.data);case ErrorState():
return error(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( T data)?  data,TResult? Function( AppFailure failure)?  error,}) {final _that = this;
switch (_that) {
case Initial() when initial != null:
return initial();case Loading() when loading != null:
return loading();case Data() when data != null:
return data(_that.data);case ErrorState() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class Initial<T> implements BaseState<T> {
  const Initial();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is Initial<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BaseState<$T>.initial()';
}


}




/// @nodoc


class Loading<T> implements BaseState<T> {
  const Loading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is Loading<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BaseState<$T>.loading()';
}


}




/// @nodoc


class Data<T> implements BaseState<T> {
  const Data(this.data);
  

 final  T data;

/// Create a copy of BaseState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataCopyWith<T, Data<T>> get copyWith => _$DataCopyWithImpl<T, Data<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is Data<T>&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(data));
}

@override
String toString() {
    return 'BaseState<$T>.data(data: $data)';
}


}

/// @nodoc
abstract mixin class $DataCopyWith<T,$Res> implements $BaseStateCopyWith<T, $Res> {
  factory $DataCopyWith(Data<T> value, $Res Function(Data<T>) _then) = _$DataCopyWithImpl;
@useResult
$Res call({
 T data
});




}
/// @nodoc
class _$DataCopyWithImpl<T,$Res>
    implements $DataCopyWith<T, $Res> {
  _$DataCopyWithImpl(this._self, this._then);

  final Data<T> _self;
  final $Res Function(Data<T>) _then;

/// Create a copy of BaseState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = freezed,}) {
  return _then(Data<T>(
freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

/// @nodoc


class ErrorState<T> implements BaseState<T> {
  const ErrorState(this.failure);
  

 final  AppFailure failure;

/// Create a copy of BaseState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorStateCopyWith<T, ErrorState<T>> get copyWith => _$ErrorStateCopyWithImpl<T, ErrorState<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorState<T>&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,failure);
}

@override
String toString() {
    return 'BaseState<$T>.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ErrorStateCopyWith<T,$Res> implements $BaseStateCopyWith<T, $Res> {
  factory $ErrorStateCopyWith(ErrorState<T> value, $Res Function(ErrorState<T>) _then) = _$ErrorStateCopyWithImpl;
@useResult
$Res call({
 AppFailure failure
});


$AppFailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ErrorStateCopyWithImpl<T,$Res>
    implements $ErrorStateCopyWith<T, $Res> {
  _$ErrorStateCopyWithImpl(this._self, this._then);

  final ErrorState<T> _self;
  final $Res Function(ErrorState<T>) _then;

/// Create a copy of BaseState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ErrorState<T>(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure,
  ));
}

/// Create a copy of BaseState
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
