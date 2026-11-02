import 'package:dio/dio.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/network/app_failure_mapper.dart';

/// Interceptor mapping transport exceptions to closed domain [AppFailure] instances.
class ErrorMappingInterceptor extends Interceptor {
  /// Creates an [ErrorMappingInterceptor].
  const ErrorMappingInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.cancel) {
      handler.next(err.copyWith(error: const AppFailure.cancelled()));
      return;
    }

    final mapped = AppFailureMapper.map(err);
    handler.next(err.copyWith(error: mapped));
  }
}
