import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:base/src/core/storage/session.dart';
import 'package:retrofit/retrofit.dart';

part '../../../generated/src/core/network/api_client.freezed.dart';
part '../../../generated/src/core/network/api_client.g.dart';

/// Sample item transfer object.
@freezed
abstract class ItemDto with _$ItemDto {
  /// Creates an [ItemDto].
  const factory ItemDto({required String id, required String title}) = _ItemDto;

  /// Deserializes JSON map into [ItemDto].
  factory ItemDto.fromJson(Map<String, dynamic> json) =>
      _$ItemDtoFromJson(json);
}

/// Generic paged collection response envelope.
@Freezed(genericArgumentFactories: true)
abstract class PagedResponseDto<T> with _$PagedResponseDto<T> {
  /// Creates a [PagedResponseDto].
  const factory PagedResponseDto({
    @Default(<Never>[]) List<T> items,
    required int page,
    required int pageSize,
    required int total,
    required bool hasMore,
  }) = _PagedResponseDto<T>;

  /// Deserializes JSON map into generic [PagedResponseDto].
  factory PagedResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PagedResponseDtoFromJson(json, fromJsonT);
}

/// Request payload sent to refresh endpoint.
@freezed
abstract class RefreshRequestDto with _$RefreshRequestDto {
  /// Creates a [RefreshRequestDto].
  const factory RefreshRequestDto({required String refreshToken}) =
      _RefreshRequestDto;

  /// Deserializes JSON map into [RefreshRequestDto].
  factory RefreshRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RefreshRequestDtoFromJson(json);
}

/// Response payload received from refresh endpoint.
@freezed
abstract class RefreshResponseDto with _$RefreshResponseDto {
  /// Creates a [RefreshResponseDto].
  const factory RefreshResponseDto({
    required String accessToken,
    required String refreshToken,
    required String tokenType,
    required int expiresIn,
  }) = _RefreshResponseDto;

  /// Deserializes JSON map into [RefreshResponseDto].
  factory RefreshResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RefreshResponseDtoFromJson(json);
}

/// Extension mapping [RefreshResponseDto] to domain [Session].
extension RefreshResponseDtoX on RefreshResponseDto {
  /// Converts this DTO into a persistent [Session].
  Session toSession({DateTime? now}) {
    final current = now ?? DateTime.now().toUtc();
    return Session(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
      expiresAt: current.add(Duration(seconds: expiresIn)),
    );
  }
}

/// Canonical Retrofit HTTP client defining sample remote endpoints.
@RestApi()
abstract class ApiClient {
  /// Creates an [ApiClient] client backed by [dio].
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  /// Retrieves a paginated list of items.
  @GET('/api/v1/items')
  @Extra(<String, Object>{'routeTemplate': '/api/v1/items'})
  Future<PagedResponseDto<ItemDto>> getItems(
    @Query('page') int page,
    @Query('page_size') int pageSize, {
    @CancelRequest() CancelToken? cancelToken,
  });

  /// Refreshes expired access credentials using a dedicated no-auth configuration.
  @POST('/api/v1/auth/refresh')
  @Extra(<String, Object>{
    'no_auth': true,
    'routeTemplate': '/api/v1/auth/refresh',
  })
  Future<RefreshResponseDto> refresh(
    @Body() RefreshRequestDto body, {
    @CancelRequest() CancelToken? cancelToken,
  });

  /// Deletes an item by id returning 204 No Content.
  @DELETE('/api/v1/items/{id}')
  @Extra(<String, Object>{'routeTemplate': '/api/v1/items/{id}'})
  Future<void> deleteItem(
    @Path('id') String id, {
    @CancelRequest() CancelToken? cancelToken,
  });
}
