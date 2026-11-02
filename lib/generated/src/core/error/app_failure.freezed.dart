// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../src/core/error/app_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppFailure {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AppFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure()';
}


}

/// @nodoc
class $AppFailureCopyWith<$Res>  {
$AppFailureCopyWith(AppFailure _, $Res Function(AppFailure) __);
}


/// Adds pattern-matching-related methods to [AppFailure].
extension AppFailurePatterns on AppFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NetworkFailure value)?  network,TResult Function( TimeoutFailure value)?  timeout,TResult Function( CancelledFailure value)?  cancelled,TResult Function( UnauthorizedFailure value)?  unauthorized,TResult Function( ForbiddenFailure value)?  forbidden,TResult Function( NotFoundFailure value)?  notFound,TResult Function( ConflictFailure value)?  conflict,TResult Function( ValidationFailure value)?  validation,TResult Function( RateLimitFailure value)?  rateLimit,TResult Function( ServerFailure value)?  server,TResult Function( PayloadTooLargeFailure value)?  payloadTooLarge,TResult Function( ParseFailure value)?  parse,TResult Function( LocalPersistenceFailure value)?  localPersistence,TResult Function( UnknownFailure value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network(_that);case TimeoutFailure() when timeout != null:
return timeout(_that);case CancelledFailure() when cancelled != null:
return cancelled(_that);case UnauthorizedFailure() when unauthorized != null:
return unauthorized(_that);case ForbiddenFailure() when forbidden != null:
return forbidden(_that);case NotFoundFailure() when notFound != null:
return notFound(_that);case ConflictFailure() when conflict != null:
return conflict(_that);case ValidationFailure() when validation != null:
return validation(_that);case RateLimitFailure() when rateLimit != null:
return rateLimit(_that);case ServerFailure() when server != null:
return server(_that);case PayloadTooLargeFailure() when payloadTooLarge != null:
return payloadTooLarge(_that);case ParseFailure() when parse != null:
return parse(_that);case LocalPersistenceFailure() when localPersistence != null:
return localPersistence(_that);case UnknownFailure() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NetworkFailure value)  network,required TResult Function( TimeoutFailure value)  timeout,required TResult Function( CancelledFailure value)  cancelled,required TResult Function( UnauthorizedFailure value)  unauthorized,required TResult Function( ForbiddenFailure value)  forbidden,required TResult Function( NotFoundFailure value)  notFound,required TResult Function( ConflictFailure value)  conflict,required TResult Function( ValidationFailure value)  validation,required TResult Function( RateLimitFailure value)  rateLimit,required TResult Function( ServerFailure value)  server,required TResult Function( PayloadTooLargeFailure value)  payloadTooLarge,required TResult Function( ParseFailure value)  parse,required TResult Function( LocalPersistenceFailure value)  localPersistence,required TResult Function( UnknownFailure value)  unknown,}){
final _that = this;
switch (_that) {
case NetworkFailure():
return network(_that);case TimeoutFailure():
return timeout(_that);case CancelledFailure():
return cancelled(_that);case UnauthorizedFailure():
return unauthorized(_that);case ForbiddenFailure():
return forbidden(_that);case NotFoundFailure():
return notFound(_that);case ConflictFailure():
return conflict(_that);case ValidationFailure():
return validation(_that);case RateLimitFailure():
return rateLimit(_that);case ServerFailure():
return server(_that);case PayloadTooLargeFailure():
return payloadTooLarge(_that);case ParseFailure():
return parse(_that);case LocalPersistenceFailure():
return localPersistence(_that);case UnknownFailure():
return unknown(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NetworkFailure value)?  network,TResult? Function( TimeoutFailure value)?  timeout,TResult? Function( CancelledFailure value)?  cancelled,TResult? Function( UnauthorizedFailure value)?  unauthorized,TResult? Function( ForbiddenFailure value)?  forbidden,TResult? Function( NotFoundFailure value)?  notFound,TResult? Function( ConflictFailure value)?  conflict,TResult? Function( ValidationFailure value)?  validation,TResult? Function( RateLimitFailure value)?  rateLimit,TResult? Function( ServerFailure value)?  server,TResult? Function( PayloadTooLargeFailure value)?  payloadTooLarge,TResult? Function( ParseFailure value)?  parse,TResult? Function( LocalPersistenceFailure value)?  localPersistence,TResult? Function( UnknownFailure value)?  unknown,}){
final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network(_that);case TimeoutFailure() when timeout != null:
return timeout(_that);case CancelledFailure() when cancelled != null:
return cancelled(_that);case UnauthorizedFailure() when unauthorized != null:
return unauthorized(_that);case ForbiddenFailure() when forbidden != null:
return forbidden(_that);case NotFoundFailure() when notFound != null:
return notFound(_that);case ConflictFailure() when conflict != null:
return conflict(_that);case ValidationFailure() when validation != null:
return validation(_that);case RateLimitFailure() when rateLimit != null:
return rateLimit(_that);case ServerFailure() when server != null:
return server(_that);case PayloadTooLargeFailure() when payloadTooLarge != null:
return payloadTooLarge(_that);case ParseFailure() when parse != null:
return parse(_that);case LocalPersistenceFailure() when localPersistence != null:
return localPersistence(_that);case UnknownFailure() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  network,TResult Function()?  timeout,TResult Function()?  cancelled,TResult Function()?  unauthorized,TResult Function()?  forbidden,TResult Function()?  notFound,TResult Function()?  conflict,TResult Function( Map<String, ValidationIssue> fields)?  validation,TResult Function( Duration? retryAfter)?  rateLimit,TResult Function( int? statusCode)?  server,TResult Function()?  payloadTooLarge,TResult Function()?  parse,TResult Function()?  localPersistence,TResult Function()?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network();case TimeoutFailure() when timeout != null:
return timeout();case CancelledFailure() when cancelled != null:
return cancelled();case UnauthorizedFailure() when unauthorized != null:
return unauthorized();case ForbiddenFailure() when forbidden != null:
return forbidden();case NotFoundFailure() when notFound != null:
return notFound();case ConflictFailure() when conflict != null:
return conflict();case ValidationFailure() when validation != null:
return validation(_that.fields);case RateLimitFailure() when rateLimit != null:
return rateLimit(_that.retryAfter);case ServerFailure() when server != null:
return server(_that.statusCode);case PayloadTooLargeFailure() when payloadTooLarge != null:
return payloadTooLarge();case ParseFailure() when parse != null:
return parse();case LocalPersistenceFailure() when localPersistence != null:
return localPersistence();case UnknownFailure() when unknown != null:
return unknown();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  network,required TResult Function()  timeout,required TResult Function()  cancelled,required TResult Function()  unauthorized,required TResult Function()  forbidden,required TResult Function()  notFound,required TResult Function()  conflict,required TResult Function( Map<String, ValidationIssue> fields)  validation,required TResult Function( Duration? retryAfter)  rateLimit,required TResult Function( int? statusCode)  server,required TResult Function()  payloadTooLarge,required TResult Function()  parse,required TResult Function()  localPersistence,required TResult Function()  unknown,}) {final _that = this;
switch (_that) {
case NetworkFailure():
return network();case TimeoutFailure():
return timeout();case CancelledFailure():
return cancelled();case UnauthorizedFailure():
return unauthorized();case ForbiddenFailure():
return forbidden();case NotFoundFailure():
return notFound();case ConflictFailure():
return conflict();case ValidationFailure():
return validation(_that.fields);case RateLimitFailure():
return rateLimit(_that.retryAfter);case ServerFailure():
return server(_that.statusCode);case PayloadTooLargeFailure():
return payloadTooLarge();case ParseFailure():
return parse();case LocalPersistenceFailure():
return localPersistence();case UnknownFailure():
return unknown();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  network,TResult? Function()?  timeout,TResult? Function()?  cancelled,TResult? Function()?  unauthorized,TResult? Function()?  forbidden,TResult? Function()?  notFound,TResult? Function()?  conflict,TResult? Function( Map<String, ValidationIssue> fields)?  validation,TResult? Function( Duration? retryAfter)?  rateLimit,TResult? Function( int? statusCode)?  server,TResult? Function()?  payloadTooLarge,TResult? Function()?  parse,TResult? Function()?  localPersistence,TResult? Function()?  unknown,}) {final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network();case TimeoutFailure() when timeout != null:
return timeout();case CancelledFailure() when cancelled != null:
return cancelled();case UnauthorizedFailure() when unauthorized != null:
return unauthorized();case ForbiddenFailure() when forbidden != null:
return forbidden();case NotFoundFailure() when notFound != null:
return notFound();case ConflictFailure() when conflict != null:
return conflict();case ValidationFailure() when validation != null:
return validation(_that.fields);case RateLimitFailure() when rateLimit != null:
return rateLimit(_that.retryAfter);case ServerFailure() when server != null:
return server(_that.statusCode);case PayloadTooLargeFailure() when payloadTooLarge != null:
return payloadTooLarge();case ParseFailure() when parse != null:
return parse();case LocalPersistenceFailure() when localPersistence != null:
return localPersistence();case UnknownFailure() when unknown != null:
return unknown();case _:
  return null;

}
}

}

