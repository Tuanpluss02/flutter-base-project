// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../src/core/network/api_client.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ItemDto {

 String get id; String get title;
/// Create a copy of ItemDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemDtoCopyWith<ItemDto> get copyWith => _$ItemDtoCopyWithImpl<ItemDto>(this as ItemDto, _$identity);

  /// Serializes this ItemDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ItemDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ItemDto;
  return Object.hash(runtimeType,_this.id,_this.title);
}

@override
String toString() {
  final _this = this as ItemDto;
  return 'ItemDto(id: ${_this.id}, title: ${_this.title})';
}


}

/// @nodoc
abstract mixin class $ItemDtoCopyWith<$Res>  {
  factory $ItemDtoCopyWith(ItemDto value, $Res Function(ItemDto) _then) = _$ItemDtoCopyWithImpl;
@useResult
$Res call({
 String id, String title
});




}
/// @nodoc
class _$ItemDtoCopyWithImpl<$Res>
    implements $ItemDtoCopyWith<$Res> {
  _$ItemDtoCopyWithImpl(this._self, this._then);

  final ItemDto _self;
  final $Res Function(ItemDto) _then;

/// Create a copy of ItemDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,}) {
  return _then(ItemDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ItemDto].
extension ItemDtoPatterns on ItemDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemDto value)  $default,){
final _that = this;
switch (_that) {
case _ItemDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemDto value)?  $default,){
final _that = this;
switch (_that) {
case _ItemDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemDto() when $default != null:
return $default(_that.id,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title)  $default,) {final _that = this;
switch (_that) {
case _ItemDto():
return $default(_that.id,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title)?  $default,) {final _that = this;
switch (_that) {
case _ItemDto() when $default != null:
return $default(_that.id,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ItemDto implements ItemDto {
  const _ItemDto({required this.id, required this.title});
  factory _ItemDto.fromJson(Map<String, dynamic> json) => _$ItemDtoFromJson(json);

@override final  String id;
@override final  String title;

/// Create a copy of ItemDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemDtoCopyWith<_ItemDto> get copyWith => __$ItemDtoCopyWithImpl<_ItemDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ItemDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title);
}

@override
String toString() {
    return 'ItemDto(id: $id, title: $title)';
}


}

/// @nodoc
abstract mixin class _$ItemDtoCopyWith<$Res> implements $ItemDtoCopyWith<$Res> {
  factory _$ItemDtoCopyWith(_ItemDto value, $Res Function(_ItemDto) _then) = __$ItemDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title
});




}
/// @nodoc
class __$ItemDtoCopyWithImpl<$Res>
    implements _$ItemDtoCopyWith<$Res> {
  __$ItemDtoCopyWithImpl(this._self, this._then);

  final _ItemDto _self;
  final $Res Function(_ItemDto) _then;

/// Create a copy of ItemDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,}) {
  return _then(_ItemDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PagedResponseDto<T> {

 List<T> get items; int get page; int get pageSize; int get total; bool get hasMore;
/// Create a copy of PagedResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PagedResponseDtoCopyWith<T, PagedResponseDto<T>> get copyWith => _$PagedResponseDtoCopyWithImpl<T, PagedResponseDto<T>>(this as PagedResponseDto<T>, _$identity);

  /// Serializes this PagedResponseDto to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT);


@override
bool operator ==(Object other) {
  final _this = this as PagedResponseDto<T>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PagedResponseDto<T>&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.pageSize, _this.pageSize) || other.pageSize == _this.pageSize)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.hasMore, _this.hasMore) || other.hasMore == _this.hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PagedResponseDto<T>;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.page,_this.pageSize,_this.total,_this.hasMore);
}

@override
String toString() {
  final _this = this as PagedResponseDto<T>;
  return 'PagedResponseDto<$T>(items: ${_this.items}, page: ${_this.page}, pageSize: ${_this.pageSize}, total: ${_this.total}, hasMore: ${_this.hasMore})';
}


}

