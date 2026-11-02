// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offline_home_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OfflineHomeState {

 List<DemoItem> get items; SyncStatus get status; bool get isLoading; AppFailure? get failure; DateTime? get lastSyncedAt;
/// Create a copy of OfflineHomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfflineHomeStateCopyWith<OfflineHomeState> get copyWith => _$OfflineHomeStateCopyWithImpl<OfflineHomeState>(this as OfflineHomeState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OfflineHomeState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OfflineHomeState&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.isLoading, _this.isLoading) || other.isLoading == _this.isLoading)&&(identical(other.failure, _this.failure) || other.failure == _this.failure)&&(identical(other.lastSyncedAt, _this.lastSyncedAt) || other.lastSyncedAt == _this.lastSyncedAt));
}


@override
int get hashCode {
  final _this = this as OfflineHomeState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.status,_this.isLoading,_this.failure,_this.lastSyncedAt);
}

@override
String toString() {
  final _this = this as OfflineHomeState;
  return 'OfflineHomeState(items: ${_this.items}, status: ${_this.status}, isLoading: ${_this.isLoading}, failure: ${_this.failure}, lastSyncedAt: ${_this.lastSyncedAt})';
}


}

/// @nodoc
abstract mixin class $OfflineHomeStateCopyWith<$Res>  {
  factory $OfflineHomeStateCopyWith(OfflineHomeState value, $Res Function(OfflineHomeState) _then) = _$OfflineHomeStateCopyWithImpl;
@useResult
$Res call({
 List<DemoItem> items, SyncStatus status, bool isLoading, AppFailure? failure, DateTime? lastSyncedAt
});


$AppFailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$OfflineHomeStateCopyWithImpl<$Res>
    implements $OfflineHomeStateCopyWith<$Res> {
  _$OfflineHomeStateCopyWithImpl(this._self, this._then);

  final OfflineHomeState _self;
  final $Res Function(OfflineHomeState) _then;

/// Create a copy of OfflineHomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? status = null,Object? isLoading = null,Object? failure = freezed,Object? lastSyncedAt = freezed,}) {
  return _then(OfflineHomeState(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<DemoItem>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SyncStatus,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of OfflineHomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}


/// Adds pattern-matching-related methods to [OfflineHomeState].
extension OfflineHomeStatePatterns on OfflineHomeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OfflineHomeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OfflineHomeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OfflineHomeState value)  $default,){
final _that = this;
switch (_that) {
case _OfflineHomeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OfflineHomeState value)?  $default,){
final _that = this;
switch (_that) {
case _OfflineHomeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DemoItem> items,  SyncStatus status,  bool isLoading,  AppFailure? failure,  DateTime? lastSyncedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OfflineHomeState() when $default != null:
return $default(_that.items,_that.status,_that.isLoading,_that.failure,_that.lastSyncedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DemoItem> items,  SyncStatus status,  bool isLoading,  AppFailure? failure,  DateTime? lastSyncedAt)  $default,) {final _that = this;
switch (_that) {
case _OfflineHomeState():
return $default(_that.items,_that.status,_that.isLoading,_that.failure,_that.lastSyncedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DemoItem> items,  SyncStatus status,  bool isLoading,  AppFailure? failure,  DateTime? lastSyncedAt)?  $default,) {final _that = this;
switch (_that) {
case _OfflineHomeState() when $default != null:
return $default(_that.items,_that.status,_that.isLoading,_that.failure,_that.lastSyncedAt);case _:
  return null;

}
}

}

/// @nodoc


class _OfflineHomeState implements OfflineHomeState {
  const _OfflineHomeState({ List<DemoItem> items = const <DemoItem>[], this.status = SyncStatus.online, this.isLoading = false, this.failure, this.lastSyncedAt}): _items = items;
  

 final  List<DemoItem> _items;
@override@JsonKey() List<DemoItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  SyncStatus status;
@override@JsonKey() final  bool isLoading;
@override final  AppFailure? failure;
@override final  DateTime? lastSyncedAt;

/// Create a copy of OfflineHomeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OfflineHomeStateCopyWith<_OfflineHomeState> get copyWith => __$OfflineHomeStateCopyWithImpl<_OfflineHomeState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OfflineHomeState&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.status, status) || other.status == status)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),status,isLoading,failure,lastSyncedAt);
}

@override
String toString() {
    return 'OfflineHomeState(items: $items, status: $status, isLoading: $isLoading, failure: $failure, lastSyncedAt: $lastSyncedAt)';
}


}

/// @nodoc
abstract mixin class _$OfflineHomeStateCopyWith<$Res> implements $OfflineHomeStateCopyWith<$Res> {
  factory _$OfflineHomeStateCopyWith(_OfflineHomeState value, $Res Function(_OfflineHomeState) _then) = __$OfflineHomeStateCopyWithImpl;
@override @useResult
$Res call({
 List<DemoItem> items, SyncStatus status, bool isLoading, AppFailure? failure, DateTime? lastSyncedAt
});


@override $AppFailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$OfflineHomeStateCopyWithImpl<$Res>
    implements _$OfflineHomeStateCopyWith<$Res> {
  __$OfflineHomeStateCopyWithImpl(this._self, this._then);

  final _OfflineHomeState _self;
  final $Res Function(_OfflineHomeState) _then;

/// Create a copy of OfflineHomeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? status = null,Object? isLoading = null,Object? failure = freezed,Object? lastSyncedAt = freezed,}) {
  return _then(_OfflineHomeState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<DemoItem>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SyncStatus,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of OfflineHomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
