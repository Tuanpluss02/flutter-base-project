import 'package:freezed_annotation/freezed_annotation.dart';

part '../../../generated/src/core/storage/session.freezed.dart';
part '../../../generated/src/core/storage/session.g.dart';

/// Mutually exclusive session record statuses in secure storage.
enum SessionStatus {
  /// Session is valid and active.
  active,

  /// Logout initiated durable state awaiting revocation completion.
  logoutPending,

  /// Session invalidation initiated durable state before token removal.
  sessionInvalidationPending,

  /// Session has been terminated or no session exists.
  signedOut,
}

/// Immutable authentication token session.
@freezed
abstract class Session with _$Session {
  /// Creates a [Session] token pair and expiration details.
  const factory Session({
    required String accessToken,
    required String refreshToken,
    required String tokenType,
    required DateTime expiresAt,
  }) = _Session;

  /// Deserializes a [Session] from JSON.
  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);
}

/// Persisted atomic session record combining status and token data.
@freezed
abstract class SessionRecord with _$SessionRecord {
  /// Creates an atomic [SessionRecord].
  const factory SessionRecord({
    required SessionStatus status,
    Session? session,
  }) = _SessionRecord;

  /// Deserializes a [SessionRecord] from JSON.
  factory SessionRecord.fromJson(Map<String, dynamic> json) =>
      _$SessionRecordFromJson(json);
}
