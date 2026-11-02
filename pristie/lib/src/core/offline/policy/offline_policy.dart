import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pristie/src/core/scope/data_classification.dart';

part 'offline_policy.freezed.dart';

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
