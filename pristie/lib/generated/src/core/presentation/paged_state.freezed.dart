// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../src/core/presentation/paged_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PagedState<T> {

 List<T> get items; int get page; bool get hasMore; bool get isLoadingFirst; bool get isLoadingMore; AppFailure? get loadFirstFailure; AppFailure? get loadMoreFailure;
/// Create a copy of PagedState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PagedStateCopyWith<T, PagedState<T>> get copyWith => _$PagedStateCopyWithImpl<T, PagedState<T>>(this as PagedState<T>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PagedState<T>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PagedState<T>&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.hasMore, _this.hasMore) || other.hasMore == _this.hasMore)&&(identical(other.isLoadingFirst, _this.isLoadingFirst) || other.isLoadingFirst == _this.isLoadingFirst)&&(identical(other.isLoadingMore, _this.isLoadingMore) || other.isLoadingMore == _this.isLoadingMore)&&(identical(other.loadFirstFailure, _this.loadFirstFailure) || other.loadFirstFailure == _this.loadFirstFailure)&&(identical(other.loadMoreFailure, _this.loadMoreFailure) || other.loadMoreFailure == _this.loadMoreFailure));
}


@override
int get hashCode {
  final _this = this as PagedState<T>;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.page,_this.hasMore,_this.isLoadingFirst,_this.isLoadingMore,_this.loadFirstFailure,_this.loadMoreFailure);
}

@override
String toString() {
  final _this = this as PagedState<T>;
  return 'PagedState<$T>(items: ${_this.items}, page: ${_this.page}, hasMore: ${_this.hasMore}, isLoadingFirst: ${_this.isLoadingFirst}, isLoadingMore: ${_this.isLoadingMore}, loadFirstFailure: ${_this.loadFirstFailure}, loadMoreFailure: ${_this.loadMoreFailure})';
}


}

/// @nodoc
abstract mixin class $PagedStateCopyWith<T,$Res>  {
  factory $PagedStateCopyWith(PagedState<T> value, $Res Function(PagedState<T>) _then) = _$PagedStateCopyWithImpl;
@useResult
$Res call({
 List<T> items, int page, bool hasMore, bool isLoadingFirst, bool isLoadingMore, AppFailure? loadFirstFailure, AppFailure? loadMoreFailure
});


$AppFailureCopyWith<$Res>? get loadFirstFailure;$AppFailureCopyWith<$Res>? get loadMoreFailure;

}
/// @nodoc
class _$PagedStateCopyWithImpl<T,$Res>
    implements $PagedStateCopyWith<T, $Res> {
  _$PagedStateCopyWithImpl(this._self, this._then);

  final PagedState<T> _self;
  final $Res Function(PagedState<T>) _then;

/// Create a copy of PagedState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? page = null,Object? hasMore = null,Object? isLoadingFirst = null,Object? isLoadingMore = null,Object? loadFirstFailure = freezed,Object? loadMoreFailure = freezed,}) {
  return _then(PagedState(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<T>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,isLoadingFirst: null == isLoadingFirst ? _self.isLoadingFirst : isLoadingFirst // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,loadFirstFailure: freezed == loadFirstFailure ? _self.loadFirstFailure : loadFirstFailure // ignore: cast_nullable_to_non_nullable
as AppFailure?,loadMoreFailure: freezed == loadMoreFailure ? _self.loadMoreFailure : loadMoreFailure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}
/// Create a copy of PagedState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get loadFirstFailure {
    if (_self.loadFirstFailure == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.loadFirstFailure!, (value) {
    return _then(_self.copyWith(loadFirstFailure: value));
  });
}/// Create a copy of PagedState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get loadMoreFailure {
    if (_self.loadMoreFailure == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.loadMoreFailure!, (value) {
    return _then(_self.copyWith(loadMoreFailure: value));
  });
}
}


