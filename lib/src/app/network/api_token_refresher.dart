import 'package:dio/dio.dart';
import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/network/api_client.dart';
import 'package:base/src/core/network/app_failure_mapper.dart';
import 'package:base/src/core/network/token_refresher.dart';
import 'package:base/src/core/result/result.dart';
import 'package:base/src/core/storage/session.dart';

/// Concrete [TokenRefresher] exchanging refresh tokens via dedicated no-auth HTTP requests.
final class ApiTokenRefresher implements TokenRefresher {
  /// Creates an [ApiTokenRefresher] backed by [dio] and an optional [ApiClient].
  ApiTokenRefresher({required this.dio, ApiClient? client})
    : _client = client ?? ApiClient(dio);

  /// Dedicated no-auth Dio instance.
  final Dio dio;

  final ApiClient _client;

  @override
  Future<Result<Session>> refresh(String refreshToken) async {
    try {
      final response = await _client.refresh(
        RefreshRequestDto(refreshToken: refreshToken),
      );
      return Result.ok(response.toSession());
    } on DioException catch (e) {
      return Result.err(AppFailureMapper.map(e));
    } catch (_) {
      return const Result.err(AppFailure.unknown());
    }
  }
}
