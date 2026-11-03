import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/presentation/base_cubit.dart';
import 'package:base/src/core/presentation/base_state.dart';

import '../../domain/usecases/login_use_case.dart';

final class LoginCubit extends BaseCubit<void> {
  LoginCubit(this._login);

  final LoginUseCase _login;

  Future<void> submit(String email, String password) async {
    final fields = <String, ValidationIssue>{};
    if (email.trim().isEmpty) {
      fields['email'] = ValidationIssue.required;
    }
    if (password.isEmpty) {
      fields['password'] = ValidationIssue.required;
    }
    if (fields.isNotEmpty) {
      safeEmit(BaseState<void>.error(AppFailure.validation(fields)));
      return;
    }
    await execute(_login.call);
    if (state is Loading<void>) {
      safeEmit(BaseState<void>.initial());
    }
  }
}
