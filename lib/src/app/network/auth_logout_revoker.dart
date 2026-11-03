import 'package:dio/dio.dart';
import 'package:base/src/core/auth/auth_coordinator.dart';
import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/network/app_failure_mapper.dart';
import 'package:base/src/core/result/result.dart';

/// Concrete [LogoutRevoker] revoking credentials remotely on dedicated no-auth transport.
final class AuthLogoutRevoker implements LogoutRevoker {
  /// Creates an [AuthLogoutRevoker] using [dio].
  AuthLogoutRevoker({required this.dio});

  /// Dedicated no-auth Dio instance.
  final Dio dio;

  @override
  Future<Result<void>> revoke(String refreshToken) async {
    try {
      await dio.post<void>(
        '/api/v1/auth/revoke',
        data: <String, dynamic>{'refresh_token': refreshToken},
        options: Options(
          extra: <String, Object>{
            'no_auth': true,
            'routeTemplate': '/api/v1/auth/revoke',
          },
        ),
      );
      return const Result.ok(null);
    } on DioException catch (e) {
      return Result.err(AppFailureMapper.map(e));
    } catch (_) {
      return const Result.err(AppFailure.unknown());
    }
  }
}
