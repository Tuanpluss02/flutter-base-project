import 'package:base/src/core/auth/auth_session_controller.dart';
import 'package:base/src/core/result/result.dart';
import 'package:base/src/core/storage/session.dart';

final class LoginUseCase {
  const LoginUseCase(this._sessionController);

  final AuthSessionController _sessionController;

  Future<Result<void>> call() => _sessionController.login(
    Session(
      accessToken: 'demo-access',
      refreshToken: 'demo-refresh',
      tokenType: 'Bearer',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    ),
  );
}