/// Adds pattern-matching-related methods to [PagedState].
extension PagedStatePatterns<T> on PagedState<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PagedState<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PagedState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PagedState<T> value)  $default,){
final _that = this;
switch (_that) {
case _PagedState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PagedState<T> value)?  $default,){
final _that = this;
switch (_that) {
case _PagedState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<T> items,  int page,  bool hasMore,  bool isLoadingFirst,  bool isLoadingMore,  AppFailure? loadFirstFailure,  AppFailure? loadMoreFailure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PagedState() when $default != null:
return $default(_that.items,_that.page,_that.hasMore,_that.isLoadingFirst,_that.isLoadingMore,_that.loadFirstFailure,_that.loadMoreFailure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<T> items,  int page,  bool hasMore,  bool isLoadingFirst,  bool isLoadingMore,  AppFailure? loadFirstFailure,  AppFailure? loadMoreFailure)  $default,) {final _that = this;
switch (_that) {
case _PagedState():
return $default(_that.items,_that.page,_that.hasMore,_that.isLoadingFirst,_that.isLoadingMore,_that.loadFirstFailure,_that.loadMoreFailure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<T> items,  int page,  bool hasMore,  bool isLoadingFirst,  bool isLoadingMore,  AppFailure? loadFirstFailure,  AppFailure? loadMoreFailure)?  $default,) {final _that = this;
switch (_that) {
case _PagedState() when $default != null:
return $default(_that.items,_that.page,_that.hasMore,_that.isLoadingFirst,_that.isLoadingMore,_that.loadFirstFailure,_that.loadMoreFailure);case _:
  return null;

}
}

}

/// @nodoc


class _PagedState<T> implements PagedState<T> {
  const _PagedState({ List<T> items = const [], this.page = 1, this.hasMore = true, this.isLoadingFirst = false, this.isLoadingMore = false, this.loadFirstFailure, this.loadMoreFailure}): _items = items;
  

 final  List<T> _items;
@override@JsonKey() List<T> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int page;
@override@JsonKey() final  bool hasMore;
@override@JsonKey() final  bool isLoadingFirst;
@override@JsonKey() final  bool isLoadingMore;
@override final  AppFailure? loadFirstFailure;
@override final  AppFailure? loadMoreFailure;

/// Create a copy of PagedState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PagedStateCopyWith<T, _PagedState<T>> get copyWith => __$PagedStateCopyWithImpl<T, _PagedState<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PagedState<T>&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.page, page) || other.page == page)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.isLoadingFirst, isLoadingFirst) || other.isLoadingFirst == isLoadingFirst)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.loadFirstFailure, loadFirstFailure) || other.loadFirstFailure == loadFirstFailure)&&(identical(other.loadMoreFailure, loadMoreFailure) || other.loadMoreFailure == loadMoreFailure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),page,hasMore,isLoadingFirst,isLoadingMore,loadFirstFailure,loadMoreFailure);
}

@override
String toString() {
    return 'PagedState<$T>(items: $items, page: $page, hasMore: $hasMore, isLoadingFirst: $isLoadingFirst, isLoadingMore: $isLoadingMore, loadFirstFailure: $loadFirstFailure, loadMoreFailure: $loadMoreFailure)';
}


}

/// @nodoc
abstract mixin class _$PagedStateCopyWith<T,$Res> implements $PagedStateCopyWith<T, $Res> {
  factory _$PagedStateCopyWith(_PagedState<T> value, $Res Function(_PagedState<T>) _then) = __$PagedStateCopyWithImpl;
@override @useResult
$Res call({
 List<T> items, int page, bool hasMore, bool isLoadingFirst, bool isLoadingMore, AppFailure? loadFirstFailure, AppFailure? loadMoreFailure
});


@override $AppFailureCopyWith<$Res>? get loadFirstFailure;@override $AppFailureCopyWith<$Res>? get loadMoreFailure;

}
/// @nodoc
class __$PagedStateCopyWithImpl<T,$Res>
    implements _$PagedStateCopyWith<T, $Res> {
  __$PagedStateCopyWithImpl(this._self, this._then);

  final _PagedState<T> _self;
  final $Res Function(_PagedState<T>) _then;

/// Create a copy of PagedState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? page = null,Object? hasMore = null,Object? isLoadingFirst = null,Object? isLoadingMore = null,Object? loadFirstFailure = freezed,Object? loadMoreFailure = freezed,}) {
  return _then(_PagedState<T>(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<T>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,isLoadingFirst: null == isLoadingFirst ? _self.isLoadingFirst : isLoadingFirst // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,loadFirstFailure: freezed == loadFirstFailure ? _self.loadFirstFailure : loadFirstFailure // ignore: cast_nullable_to_non_nullable
as AppFailure?,loadMoreFailure: freezed == loadMoreFailure ? _self.loadMoreFailure : loadMoreFailure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}

/// Create a copy of PagedState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get loadFirstFailure {
    if (_self.loadFirstFailure == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.loadFirstFailure!, (value) {
    return _then(_self.copyWith(loadFirstFailure: value));
  });
}/// Create a copy of PagedState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get loadMoreFailure {
    if (_self.loadMoreFailure == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.loadMoreFailure!, (value) {
    return _then(_self.copyWith(loadMoreFailure: value));
  });
}
}

