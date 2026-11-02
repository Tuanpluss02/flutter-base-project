import 'package:pristie/src/core/auth/auth_state.dart';
import 'package:pristie/src/core/auth/session_state_sink.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/core/storage/session.dart';

/// Central controller governing authentication state stream, request gate, and session epochs.
abstract interface class AuthSessionController implements SessionStateSink {
  /// Stream broadcasting authentication state changes.
  Stream<AuthState> get authStateStream;

  /// Current cached [AuthState].
  AuthState get currentAuthState;

  /// Monotonically increasing epoch counter bumped on every session transition.
  int get sessionEpoch;

  /// Whether the volatile network request gate is open for authenticated traffic.
  bool get isRequestGateOpen;

  /// Restores session state from persistent storage during application bootstrap.
  Future<AuthState> restore();

  /// Transitions the controller to authenticated state with [session].
  Future<Result<void>> login(Session session);
}