/// @nodoc
abstract mixin class $PagedResponseDtoCopyWith<T,$Res>  {
  factory $PagedResponseDtoCopyWith(PagedResponseDto<T> value, $Res Function(PagedResponseDto<T>) _then) = _$PagedResponseDtoCopyWithImpl;
@useResult
$Res call({
 List<T> items, int page, int pageSize, int total, bool hasMore
});




}
/// @nodoc
class _$PagedResponseDtoCopyWithImpl<T,$Res>
    implements $PagedResponseDtoCopyWith<T, $Res> {
  _$PagedResponseDtoCopyWithImpl(this._self, this._then);

  final PagedResponseDto<T> _self;
  final $Res Function(PagedResponseDto<T>) _then;

/// Create a copy of PagedResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? page = null,Object? pageSize = null,Object? total = null,Object? hasMore = null,}) {
  return _then(PagedResponseDto(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<T>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PagedResponseDto].
extension PagedResponseDtoPatterns<T> on PagedResponseDto<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PagedResponseDto<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PagedResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PagedResponseDto<T> value)  $default,){
final _that = this;
switch (_that) {
case _PagedResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PagedResponseDto<T> value)?  $default,){
final _that = this;
switch (_that) {
case _PagedResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<T> items,  int page,  int pageSize,  int total,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PagedResponseDto() when $default != null:
return $default(_that.items,_that.page,_that.pageSize,_that.total,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<T> items,  int page,  int pageSize,  int total,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _PagedResponseDto():
return $default(_that.items,_that.page,_that.pageSize,_that.total,_that.hasMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<T> items,  int page,  int pageSize,  int total,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _PagedResponseDto() when $default != null:
return $default(_that.items,_that.page,_that.pageSize,_that.total,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class _PagedResponseDto<T> implements PagedResponseDto<T> {
  const _PagedResponseDto({ List<T> items = const <Never>[], required this.page, required this.pageSize, required this.total, required this.hasMore}): _items = items;
  factory _PagedResponseDto.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$PagedResponseDtoFromJson(json,fromJsonT);

 final  List<T> _items;
@override@JsonKey() List<T> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int page;
@override final  int pageSize;
@override final  int total;
@override final  bool hasMore;

/// Create a copy of PagedResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PagedResponseDtoCopyWith<T, _PagedResponseDto<T>> get copyWith => __$PagedResponseDtoCopyWithImpl<T, _PagedResponseDto<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$PagedResponseDtoToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PagedResponseDto<T>&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.total, total) || other.total == total)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),page,pageSize,total,hasMore);
}

@override
String toString() {
    return 'PagedResponseDto<$T>(items: $items, page: $page, pageSize: $pageSize, total: $total, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$PagedResponseDtoCopyWith<T,$Res> implements $PagedResponseDtoCopyWith<T, $Res> {
  factory _$PagedResponseDtoCopyWith(_PagedResponseDto<T> value, $Res Function(_PagedResponseDto<T>) _then) = __$PagedResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 List<T> items, int page, int pageSize, int total, bool hasMore
});




}
/// @nodoc
class __$PagedResponseDtoCopyWithImpl<T,$Res>
    implements _$PagedResponseDtoCopyWith<T, $Res> {
  __$PagedResponseDtoCopyWithImpl(this._self, this._then);

  final _PagedResponseDto<T> _self;
  final $Res Function(_PagedResponseDto<T>) _then;

/// Create a copy of PagedResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? page = null,Object? pageSize = null,Object? total = null,Object? hasMore = null,}) {
  return _then(_PagedResponseDto<T>(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<T>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$RefreshRequestDto {

 String get refreshToken;
/// Create a copy of RefreshRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RefreshRequestDtoCopyWith<RefreshRequestDto> get copyWith => _$RefreshRequestDtoCopyWithImpl<RefreshRequestDto>(this as RefreshRequestDto, _$identity);

  /// Serializes this RefreshRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RefreshRequestDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RefreshRequestDto&&(identical(other.refreshToken, _this.refreshToken) || other.refreshToken == _this.refreshToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RefreshRequestDto;
  return Object.hash(runtimeType,_this.refreshToken);
}

@override
String toString() {
  final _this = this as RefreshRequestDto;
  return 'RefreshRequestDto(refreshToken: ${_this.refreshToken})';
}


}

/// @nodoc
abstract mixin class $RefreshRequestDtoCopyWith<$Res>  {
  factory $RefreshRequestDtoCopyWith(RefreshRequestDto value, $Res Function(RefreshRequestDto) _then) = _$RefreshRequestDtoCopyWithImpl;
@useResult
$Res call({
 String refreshToken
});




}
/// @nodoc
class _$RefreshRequestDtoCopyWithImpl<$Res>
    implements $RefreshRequestDtoCopyWith<$Res> {
  _$RefreshRequestDtoCopyWithImpl(this._self, this._then);

  final RefreshRequestDto _self;
  final $Res Function(RefreshRequestDto) _then;

/// Create a copy of RefreshRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? refreshToken = null,}) {
  return _then(RefreshRequestDto(
refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RefreshRequestDto].
extension RefreshRequestDtoPatterns on RefreshRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RefreshRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RefreshRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RefreshRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _RefreshRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RefreshRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _RefreshRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String refreshToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RefreshRequestDto() when $default != null:
return $default(_that.refreshToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String refreshToken)  $default,) {final _that = this;
switch (_that) {
case _RefreshRequestDto():
return $default(_that.refreshToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String refreshToken)?  $default,) {final _that = this;
switch (_that) {
case _RefreshRequestDto() when $default != null:
return $default(_that.refreshToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RefreshRequestDto implements RefreshRequestDto {
  const _RefreshRequestDto({required this.refreshToken});
  factory _RefreshRequestDto.fromJson(Map<String, dynamic> json) => _$RefreshRequestDtoFromJson(json);

@override final  String refreshToken;

/// Create a copy of RefreshRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RefreshRequestDtoCopyWith<_RefreshRequestDto> get copyWith => __$RefreshRequestDtoCopyWithImpl<_RefreshRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RefreshRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RefreshRequestDto&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,refreshToken);
}

@override
String toString() {
    return 'RefreshRequestDto(refreshToken: $refreshToken)';
}


}

/// @nodoc
abstract mixin class _$RefreshRequestDtoCopyWith<$Res> implements $RefreshRequestDtoCopyWith<$Res> {
  factory _$RefreshRequestDtoCopyWith(_RefreshRequestDto value, $Res Function(_RefreshRequestDto) _then) = __$RefreshRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String refreshToken
});




}
/// @nodoc
class __$RefreshRequestDtoCopyWithImpl<$Res>
    implements _$RefreshRequestDtoCopyWith<$Res> {
  __$RefreshRequestDtoCopyWithImpl(this._self, this._then);

  final _RefreshRequestDto _self;
  final $Res Function(_RefreshRequestDto) _then;

/// Create a copy of RefreshRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? refreshToken = null,}) {
  return _then(_RefreshRequestDto(
refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RefreshResponseDto {

 String get accessToken; String get refreshToken; String get tokenType; int get expiresIn;
/// Create a copy of RefreshResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RefreshResponseDtoCopyWith<RefreshResponseDto> get copyWith => _$RefreshResponseDtoCopyWithImpl<RefreshResponseDto>(this as RefreshResponseDto, _$identity);

  /// Serializes this RefreshResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RefreshResponseDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RefreshResponseDto&&(identical(other.accessToken, _this.accessToken) || other.accessToken == _this.accessToken)&&(identical(other.refreshToken, _this.refreshToken) || other.refreshToken == _this.refreshToken)&&(identical(other.tokenType, _this.tokenType) || other.tokenType == _this.tokenType)&&(identical(other.expiresIn, _this.expiresIn) || other.expiresIn == _this.expiresIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RefreshResponseDto;
  return Object.hash(runtimeType,_this.accessToken,_this.refreshToken,_this.tokenType,_this.expiresIn);
}

@override
String toString() {
  final _this = this as RefreshResponseDto;
  return 'RefreshResponseDto(accessToken: ${_this.accessToken}, refreshToken: ${_this.refreshToken}, tokenType: ${_this.tokenType}, expiresIn: ${_this.expiresIn})';
}


}

/// @nodoc
abstract mixin class $RefreshResponseDtoCopyWith<$Res>  {
  factory $RefreshResponseDtoCopyWith(RefreshResponseDto value, $Res Function(RefreshResponseDto) _then) = _$RefreshResponseDtoCopyWithImpl;
@useResult
$Res call({
 String accessToken, String refreshToken, String tokenType, int expiresIn
});




}
/// @nodoc
class _$RefreshResponseDtoCopyWithImpl<$Res>
    implements $RefreshResponseDtoCopyWith<$Res> {
  _$RefreshResponseDtoCopyWithImpl(this._self, this._then);

  final RefreshResponseDto _self;
  final $Res Function(RefreshResponseDto) _then;

/// Create a copy of RefreshResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? refreshToken = null,Object? tokenType = null,Object? expiresIn = null,}) {
  return _then(RefreshResponseDto(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,tokenType: null == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RefreshResponseDto].
extension RefreshResponseDtoPatterns on RefreshResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RefreshResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RefreshResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RefreshResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _RefreshResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RefreshResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _RefreshResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  String tokenType,  int expiresIn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RefreshResponseDto() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.tokenType,_that.expiresIn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  String tokenType,  int expiresIn)  $default,) {final _that = this;
switch (_that) {
case _RefreshResponseDto():
return $default(_that.accessToken,_that.refreshToken,_that.tokenType,_that.expiresIn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  String refreshToken,  String tokenType,  int expiresIn)?  $default,) {final _that = this;
switch (_that) {
case _RefreshResponseDto() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.tokenType,_that.expiresIn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RefreshResponseDto implements RefreshResponseDto {
  const _RefreshResponseDto({required this.accessToken, required this.refreshToken, required this.tokenType, required this.expiresIn});
  factory _RefreshResponseDto.fromJson(Map<String, dynamic> json) => _$RefreshResponseDtoFromJson(json);

@override final  String accessToken;
@override final  String refreshToken;
@override final  String tokenType;
@override final  int expiresIn;

/// Create a copy of RefreshResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RefreshResponseDtoCopyWith<_RefreshResponseDto> get copyWith => __$RefreshResponseDtoCopyWithImpl<_RefreshResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RefreshResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RefreshResponseDto&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,accessToken,refreshToken,tokenType,expiresIn);
}

@override
String toString() {
    return 'RefreshResponseDto(accessToken: $accessToken, refreshToken: $refreshToken, tokenType: $tokenType, expiresIn: $expiresIn)';
}


}

/// @nodoc
abstract mixin class _$RefreshResponseDtoCopyWith<$Res> implements $RefreshResponseDtoCopyWith<$Res> {
  factory _$RefreshResponseDtoCopyWith(_RefreshResponseDto value, $Res Function(_RefreshResponseDto) _then) = __$RefreshResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, String refreshToken, String tokenType, int expiresIn
});




}
/// @nodoc
class __$RefreshResponseDtoCopyWithImpl<$Res>
    implements _$RefreshResponseDtoCopyWith<$Res> {
  __$RefreshResponseDtoCopyWithImpl(this._self, this._then);

  final _RefreshResponseDto _self;
  final $Res Function(_RefreshResponseDto) _then;

/// Create a copy of RefreshResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = null,Object? tokenType = null,Object? expiresIn = null,}) {
  return _then(_RefreshResponseDto(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,tokenType: null == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