/// @nodoc
mixin _$PagedPage<T> {

 List<T> get items; bool get hasMore;
/// Create a copy of PagedPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PagedPageCopyWith<T, PagedPage<T>> get copyWith => _$PagedPageCopyWithImpl<T, PagedPage<T>>(this as PagedPage<T>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PagedPage<T>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PagedPage<T>&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.hasMore, _this.hasMore) || other.hasMore == _this.hasMore));
}


@override
int get hashCode {
  final _this = this as PagedPage<T>;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.hasMore);
}

@override
String toString() {
  final _this = this as PagedPage<T>;
  return 'PagedPage<$T>(items: ${_this.items}, hasMore: ${_this.hasMore})';
}


}

/// @nodoc
abstract mixin class $PagedPageCopyWith<T,$Res>  {
  factory $PagedPageCopyWith(PagedPage<T> value, $Res Function(PagedPage<T>) _then) = _$PagedPageCopyWithImpl;
@useResult
$Res call({
 List<T> items, bool hasMore
});




}
/// @nodoc
class _$PagedPageCopyWithImpl<T,$Res>
    implements $PagedPageCopyWith<T, $Res> {
  _$PagedPageCopyWithImpl(this._self, this._then);

  final PagedPage<T> _self;
  final $Res Function(PagedPage<T>) _then;

/// Create a copy of PagedPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? hasMore = null,}) {
  return _then(PagedPage(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<T>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PagedPage].
extension PagedPagePatterns<T> on PagedPage<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PagedPage<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PagedPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PagedPage<T> value)  $default,){
final _that = this;
switch (_that) {
case _PagedPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PagedPage<T> value)?  $default,){
final _that = this;
switch (_that) {
case _PagedPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<T> items,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PagedPage() when $default != null:
return $default(_that.items,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<T> items,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _PagedPage():
return $default(_that.items,_that.hasMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<T> items,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _PagedPage() when $default != null:
return $default(_that.items,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc


class _PagedPage<T> implements PagedPage<T> {
  const _PagedPage({ List<T> items = const [], required this.hasMore}): _items = items;
  

 final  List<T> _items;
@override@JsonKey() List<T> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  bool hasMore;

/// Create a copy of PagedPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PagedPageCopyWith<T, _PagedPage<T>> get copyWith => __$PagedPageCopyWithImpl<T, _PagedPage<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PagedPage<T>&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),hasMore);
}

@override
String toString() {
    return 'PagedPage<$T>(items: $items, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$PagedPageCopyWith<T,$Res> implements $PagedPageCopyWith<T, $Res> {
  factory _$PagedPageCopyWith(_PagedPage<T> value, $Res Function(_PagedPage<T>) _then) = __$PagedPageCopyWithImpl;
@override @useResult
$Res call({
 List<T> items, bool hasMore
});




}
/// @nodoc
class __$PagedPageCopyWithImpl<T,$Res>
    implements _$PagedPageCopyWith<T, $Res> {
  __$PagedPageCopyWithImpl(this._self, this._then);

  final _PagedPage<T> _self;
  final $Res Function(_PagedPage<T>) _then;

/// Create a copy of PagedPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? hasMore = null,}) {
  return _then(_PagedPage<T>(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<T>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
