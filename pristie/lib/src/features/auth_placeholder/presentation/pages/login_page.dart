import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pristie/src/app/app_router.gr.dart';
import 'package:pristie/src/app/injection.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/presentation/base_state.dart';
import 'package:pristie/src/l10n/strings.g.dart';
import 'package:pristie/src/shared/widgets/app_button.dart';
import 'package:pristie/src/shared/widgets/app_error_view.dart';

import '../cubit/login_cubit.dart';

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<LoginCubit>(),
    child: const _LoginForm(),
  );
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<LoginCubit, BaseState<void>>(
        listener: (context, state) {
          if (state is Data<void>) {
            context.router.replaceAll([const HomeRoute()]);
          }
        },
        builder: (context, state) {
          final validation = _validationFailure(state);
          String? fieldError(String field) =>
              validation?.fields.containsKey(field) ?? false
              ? context.t.login.required
              : null;

          return Scaffold(
            appBar: AppBar(title: Text(context.t.login.title)),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                  children: [
                    TextField(
                      key: const Key('login.email'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: context.t.login.email,
                        errorText: fieldError('email'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('login.password'),
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: context.t.login.password,
                        errorText: fieldError('password'),
                      ),
                      onSubmitted: (_) => _submit(context),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      key: const Key('login.submit'),
                      label: context.t.login.submit,
                      isLoading: state is Loading<void>,
                      onPressed: () => _submit(context),
                    ),
                    if (state case ErrorState<void>(failure: final failure))
                      if (failure is! ValidationFailure)
                        AppErrorView(failure: failure),
                  ],
                ),
              ),
            ),
          );
        },
      );

  void _submit(BuildContext context) {
    context.read<LoginCubit>().submit(
      _emailController.text,
      _passwordController.text,
    );
  }

  ValidationFailure? _validationFailure(BaseState<void> state) {
    if (state case ErrorState<void>(failure: ValidationFailure failure)) {
      return failure;
    }
    return null;
  }
}
