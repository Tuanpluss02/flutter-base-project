import 'package:base/src/core/auth/auth_coordinator.dart';
import 'package:base/src/core/result/result.dart';

final class LogoutUseCase {
  const LogoutUseCase(this._authCoordinator);

  final AuthCoordinator _authCoordinator;

  Future<Result<void>> call() => _authCoordinator.logout();
}
