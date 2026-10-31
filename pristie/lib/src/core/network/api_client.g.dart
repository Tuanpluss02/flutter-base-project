// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ItemDto _$ItemDtoFromJson(Map<String, dynamic> json) =>
    _ItemDto(id: json['id'] as String, title: json['title'] as String);

Map<String, dynamic> _$ItemDtoToJson(_ItemDto instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
};

_PagedResponseDto<T> _$PagedResponseDtoFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => _PagedResponseDto<T>(
  items:
      (json['items'] as List<dynamic>?)?.map(fromJsonT).toList() ??
      const <Never>[],
  page: (json['page'] as num).toInt(),
  pageSize: (json['page_size'] as num).toInt(),
  total: (json['total'] as num).toInt(),
  hasMore: json['has_more'] as bool,
);

Map<String, dynamic> _$PagedResponseDtoToJson<T>(
  _PagedResponseDto<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'items': instance.items.map(toJsonT).toList(),
  'page': instance.page,
  'page_size': instance.pageSize,
  'total': instance.total,
  'has_more': instance.hasMore,
};

_RefreshRequestDto _$RefreshRequestDtoFromJson(Map<String, dynamic> json) =>
    _RefreshRequestDto(refreshToken: json['refresh_token'] as String);

Map<String, dynamic> _$RefreshRequestDtoToJson(_RefreshRequestDto instance) =>
    <String, dynamic>{'refresh_token': instance.refreshToken};

_RefreshResponseDto _$RefreshResponseDtoFromJson(Map<String, dynamic> json) =>
    _RefreshResponseDto(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
    );

Map<String, dynamic> _$RefreshResponseDtoToJson(_RefreshResponseDto instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'token_type': instance.tokenType,
      'expires_in': instance.expiresIn,
    };

// dart format off

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: type=lint
// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter,avoid_unused_constructor_parameters,unreachable_from_main,avoid_redundant_argument_values

class _ApiClient implements ApiClient {
  _ApiClient(this._dio, {this.baseUrl, this.errorLogger});

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<PagedResponseDto<ItemDto>> getItems(
    int page,
    int pageSize, {
    CancelToken? cancelToken,
  }) async {
    final _extra = <String, dynamic>{'routeTemplate': '/api/v1/items'};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'page_size': pageSize,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<PagedResponseDto<ItemDto>>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/items',
            queryParameters: queryParameters,
            data: _data,
            cancelToken: cancelToken,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late PagedResponseDto<ItemDto> _value;
    try {
      _value = PagedResponseDto<ItemDto>.fromJson(
        _result.data!,
        (json) => ItemDto.fromJson(json as Map<String, dynamic>),
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<RefreshResponseDto> refresh(
    RefreshRequestDto body, {
    CancelToken? cancelToken,
  }) async {
    final _extra = <String, dynamic>{
      'no_auth': true,
      'routeTemplate': '/api/v1/auth/refresh',
    };
    final queryParameters = <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<RefreshResponseDto>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/auth/refresh',
            queryParameters: queryParameters,
            data: _data,
            cancelToken: cancelToken,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late RefreshResponseDto _value;
    try {
      _value = RefreshResponseDto.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<void> deleteItem(String id, {CancelToken? cancelToken}) async {
    final _extra = <String, dynamic>{'routeTemplate': '/api/v1/items/{id}'};
    final queryParameters = <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<void>(
      Options(method: 'DELETE', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/items/${id}',
            queryParameters: queryParameters,
            data: _data,
            cancelToken: cancelToken,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    await _dio.fetch<void>(_options);
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(String dioBaseUrl, String? baseUrl) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}

// dart format on
