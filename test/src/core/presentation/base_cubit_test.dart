import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/presentation/base_cubit.dart';
import 'package:base/src/core/presentation/base_state.dart';
import 'package:base/src/core/result/result.dart';

final class _TestCubit extends BaseCubit<String> {}

void main() {
  group('BaseCubit', () {
    test('does not emit a cancelled result as an error', () async {
      final cubit = _TestCubit();
      final states = <BaseState<String>>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.execute(() async => const Result.err(AppFailure.cancelled()));

      expect(cubit.state, isA<Loading<String>>());
      expect(states, hasLength(1));
      await subscription.cancel();
      await cubit.close();
    });

    test('does not emit after close while an operation is pending', () async {
      final cubit = _TestCubit();
      final completion = Completer<Result<String>>();
      final states = <BaseState<String>>[];
      final subscription = cubit.stream.listen(states.add);
      final execution = cubit.execute(() => completion.future);

      await cubit.close();
      final stateCountAfterClose = states.length;
      completion.complete(const Result.ok('done'));
      await execution;

      expect(states, hasLength(stateCountAfterClose));
      await subscription.cancel();
    });
  });
}