/// @nodoc


class NetworkFailure implements AppFailure {
  const NetworkFailure();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure.network()';
}


}




/// @nodoc


class TimeoutFailure implements AppFailure {
  const TimeoutFailure();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeoutFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure.timeout()';
}


}




/// @nodoc


class CancelledFailure implements AppFailure {
  const CancelledFailure();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CancelledFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure.cancelled()';
}


}




/// @nodoc


class UnauthorizedFailure implements AppFailure {
  const UnauthorizedFailure();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UnauthorizedFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure.unauthorized()';
}


}




/// @nodoc


class ForbiddenFailure implements AppFailure {
  const ForbiddenFailure();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ForbiddenFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure.forbidden()';
}


}




/// @nodoc


class NotFoundFailure implements AppFailure {
  const NotFoundFailure();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NotFoundFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure.notFound()';
}


}




/// @nodoc


class ConflictFailure implements AppFailure {
  const ConflictFailure();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ConflictFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure.conflict()';
}


}




/// @nodoc


class ValidationFailure implements AppFailure {
  const ValidationFailure( Map<String, ValidationIssue> fields): _fields = fields;
  

 final  Map<String, ValidationIssue> _fields;
 Map<String, ValidationIssue> get fields {
  if (_fields is EqualUnmodifiableMapView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_fields);
}


/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValidationFailureCopyWith<ValidationFailure> get copyWith => _$ValidationFailureCopyWithImpl<ValidationFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidationFailure&&const DeepCollectionEquality().equals(other.fields, _fields));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_fields));
}

