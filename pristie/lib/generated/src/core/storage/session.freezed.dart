// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../src/core/storage/session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Session {

 String get accessToken; String get refreshToken; String get tokenType; DateTime get expiresAt;
/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionCopyWith<Session> get copyWith => _$SessionCopyWithImpl<Session>(this as Session, _$identity);

  /// Serializes this Session to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Session;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Session&&(identical(other.accessToken, _this.accessToken) || other.accessToken == _this.accessToken)&&(identical(other.refreshToken, _this.refreshToken) || other.refreshToken == _this.refreshToken)&&(identical(other.tokenType, _this.tokenType) || other.tokenType == _this.tokenType)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Session;
  return Object.hash(runtimeType,_this.accessToken,_this.refreshToken,_this.tokenType,_this.expiresAt);
}

@override
String toString() {
  final _this = this as Session;
  return 'Session(accessToken: ${_this.accessToken}, refreshToken: ${_this.refreshToken}, tokenType: ${_this.tokenType}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $SessionCopyWith<$Res>  {
  factory $SessionCopyWith(Session value, $Res Function(Session) _then) = _$SessionCopyWithImpl;
@useResult
$Res call({
 String accessToken, String refreshToken, String tokenType, DateTime expiresAt
});




}
/// @nodoc
class _$SessionCopyWithImpl<$Res>
    implements $SessionCopyWith<$Res> {
  _$SessionCopyWithImpl(this._self, this._then);

  final Session _self;
  final $Res Function(Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? refreshToken = null,Object? tokenType = null,Object? expiresAt = null,}) {
  return _then(Session(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,tokenType: null == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Session].
extension SessionPatterns on Session {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Session value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Session() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Session value)  $default,){
final _that = this;
switch (_that) {
case _Session():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Session value)?  $default,){
final _that = this;
switch (_that) {
case _Session() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  String tokenType,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.tokenType,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  String tokenType,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _Session():
return $default(_that.accessToken,_that.refreshToken,_that.tokenType,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  String refreshToken,  String tokenType,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.tokenType,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Session implements Session {
  const _Session({required this.accessToken, required this.refreshToken, required this.tokenType, required this.expiresAt});
  factory _Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);

@override final  String accessToken;
@override final  String refreshToken;
@override final  String tokenType;
@override final  DateTime expiresAt;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionCopyWith<_Session> get copyWith => __$SessionCopyWithImpl<_Session>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Session&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,accessToken,refreshToken,tokenType,expiresAt);
}

@override
String toString() {
    return 'Session(accessToken: $accessToken, refreshToken: $refreshToken, tokenType: $tokenType, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$SessionCopyWith<$Res> implements $SessionCopyWith<$Res> {
  factory _$SessionCopyWith(_Session value, $Res Function(_Session) _then) = __$SessionCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, String refreshToken, String tokenType, DateTime expiresAt
});




}
/// @nodoc
class __$SessionCopyWithImpl<$Res>
    implements _$SessionCopyWith<$Res> {
  __$SessionCopyWithImpl(this._self, this._then);

  final _Session _self;
  final $Res Function(_Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = null,Object? tokenType = null,Object? expiresAt = null,}) {
  return _then(_Session(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,tokenType: null == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$SessionRecord {

 SessionStatus get status; Session? get session;
/// Create a copy of SessionRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionRecordCopyWith<SessionRecord> get copyWith => _$SessionRecordCopyWithImpl<SessionRecord>(this as SessionRecord, _$identity);

  /// Serializes this SessionRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SessionRecord;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionRecord&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.session, _this.session) || other.session == _this.session));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SessionRecord;
  return Object.hash(runtimeType,_this.status,_this.session);
}

@override
String toString() {
  final _this = this as SessionRecord;
  return 'SessionRecord(status: ${_this.status}, session: ${_this.session})';
}


}

/// @nodoc
abstract mixin class $SessionRecordCopyWith<$Res>  {
  factory $SessionRecordCopyWith(SessionRecord value, $Res Function(SessionRecord) _then) = _$SessionRecordCopyWithImpl;
@useResult
$Res call({
 SessionStatus status, Session? session
});


$SessionCopyWith<$Res>? get session;

}
/// @nodoc
class _$SessionRecordCopyWithImpl<$Res>
    implements $SessionRecordCopyWith<$Res> {
  _$SessionRecordCopyWithImpl(this._self, this._then);

  final SessionRecord _self;
  final $Res Function(SessionRecord) _then;

/// Create a copy of SessionRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? session = freezed,}) {
  return _then(SessionRecord(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,session: freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as Session?,
  ));
}
/// Create a copy of SessionRecord
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionCopyWith<$Res>? get session {
    if (_self.session == null) {
    return null;
  }

  return $SessionCopyWith<$Res>(_self.session!, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}


/// Adds pattern-matching-related methods to [SessionRecord].
extension SessionRecordPatterns on SessionRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionRecord value)  $default,){
final _that = this;
switch (_that) {
case _SessionRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionRecord value)?  $default,){
final _that = this;
switch (_that) {
case _SessionRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SessionStatus status,  Session? session)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionRecord() when $default != null:
return $default(_that.status,_that.session);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SessionStatus status,  Session? session)  $default,) {final _that = this;
switch (_that) {
case _SessionRecord():
return $default(_that.status,_that.session);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SessionStatus status,  Session? session)?  $default,) {final _that = this;
switch (_that) {
case _SessionRecord() when $default != null:
return $default(_that.status,_that.session);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionRecord implements SessionRecord {
  const _SessionRecord({required this.status, this.session});
  factory _SessionRecord.fromJson(Map<String, dynamic> json) => _$SessionRecordFromJson(json);

@override final  SessionStatus status;
@override final  Session? session;

/// Create a copy of SessionRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionRecordCopyWith<_SessionRecord> get copyWith => __$SessionRecordCopyWithImpl<_SessionRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionRecordToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionRecord&&(identical(other.status, status) || other.status == status)&&(identical(other.session, session) || other.session == session));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,status,session);
}

@override
String toString() {
    return 'SessionRecord(status: $status, session: $session)';
}


}

/// @nodoc
abstract mixin class _$SessionRecordCopyWith<$Res> implements $SessionRecordCopyWith<$Res> {
  factory _$SessionRecordCopyWith(_SessionRecord value, $Res Function(_SessionRecord) _then) = __$SessionRecordCopyWithImpl;
@override @useResult
$Res call({
 SessionStatus status, Session? session
});


@override $SessionCopyWith<$Res>? get session;

}
/// @nodoc
class __$SessionRecordCopyWithImpl<$Res>
    implements _$SessionRecordCopyWith<$Res> {
  __$SessionRecordCopyWithImpl(this._self, this._then);

  final _SessionRecord _self;
  final $Res Function(_SessionRecord) _then;

/// Create a copy of SessionRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? session = freezed,}) {
  return _then(_SessionRecord(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,session: freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as Session?,
  ));
}

/// Create a copy of SessionRecord
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionCopyWith<$Res>? get session {
    if (_self.session == null) {
    return null;
  }

  return $SessionCopyWith<$Res>(_self.session!, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

// dart format on
