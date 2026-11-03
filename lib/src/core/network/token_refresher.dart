import 'package:base/src/core/result/result.dart';
import 'package:base/src/core/storage/session.dart';

/// Contract for exchanging a refresh token for a newly issued session.
abstract interface class TokenRefresher {
  /// Exchanges [refreshToken] for a newly issued [Session].
  Future<Result<Session>> refresh(String refreshToken);
}
