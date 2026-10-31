import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/observability/app_logger.dart';

/// Application-wide [BlocObserver] logging state transitions and unhandled exceptions.
class AppBlocObserver extends BlocObserver {
  /// Creates an [AppBlocObserver] reporting through [logger].
  AppBlocObserver({required this.logger});

  /// Underlying sanitized application logger.
  final AppLogger logger;

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    logger.debug(
      'bloc_change',
      fields: {'operation': bloc.runtimeType.toString(), 'stage': 'transition'},
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (_isCancellation(error)) {
      return;
    }
    logger.error(
      'bloc_error',
      fields: {'operation': bloc.runtimeType.toString(), 'stage': 'error'},
      error: error,
      stackTrace: stackTrace,
    );
  }

  bool _isCancellation(Object error) {
    if (error is CancelledFailure) {
      return true;
    }
    if (error is AppFailure && error is CancelledFailure) {
      return true;
    }
    if (error is DioException && error.type == DioExceptionType.cancel) {
      return true;
    }
    return false;
  }
}
