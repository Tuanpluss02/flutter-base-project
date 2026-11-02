import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/presentation/base_state.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/features/auth_placeholder/domain/usecases/login_use_case.dart';
import 'package:pristie/src/features/auth_placeholder/presentation/cubit/login_cubit.dart';

import '../../support/fakes.dart';

void main() {
  group('LoginCubit', () {
    late FakeAuthSessionController controller;
    late LoginCubit cubit;

    setUp(() {
      controller = FakeAuthSessionController();
      cubit = LoginCubit(LoginUseCase(controller));
    });

    tearDown(() async {
      await cubit.close();
      await controller.dispose();
    });

    test(
      'empty credentials emit field validation without logging in',
      () async {
        await cubit.submit('   ', '');

        final state = cubit.state;
        expect(state, isA<ErrorState<void>>());
        final failure = (state as ErrorState<void>).failure;
        expect(failure, isA<ValidationFailure>());
        final fields = (failure as ValidationFailure).fields;
        expect(fields.keys, containsAll(['email', 'password']));
        expect(fields['email'], ValidationIssue.required);
        expect(fields['password'], ValidationIssue.required);
        expect(controller.loginCalls, 0);
      },
    );

    test('reports only the empty field when the other is filled', () async {
      await cubit.submit('demo@example.com', '');

      final failure = (cubit.state as ErrorState<void>).failure;
      final fields = (failure as ValidationFailure).fields;
      expect(fields.keys, ['password']);
    });

    test(
      'valid credentials call the login use case once with demo session',
      () async {
        await cubit.submit('demo@example.com', 'password');

        expect(controller.loginCalls, 1);
        expect(controller.lastSession?.accessToken, 'demo-access');
        expect(cubit.state, isA<Data<void>>());
      },
    );

    test('login failure becomes localized error state', () async {
      controller.loginResult = const Result.err(AppFailure.localPersistence());

      await cubit.submit('demo@example.com', 'password');

      expect(cubit.state, isA<ErrorState<void>>());
      expect(
        (cubit.state as ErrorState<void>).failure,
        const AppFailure.localPersistence(),
      );
    });

    test('cancellation is not presented as a UI error', () async {
      controller.loginResult = const Result.err(AppFailure.cancelled());

      await cubit.submit('demo@example.com', 'password');

      expect(cubit.state, isNot(isA<ErrorState<void>>()));
      expect(controller.loginCalls, 1);
    });

    test('does not emit after close', () async {
      final states = <BaseState<void>>[];
      final subscription = cubit.stream.listen(states.add);
      await cubit.close();

      await cubit.submit('demo@example.com', 'password');
      await pumpEventQueue();

      expect(states, isEmpty);
      expect(controller.loginCalls, 1);
      await subscription.cancel();
    });
  });
}
