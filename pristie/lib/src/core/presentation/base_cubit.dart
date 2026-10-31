import 'package:flutter_bloc/flutter_bloc.dart';

import '../error/app_failure.dart';
import '../result/result.dart';
import 'base_state.dart';

abstract class BaseCubit<T> extends Cubit<BaseState<T>> {
  BaseCubit() : super(BaseState<T>.initial());

  void safeEmit(BaseState<T> state) {
    if (!isClosed) emit(state);
  }

  Future<void> execute(Future<Result<T>> Function() operation) async {
    safeEmit(BaseState<T>.loading());
    final result = await operation();
    if (isClosed) return;

    switch (result) {
      case Ok<T>(:final data):
        safeEmit(BaseState<T>.data(data));
      case Err<T>(failure: CancelledFailure()):
        return;
      case Err<T>(:final failure):
        safeEmit(BaseState<T>.error(failure));
    }
  }
}
