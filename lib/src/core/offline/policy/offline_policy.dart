import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:base/src/core/scope/data_classification.dart';

part '../../../../generated/src/core/offline/policy/offline_policy.freezed.dart';

/// Local mutation kinds a dataset may allow while offline.
enum OfflineOperation { create, update, delete }

/// Conflict handling strategy declared per dataset.
enum ConflictPolicy { serverWins, featureResolver, manual }

/// Per-dataset offline contract. A dataset without a policy must stay
/// online-only.
@freezed
abstract class OfflinePolicy with _$OfflinePolicy {
  const factory OfflinePolicy({
    required String dataset,
    required DataClassification classification,
    required Duration ttl,
    required Set<OfflineOperation> allowedOperations,
    required ConflictPolicy conflictPolicy,
  }) = _OfflinePolicy;
}

/// Fail-closed policy checks shared by the outbox and sync coordinator.
///
/// S2 (personal) and S3 (secret) data stay online-only until the security
/// gates in the offline-first specification are approved.
extension OfflinePolicyRules on OfflinePolicy {
  /// Whether this dataset may be persisted in the local encrypted database.
  bool get mayPersistLocally =>
      classification == DataClassification.s0 ||
      classification == DataClassification.s1;

  /// Whether [operation] may be queued for this dataset.
  bool allows(OfflineOperation operation) =>
      mayPersistLocally && allowedOperations.contains(operation);
}

/// Thrown when a feature tries to persist data the policy does not allow.
final class OfflinePolicyViolation implements Exception {
  const OfflinePolicyViolation(this.message);

  /// Human-readable reason intended for diagnostics, never for UI.
  final String message;

  @override
  String toString() => 'OfflinePolicyViolation: $message';
}