@override
String toString() {
    return 'AppFailure.validation(fields: $fields)';
}


}

/// @nodoc
abstract mixin class $ValidationFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $ValidationFailureCopyWith(ValidationFailure value, $Res Function(ValidationFailure) _then) = _$ValidationFailureCopyWithImpl;
@useResult
$Res call({
 Map<String, ValidationIssue> fields
});




}
/// @nodoc
class _$ValidationFailureCopyWithImpl<$Res>
    implements $ValidationFailureCopyWith<$Res> {
  _$ValidationFailureCopyWithImpl(this._self, this._then);

  final ValidationFailure _self;
  final $Res Function(ValidationFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? fields = null,}) {
  return _then(ValidationFailure(
null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as Map<String, ValidationIssue>,
  ));
}


}

/// @nodoc


class RateLimitFailure implements AppFailure {
  const RateLimitFailure(this.retryAfter);
  

 final  Duration? retryAfter;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RateLimitFailureCopyWith<RateLimitFailure> get copyWith => _$RateLimitFailureCopyWithImpl<RateLimitFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RateLimitFailure&&(identical(other.retryAfter, retryAfter) || other.retryAfter == retryAfter));
}


@override
int get hashCode {
    return Object.hash(runtimeType,retryAfter);
}

@override
String toString() {
    return 'AppFailure.rateLimit(retryAfter: $retryAfter)';
}


}

/// @nodoc
abstract mixin class $RateLimitFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $RateLimitFailureCopyWith(RateLimitFailure value, $Res Function(RateLimitFailure) _then) = _$RateLimitFailureCopyWithImpl;
@useResult
$Res call({
 Duration? retryAfter
});




}
/// @nodoc
class _$RateLimitFailureCopyWithImpl<$Res>
    implements $RateLimitFailureCopyWith<$Res> {
  _$RateLimitFailureCopyWithImpl(this._self, this._then);

  final RateLimitFailure _self;
  final $Res Function(RateLimitFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? retryAfter = freezed,}) {
  return _then(RateLimitFailure(
freezed == retryAfter ? _self.retryAfter : retryAfter // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

/// @nodoc


class ServerFailure implements AppFailure {
  const ServerFailure(this.statusCode);
  

 final  int? statusCode;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerFailureCopyWith<ServerFailure> get copyWith => _$ServerFailureCopyWithImpl<ServerFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerFailure&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,statusCode);
}

@override
String toString() {
    return 'AppFailure.server(statusCode: $statusCode)';
}


}

/// @nodoc
abstract mixin class $ServerFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $ServerFailureCopyWith(ServerFailure value, $Res Function(ServerFailure) _then) = _$ServerFailureCopyWithImpl;
@useResult
$Res call({
 int? statusCode
});




}
/// @nodoc
class _$ServerFailureCopyWithImpl<$Res>
    implements $ServerFailureCopyWith<$Res> {
  _$ServerFailureCopyWithImpl(this._self, this._then);

  final ServerFailure _self;
  final $Res Function(ServerFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? statusCode = freezed,}) {
  return _then(ServerFailure(
freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class PayloadTooLargeFailure implements AppFailure {
  const PayloadTooLargeFailure();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PayloadTooLargeFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure.payloadTooLarge()';
}


}




/// @nodoc


class ParseFailure implements AppFailure {
  const ParseFailure();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ParseFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure.parse()';
}


}




/// @nodoc


class LocalPersistenceFailure implements AppFailure {
  const LocalPersistenceFailure();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalPersistenceFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure.localPersistence()';
}


}




/// @nodoc


class UnknownFailure implements AppFailure {
  const UnknownFailure();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure.unknown()';
}


}




// dart format on
